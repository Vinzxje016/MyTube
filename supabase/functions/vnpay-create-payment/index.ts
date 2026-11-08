import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { signVnpay } from "../_shared/vnpay.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { ...corsHeaders, "Content-Type": "application/json" },
});

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: "Method not allowed." }, 405);

  const authorization = request.headers.get("Authorization");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const tmnCode = Deno.env.get("VNPAY_TMN_CODE");
  const hashSecret = Deno.env.get("VNPAY_HASH_SECRET");
  if (!authorization?.startsWith("Bearer ") || !supabaseUrl || !anonKey) {
    return json({ code: "AUTH_REQUIRED", error: "Authentication is required." }, 401);
  }
  if (!serviceRoleKey || !tmnCode || !hashSecret) {
    return json({ code: "VNPAY_NOT_CONFIGURED", error: "VNPay is not configured." }, 503);
  }

  try {
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) return json({ code: "INVALID_SESSION", error: "Invalid session." }, 401);

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: subscription, error: subscriptionError } = await admin
      .from("premium_subscriptions")
      .select("expires_at")
      .eq("user_id", user.id)
      .maybeSingle();
    if (subscriptionError) throw subscriptionError;
    if (subscription && Date.parse(subscription.expires_at) > Date.now()) {
      return json({ code: "ALREADY_PREMIUM", error: "Premium is already active." }, 409);
    }

    const txnRef = crypto.randomUUID().replaceAll("-", "");
    const { error: insertError } = await admin.from("vnpay_payment_orders").insert({
      txn_ref: txnRef,
      user_id: user.id,
      amount_vnd: 10000,
      status: "pending",
    });
    if (insertError) throw insertError;

    const now = Date.now();
    const params = new URLSearchParams({
      vnp_Version: "2.1.0",
      vnp_Command: "pay",
      vnp_TmnCode: tmnCode,
      vnp_Amount: "1000000",
      vnp_CurrCode: "VND",
      vnp_TxnRef: txnRef,
      vnp_OrderInfo: "MyTube Premium 30 days",
      vnp_OrderType: "other",
      vnp_Locale: "vn",
      vnp_ReturnUrl: `${supabaseUrl}/functions/v1/vnpay-return`,
      vnp_IpAddr: request.headers.get("x-forwarded-for")?.split(",")[0].trim() || "127.0.0.1",
      vnp_CreateDate: formatVnPayDate(now),
      vnp_ExpireDate: formatVnPayDate(now + 15 * 60 * 1000),
    });
    const signature = await signVnpay(params, hashSecret);
    params.set("vnp_SecureHash", signature);
    const paymentUrl = new URL("https://sandbox.vnpayment.vn/paymentv2/vpcpay.html");
    paymentUrl.search = params.toString();
    return json({ paymentUrl: paymentUrl.toString(), txnRef });
  } catch (error) {
    console.error("Could not create VNPay payment:", error);
    return json({ code: "PAYMENT_CREATION_FAILED", error: "Could not create a payment." }, 500);
  }
});

function formatVnPayDate(timestamp: number): string {
  return new Date(timestamp + 7 * 60 * 60 * 1000).toISOString().replace(/[-:TZ.]/g, "").slice(0, 14);
}

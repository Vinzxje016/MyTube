import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { hmacSha256 } from "../_shared/zalopay.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const createOrderEndpoint = "https://sandbox.zalopay.com.vn/v001/tpe/createorder";
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
  const appId = Deno.env.get("ZALOPAY_APP_ID");
  const key1 = Deno.env.get("ZALOPAY_KEY1");
  if (!authorization?.startsWith("Bearer ") || !supabaseUrl || !anonKey) {
    return json({ code: "AUTH_REQUIRED", error: "Authentication is required." }, 401);
  }
  if (!serviceRoleKey || !appId || !key1) {
    return json({ code: "ZALOPAY_NOT_CONFIGURED", error: "ZaloPay is not configured." }, 503);
  }

  let failureStage = "authenticate_user";
  try {
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) return json({ code: "INVALID_SESSION", error: "Invalid session." }, 401);

    failureStage = "check_premium_subscription";
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

    const now = Date.now();
    const datePrefix = new Date(now + 7 * 60 * 60 * 1000).toISOString().slice(2, 10).replaceAll("-", "");
    const appTransId = `${datePrefix}_${crypto.randomUUID().replaceAll("-", "")}`;
    const appTime = now;
    const amount = 10000;
    const embedData = "{}";
    const item = "[]";
    const appUser = user.id;
    failureStage = "save_payment_order";
    const { error: insertError } = await admin.from("zalopay_payment_orders").insert({
      app_trans_id: appTransId,
      user_id: user.id,
      amount_vnd: amount,
      status: "pending",
    });
    if (insertError) {
      console.error("Could not save ZaloPay order:", insertError);
      const isMissingTable = insertError.code === "42P01" ||
        insertError.message.toLowerCase().includes("zalopay_payment_orders");
      return json({
        code: isMissingTable ? "ZALOPAY_SCHEMA_NOT_READY" : "PAYMENT_ORDER_CREATE_FAILED",
        error: isMissingTable
          ? "The ZaloPay payment migration has not been applied."
          : "Could not save the payment order.",
      }, isMissingTable ? 503 : 500);
    }

    const macInput = [appId, appTransId, appUser, amount, appTime, embedData, item].join("|");
    const payload = new URLSearchParams({
      appid: appId,
      apptransid: appTransId,
      appuser: appUser,
      apptime: String(appTime),
      amount: String(amount),
      description: "MyTube Premium 30 days",
      bankcode: "zalopayapp",
      item,
      embeddata: embedData,
      mac: await hmacSha256(macInput, key1),
    });
    failureStage = "request_zalopay_order";
    let response: Response;
    let result: Record<string, unknown>;
    try {
      response = await fetch(createOrderEndpoint, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: payload,
        signal: AbortSignal.timeout(30000),
      });
      result = await response.json();
    } catch (error) {
      console.error(`Could not reach ZaloPay API at ${createOrderEndpoint}:`, error);
      return json({
        code: "ZALOPAY_API_UNAVAILABLE",
        error: "Could not reach ZaloPay Sandbox. Check the Edge Function logs and try again.",
        diagnostic: error instanceof Error
          ? `v1 endpoint ${createOrderEndpoint}: ${error.name}: ${error.message}`
          : `v1 endpoint ${createOrderEndpoint}: ${String(error)}`,
      }, 502);
    }
    if (!response.ok || result.returncode !== 1 || typeof result.orderurl !== "string") {
      console.error("ZaloPay create order failed:", result.returncode, result.returnmessage);
      await admin.from("zalopay_payment_orders")
        .update({ status: "failed" })
        .eq("app_trans_id", appTransId)
        .eq("status", "pending");
      return json({ code: "ZALOPAY_ORDER_REJECTED", error: "ZaloPay rejected the order." }, 502);
    }
    return json({ paymentUrl: result.orderurl, appTransId });
  } catch (error) {
    console.error(`Could not create ZaloPay payment at ${failureStage}:`, error);
    return json({
      code: "PAYMENT_CREATION_FAILED",
      stage: failureStage,
      error: "Could not create a payment. Check the Edge Function logs.",
    }, 500);
  }
});

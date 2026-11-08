import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { hmacSha256, safeEqual } from "../_shared/zalopay.ts";

const response = (return_code: number, return_message: string) =>
  new Response(JSON.stringify({ returncode: return_code, returnmessage: return_message }), {
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (request) => {
  if (request.method !== "POST") return response(2, "Invalid request");
  const key2 = Deno.env.get("ZALOPAY_KEY2");
  const appId = Deno.env.get("ZALOPAY_APP_ID");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  if (!key2 || !appId || !serviceRoleKey || !supabaseUrl) {
    return response(0, "Merchant configuration error");
  }

  try {
    const body = await request.json();
    if (typeof body.data !== "string" || typeof body.mac !== "string") {
      return response(2, "Invalid callback");
    }
    const expectedMac = await hmacSha256(body.data, key2);
    if (!safeEqual(body.mac.toLowerCase(), expectedMac)) return response(2, "Invalid signature");

    const payment = JSON.parse(body.data);
    const appTransId = payment.apptransid;
    const amount = payment.amount;
    const transactionId = payment.zptransid;
    if (payment.appid !== Number(appId) || typeof appTransId !== "string" ||
      !Number.isSafeInteger(amount) || typeof transactionId !== "number") {
      return response(2, "Invalid payment data");
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: order, error: orderError } = await admin
      .from("zalopay_payment_orders")
      .select("amount_vnd, status")
      .eq("app_trans_id", appTransId)
      .maybeSingle();
    if (orderError) throw orderError;
    if (!order || amount !== order.amount_vnd) return response(2, "Order or amount mismatch");
    if (order.status === "paid") return response(1, "Success");
    if (order.status !== "pending") return response(2, "Order already processed");

    const { data: confirmation, error: confirmError } = await admin.rpc("confirm_zalopay_payment", {
      p_app_trans_id: appTransId,
      p_amount_vnd: order.amount_vnd,
      p_transaction_id: String(transactionId),
    });
    if (confirmError) throw confirmError;
    return confirmation === "confirmed" || confirmation === "duplicate"
      ? response(1, "Success")
      : response(2, "Order could not be confirmed");
  } catch (error) {
    console.error("ZaloPay callback processing failed:", error);
    return response(0, "Could not process callback");
  }
});

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { safeEqual, signVnpay } from "../_shared/vnpay.ts";

const response = (RspCode: string, Message: string) =>
  new Response(JSON.stringify({ RspCode, Message }), {
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (request) => {
  if (request.method !== "GET") return response("99", "Method not supported");
  const hashSecret = Deno.env.get("VNPAY_HASH_SECRET");
  const tmnCode = Deno.env.get("VNPAY_TMN_CODE");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  if (!hashSecret || !tmnCode || !serviceRoleKey || !supabaseUrl) {
    return response("99", "Merchant configuration error");
  }

  try {
    const params = new URL(request.url).searchParams;
    const suppliedHash = params.get("vnp_SecureHash") ?? "";
    const expectedHash = await signVnpay(params, hashSecret);
    if (!safeEqual(suppliedHash.toLowerCase(), expectedHash)) return response("97", "Invalid signature");
    if (params.get("vnp_TmnCode") !== tmnCode) return response("97", "Invalid merchant");

    const txnRef = params.get("vnp_TxnRef");
    const amount = Number(params.get("vnp_Amount"));
    const transactionNo = params.get("vnp_TransactionNo") ?? "";
    if (!txnRef || !Number.isSafeInteger(amount)) return response("99", "Invalid payment data");

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: order, error: orderError } = await admin
      .from("vnpay_payment_orders")
      .select("amount_vnd, status")
      .eq("txn_ref", txnRef)
      .maybeSingle();
    if (orderError) throw orderError;
    if (!order) return response("01", "Order not found");
    if (amount !== order.amount_vnd * 100) return response("04", "Invalid amount");
    if (order.status === "paid") return response("02", "Order already confirmed");
    if (order.status !== "pending") return response("02", "Order already processed");

    const successful = params.get("vnp_ResponseCode") === "00" &&
      params.get("vnp_TransactionStatus") === "00";
    if (!successful) {
      const { error } = await admin.from("vnpay_payment_orders")
        .update({ status: "failed" })
        .eq("txn_ref", txnRef)
        .eq("status", "pending");
      if (error) throw error;
      return response("00", "Payment status updated");
    }

    const { data: confirmation, error: confirmError } = await admin.rpc("confirm_vnpay_payment", {
      p_txn_ref: txnRef,
      p_amount_vnd: order.amount_vnd,
      p_transaction_no: transactionNo,
    });
    if (confirmError) throw confirmError;
    if (confirmation === "confirmed" || confirmation === "duplicate") {
      return response(confirmation === "confirmed" ? "00" : "02", "Payment confirmed");
    }
    return response(confirmation === "not_found" ? "01" : "04", "Payment does not match order");
  } catch (error) {
    console.error("VNPay IPN processing failed:", error);
    return response("99", "Could not process payment");
  }
});

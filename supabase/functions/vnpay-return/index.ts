import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { safeEqual, signVnpay } from "../_shared/vnpay.ts";

Deno.serve(async (request) => {
  const params = new URL(request.url).searchParams;
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const hashSecret = Deno.env.get("VNPAY_HASH_SECRET");
  const tmnCode = Deno.env.get("VNPAY_TMN_CODE");
  let status = "unverified";

  try {
    if (supabaseUrl && serviceRoleKey && hashSecret && tmnCode) {
      const suppliedHash = params.get("vnp_SecureHash") ?? "";
      const expectedHash = await signVnpay(params, hashSecret);
      const valid = safeEqual(suppliedHash.toLowerCase(), expectedHash) &&
        params.get("vnp_TmnCode") === tmnCode;

      if (valid) {
        const txnRef = params.get("vnp_TxnRef");
        const amount = Number(params.get("vnp_Amount"));
        const transactionNo = params.get("vnp_TransactionNo") ?? "";
        const successful = params.get("vnp_ResponseCode") === "00" &&
          params.get("vnp_TransactionStatus") === "00";

        if (txnRef && Number.isSafeInteger(amount)) {
          const admin = createClient(supabaseUrl, serviceRoleKey, {
            auth: { persistSession: false, autoRefreshToken: false },
          });
          const { data: order, error: orderError } = await admin
            .from("vnpay_payment_orders")
            .select("amount_vnd, status")
            .eq("txn_ref", txnRef)
            .maybeSingle();
          if (orderError) throw orderError;

          if (order && amount === order.amount_vnd * 100) {
            if (successful && (order.status === "pending" || order.status === "paid")) {
              const { data: confirmation, error: confirmError } = await admin.rpc("confirm_vnpay_payment", {
                p_txn_ref: txnRef,
                p_amount_vnd: order.amount_vnd,
                p_transaction_no: transactionNo,
              });
              if (confirmError) throw confirmError;
              if (confirmation === "confirmed" || confirmation === "duplicate") status = "success";
            } else if (!successful && order.status === "pending") {
              const { error: updateError } = await admin
                .from("vnpay_payment_orders")
                .update({ status: "failed" })
                .eq("txn_ref", txnRef)
                .eq("status", "pending");
              if (updateError) throw updateError;
              status = "failed";
            } else if (!successful && order.status === "failed") {
              status = "failed";
            }
          }
        }
      }
    }
  } catch (error) {
    console.error("VNPay return processing failed:", error);
  }

  const appReturn = new URL("mytube://payment-return");
  appReturn.searchParams.set("status", status);
  const txnRef = params.get("vnp_TxnRef");
  if (txnRef) appReturn.searchParams.set("txnRef", txnRef);

  return new Response(null, {
    status: 302,
    headers: {
      "Location": appReturn.toString(),
      "Cache-Control": "no-store",
    },
  });
});

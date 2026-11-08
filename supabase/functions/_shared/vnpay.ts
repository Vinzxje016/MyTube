const encoder = new TextEncoder();

export function vnpaySignatureData(params: URLSearchParams): string {
  return [...params.entries()]
    .filter(([key]) => key.startsWith("vnp_") && key !== "vnp_SecureHash" && key !== "vnp_SecureHashType")
    .sort(([a], [b]) => a < b ? -1 : a > b ? 1 : 0)
    .map(([key, value]) => `${formEncode(key)}=${formEncode(value)}`)
    .join("&");
}

function formEncode(value: string): string {
  return encodeURIComponent(value).replace(/%20/g, "+");
}

export async function signVnpay(params: URLSearchParams, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-512" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(vnpaySignatureData(params)));
  return [...new Uint8Array(signature)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

export function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let mismatch = 0;
  for (let i = 0; i < a.length; i++) mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return mismatch === 0;
}

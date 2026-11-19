// SmartBudget — PayPal helpers (a billing provider adapter).
//
// PayPal Subscriptions: create a subscription from a billing plan and hand the
// user PayPal's approval URL; the webhook (BILLING.SUBSCRIPTION.*) grants or
// revokes entitlement. Client id/secret live ONLY in Edge Function secrets.

export function paypalApiBase(): string {
  // Live: https://api-m.paypal.com  · Sandbox: https://api-m.sandbox.paypal.com
  return (Deno.env.get("PAYPAL_API_URL") ?? "https://api-m.paypal.com")
    .replace(/\/+$/, "");
}

export function paypalConfigured(): boolean {
  return Boolean(
    (Deno.env.get("PAYPAL_CLIENT_ID") ?? "").trim() &&
      (Deno.env.get("PAYPAL_SECRET") ?? "").trim(),
  );
}

/**
 * The last access token, kept until a minute before PayPal says it expires
 * (expires_in, usually hours), per API URL and client id. Without it every
 * call — including every webhook delivery, forged or not — asked PayPal for a
 * new token (security audit F-06).
 */
let cachedToken: { key: string; token: string; until: number } | null = null;

/** Seconds a token is reused for: PayPal's expires_in minus a minute, or 0. */
export function tokenLifetimeS(expiresIn: unknown): number {
  const s = Number(expiresIn);
  return Number.isFinite(s) && s > 60 ? Math.floor(s - 60) : 0;
}

/** OAuth2 client-credentials access token, or throws. */
export async function paypalAccessToken(now: number = Date.now()): Promise<string> {
  const id = (Deno.env.get("PAYPAL_CLIENT_ID") ?? "").trim();
  const secret = (Deno.env.get("PAYPAL_SECRET") ?? "").trim();
  const key = `${paypalApiBase()} ${id}`;
  if (cachedToken && cachedToken.key === key && now < cachedToken.until) {
    return cachedToken.token;
  }
  const res = await fetch(`${paypalApiBase()}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      "Authorization": `Basic ${btoa(`${id}:${secret}`)}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });
  if (!res.ok) throw new Error("paypal_auth_failed");
  const j = await res.json();
  const token = String(j.access_token);
  const lifetime = tokenLifetimeS(j.expires_in);
  cachedToken = lifetime > 0 ? { key, token, until: now + lifetime * 1000 } : null;
  return token;
}

/** Where PayPal publishes the certificates it signs webhooks with (live and
 * sandbox). Anything else cannot be a genuine PayPal delivery. */
const PAYPAL_CERT_URL =
  /^https:\/\/api(-m)?(\.sandbox)?\.paypal\.com\/v1\/notifications\/certs\/\S+$/;

/**
 * A free, local check of PayPal's signature headers before anything is asked
 * of PayPal: the algorithm PayPal signs with and a certificate URL on
 * PayPal's own API host. It proves nothing by itself (the headers are
 * public), but a request that fails it is refused without spending a call to
 * PayPal's verify API (security audit F-06). Verification stays with PayPal.
 */
export function plausiblePaypalSignature(headers: Headers): boolean {
  return headers.get("paypal-auth-algo") === "SHA256withRSA" &&
    PAYPAL_CERT_URL.test(headers.get("paypal-cert-url") ?? "");
}

/**
 * Create a subscription for a billing plan and return the approval URL the user
 * must visit, or null. custom_id carries our user id back on the webhook.
 */
export async function createPaypalSubscription(
  token: string,
  planId: string,
  userId: string,
  returnUrl?: string,
  cancelUrl?: string,
): Promise<string | null> {
  const res = await fetch(`${paypalApiBase()}/v1/billing/subscriptions`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      plan_id: planId,
      custom_id: userId,
      application_context: {
        user_action: "SUBSCRIBE_NOW",
        shipping_preference: "NO_SHIPPING",
        ...(returnUrl ? { return_url: returnUrl } : {}),
        ...(cancelUrl ? { cancel_url: cancelUrl } : {}),
      },
    }),
  });
  if (!res.ok) return null;
  const j = await res.json();
  const links: Array<{ rel?: string; href?: string }> = j?.links ?? [];
  return links.find((l) => l.rel === "approve")?.href ?? null;
}

/**
 * Verify a PayPal webhook using PayPal's verify-webhook-signature API. Needs the
 * transmission headers, the configured webhook id, and the PARSED event object.
 */
export async function verifyPaypalWebhook(
  token: string,
  headers: Headers,
  webhookId: string,
  event: unknown,
): Promise<boolean> {
  if (!webhookId) return false;
  const res = await fetch(
    `${paypalApiBase()}/v1/notifications/verify-webhook-signature`,
    {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        auth_algo: headers.get("paypal-auth-algo"),
        cert_url: headers.get("paypal-cert-url"),
        transmission_id: headers.get("paypal-transmission-id"),
        transmission_sig: headers.get("paypal-transmission-sig"),
        transmission_time: headers.get("paypal-transmission-time"),
        webhook_id: webhookId,
        webhook_event: event,
      }),
    },
  );
  if (!res.ok) return false;
  const j = await res.json();
  return j?.verification_status === "SUCCESS";
}

/** A captured payment (sale): its subscription and amount, or throws. */
export async function paypalSale(
  token: string,
  saleId: string,
): Promise<{ subscriptionId: string | null; total: number }> {
  const res = await fetch(
    `${paypalApiBase()}/v1/payments/sale/${encodeURIComponent(saleId)}`,
    { headers: { "Authorization": `Bearer ${token}` } },
  );
  if (!res.ok) throw new Error("paypal_sale_lookup_failed");
  const j = await res.json();
  return {
    subscriptionId: j?.billing_agreement_id ? String(j.billing_agreement_id) : null,
    total: Number(j?.amount?.total ?? NaN),
  };
}

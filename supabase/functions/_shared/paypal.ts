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

/** OAuth2 client-credentials access token, or throws. */
export async function paypalAccessToken(): Promise<string> {
  const id = (Deno.env.get("PAYPAL_CLIENT_ID") ?? "").trim();
  const secret = (Deno.env.get("PAYPAL_SECRET") ?? "").trim();
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
  return String(j.access_token);
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

// SmartBudget — Whop helpers (a billing provider adapter).
//
// Whop sells each plan as a "plan" (plan_...) of a product; a purchase is a
// "membership" (mem_...). create-checkout makes a checkout configuration for
// the plan, carrying our user id in its metadata (Whop copies it onto the
// membership), and sends the buyer to its purchase_url. whop-webhook then
// reads the membership back from the API and applies it. The API key and
// webhook secret live ONLY in Edge Function secrets.
//
// Shapes follow Whop's API v1 (https://api.whop.com/api/v1, as in the
// official @whop/sdk): POST /checkout_configurations, GET /memberships/{id}.

import type { SubStatus } from "./subscriptions.ts";

/** Live: https://api.whop.com/api/v1 · Sandbox: https://sandbox-api.whop.com/api/v1 */
export function whopApiBase(): string {
  return (Deno.env.get("WHOP_API_URL") ?? "https://api.whop.com/api/v1")
    .replace(/\/+$/, "");
}

export function whopApiKey(): string {
  return (Deno.env.get("WHOP_API_KEY") ?? "").trim();
}

export function whopConfigured(): boolean {
  return Boolean(whopApiKey());
}

// deno-lint-ignore no-explicit-any
type Json = any;

/** A hosted checkout URL for [planId], or null when Whop gives none. */
export async function createWhopCheckout(
  planId: string,
  metadata: Record<string, string>,
  redirectUrl?: string,
): Promise<string | null> {
  const account = (Deno.env.get("WHOP_COMPANY_ID") ?? "").trim();
  const res = await fetch(`${whopApiBase()}/checkout_configurations`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${whopApiKey()}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      plan_id: planId,
      metadata,
      ...(account ? { account_id: account } : {}),
      ...(redirectUrl ? { redirect_url: redirectUrl } : {}),
    }),
  });
  if (!res.ok) return null;
  const data: Json = await res.json().catch(() => ({}));
  const url = data?.purchase_url;
  return typeof url === "string" && url ? url : null;
}

/** The membership as Whop has it now, or null when Whop doesn't know it.
 * Throws on any other failure, so the webhook is retried. */
export async function fetchWhopMembership(id: string): Promise<Json | null> {
  const res = await fetch(
    `${whopApiBase()}/memberships/${encodeURIComponent(id)}`,
    { headers: { "Authorization": `Bearer ${whopApiKey()}` } },
  );
  if (res.status === 404) return null;
  if (!res.ok) throw new Error("whop_membership_" + res.status);
  return await res.json();
}

/** The membership an event is about: the event's own object when it is a
 * membership, or the one a payment, refund or dispute belongs to. */
export function membershipIdOf(data: Json): string | null {
  const candidates = [
    data?.id,
    data?.membership_id,
    data?.membership?.id,
    data?.payment?.membership_id,
    data?.payment?.membership?.id,
  ];
  for (const c of candidates) {
    const s = String(c ?? "");
    if (s.startsWith("mem_")) return s;
  }
  return null;
}

/** Our status for a Whop membership status, and whether it ends at the end
 * of the paid period. Null for one we don't know. */
export function whopStatus(
  s: unknown,
): { status: SubStatus; cancelAtPeriodEnd: boolean } | null {
  switch (String(s ?? "").toLowerCase()) {
    case "active":
      return { status: "active", cancelAtPeriodEnd: false };
    case "trialing":
      return { status: "trialing", cancelAtPeriodEnd: false };
    case "canceling":
      // Cancelled by the buyer, still paid until the period ends.
      return { status: "active", cancelAtPeriodEnd: true };
    case "past_due":
      return { status: "past_due", cancelAtPeriodEnd: false };
    case "unresolved":
      // A payment problem being worked out: no access meanwhile.
      return { status: "paused", cancelAtPeriodEnd: false };
    case "canceled":
    case "expired":
    case "completed":
      return { status: "canceled", cancelAtPeriodEnd: false };
    case "drafted":
      return { status: "pending", cancelAtPeriodEnd: false };
    default:
      return null;
  }
}

/** How far a webhook's signing time may be from now, in seconds. */
export const WHOP_SIGNATURE_MAX_AGE_S = 300;

/**
 * Verify a Whop webhook (Standard Webhooks): the signed content is
 * `${webhook-id}.${webhook-timestamp}.${body}`, HMAC-SHA256, base64, sent in
 * `webhook-signature` as space-separated `v1,<signature>` entries. Whop keys
 * the HMAC with the secret's own UTF-8 bytes, exactly as shown in the
 * dashboard (`ws_...`), prefix included. A signature made more than
 * [WHOP_SIGNATURE_MAX_AGE_S] from now is refused.
 */
export async function verifyWhopSignature(
  rawBody: string,
  headers: Headers,
  secret: string,
  nowS: number = Date.now() / 1000,
): Promise<boolean> {
  const id = headers.get("webhook-id") ?? "";
  const ts = headers.get("webhook-timestamp") ?? "";
  const sigs = headers.get("webhook-signature") ?? "";
  if (!id || !ts || !sigs || !secret) return false;
  const signedAt = Number(ts);
  if (
    !Number.isFinite(signedAt) ||
    Math.abs(nowS - signedAt) > WHOP_SIGNATURE_MAX_AGE_S
  ) {
    return false;
  }
  const expected = await whopSign(secret, id, ts, rawBody);
  return sigs.split(" ").some((entry) => {
    const [version, sig] = entry.split(",", 2);
    return version === "v1" && !!sig && timingSafeEqual(sig, expected);
  });
}

/** The `v1` signature of one delivery (also used by the tests). */
export function whopSign(
  secret: string,
  id: string,
  ts: string,
  rawBody: string,
): Promise<string> {
  return hmacBase64(new TextEncoder().encode(secret), `${id}.${ts}.${rawBody}`);
}

/** Base64 HMAC-SHA256 of [content] under [key]. */
export async function hmacBase64(key: BufferSource, content: string): Promise<string> {
  const k = await crypto.subtle.importKey(
    "raw",
    key,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = await crypto.subtle.sign("HMAC", k, new TextEncoder().encode(content));
  let binary = "";
  for (const b of new Uint8Array(mac)) binary += String.fromCharCode(b);
  return btoa(binary);
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

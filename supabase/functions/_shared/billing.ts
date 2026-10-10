// SmartBudget — billing helpers (provider-agnostic core).
//
// Price map, webhook idempotency and Paddle signatures. The webhooks apply
// subscription changes through subscriptions.ts. Nothing here talks to a
// specific provider except verifyPaddleSignature (clearly named).
import type { SupabaseClient } from "npm:@supabase/supabase-js@2.117.2";
import { HttpError } from "./auth.ts";
import { normalizePlan, type Plan } from "./quota.ts";

export interface PriceMapping {
  plan: Plan;
  period: "monthly" | "yearly";
}

/**
 * Resolve a provider price id to (plan, period) via billing_prices. Webhooks
 * pass [includeRetired]: a price no longer sold still maps for the people
 * subscribed on it.
 */
export async function priceToPlan(
  db: SupabaseClient,
  priceId: string,
  provider = "paddle",
  includeRetired = false,
): Promise<PriceMapping | null> {
  const { data } = await db.from("billing_prices")
    .select("plan, period, active")
    .eq("price_id", priceId).eq("provider", provider).maybeSingle();
  if (!data || (!includeRetired && data.active !== true)) return null;
  return {
    plan: normalizePlan(data.plan),
    period: data.period === "yearly" ? "yearly" : "monthly",
  };
}

/** The provider price id for a (plan, period), or null. */
export async function planToPrice(
  db: SupabaseClient,
  plan: Plan,
  period: "monthly" | "yearly",
  provider = "paddle",
): Promise<string | null> {
  const { data } = await db.from("billing_prices")
    .select("price_id").eq("plan", plan).eq("period", period)
    .eq("provider", provider).eq("active", true).maybeSingle();
  return (data?.price_id as string | undefined) ?? null;
}

/**
 * True once, then false — records the event id so replays are ignored. Any
 * other failure throws, so the provider retries the delivery later.
 */
export async function markEventOnce(
  db: SupabaseClient,
  eventId: string,
  type: string,
  provider = "paddle",
): Promise<boolean> {
  if (!eventId) return true; // no id ⇒ can't dedupe; let caller proceed
  const { error } = await db.from("billing_events")
    .insert({ event_id: eventId, type, provider });
  if (!error) return true;
  // A duplicate primary key means we've already processed this event.
  if (error.code === "23505") return false;
  throw new HttpError(500, "event_store_failed");
}

/** Forgets an event that couldn't be applied, so its retry is processed. */
export async function unmarkEvent(
  db: SupabaseClient,
  eventId: string,
): Promise<void> {
  if (!eventId) return;
  try {
    await db.from("billing_events").delete().eq("event_id", eventId);
  } catch (_) {
    // The retry will then be seen as a duplicate; logged by the caller.
  }
}

/** How far a Paddle webhook's signing time may be from now, in seconds. */
export const PADDLE_SIGNATURE_MAX_AGE_S = 300;

/**
 * Verify a Paddle Billing webhook signature.
 * Header format: `ts=<unix>;h1=<hex hmac>`; the signed payload is
 * `${ts}:${rawBody}` HMAC-SHA256 with the webhook secret. A signature made
 * more than [PADDLE_SIGNATURE_MAX_AGE_S] from now is refused, so a captured
 * webhook can't be sent again later (Paddle signs each retry afresh).
 */
export async function verifyPaddleSignature(
  rawBody: string,
  signatureHeader: string | null,
  secret: string,
  nowS: number = Date.now() / 1000,
): Promise<boolean> {
  if (!signatureHeader || !secret) return false;
  const parts = Object.fromEntries(
    signatureHeader.split(";").map((kv) => {
      const i = kv.indexOf("=");
      return [kv.slice(0, i).trim(), kv.slice(i + 1).trim()];
    }),
  );
  const ts = parts["ts"];
  const h1 = parts["h1"];
  if (!ts || !h1) return false;
  const signedAt = Number(ts);
  if (
    !Number.isFinite(signedAt) ||
    Math.abs(nowS - signedAt) > PADDLE_SIGNATURE_MAX_AGE_S
  ) {
    return false;
  }

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(`${ts}:${rawBody}`),
  );
  const hex = Array.from(new Uint8Array(mac))
    .map((b) => b.toString(16).padStart(2, "0")).join("");
  return timingSafeEqual(hex, h1);
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

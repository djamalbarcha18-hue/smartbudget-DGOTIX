// Shared setup for the Edge Function scenario tests: each function's handler
// is captured instead of served, outside services (Gemini, PayPal) are stubbed,
// and the database is the in-memory fake_supabase.ts. When PGHOST is set, the
// subscription function apply_subscription_event runs on that real Postgres
// (supabase/setup_all.sql applied), so lifecycle tests exercise the real SQL.
// deno-lint-ignore-file no-explicit-any
for (const [k, v] of Object.entries({
  BETA_ALL_ACCESS: "false", PADDLE_WEBHOOK_SECRET: "whsec_test", PAYPAL_CLIENT_ID: "c",
  PAYPAL_SECRET: "s", PAYPAL_WEBHOOK_ID: "w", PAYPAL_API_URL: "https://api-m.sandbox.paypal.com",
  GEMINI_API_KEY: "k", SUPABASE_URL: "http://x", SUPABASE_ANON_KEY: "a", SUPABASE_SERVICE_ROLE_KEY: "s",
  PADDLE_API_KEY: "pk",
})) Deno.env.set(k, v);

const g = globalThis as any;
g.__db = { tables: {}, failTable: "", failRpc: "", calls: [] };
export const db = g.__db;

/** Runs SQL on the test Postgres (PGHOST etc.) and returns the first column. */
export async function sql(q: string): Promise<string> {
  const out = await new Deno.Command("psql", {
    args: ["-v", "ON_ERROR_STOP=1", "-tAc", q],
    stdout: "piped",
    stderr: "piped",
  }).output();
  if (!out.success) throw new Error(new TextDecoder().decode(out.stderr));
  return new TextDecoder().decode(out.stdout).trim();
}
if (Deno.env.get("PGHOST")) g.__pg = sql;

const handlers: Record<string, (r: Request) => Promise<Response>> = {};
let current = "";
(Deno as any).serve = (h: any) => { handlers[current] = h; return { finished: Promise.resolve() }; };

export const model = {
  reply: "ok",
  calls: 0,
  /** Model ids that answer with this HTTP status instead (e.g. 503, 404). */
  fail: {} as Record<string, number>,
  /** The model ids asked, in order. */
  asked: [] as string[],
};
/** PayPal sales by id, as the sale lookup returns them. */
export const paypalSales: Record<string, any> = {};

/** Every outside URL the functions called, in order. */
export const outbound: string[] = [];

globalThis.fetch = (async (input: any, init?: any) => {
  outbound.push(String(input?.url ?? input));
  const url = String(input instanceof Request ? input.url : input);
  if (url.includes("generativelanguage")) {
    model.calls++;
    const id = url.match(/models\/([^:]+):/)?.[1] ?? "";
    model.asked.push(id);
    if (model.fail[id]) {
      return new Response(JSON.stringify({ error: { message: "stub " + model.fail[id] } }), { status: model.fail[id] });
    }
    const h = new Headers(init?.headers);
    if (url.includes("key=") || h.get("x-goog-api-key") !== "k") throw new Error("Gemini key not sent as a header");
    await new Promise((r) => setTimeout(r, 20));
    const text = String(init?.body ?? "").includes("inline_data") ? model.reply : "ok";
    return new Response(JSON.stringify({ candidates: [{ content: { parts: [{ text }] }, finishReason: "STOP" }], usageMetadata: { promptTokenCount: 10, candidatesTokenCount: 2 } }));
  }
  if (url.includes("/v1/oauth2/token")) return new Response(JSON.stringify({ access_token: "t" }));
  if (url.includes("verify-webhook-signature")) return new Response(JSON.stringify({ verification_status: "SUCCESS" }));
  const sale = url.match(/\/v1\/payments\/sale\/([^/?]+)/);
  if (sale) {
    const s = paypalSales[decodeURIComponent(sale[1])];
    return s ? new Response(JSON.stringify(s)) : new Response("{}", { status: 404 });
  }
  if (url.includes("/transactions")) {
    return new Response(JSON.stringify({ data: { checkout: { url: "https://pay.example/checkout" } } }));
  }
  throw new Error("unexpected fetch " + url);
}) as typeof fetch;

/** Loads the named functions; returns their request handlers. */
export async function load(...fns: string[]) {
  for (const fn of fns) {
    current = fn;
    await import(new URL("../functions/" + fn + "/index.ts", import.meta.url).href);
  }
  return handlers;
}

const results: string[] = [];
export function check(name: string, ok: boolean, detail = "") {
  results.push((ok ? "PASS " : "FAIL ") + name + (ok ? "" : "  -> " + detail));
}
/** Prints the results and exits non-zero if any failed. */
export function finish() {
  console.log(results.join("\n"));
  const failed = results.filter((x) => x.startsWith("FAIL")).length;
  console.log((results.length - failed) + " passed, " + failed + " failed");
  if (failed > 0) Deno.exit(1);
}

export async function sign(body: string, ts = Math.floor(Date.now() / 1000)) {
  const k = await crypto.subtle.importKey("raw", new TextEncoder().encode(Deno.env.get("PADDLE_WEBHOOK_SECRET")!), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const mac = await crypto.subtle.sign("HMAC", k, new TextEncoder().encode(ts + ":" + body));
  return "ts=" + ts + ";h1=" + Array.from(new Uint8Array(mac)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

/** Sends a Paddle event (correctly signed unless [sig] is given). */
export async function paddle(evt: any, sig?: string) {
  const body = typeof evt === "string" ? evt : JSON.stringify(evt);
  const res = await handlers["paddle-webhook"](new Request("http://x/", { method: "POST", body, headers: { "Paddle-Signature": sig ?? await sign(body) } }));
  return { status: res.status, body: await res.json() };
}

/** The headers PayPal signs a webhook with (the verify API stub accepts them). */
export const paypalHeaders = {
  "paypal-auth-algo": "SHA256withRSA",
  "paypal-cert-url": "https://api.paypal.com/v1/notifications/certs/CERT",
  "paypal-transmission-id": "t-1",
  "paypal-transmission-sig": "sig",
  "paypal-transmission-time": "2026-10-01T10:00:00Z",
};

/** Sends a PayPal event (the verify API stub accepts it). */
export async function paypal(evt: any, headers: Record<string, string> = paypalHeaders) {
  const res = await handlers["paypal-webhook"](new Request("http://x/", { method: "POST", body: JSON.stringify(evt), headers }));
  return { status: res.status, body: await res.json() };
}

/** A Paddle subscription.* event. */
export const paddleSub = (
  id: string, type: string, user: string | null, sub: string, price: string, status: string,
  at: string, extra: any = {},
) => ({
  event_id: id, event_type: type, occurred_at: at,
  data: { id: sub, status, items: [{ price: { id: price } }], custom_data: user ? { user_id: user } : {}, ...extra },
});

/** A PayPal BILLING.SUBSCRIPTION.* event. */
export const paypalSub = (
  id: string, type: string, user: string | null, sub: string, plan: string, status: string,
  at: string, extra: any = {},
) => ({
  id, event_type: type, create_time: at,
  resource: { id: sub, plan_id: plan, custom_id: user ?? undefined, status, ...extra },
});

export const PRICES = [
  { price_id: "pri_basic", provider: "paddle", plan: "basic", period: "monthly", active: true },
  { price_id: "pri_pro", provider: "paddle", plan: "pro", period: "monthly", active: true },
  { price_id: "pri_old", provider: "paddle", plan: "basic", period: "monthly", active: false },
  { price_id: "P-BASIC", provider: "paypal", plan: "basic", period: "monthly", active: true },
  { price_id: "P-PRO", provider: "paypal", plan: "pro", period: "monthly", active: true },
];

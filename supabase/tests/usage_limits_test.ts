// Limits against mass sign-ups, end to end: the real ai-gateway, receipt-scan,
// create-checkout and delete-account handlers (harness.ts) reserving usage
// through the real SQL on Postgres (supabase/setup_all.sql applied; see
// .github/workflows/security-tests.yml). Needs PGHOST/PGUSER/PGPASSWORD.
//   deno run -A --import-map supabase/tests/import_map.json supabase/tests/usage_limits_test.ts
// Exits non-zero when a scenario fails.
// deno-lint-ignore-file no-explicit-any
import { check, db, finish, load, model, PRICES, sql } from "./harness.ts";

if (!Deno.env.get("PGHOST")) throw new Error("set PGHOST (and PGUSER/PGPASSWORD) to a database with setup_all.sql");
const handlers = await load("ai-gateway", "receipt-scan", "create-checkout", "delete-account");
db.tables.billing_prices = PRICES;
Deno.env.set("BETA_ALL_ACCESS", "true"); // every account gets PRO's features
const month = new Date().toISOString().slice(0, 7);

/** An account [days] old; unconfirmed when [confirmed] is false. */
async function account(days: number, confirmed = true): Promise<string> {
  const id = crypto.randomUUID();
  await sql(`insert into auth.users (id, email, created_at, email_confirmed_at)
    values ('${id}', '${id}@test', now() - interval '${days} days', ${confirmed ? "now()" : "null"})`);
  return id;
}
const call = async (fn: string, u: string, body: any = {}) => {
  const res = await handlers[fn](new Request("http://x/", { method: "POST", headers: { Authorization: "Bearer user-" + u }, body: JSON.stringify(body) }));
  return { status: res.status, body: await res.json() };
};
const ask = (u: string) => call("ai-gateway", u, { prompt: "hi" });
const scan = (u: string) => call("receipt-scan", u, { imageBase64: "AAAA", mimeType: "image/jpeg", v: 2 });
const many = async (n: number, f: () => Promise<any>) => await Promise.all(Array.from({ length: n }, f));
const served = (rs: any[]) => rs.filter((r) => r.status === 200).length;
const freshWindow = (u: string) => sql(`delete from rate_limits where user_id = '${u}'`);

// ---- New and unconfirmed accounts don't get PRO's allowance ----
{
  const u = await account(0);
  model.calls = 0;
  const rs = await many(12, () => ask(u));
  check("New account (beta): 12 questions at once, 5 answered (daily cap)", served(rs) === 5 && model.calls === 5, rs.map((r) => r.status).join(","));
  check("New account: the rest are told the daily limit (5) or the per-minute limit (10) is reached", rs.filter((r) => r.body.scope === "daily").length === 5 && rs.filter((r) => r.body.error === "rate_limited").length === 2, JSON.stringify(rs.map((r) => r.body)));
  await sql(`update usage_daily set count = 0 where user_id = '${u}'`);
  await sql(`update ai_usage_monthly set requests = 10 where user_id = '${u}'`);
  await freshWindow(u);
  const r = await ask(u);
  check("New account: at most 10 answers a month, whatever the plan", r.status === 429 && r.body.error === "quota_exceeded" && !r.body.scope, JSON.stringify(r));
}
{
  const u = await account(30, false);
  const rs = await many(8, () => ask(u));
  check("Unconfirmed account, even an old one, is treated as new", served(rs) === 5, rs.map((r) => r.status).join(","));
}
{
  const u = await account(30);
  const rs = await many(12, () => ask(u));
  check("Established account: more than a new one, up to the per-minute limit (10)", served(rs) === 10 && rs.filter((r) => r.body.error === "rate_limited").length === 2, rs.map((r) => r.status).join(","));
  await sql(`update usage_daily set count = 30 where user_id = '${u}'`);
  await freshWindow(u);
  const r = await ask(u);
  check("Established account: daily cap (30)", r.status === 429 && r.body.scope === "daily", JSON.stringify(r));
}
{
  const u = await account(0);
  model.reply = JSON.stringify({ r: true, inv: "", dt: "2026-10-01", cur: "USD", sym: "$", sup: "S", cus: "", cat: "x", it: [], sub: "", dis: "", tax: "", tot: "9.50", paid: "", due: "" });
  const rs = await many(5, () => scan(u));
  check("New account: 5 scans at once, 3 read (daily cap)", served(rs) === 3, rs.map((r) => r.status).join(","));
  const before = await sql(`select count from usage_pools where kind = 'ocr' and month = '${month}' and pool = 'new'`);
  model.reply = JSON.stringify({ r: false });
  await sql(`update usage_daily set count = 0 where user_id = '${u}'`);
  await freshWindow(u);
  const r = await scan(u);
  const after = await sql(`select count from usage_pools where kind = 'ocr' and month = '${month}' and pool = 'new'`);
  check("An unreadable photo gives back its scan, also in the new accounts' share", r.body.reason === "unreadable" && before === after, `${before} -> ${after}`);
}

// ---- Shares of the monthly capacity: fake accounts can't use it all ----
{
  Deno.env.set("AI_GLOBAL_MONTHLY_REQUESTS", "1000"); // unpaid share 700, new 200
  await sql(`insert into usage_pools (kind, month, pool, count) values ('ai', '${month}', 'unpaid', 700)
    on conflict (kind, month, pool) do update set count = 700`);
  const est = await account(30);
  const r1 = await ask(est);
  check("Unpaid accounts' share used up: an established free account is turned away", r1.status === 503 && r1.body.error === "ai_unavailable", JSON.stringify(r1));
  const paid = await account(0);
  db.tables.ai_entitlements = [{ user_id: paid, plan: "pro" }];
  const r2 = await ask(paid);
  check("…while a paying account (even a new one) is still served", r2.status === 200, JSON.stringify(r2));

  await sql(`update usage_pools set count = 300 where kind = 'ai' and month = '${month}' and pool = 'unpaid'`);
  await sql(`insert into usage_pools (kind, month, pool, count) values ('ai', '${month}', 'new', 200)
    on conflict (kind, month, pool) do update set count = 200`);
  const fresh = await account(0);
  const r3 = await ask(fresh);
  check("New accounts' share used up: a new account is turned away", r3.status === 503, JSON.stringify(r3));
  await freshWindow(est);
  const r4 = await ask(est);
  check("…while an established account is still served", r4.status === 200, JSON.stringify(r4));
  Deno.env.delete("AI_GLOBAL_MONTHLY_REQUESTS");
}

// ---- Rate limits on the other costly functions ----
{
  const u = await account(30);
  const rs: any[] = [];
  for (let i = 0; i < 11; i++) rs.push(await call("create-checkout", u, { plan: "pro", period: "monthly" }));
  check("Checkout: 10 an hour per account, the 11th refused", rs.slice(0, 10).every((r) => r.status === 200) && rs[10].status === 429 && rs[10].body.error === "rate_limited", rs.map((r) => r.status).join(","));
  const ds: any[] = [];
  for (let i = 0; i < 6; i++) ds.push(await call("delete-account", u));
  check("Account deletion: 5 an hour per account, the 6th refused", ds[5].status === 429 && ds.slice(0, 5).every((r) => r.status !== 429), ds.map((r) => r.status).join(","));
}

finish();

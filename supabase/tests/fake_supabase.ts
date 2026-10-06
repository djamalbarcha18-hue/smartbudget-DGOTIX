// In-memory stand-in for supabase-js, enough for functions_test.ts. State is
// shared through globalThis.__db so the test can seed and inspect it.
// db.failTable (or FAIL_TABLE) makes writes to that table fail, db.failRpc
// makes that database function fail; NO_EVENT_COL hides
// subscriptions.provider_event_at and NO_RPC removes the database functions,
// as in a database without supabase/security_hardening.sql.
// apply_subscription_event runs on the real Postgres when the test provides
// one (globalThis.__pg, see harness.ts); otherwise its calls are recorded in
// db.calls and answered 'applied'.
// deno-lint-ignore-file no-explicit-any
type Row = Record<string, any>;
const g = globalThis as any;
g.__db ??= { tables: {} as Record<string, Row[]>, failTable: "" };
const db = g.__db;
const t = (n: string): Row[] => (db.tables[n] ??= []);
const PK: Record<string, string[]> = {
  billing_events: ["event_id"], subscriptions: ["user_id"], ai_entitlements: ["user_id"],
  ai_usage_monthly: ["user_id", "month"], ai_usage_lifetime: ["user_id"],
  ocr_usage_monthly: ["user_id", "month"], ocr_usage_lifetime: ["user_id"],
};
const fail = (n: string) => (db.failTable || Deno.env.get("FAIL_TABLE")) === n;

class Q {
  filters: Array<(r: Row) => boolean> = [];
  op = "select"; payload: any = null; cols = "*"; head = false; count = false;
  constructor(public name: string) {}
  select(cols = "*", o?: any) { if (this.op === "select") this.op = "select"; this.cols = cols; this.head = !!o?.head; this.count = !!o?.count; return this; }
  insert(p: any) { this.op = "insert"; this.payload = p; return this; }
  upsert(p: any) { this.op = "upsert"; this.payload = p; return this; }
  update(p: any) { this.op = "update"; this.payload = p; return this; }
  delete() { this.op = "delete"; return this; }
  eq(c: string, v: any) { this.filters.push((r) => r[c] === v); return this; }
  gte(c: string, v: any) { this.filters.push((r) => r[c] >= v); return this; }
  lt(c: string, v: any) { this.filters.push((r) => r[c] < v); return this; }
  in(c: string, v: any[]) { this.filters.push((r) => v.includes(r[c])); return this; }
  match(r: Row) { return this.filters.every((f) => f(r)); }
  async run(): Promise<any> {
    const rows = t(this.name);
    if (this.op === "select") {
      if (this.name === "subscriptions" && this.cols.includes("provider_event_at") && Deno.env.get("NO_EVENT_COL")) {
        return { data: null, error: { code: "42703", message: "column does not exist" } };
      }
      const hit = rows.filter((r) => this.match(r));
      return { data: hit, error: null, count: hit.length };
    }
    if (fail(this.name)) return { data: null, error: { code: "XX000", message: "write failed" } };
    if (this.op === "insert") {
      const pk = PK[this.name];
      if (pk && rows.some((r) => pk.every((k) => r[k] === this.payload[k]))) {
        return { data: null, error: { code: "23505", message: "duplicate key" } };
      }
      rows.push({ ...this.payload }); return { data: null, error: null };
    }
    if (this.op === "upsert") {
      if (this.name === "subscriptions" && "provider_event_at" in this.payload && Deno.env.get("NO_EVENT_COL")) {
        return { data: null, error: { code: "PGRST204", message: "unknown column" } };
      }
      const pk = PK[this.name] ?? ["id"];
      const cur = rows.find((r) => pk.every((k) => r[k] === this.payload[k]));
      if (cur) Object.assign(cur, this.payload); else rows.push({ ...this.payload });
      return { data: null, error: null };
    }
    if (this.op === "update") { rows.filter((r) => this.match(r)).forEach((r) => Object.assign(r, this.payload)); return { data: null, error: null }; }
    if (this.op === "delete") { db.tables[this.name] = rows.filter((r) => !this.match(r)); return { data: null, error: null }; }
  }
  async maybeSingle() { const r = await this.run(); return { data: r.data?.[0] ?? null, error: r.error }; }
  async single() { return this.maybeSingle(); }
  then(res: any, rej: any) { return this.run().then(res, rej); }
}

function reserve(a: any): string {
  const k = a.p_kind === "ai" ? "requests" : "scans";
  const life = t(`${a.p_kind}_usage_lifetime`).find((r) => r.user_id === a.p_user);
  const mon = t(`${a.p_kind}_usage_monthly`).find((r) => r.user_id === a.p_user && r.month === a.p_month);
  const used = (a.p_lifetime ? life : mon)?.[k] ?? 0;
  if (used >= a.p_limit) return "quota";
  if (a.p_global_limit != null) {
    const total = t(`${a.p_kind}_usage_monthly`).filter((r) => r.month === a.p_month).reduce((s, r) => s + (r[k] ?? 0), 0);
    if (total >= a.p_global_limit) return "global";
  }
  if (mon) mon[k] = (mon[k] ?? 0) + 1; else t(`${a.p_kind}_usage_monthly`).push({ user_id: a.p_user, month: a.p_month, [k]: 1 });
  if (life) life[k] = (life[k] ?? 0) + 1; else t(`${a.p_kind}_usage_lifetime`).push({ user_id: a.p_user, [k]: 1 });
  return "ok";
}

/** A SQL literal for a call argument. */
function lit(v: any): string {
  if (v === null || v === undefined) return "null";
  if (typeof v === "boolean" || typeof v === "number") return String(v);
  return "'" + String(v).replace(/'/g, "''") + "'";
}

async function applySubscriptionEvent(a: any): Promise<any> {
  if (!g.__pg) { (db.calls ??= []).push(a); return { data: "applied", error: null }; }
  const args = Object.entries(a).map(([k, v]) => `${k} => ${lit(v)}`).join(", ");
  try {
    return { data: await g.__pg(`select apply_subscription_event(${args})`), error: null };
  } catch (e) {
    return { data: null, error: { code: "P0001", message: String(e) } };
  }
}

export function createClient(..._args: unknown[]): any {
  return {
    auth: { getUser: (tok: string) => Promise.resolve({ data: { user: { id: tok.replace("user-", "") } }, error: null }) },
    from: (n: string) => new Q(n),
    rpc: async (fn: string, a: any) => {
      if (Deno.env.get("NO_RPC")) return { data: null, error: { code: "PGRST202", message: "not found" } };
      if (db.failRpc === fn) return { data: null, error: { code: "XX000", message: "failed" } };
      if (fn === "apply_subscription_event") return await applySubscriptionEvent(a);
      if (fn === "reserve_usage") return { data: reserve(a), error: null };
      if (fn === "release_usage") {
        const k = a.p_kind === "ai" ? "requests" : "scans";
        for (const r of [...t(`${a.p_kind}_usage_monthly`).filter((r) => r.user_id === a.p_user && r.month === a.p_month), ...t(`${a.p_kind}_usage_lifetime`).filter((r) => r.user_id === a.p_user)]) r[k] = Math.max(0, (r[k] ?? 0) - 1);
        return { data: null, error: null };
      }
      return { data: null, error: { code: "PGRST202" } };
    },
  };
}
export type SupabaseClient = any;

// SmartBudget — ai-gateway (Supabase Edge Function, Deno).
//
// SmartBudget → DGOTIX AI → this gateway → quota/entitlement → model router →
// provider registry → {Gemini | OpenAI | Anthropic}. Provider keys live only in
// Edge Function secrets. Failover happens on transient errors only; a per-user
// monthly quota is enforced first. The client never learns which provider was
// used or which one failed.
//
// Deploy:  supabase functions deploy ai-gateway
// Secrets: supabase secrets set GEMINI_API_KEY=... OPENAI_API_KEY=... ANTHROPIC_API_KEY=...
// Body:    { "task": "chat", "prompt": "…", "context": "…",
//            "history": [{ "role": "user"|"assistant", "text": "…" }] }
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { HttpError, requireUserId, serviceClient } from "../_shared/auth.ts";
import {
  candidates,
  classify,
  estCostUsd,
  generate,
  isOpen,
  loadConfig,
  type ProviderId,
  ProviderError,
  recordFailure,
  recordSuccess,
  type TaskType,
} from "../_shared/ai/gateway.ts";
import {
  AI_MONTHLY_COST_CEILING_USD,
  AI_QUOTA,
  effectivePlan,
  normalizePlan,
} from "../_shared/quota.ts";

const VALID_TASKS = new Set<string>([
  "chat", "analysis", "financial_insight", "report", "receipt_scan", "receipt_retry",
]);

function monthKey(): string {
  const d = new Date();
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
}

Deno.serve(async (req: Request) => {
  const cors = corsHeaders();
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405, cors);
  }

  try {
    const userId = await requireUserId(req);
    const body = await req.json().catch(() => ({}));
    const task = (VALID_TASKS.has(body?.task) ? body.task : "chat") as TaskType;
    const prompt = String(body?.prompt ?? "").trim();
    const context = String(body?.context ?? "");
    const history = sanitizeHistory(body?.history);
    if (!prompt) return jsonResponse({ error: "empty_prompt" }, 400, cors);

    const db = serviceClient();
    const month = monthKey();

    // ---- Entitlement + quota (plan-driven; server is the source of truth) ----
    const { data: ent } = await db.from("ai_entitlements")
      .select("plan, trial_plan, trial_expires_at")
      .eq("user_id", userId).maybeSingle();
    const plan = effectivePlan(
      normalizePlan(ent?.plan),
      ent?.trial_plan ? normalizePlan(ent.trial_plan) : null,
      (ent?.trial_expires_at as string | null) ?? null,
    );
    const allow = AI_QUOTA[plan];
    const costCeiling = AI_MONTHLY_COST_CEILING_USD[plan];

    // Monthly cost is always the secondary guard; the request count is checked
    // against the plan's window (FREE = one-time lifetime, paid = monthly).
    const { data: usage } = await db.from("ai_usage_monthly")
      .select("requests, est_cost_usd")
      .eq("user_id", userId).eq("month", month).maybeSingle();
    const usedCost = Number(usage?.est_cost_usd ?? 0);

    let usedReq: number;
    if (allow.window === "lifetime") {
      const { data: life } = await db.from("ai_usage_lifetime")
        .select("requests").eq("user_id", userId).maybeSingle();
      usedReq = life?.requests ?? 0;
    } else {
      usedReq = usage?.requests ?? 0;
    }
    if (usedReq >= allow.limit || usedCost >= costCeiling) {
      return jsonResponse({ error: "quota_exceeded" }, 429, cors);
    }

    // ---- Route + failover ----
    const cfg = await loadConfig(db);
    const pool = candidates(task, cfg).filter((m) => !isOpen(m.provider));
    if (pool.length === 0) {
      await log(db, userId, task, null, null, false, 0, 0, 0, 0, "no_provider");
      return jsonResponse({ error: "ai_unavailable" }, 503, cors);
    }

    const maxTries = 1 + Math.max(0, Math.min(5, cfg.maxFallbackAttempts));
    const tried = pool.slice(0, maxTries);
    let lastCode = "unknown";
    for (let i = 0; i < tried.length; i++) {
      const m = tried[i];
      const started = Date.now();
      try {
        const out = await generate(m.provider as ProviderId, m.id, "", buildPrompt(context, history, prompt));
        recordSuccess(m.provider as ProviderId);
        const cost = estCostUsd(m, out.inputTokens, out.outputTokens);
        await bumpUsage(db, userId, month, out.inputTokens, out.outputTokens, cost);
        await log(db, userId, task, m.provider, m.id, i > 0, Date.now() - started,
          out.inputTokens, out.outputTokens, cost, null);
        // Never leak the provider name or that a fallback happened as an error.
        return jsonResponse({
          ok: true,
          text: out.text,
          model: m.id,
          usage: { input: out.inputTokens, output: out.outputTokens },
          fallbackUsed: i > 0,
        }, 200, cors);
      } catch (e) {
        const status = e instanceof ProviderError ? e.status : 500;
        const detail = e instanceof ProviderError ? e.detail : String(e);
        const c = classify(status, detail);
        lastCode = c.code;
        await log(db, userId, task, m.provider, m.id, i > 0, Date.now() - started,
          0, 0, 0, c.code);
        recordFailure(m.provider as ProviderId);
        // Permanent errors: do not fail over (would fail the same way).
        if (!c.retryable) break;
      }
    }
    return jsonResponse({ error: "ai_unavailable", code: lastCode }, 503, cors);
  } catch (e) {
    const status = e instanceof HttpError ? e.status : 500;
    const code = e instanceof HttpError ? e.code : "server_error";
    return jsonResponse({ error: code }, status, corsHeaders());
  }
});

type Turn = { role: "user" | "assistant"; text: string };

/// Conversation memory from the client, re-validated here: at most 6 turns,
/// each capped, roles restricted — the client can't inflate the request.
function sanitizeHistory(raw: unknown): Turn[] {
  if (!Array.isArray(raw)) return [];
  const out: Turn[] = [];
  for (const t of raw.slice(-6)) {
    const role = t?.role === "assistant" ? "assistant" : t?.role === "user" ? "user" : null;
    const text = String(t?.text ?? "").trim().slice(0, 1000);
    if (role && text) out.push({ role, text });
  }
  return out;
}

function buildPrompt(context: string, history: Turn[], prompt: string): string {
  const parts: string[] = [];
  if (context && context.trim().length > 0) {
    parts.push(`User financial context:\n${context}`);
  }
  if (history.length > 0) {
    parts.push("Conversation so far:\n" + history
      .map((t) => `${t.role === "user" ? "User" : "DGOTIX AI"}: ${t.text}`)
      .join("\n"));
  }
  parts.push(`Question:\n${prompt}`);
  return parts.join("\n\n");
}

async function bumpUsage(
  db: ReturnType<typeof serviceClient>,
  userId: string,
  month: string,
  inTok: number,
  outTok: number,
  cost: number,
): Promise<void> {
  // Atomic-ish upsert increment via RPC if present, else read-modify-write.
  const nowIso = new Date().toISOString();
  try {
    const { data: cur } = await db.from("ai_usage_monthly")
      .select("requests, input_tokens, output_tokens, est_cost_usd")
      .eq("user_id", userId).eq("month", month).maybeSingle();
    await db.from("ai_usage_monthly").upsert({
      user_id: userId,
      month,
      requests: (cur?.requests ?? 0) + 1,
      input_tokens: (cur?.input_tokens ?? 0) + inTok,
      output_tokens: (cur?.output_tokens ?? 0) + outTok,
      est_cost_usd: Number(cur?.est_cost_usd ?? 0) + cost,
      updated_at: nowIso,
    });
  } catch (_) { /* non-fatal */ }
  // Lifetime counter backs the FREE one-time allowance; bump it every time.
  try {
    const { data: life } = await db.from("ai_usage_lifetime")
      .select("requests").eq("user_id", userId).maybeSingle();
    await db.from("ai_usage_lifetime").upsert({
      user_id: userId,
      requests: (life?.requests ?? 0) + 1,
      updated_at: nowIso,
    });
  } catch (_) { /* non-fatal */ }
}

async function log(
  db: ReturnType<typeof serviceClient>,
  userId: string,
  task: string,
  provider: string | null,
  model: string | null,
  fallbackUsed: boolean,
  latencyMs: number,
  inTok: number,
  outTok: number,
  cost: number,
  errorCode: string | null,
): Promise<void> {
  try {
    await db.from("ai_request_log").insert({
      user_id: userId,
      task,
      provider,
      model,
      fallback_used: fallbackUsed,
      latency_ms: latencyMs,
      input_tokens: inTok,
      output_tokens: outTok,
      est_cost_usd: cost,
      error_code: errorCode,
    });
  } catch (_) { /* observability is best-effort; never blocks the response */ }
}

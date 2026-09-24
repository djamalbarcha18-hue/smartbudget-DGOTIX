// DGOTIX AI Gateway core (Deno / Supabase Edge Function).
//
// Provider-agnostic: SmartBudget never talks to Gemini/OpenAI/Anthropic
// directly through this path — it calls the gateway, which routes by task
// capability + config + cost, and fails over on transient errors only. Keys
// live ONLY in Edge Function secrets (env), never in the client or the DB.
//
// Config is read from DB tables (ai_provider_flags / ai_model_flags) so an
// owner can disable a provider/model or change priority WITHOUT a new app
// release or client change.
import { type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export type ProviderId = "google" | "openai" | "anthropic";
export type Capability = "text" | "image" | "structured" | "streaming";
export type TaskType =
  | "chat"
  | "analysis"
  | "financial_insight"
  | "report"
  | "receipt_scan"
  | "receipt_retry";

export interface ModelDef {
  provider: ProviderId;
  id: string;
  caps: Capability[];
  inputPerM: number; // USD / 1M tokens
  outputPerM: number;
  priority: number; // lower = preferred
  active: boolean;
}

/** Which Edge Function secret holds each provider's server key. */
export const PROVIDER_ENV: Record<ProviderId, string> = {
  google: "GEMINI_API_KEY",
  openai: "OPENAI_API_KEY",
  anthropic: "ANTHROPIC_API_KEY",
};

const MM: Capability[] = ["text", "image", "structured", "streaming"];
const TXT: Capability[] = ["text", "structured", "streaming"];

// Verified active models (Sept 2026). Retired Gemini 1.5/2.0 are intentionally
// absent. Aliases track the newest Flash → deprecation-proof.
export const DEFAULT_MODELS: ModelDef[] = [
  { provider: "google", id: "gemini-flash-latest", caps: MM, inputPerM: 0.75, outputPerM: 3.75, priority: 1, active: true },
  { provider: "google", id: "gemini-flash-lite-latest", caps: MM, inputPerM: 0.10, outputPerM: 0.40, priority: 4, active: true },
  { provider: "google", id: "gemini-2.5-flash", caps: MM, inputPerM: 0.30, outputPerM: 2.50, priority: 3, active: true },
  { provider: "google", id: "gemini-2.5-flash-lite", caps: MM, inputPerM: 0.10, outputPerM: 0.40, priority: 5, active: true },
  { provider: "openai", id: "gpt-4o-mini", caps: MM, inputPerM: 0.15, outputPerM: 0.60, priority: 1, active: true },
  { provider: "anthropic", id: "claude-3-5-haiku-latest", caps: TXT, inputPerM: 0.80, outputPerM: 4.0, priority: 1, active: true },
];

export function requiredCaps(task: TaskType): Capability[] {
  switch (task) {
    case "receipt_scan":
    case "receipt_retry":
      return ["image", "structured"];
    default:
      return ["text"];
  }
}

// Correctness-critical tasks prefer capability over the cheapest model.
function costSensitive(task: TaskType): boolean {
  return task === "chat" || task === "analysis";
}

export interface GatewayConfig {
  providerEnabled: Record<string, boolean>;
  providerPriority: Record<string, number>;
  modelEnabled: Record<string, boolean>;
  modelPrice: Record<string, { input: number; output: number }>;
  modelPriority: Record<string, number>;
  maxFallbackAttempts: number;
}

/** Reads owner config from DB; missing tables/rows fall back to defaults. */
export async function loadConfig(db: SupabaseClient): Promise<GatewayConfig> {
  const cfg: GatewayConfig = {
    providerEnabled: {},
    providerPriority: {},
    modelEnabled: {},
    modelPrice: {},
    modelPriority: {},
    maxFallbackAttempts: 2,
  };
  try {
    const { data: pf } = await db.from("ai_provider_flags").select("*");
    for (const r of pf ?? []) {
      cfg.providerEnabled[r.provider_id] = r.enabled !== false;
      if (typeof r.priority === "number") cfg.providerPriority[r.provider_id] = r.priority;
    }
  } catch (_) { /* defaults */ }
  try {
    const { data: mf } = await db.from("ai_model_flags").select("*");
    for (const r of mf ?? []) {
      cfg.modelEnabled[r.model_id] = r.enabled !== false;
      if (r.input_per_m != null && r.output_per_m != null) {
        cfg.modelPrice[r.model_id] = { input: Number(r.input_per_m), output: Number(r.output_per_m) };
      }
      if (typeof r.priority === "number") cfg.modelPriority[r.model_id] = r.priority;
    }
  } catch (_) { /* defaults */ }
  return cfg;
}

/** Effective model list after applying config overlays. */
export function effectiveModels(cfg: GatewayConfig): ModelDef[] {
  return DEFAULT_MODELS.map((m) => ({
    ...m,
    priority: cfg.modelPriority[m.id] ?? m.priority,
    inputPerM: cfg.modelPrice[m.id]?.input ?? m.inputPerM,
    outputPerM: cfg.modelPrice[m.id]?.output ?? m.outputPerM,
    active: m.active && (cfg.modelEnabled[m.id] ?? true),
  }));
}

/** Ordered candidates for a task: capable + provider enabled + key present. */
export function candidates(task: TaskType, cfg: GatewayConfig): ModelDef[] {
  const need = requiredCaps(task);
  const cheap = costSensitive(task);
  const pool = effectiveModels(cfg).filter((m) => {
    if (!m.active) return false;
    if ((cfg.providerEnabled[m.provider] ?? true) === false) return false;
    if (!Deno.env.get(PROVIDER_ENV[m.provider])) return false; // no key → skip
    return need.every((c) => m.caps.includes(c));
  });
  pool.sort((a, b) => {
    const pa = cfg.providerPriority[a.provider] ?? 50;
    const pb = cfg.providerPriority[b.provider] ?? 50;
    if (pa !== pb) return pa - pb;
    if (cheap) {
      const ca = a.inputPerM + a.outputPerM;
      const cb = b.inputPerM + b.outputPerM;
      if (ca !== cb) return ca - cb;
    }
    return a.priority - b.priority;
  });
  return pool;
}

// ---- Error classification (failover policy) ----
export interface Classified { code: string; retryable: boolean; }
export function classify(status: number, message = ""): Classified {
  const m = message.toLowerCase();
  if (status === 401 || status === 403 || m.includes("api key") || m.includes("permission")) {
    return { code: "invalid_api_key", retryable: false };
  }
  if (status === 429) {
    return { code: m.includes("quota") ? "quota_exceeded" : "rate_limited", retryable: true };
  }
  if (status === 400) return { code: "invalid_request", retryable: false };
  if (status === 404) return { code: "unsupported", retryable: false };
  if (status === 408 || status === 504) return { code: "timeout", retryable: true };
  if (status === 503) return { code: "provider_unavailable", retryable: true };
  if (status >= 500) return { code: "server_error", retryable: true };
  return { code: "unknown", retryable: false };
}

// ---- Circuit breaker (per warm instance) ----
interface Breaker { failures: number; openUntil: number; }
const breakers = new Map<ProviderId, Breaker>();
const OPEN_MS = 30_000;
const TRIP_AT = 3;

export function isOpen(p: ProviderId): boolean {
  const b = breakers.get(p);
  return !!b && b.openUntil > Date.now();
}
export function recordFailure(p: ProviderId): void {
  const b = breakers.get(p) ?? { failures: 0, openUntil: 0 };
  b.failures += 1;
  if (b.failures >= TRIP_AT) b.openUntil = Date.now() + OPEN_MS;
  breakers.set(p, b);
}
export function recordSuccess(p: ProviderId): void {
  breakers.set(p, { failures: 0, openUntil: 0 });
}

// ---- Provider adapters (server key) ----
export interface GenResult { text: string; inputTokens: number; outputTokens: number; }
export class ProviderError extends Error {
  constructor(public status: number, public detail: string) { super(detail); }
}

// The one DGOTIX AI system prompt. DGOTIX is the only AI provider, so this is
// the single source of truth (test/ai_assistant_test.dart checks its rules).
const SYSTEM =
  "You are DGOTIX AI, a concise, practical personal-finance assistant " +
  "inside the SmartBudget app. Use the user's real financial context " +
  "below when it helps, and refer to the actual figures. Never invent " +
  "exact figures that are not provided; if something is missing, say so " +
  "and suggest where in the app to add it. Prefer halal-friendly guidance " +
  "(no interest-based products). Reply in the same language as the " +
  "user's latest message (Arabic or English). Keep answers short: a " +
  "sentence or two, then at most 5 bullet points using \"- \", with **bold** " +
  "for key numbers. Use Latin digits (0-9).";

export async function generate(
  provider: ProviderId,
  model: string,
  system: string,
  prompt: string,
): Promise<GenResult> {
  const sys = system && system.length > 0 ? system : SYSTEM;
  if (provider === "google") return geminiGen(model, sys, prompt);
  if (provider === "openai") return openaiGen(model, sys, prompt);
  return anthropicGen(model, sys, prompt);
}

async function post(url: string, headers: HeadersInit, body: unknown): Promise<Response> {
  try {
    return await fetch(url, { method: "POST", headers, body: JSON.stringify(body) });
  } catch (e) {
    throw new ProviderError(503, String(e));
  }
}

async function geminiGen(model: string, sys: string, prompt: string): Promise<GenResult> {
  const key = Deno.env.get(PROVIDER_ENV.google) ?? "";
  const res = await post(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${key}`,
    { "Content-Type": "application/json" },
    {
      systemInstruction: { parts: [{ text: sys }] },
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.4, maxOutputTokens: 800 },
    },
  );
  const raw = await res.text();
  if (res.status !== 200) throw new ProviderError(res.status, providerMsg(raw));
  const d = JSON.parse(raw);
  const text = d?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
  if (!text.trim()) throw new ProviderError(502, "empty");
  const u = d?.usageMetadata ?? {};
  return { text: text.trim(), inputTokens: u.promptTokenCount ?? 0, outputTokens: u.candidatesTokenCount ?? 0 };
}

async function openaiGen(model: string, sys: string, prompt: string): Promise<GenResult> {
  const key = Deno.env.get(PROVIDER_ENV.openai) ?? "";
  const res = await post(
    "https://api.openai.com/v1/chat/completions",
    { "Content-Type": "application/json", Authorization: `Bearer ${key}` },
    {
      model,
      messages: [{ role: "system", content: sys }, { role: "user", content: prompt }],
      temperature: 0.4,
      max_tokens: 800,
    },
  );
  const raw = await res.text();
  if (res.status !== 200) throw new ProviderError(res.status, providerMsg(raw));
  const d = JSON.parse(raw);
  const text = d?.choices?.[0]?.message?.content ?? "";
  if (!text.trim()) throw new ProviderError(502, "empty");
  const u = d?.usage ?? {};
  return { text: text.trim(), inputTokens: u.prompt_tokens ?? 0, outputTokens: u.completion_tokens ?? 0 };
}

async function anthropicGen(model: string, sys: string, prompt: string): Promise<GenResult> {
  const key = Deno.env.get(PROVIDER_ENV.anthropic) ?? "";
  const res = await post(
    "https://api.anthropic.com/v1/messages",
    { "Content-Type": "application/json", "x-api-key": key, "anthropic-version": "2023-06-01" },
    { model, max_tokens: 800, system: sys, messages: [{ role: "user", content: prompt }] },
  );
  const raw = await res.text();
  if (res.status !== 200) throw new ProviderError(res.status, providerMsg(raw));
  const d = JSON.parse(raw);
  const text = d?.content?.[0]?.text ?? "";
  if (!text.trim()) throw new ProviderError(502, "empty");
  const u = d?.usage ?? {};
  return { text: text.trim(), inputTokens: u.input_tokens ?? 0, outputTokens: u.output_tokens ?? 0 };
}

function providerMsg(raw: string): string {
  try {
    const d = JSON.parse(raw);
    const m = d?.error?.message;
    if (typeof m === "string") return m;
  } catch (_) { /* non-JSON */ }
  return raw.slice(0, 200);
}

export function estCostUsd(m: ModelDef, inTok: number, outTok: number): number {
  return (inTok / 1e6) * m.inputPerM + (outTok / 1e6) * m.outputPerM;
}

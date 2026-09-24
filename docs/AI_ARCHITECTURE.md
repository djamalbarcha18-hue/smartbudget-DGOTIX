# DGOTIX AI Architecture

DGOTIX AI is **provider-independent**. SmartBudget never depends on Gemini,
OpenAI or Anthropic as an unreplaceable part — they are just implementations
behind a stable interface, and any of them can be swapped or disabled without an
app release.

```
SmartBudget
    ↓
DGOTIX AI
    ↓
Supabase Edge Function (ai-gateway)
    ↓
Quota / Entitlement
    ↓
Model Router  (capability + kill-switch + priority + cost)
    ↓
Provider Registry
    ↓
┌─────────┬─────────┬──────────┐
│ Gemini  │ OpenAI  │ Anthropic│
└─────────┴─────────┴──────────┘
```

## One path: the server gateway

DGOTIX is the only AI provider; users never bring their own key.

**Server gateway (`ai-gateway`)** — DGOTIX-provided AI with per-user plan
quota. Keys live only in Edge Function secrets. Routing, failover, circuit
breaker, kill switches and observability run server-side and are
**config-driven from the DB** (no app release to change them). The client never
learns which provider was used or which failed. The system prompt lives only in
`supabase/functions/_shared/ai/gateway.ts` (`SYSTEM`).

Client and server read the same **source-of-truth model registry** so there is no hardcoded
model id in widgets: client `lib/features/ai/domain/ai_registry.dart`, server
`supabase/functions/_shared/ai/gateway.ts` (`DEFAULT_MODELS`).

## Verified models (Sept 2026)

Active: `gemini-flash-latest`, `gemini-flash-lite-latest`, `gemini-2.5-flash`,
`gemini-2.5-flash-lite` (+ `gemini-3.8-flash` on the client list). The
`-latest` aliases auto-track the newest Flash (Google gives 2 weeks' notice
before breaking changes), so they are the default → deprecation-proof.

**Shut down / 404** (kept only for migration mapping): all Gemini 1.5 and 2.0
(Flash & Flash-Lite). Stored dead ids are migrated to a live replacement on
load. OpenAI / Anthropic ids were not re-verified in this pass.

## Failover policy

- Retryable (may fail over): timeout, 503, 5xx, 429, quota.
- Permanent (stop immediately): invalid key, 400, 404 / unsupported capability.
- `maxFallbackAttempts` (default 2) bounds how many extra models are tried.
- Capabilities are enforced first: Receipt Scan requires image + structured
  output, so a text-only model is never chosen for it.
- A per-instance **circuit breaker** opens a provider after repeated failures
  and skips it for a cooldown (server side).

## Kill switches (no app release)

- `ai_provider_flags.enabled = false` → the provider is never called.
- `ai_model_flags.enabled = false` → that single model is skipped.
- A provider with no secret key set is treated as disabled automatically.
- `ai_model_flags.input_per_m / output_per_m / priority` override pricing and
  ordering. Change a row → next request uses it. No client change, no release.

## Graceful degradation

AI is an additive layer, never a failure point for finance. If every provider is
down the app still runs Dashboard, Transactions, Budgets, Goals, Debts, Reports
and Charts normally; financial figures come from the deterministic engine, not
AI. Reports render without AI insights when AI is unavailable. Users see
"DGOTIX AI is temporarily unavailable. Your data and features are still
available." — never "Gemini/OpenAI failed".

## Deploy the gateway (owner)

```bash
# 1. Tables (config, entitlement, usage, logs)
supabase db execute -f supabase/ai_gateway.sql   # or paste into the SQL editor

# 2. Function
supabase functions deploy ai-gateway

# 3. Server keys (only where you want that provider enabled)
supabase secrets set GEMINI_API_KEY=... OPENAI_API_KEY=... ANTHROPIC_API_KEY=...
supabase secrets set ALLOWED_ORIGIN=https://djamalbarcha18-hue.github.io
```

## Quotas are plan-driven

Enforcement reads the user's **plan** from `ai_entitlements` and applies the
allowance from `supabase/functions/_shared/quota.ts`, which mirrors the app's
`FeatureCatalog` and `docs/PRICING.md`:

| plan | DGOTIX AI answers | window |
|------|-------------------|--------|
| free | 5 | one-time (lifetime) |
| basic | 30 | monthly |
| pro | 150 | monthly |

FREE's one-time allowance is counted in `ai_usage_lifetime`; paid plans are
counted in `ai_usage_monthly`. A per-plan monthly USD ceiling
(`AI_MONTHLY_COST_CEILING_USD`) is a secondary guard so a run of unusually
expensive answers can't blow the budget even under the request count. A
time-boxed `trial_plan` / `trial_expires_at` temporarily lifts the plan and
lapses back with no data loss. **Cloud OCR** quotas (3 / 15 / 100) live in the
same file (`OCR_QUOTA`) with counters `ocr_usage_monthly` / `ocr_usage_lifetime`.
The `receipt-scan` function serves every scan with the server Gemini key and
meters it; without `GEMINI_API_KEY` it answers `ocr_unavailable`.

To change a user's tier, set their **plan** (limits follow automatically) — the
numeric `*_limit` columns are legacy overrides, not the source of truth.

Emergency switch examples (SQL editor):

```sql
update ai_provider_flags set enabled = false where provider_id = 'google';   -- kill Gemini
update ai_model_flags set enabled = false where model_id = 'gpt-4o';         -- kill one model
update ai_entitlements set plan = 'pro' where user_id = '...';               -- change a user's tier
```

## Client wiring

`lib/features/ai/data/ai_gateway_service.dart` (`aiGatewayServiceProvider`) is
the client for the gateway; it returns text + usage + model and a neutral
failure. The assistant uses it whenever Supabase is configured and the user is
signed in (`assistantReadyProvider`); otherwise it shows an "available soon"
card. Core financial features never depend on it.

## Not yet implemented (needs the deploy above)

Server-side circuit-breaker persistence across instances, an admin diagnostics
screen, and cross-provider failover on the live client path all require the
gateway to be deployed. This repo ships the code deploy-ready; it cannot be
deployed or verified from the build pipeline (CI builds only the web app).

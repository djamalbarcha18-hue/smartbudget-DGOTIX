# SmartBudget — Pricing & Tiering (by DGOTIX)

> Single source of truth for **what each plan includes and what it costs**.
> Feature gates in code read the machine-readable catalog
> (`lib/features/billing/domain/feature_catalog.dart`); this document is the
> human-readable companion. When the two disagree, the code is authoritative —
> fix this doc.

Status: **design locked** · Prices in **USD** · Last reviewed **2026-09**.

> **Beta: everything is unlocked.** While SmartBudget is in beta every user
> gets PRO limits plus the yearly-only extras, and upgrade prompts, checkout
> buttons and the coupon box are hidden. One switch on each side turns it off
> when paid plans go live:
> - app: build with `--dart-define=BETA_ALL_ACCESS=false` (`AppEnv.betaAllAccess`);
> - server: set the Edge Function secret `BETA_ALL_ACCESS=false`
>   (`betaAllAccess()` in `supabase/functions/_shared/quota.ts`).

---

## 1. Plans at a glance

| | **FREE** | **BASIC** | **PRO** |
|---|---|---|---|
| Monthly | **$0** | **$7.99 / mo** | **$14.99 / mo** |
| Yearly | — | **$50 / yr** (≈ $4.17/mo) | **$119 / yr** (≈ $9.92/mo) |
| Yearly saving vs monthly | — | ~48% | ~34% |
| Positioning | Try the whole engine | Everyday budgeter | Power user / advisor-grade |

FREE is a **permanent free tier** (not a time-boxed trial). A new account MAY
receive a short PRO trial window; that is a marketing lever, not a plan — see
§7 Coupons & trials.

All prices are **placeholders in code** until the billing provider is wired; no
charge happens without an explicit checkout the user starts.

---

## 2. AI quotas (DGOTIX AI — server gateway)

Quota is enforced **server-side** in the `ai-gateway` Edge Function. The number
below is the count of **successful** assistant answers per period.

| | FREE | BASIC | PRO |
|---|---|---|---|
| DGOTIX AI answers | **5 total** (one-time) | **30 / month** | **150 / month** |
| Reset | never (lifetime intro) | monthly (calendar) | monthly (calendar) |

- FREE's 5 is a **lifetime** allowance to feel the value, not a monthly refill.
- Quotas are **request budgets bounded by token governance** (§4), not raw
  request counts alone — a single abusive request cannot drain the month.
- **DGOTIX is the only AI provider.** Users never bring their own key: every
  answer goes through the server gateway and counts against the plan quota.
  This keeps pricing simple and gives the product full control (models,
  cost, safety). When the quota is reached the only call to action is
  **Upgrade** (or wait for the reset).
- Until the gateway is live, the assistant shows an "available soon / see
  plans" card instead of the chat. Users see only answers used / left, never
  tokens, dollar costs or model names (internal data).

## 3. Receipt OCR quotas

On-device OCR (`OfflineOcrEngine`) is **unlimited and free on every plan** — it
runs locally, costs us nothing, and must never be gated.

Cloud OCR (`GeminiOnlineEngine` via the `receipt-scan` function) has real cost
and is metered **server-side**:

| | FREE | BASIC | PRO |
|---|---|---|---|
| Cloud OCR scans | **3 total** (one-time) | **15 / month** | **100 / month** |
| On-device OCR | ∞ | ∞ | ∞ |

Same policy as AI: exceeding cloud OCR → **Upgrade** CTA.

The `receipt-scan` function serves every scan with DGOTIX's **server** Gemini
key and meters it against the plan quota (counting only successful
extractions). Without a server key it answers `ocr_unavailable`; there is no
personal-key fallback.

---

## 4. Token governance (why quotas are safe)

A request-count quota alone is exploitable (one huge prompt = one request). The
gateway therefore also governs **tokens**:

- **Per-request input cap** — oversized prompts are trimmed/rejected before the
  provider call.
- **Per-request output cap** (`max_tokens`) — bounds the answer length, so cost
  per answer has a ceiling.
- **Monthly token ceiling per plan** — a secondary guard; hitting it counts as
  reaching the quota even if the request count is below the limit.
- **Rate limit** — a short-window cap (requests / minute) stops bursts and
  scripted abuse independent of the monthly budget.

These live server-side and are logged (`ai_request_log`) without ever storing
prompt content or keys.

---

## 5. Feature gating (FREE vs paid)

The catalog is the source of truth; this is the intended shape:

| Capability | FREE | BASIC | PRO |
|---|---|---|---|
| Core financial engine (budgets, expenses, income, transactions, debts, goals, zakat) | ✅ | ✅ | ✅ |
| Financial health score & insights (on-device) | ✅ | ✅ | ✅ |
| Reports & analytics — basic | ✅ | ✅ | ✅ |
| Reports & analytics — advanced (deep breakdowns, longer history) | — | ✅ | ✅ |
| Smart salary split (budget suggested from your own spending) | — | ✅ | ✅ |
| Smart alerts (budget forecasts, unusual spending, weekly & monthly summaries) | — | yearly billing only | yearly billing only |
| DGOTIX AI assistant | 5 lifetime | 30 / mo | 150 / mo |
| Cloud receipt OCR | 3 lifetime | 15 / mo | 100 / mo |
| On-device receipt OCR | ✅ | ✅ | ✅ |
| Cloud sync & backup | basic | ✅ | ✅ |
| Portfolio & markets | view | ✅ | ✅ |
| Priority support | — | — | ✅ |

> **Smart alerts** are a perk of **yearly** billing on BASIC or PRO (the
> `yearlyOnly` rule on `Feature.smartAlerts`); monthly subscribers are invited
> to switch to yearly. The period comes from the server's `subscriptions`
> row, so it can't be granted client-side. The basic alerts (over/near
> budget, negative cash flow, goals, upcoming recurring items, backup
> reminder) stay free for everyone.

> The **financial engine is never gated**. A user who never pays keeps a
> genuinely useful budgeting app. Paid tiers add AI volume, cloud OCR volume,
> advanced analytics, and support — not the ability to track money.

---

## 6. UX: quota nudges

Client-side advisory nudges (server enforcement is the real gate) fire as usage
approaches the limit, so the wall is never a surprise:

- **80%** — quiet inline note ("You've used 24 of 30 this month").
- **90%** — stronger note with an Upgrade affordance.
- **100%** — blocking state: the assistant/OCR action is disabled with the
  **Upgrade** CTA and the reset date. Core financial features keep working.

Nudges are **upgrade-oriented only**.

---

## 7. Coupons & trials (marketing)

Coupons are a **separate system from entitlements**. A coupon changes the
**price** of a checkout (or grants a trial window); it never itself unlocks a
feature — the plan does that.

A coupon (server-side `coupons` table) has:

- `code` — case-insensitive redemption code.
- `kind` — `percent` (e.g. 25% off), `fixed` (e.g. $5 off), or
  `trial_extension` (adds N days of PRO trial).
- `target` — which plan/period it applies to (or "any").
- `valid_from` / `valid_until` — activation window.
- `max_redemptions` — global cap; `per_user_limit` (default 1) — one per user.
- Redemptions recorded server-side; validation and price math happen
  **server-side only** so a coupon can never be forged client-side.

Trials are delivered as a PRO entitlement with an `expires_at`; when it lapses
the account falls back to FREE with no loss of the user's own data.

**Implemented:** `supabase/coupons.sql` (tables `coupons` + `coupon_redemptions`,
server-only RLS) and the `coupon-validate` Edge Function, which validates a code
(window, global cap, per-user cap) and returns the resulting price or trial
without redeeming it — redemption happens at checkout. The Plans screen has a
"Have a coupon?" field that previews a code via the function's probe mode.
Deploy: `supabase db execute -f supabase/coupons.sql` + `supabase functions
deploy coupon-validate`.

---

## 8. Pricing rationale (market context)

Benchmarks (annual, list): YNAB ~$109/yr, Monarch ~$99.99/yr, Copilot ~$95/yr.
SmartBudget PRO at **$119/yr** sits at the premium end but bundles a
multi-provider AI assistant and receipt OCR that those tools charge more (or
extra) for; BASIC at **$50/yr** undercuts the field for everyday users. FREE is
deliberately generous on the engine to drive adoption, with paid volume on the
two features that actually cost us money to serve (AI + cloud OCR).

---

## 9. Invariants (do not break)

1. Server is the source of truth for entitlement and quota. The client gate is
   advisory UX only.
2. Exceeding any quota → **Upgrade** CTA only. DGOTIX is the only AI
   provider; users never bring their own key.
3. The financial engine, RTL, and localization are never gated or degraded by
   billing state.
4. An AI/OCR outage or a lapsed plan never blocks core financial functions.
5. No API keys in the frontend. Keys never appear in logs or analytics.
6. Never fabricate usage or price numbers; show "—"/unavailable when unknown.

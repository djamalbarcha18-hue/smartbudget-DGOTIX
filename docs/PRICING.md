# SmartBudget — Pricing & Tiering (by DGOTIX)

> Single source of truth for **what each plan includes and what it costs**.
> Feature gates in code read the machine-readable catalog
> (`lib/features/billing/domain/feature_catalog.dart`); this document is the
> human-readable companion. When the two disagree, the code is authoritative —
> fix this doc.

Status: **design locked** · Prices in **USD** · Last reviewed **2026-10**.

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
| Monthly | **$0** | **$4.99 / mo** | **$8.99 / mo** |
| Yearly | — | **$39.99 / yr** (≈ $3.33/mo) | **$69.99 / yr** (≈ $5.83/mo) |
| Yearly saving vs monthly | — | ~33% | ~35% |
| Positioning | Build the habit | Everyday budgeter, expats | Multiple incomes, investing, heavy AI |

**Regional prices** (set in Paddle as country price overrides on the same
prices, so no code changes): Arab countries outside the Gulf (Egypt, the
Maghreb, the Levant, Iraq, Sudan, …) pay BASIC **$2.99 / $24.99** and PRO
**$5.49 / $44.99**. The app shows the USD list price; the checkout shows the
buyer's own price and currency.

FREE is a **permanent free tier** (not a time-boxed trial). A new account MAY
receive a short PRO trial window; that is a marketing lever, not a plan — see
§7 Coupons & trials.

All prices are **placeholders in code** until the billing provider is wired; no
charge happens without an explicit checkout the user starts.

### Unit economics (why these numbers)

Estimated model cost per use, from the gateway's registry prices: an assistant
answer ≈ $0.001 (Flash-Lite), at worst ≈ $0.01; a cloud scan ≈ $0.006, at
worst ≈ $0.03 per part. A subscriber who spends the whole allowance every month
at worst-case cost:

| | net / month (yearly, cheapest region, after Paddle) | typical cost | worst case |
|---|---|---|---|
| BASIC | ≈ $1.95 | ≈ $0.15 | ≈ $0.70 |
| PRO | ≈ $3.50 | ≈ $0.50 | ≈ $2.40 |

So every plan stays profitable in every region even at the worst case. Paddle
takes about 5% + $0.50 per payment, which is why yearly billing is pushed.

---

## 2. AI quotas (DGOTIX AI — server gateway)

Quota is enforced **server-side** in the `ai-gateway` Edge Function. The number
below is the count of **successful** assistant answers per period.

| | FREE | BASIC | PRO |
|---|---|---|---|
| DGOTIX AI answers | **5 total** (one-time) | **25 / month** | **100 / month** |
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
| Cloud OCR scans | **3 total** (one-time) | **15 / month** | **50 / month** |
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

### Limits against mass sign-ups

Sign-up is free, so the limits also depend on the account, not on IP addresses
(`supabase/abuse_limits.sql`, numbers in `supabase/functions/_shared/quota.ts`):

| Account | AI answers | Cloud scans |
|---|---|---|
| **New** (under 7 days, or email not confirmed), unpaid | plan allowance, at most 10, and 5 a day | plan allowance, at most 5, and 3 a day |
| **Established**, unpaid (incl. beta) | plan allowance, 30 a day | plan allowance, 15 a day |
| **Paying** | plan allowance, 60 a day | plan allowance, 40 a day |

- **Shares of the monthly capacity** (`AI_GLOBAL_MONTHLY_REQUESTS`,
  `OCR_GLOBAL_MONTHLY_SCANS`):
  - Unpaid accounts together use at most 70% of it (`UNPAID_SHARE_PERCENT`).
  - New accounts use at most 20% (`NEW_SHARE_PERCENT`).
  - A crowd of fake accounts can only exhaust its share. Paying users keep the
    rest.
- **Per-account rate limits:**
  - AI: 10 a minute.
  - Scans: 6 a minute.
  - Checkout: 10 an hour.
  - Manage subscription: 30 an hour.
  - Account deletion: 5 an hour.
- **Other per-account caps:** AI-answer reports are limited to 20 a day, and
  cloud backups of new accounts to 2 MB.
- **Configuration:** `NEW_ACCOUNT_DAYS` changes the 7 days.

---

## 5. Feature gating (FREE vs paid)

The catalog is the source of truth; this is the intended shape:

| Capability | FREE | BASIC | PRO |
|---|---|---|---|
| Transactions, categories, dashboard, quick entry | ✅ unlimited | ✅ | ✅ |
| Zakat calculator, app lock, challenges and badges | ✅ | ✅ | ✅ |
| On-device receipt OCR | ✅ unlimited | ✅ | ✅ |
| Wallets | 2 (incl. General), base currency only | unlimited, any currency | ✅ |
| Category budgets (per month) | 5 | unlimited | ✅ |
| Goals / debts / darets | 1 / 2 / 1 | unlimited | ✅ |
| Season plans (still ahead or running) | 1 | unlimited | ✅ |
| Recurring rules | 5 | unlimited | ✅ |
| Reports | monthly: this month and the previous one | every period, any year | ✅ |
| Exchange rates | official rates + converter | + parallel / P2P / custom | ✅ |
| Financial health | score, risks, emergency fund | + strengths, pillars, recommendations | ✅ |
| Automatic sync across devices | — (backup file export only) | ✅ | ✅ |
| Smart salary split | — | ✅ | ✅ |
| PDF report export | — | — | ✅ |
| Yearly trend chart (months compared) | — | — | ✅ |
| Smart alerts (forecasts, unusual spending, summaries) | — | — | ✅ |
| Markets: crypto, metals, commodities | — | — | ✅ |
| Projects and investment portfolio | — | — | ✅ |
| Cloud receipt OCR | 3 lifetime | 15 / mo | 50 / mo |
| DGOTIX AI assistant | 5 lifetime | 25 / mo | 100 / mo |
| Priority support | — | — | ✅ |

- **Counted features** (`QuotaWindow.items`) are checked where something new
  is added (`PlanLimits.allowAdd`), so a user who goes back to FREE keeps
  everything they already have; only adding more is blocked. These counts
  live on the device (the data is local-first), so they are a client-side
  gate; the costly features (AI, cloud OCR) are enforced by the server.
- **PRO has its own features** (PDF, trend chart, smart alerts, the wider
  markets, the projects portfolio), so there is a reason to go from BASIC to
  PRO, not just bigger allowances. **Smart alerts** come with PRO whether
  billed monthly or yearly. The basic alerts (over/near budget, negative cash flow, goals,
  upcoming recurring items, backup reminder) stay free for everyone.
- Zakat stays free on purpose: gating a religious duty would hurt the brand.

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
SmartBudget is priced for Arab users, who compare it with what they already
pay monthly (music, video, a coffee): BASIC at **$4.99** reads as "a coffee a
month" and **$39.99/yr** as a clear deal; PRO stays under **$9** so it
doesn't feel like a Netflix-sized decision. The product sells what others
don't: Arab currencies and parallel rates, zakat, seasons and darets, and the
bilingual app. A 14-day PRO trial and showing the yearly price per month do
more for conversion than a lower number.

---

## 9. Invariants (do not break)

1. Server is the source of truth for entitlement and quota. The client gate is
   advisory UX only.
2. Exceeding any quota → **Upgrade** CTA only. DGOTIX is the only AI
   provider; users never bring their own key.
3. Recording income and expenses, RTL and localization are never gated or
   degraded by billing state, and a lower plan never removes data: limits
   only stop adding more.
4. An AI/OCR outage or a lapsed plan never blocks core financial functions.
5. No API keys in the frontend. Keys never appear in logs or analytics.
6. Never fabricate usage or price numbers; show "—"/unavailable when unknown.

# DGoTix / SmartBudget — Security Audit

October 2026. Scope: the Flutter app (web and Android), the Supabase project
(Auth, Postgres, Edge Functions), payments (Paddle, PayPal), email (Brevo),
the domain (Namecheap DNS, GitHub Pages) and CI/CD (GitHub Actions).

No system is "100% secure". This report says what was checked, what was
found and fixed, how each fix was verified, and what risk remains.

## 1. Summary

- **No known Critical vulnerabilities remain.**
- **Three High issues were found and fixed:**
  - Usage limits could be bypassed with parallel requests.
  - Total model spend was uncapped while beta gives every account Pro limits.
  - A Paddle webhook could grant a plan from data the checkout carried.
- **The Medium issues found are fixed:**
  - Payment events lost on a failed write.
  - Retired prices downgrading subscribers.
  - Out-of-order events.
  - Unpinned dependencies.
  - Personal data shared between accounts on one device.
  - The API key in URLs.
  - No Content-Security-Policy.
  - Missing request size limits.
  - Webhook replay window.
  - Coupon guessing.
- **One step is needed to activate part of the fixes:** run
  `supabase/security_hardening.sql` in the Supabase SQL editor. Until it runs,
  the functions behave as before, and nothing breaks.
- **Verdict.** Ready for free beta users. Before taking real payments,
  complete the checklist in §9.

## 2. Architecture and trust boundaries

```
Browser / Android app  (untrusted)
   │  Supabase session JWT (Authorization header; no cookies)
   ▼
Supabase
   ├─ Auth            sign-up/in, email confirmation, OTP reset (bcrypt, refresh rotation)
   ├─ PostgREST       RLS on every table; clients use the publishable key only
   └─ Edge Functions  verify the JWT themselves (requireUserId) and use the
                      service role server-side only
        ├─ ai-gateway, receipt-scan  → Gemini (key in function secrets)
        ├─ create-checkout, manage-subscription → Paddle / PayPal APIs
        ├─ paddle-webhook, paypal-webhook  ← providers (signature-verified)
        ├─ coupon-validate, delete-account, billing-config
        └─ market-proxy, parallel-proxy  (public, fixed upstreams)
GitHub Pages  smartbudget.dgotix.com (static web build, CSP in index.html)
Brevo SMTP    auth emails + support replies from support@dgotix.com (DKIM, DMARC)
```

**Where the data lives:**
- **On the device:** the financial data (transactions, budgets, goals and so on).
- **On the server:** the optional cloud backup is one JSON document per user,
  protected by RLS.
- **Server-side state:**
  - Subscriptions and entitlements.
  - Usage counters.
  - The payment event ids, kept for idempotency.
  - An AI request log holding numbers only, with no prompts or answers.

**Secrets:** service role key, Gemini, Paddle, PayPal, Brevo, the Supabase
access token. They are kept only in Supabase function secrets, GitHub secrets
or the providers' dashboards. A scan of the full git history found none
committed. The publishable key in the app is public by design.

## 3. Threat model (main scenarios)

| Actor | Goal | Path | Control |
|---|---|---|---|
| Signed-in user | Read/modify another user's data | PostgREST with own JWT, IDs of others | RLS on every table (tested: 34 checks) |
| Signed-in user | Pro features / AI without paying | Write own entitlement/usage rows; parallel requests | No client write access to entitlements/usage; atomic reservation |
| Anyone | Run up model costs | Many accounts, big payloads | Per-user quotas, global monthly ceilings, body/image size limits |
| Anyone | Fake a payment | Forged or replayed webhook, client-side "success" | HMAC/PayPal verification, 5-min window, idempotency, plan from price map only |
| Attacker with XSS | Exfiltrate data/session | Injected script | Flutter renders no HTML; CSP blocks inline script and unknown hosts |
| Malicious invoice | Prompt injection | Text in the image | Structured schema output, arithmetic checks on device, no tools/privileges for the model |
| Person with the phone | Read another account's data | Shared device | Per-account storage keys, app lock, no auto backup |
| Supply chain | Malicious dependency/action | Floating versions | pubspec.lock enforced, Flutter and actions pinned, supabase-js pinned |
| Domain/account takeover | Hijack site/email | Registrar, GitHub, Supabase, Brevo logins | Owner accounts on 2FA, domain lock, verified sender domain |

## 4. Findings

Status: **Fixed** (in code, verified), **Owner** (needs an action outside the
code), **Accepted** (documented risk).

| # | Sev. | Component | Finding | Status |
|---|---|---|---|---|
| 1 | High | ai-gateway, receipt-scan | Quota checked, then the model called, then counted: N parallel requests all pass. 10 parallel scans on a 3-scan allowance were all served. | Fixed: `reserve_usage` counts atomically before the call (advisory lock per user); failures give the count back |
| 2 | High | Cost control | Beta (`BETA_ALL_ACCESS`, default on) gives every account Pro quotas, and sign-up is free: no cap on total spend. | Fixed: platform-wide monthly ceilings (AI 5,000 requests, OCR 3,000 scans by default, Edge Function secrets `AI_GLOBAL_MONTHLY_REQUESTS` / `OCR_GLOBAL_MONTHLY_SCANS`) |
| 3 | High | paddle-webhook | For a price missing from `billing_prices`, the plan came from `custom_data.plan`. | Fixed: plan only from the price map; unknown price is ignored |
| 4 | Medium | webhooks | A failed DB write was acknowledged (200) after the event id was stored, so the retry was dropped as a duplicate: a payer could stay on Free. | Fixed: writes throw, event id is removed, 500 makes the provider retry |
| 5 | Medium | webhooks | A price marked inactive (no longer sold) mapped to Free on the next event, downgrading its subscribers. | Fixed: webhooks map retired prices too |
| 6 | Medium | webhooks | An older event delivered late could re-activate a cancelled plan. | Fixed: `subscriptions.provider_event_at`; older events ignored |
| 7 | Medium | paypal-webhook | Activation with an unknown plan id set the user to Free. | Fixed: ignored |
| 8 | Medium | CI / supply chain | No `pubspec.lock` committed (every build resolved new versions); Flutter channel floating; `supabase-js@2` floating; third-party actions on moving tags; workflow tokens with default permissions. | Fixed: lockfile enforced, Flutter 3.47.5 pinned, supabase-js 2.117.2, actions pinned to commits, read-only tokens |
| 9 | Medium | App (device) | AI chat, zakat, categories, emergency savings… stored device-wide: a second account on the same device saw them. | Fixed: per-account keys with one-time adoption |
| 10 | Medium | ai-gateway, receipt-scan | No request size limits (cost inflation). | Fixed: 64 KB / 12 MB bodies, prompt/context caps, image types only |
| 11 | Medium | Web | No Content-Security-Policy. | Fixed: CSP (tested in Chromium on 10 pages; injected script, exfiltration and tracking pixel blocked) |
| 12 | Medium | Android | Auto backup copied app data (financial data, lock settings) to the Google account. | Fixed: `allowBackup=false` |
| 13 | Low | Gemini calls | API key in the URL query string (ends up in logs). | Fixed: `x-goog-api-key` header |
| 14 | Low | paddle-webhook | No timestamp window (replay mitigated only by event id). | Fixed: 5-minute window |
| 15 | Low | coupon-validate | Unlimited guesses. | Fixed: 10 checks per user per hour |
| 16 | Low | profiles | Clients could write `profiles.plan` (unused by the server, so no escalation). | Fixed: column privileges |
| 17 | Low | user_backups | No size limit. | Fixed: 10 MB constraint |
| 18 | Low | Account deletion | Wiped every account's data on the device; AI log rows kept. | Fixed |
| 19 | Low | Web hosting | GitHub Pages can't send HSTS, `frame-ancestors`, `Permissions-Policy`, `X-Content-Type-Options` headers. | Owner: put Cloudflare in front when convenient (§9) |
| 20 | Low | Android | Release builds fall back to the debug key when no release key is configured. | Owner: create the upload key before Play publication |
| 21 | Info | Web/mobile | The Supabase session lives in localStorage / app storage (no HttpOnly cookie, inherent to supabase_flutter). | Accepted: mitigated by CSP and short-lived access tokens |
| 22 | Info | Local features | Pro-only features computed on the device (salary split, smart alerts) can be unlocked by a modified client. | Accepted: no server data or cost involved; metered features are enforced server-side |
| 23 | Info | DNS | No dangling records: `smartbudget` → GitHub Pages, `www` → Namecheap parking, apex/others unset. | Done: `dgotix.com` is verified in GitHub Pages |

**Checked with no issue found:**
- **SQL injection:** queries go through the supabase-js query builder, and the
  SQL functions use parameters only.
- **SSRF:** proxy upstreams are fixed, and parameters select from allow-lists.
- **XSS:** Flutter renders text, not HTML.
- **CSRF:** there are no cookies, and auth uses the Authorization header.
- **Error messages:** they return codes only, with no stack traces or details.
- **Secrets:** none in git history, the bundle or logs.
- **Checkout:** the user comes from the JWT and the price from the server.
- **manage-subscription:** acts only on the caller's own subscription.
- **Card numbers read from receipts:** masked server-side.

## 5. Verification

| What | How | Result |
|---|---|---|
| Access control (IDOR/BOLA, privilege escalation) | `supabase/tests/access_control_test.sql`: 34 attempts as user A and as anon against Supabase-like grants + RLS | 34/34 blocked/allowed as expected; reopening two holes makes it fail |
| Atomic quotas | 20 concurrent `reserve_usage` calls on Postgres 16, limit 5 | exactly 5 `ok`, counter = 5 |
| Payments and limits end to end | `supabase/tests/functions_test.ts`: 15 scenarios through the real function handlers (in-memory DB, stubbed providers) | 15/15; the previous code fails 8 |
| Database setup | `setup_all.sql` applied twice on a fresh Postgres | succeeds (re-runnable) |
| CSP | built site in Chromium, 10 pages + attack probes | no violations; attacks blocked |
| Regression | Flutter analyze + 480 tests; Deno unit tests | pass |

The new **Security tests** workflow runs the access-control and the
function scenarios on every push.

Not tested here: live Paddle/PayPal sandboxes, a real Android device,
production HTTP headers (the sandbox can't reach the domain).

## 6. MFA readiness

Supabase Auth supports TOTP MFA without a rebuild:

1. Enable MFA in Authentication → Settings.
2. Add enrollment and challenge screens using `supabase.auth.mfa`.
3. For sensitive actions (delete account, manage subscription), have
   `requireUserId` also return the token's `aal` claim, and require `aal2`
   once the user has a factor.

## 7. Monitoring

**What exists today:**
- Supabase Auth audit logs (sign-ins, password resets, user changes).
- `billing_events` (every payment event id).
- `ai_request_log` (per request: model, latency, tokens, cost estimate and
  error code, including `global_limit`).

**Recommended:**
- A weekly look at Auth logs for failed sign-in bursts.
- Budget alerts in Google Cloud for the Gemini key.
- Supabase usage alerts.

## 8. Security score (current, after the SQL is run)

| Area | Score |
|---|---|
| Authentication | 72 |
| Authorization | 88 |
| API security | 80 |
| Database | 84 |
| Payment security | 80 |
| File upload (receipt images) | 82 |
| Mobile | 65 |
| Web | 72 |
| Infrastructure | 72 |
| Monitoring | 45 |
| **Overall** | **74 / 100** |

**What would raise it:**
- MFA for users.
- A release signing key.
- Cloudflare in front of the site (headers, WAF, rate limits).
- Alerting.
- Encrypted on-device storage.
- A live payment sandbox test.

## 9. Before real payments and public launch

1. **Run `supabase/security_hardening.sql`** in the Supabase SQL editor.
2. **Turn beta off when paid plans go live:** set the Edge Function secret
   `BETA_ALL_ACCESS=false` (and build the app with `BETA_ALL_ACCESS=false`).
3. **Payments:**
   - Fill `billing_prices` with the real Paddle/PayPal ids.
   - Set the webhook secrets: `PADDLE_WEBHOOK_SECRET`, `PAYPAL_WEBHOOK_ID`.
   - Run one full sandbox purchase, renewal and cancellation for each
     provider.
4. **Gemini:** the key is on the free tier (no billing, so no charges, but
   Google may use free-tier content to improve its products). Before the
   public launch, move to the paid tier with a budget alert, restrict the
   key to the Generative Language API, and say in the privacy policy that
   receipts and AI questions are processed by Google Gemini.
5. **Supabase Auth settings:** done: email OTP expiry is 15 minutes, the
   minimum password is 8 characters (letters and digits), and secure email
   change is on. Keep the default rate limits, and consider a CAPTCHA
   (Cloudflare Turnstile) on sign-up and reset if abuse appears.
6. **Android:** create the upload/release key, and store it in GitHub
   secrets.
7. **GitHub Pages:** done: `dgotix.com` is verified for the account.
8. **Later:**
   - Cloudflare proxy (HSTS, frame-ancestors, Permissions-Policy, WAF,
     rate limits).
   - Encrypted on-device storage.
   - MFA.

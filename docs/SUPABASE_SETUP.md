# Production backend (Supabase) — setup

The app ships as a working demo on the **local dev backend** (in-memory / device
storage) with zero credentials. To turn it into a real product with cloud
accounts and persistence, connect a free Supabase project. Nothing in the UI or
business logic changes — only which backend the repositories bind to.

## 1. Create the project & schema

1. Create a project at https://supabase.com (free tier is enough).
2. In the SQL editor, run `supabase/schema.sql` (tables + Row Level Security).

## 2. Build with credentials

The URL and anon key are public client config (safe to embed), injected at build:

```bash
flutter build web --release \
  --base-href /smartbudget-DGOTIX/ \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

When both are set, `AppEnv.hasSupabase` is true, `main()` initializes Supabase,
and **auth** binds to `SupabaseAuthRepository` (real sign-in / sign-up / reset).
With them absent, the app stays on the fake dev backend.

> Secrets: only the **anon** key belongs in the client (RLS protects data). The
> service-role key and any provider keys stay server-side (Edge Functions / env)
> — never in the frontend.

## 3. Status of the migration

- ✅ **Auth** — real Supabase sign-in/up/reset, dormant until configured.
- ⏳ **Data repositories** (transactions, budgets, goals, debts) — the clean
  interfaces are backend-agnostic and ready; the Supabase implementations are
  wired next, against a live project so each can be validated (the financial
  data layer is not ported blind). Until then, with Supabase auth on, data still
  uses device storage.

To enable the market-data proxy for commodities, see `docs/MARKETS_BACKEND.md`.

## 4. Account recovery by email code + strong passwords

The app's "Forgot password?" flow is code-based: the user enters their email,
receives a one-time **code**, then types it with a new password (entered twice).
The app calls `resetPasswordForEmail` → `verifyOTP(type: recovery)` →
`updateUser(password)`. Four dashboard settings make it work in production:

1. **Custom SMTP — required.** Supabase's built-in email service only delivers
   to your own project team's addresses (everyone else gets "Email address not
   authorized") and has a very low rate limit. Set up a provider under
   *Authentication → Emails → SMTP Settings* (e.g. Resend, Brevo, Postmark,
   Amazon SES, or your domain's mail server). New free-tier projects also
   cannot edit email templates without custom SMTP.

2. **Recovery email template — must contain the code.** The default "Reset
   Password" email only has a link. Under *Authentication → Emails → Templates →
   Reset Password*, paste `supabase/templates/recovery.html` (bilingual EN/AR;
   it renders `{{ .Token }}`). Suggested subject:
   `Your SmartBudget verification code / رمز التحقّق الخاص بك`.

3. **Password rules (server side).** Under *Authentication → Providers → Email*:
   - **Minimum password length: 8**
   - **Password requirements: "Letters and digits"** (`letters_digits`)

   Supabase has no "letters + digits + symbol" option, so the app enforces the
   symbol rule itself (8+ chars, a letter, a digit, a symbol, no spaces — see
   `lib/features/auth/domain/password_policy.dart`). The app's symbol set is the
   same ASCII set Supabase uses, so nothing the app accepts is rejected by the
   server. Do **not** pick the uppercase/lowercase options unless you also add
   those rules to the app, or valid passwords will be refused.

4. **Code lifetime.** *Email OTP expiration* (same page): 600–900 seconds
   (10–15 minutes) is a sensible value for a recovery code.

Sign-in never applies the new rules, so existing users with older passwords are
never locked out; they are only asked for a strong password the next time they
set one. Without a Supabase project configured, the dev fake accepts any 6-digit
code for the email that requested it (development only).

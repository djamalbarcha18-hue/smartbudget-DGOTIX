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

# SmartBudget — by DGOTIX (Flutter app)

Premium financial SaaS, **Web-first** (Android/iOS later from the same codebase).
This folder (`app/`) is the **V2 product**. It lives beside the existing Google
Apps Script project (V1) **without touching it** — V1 keeps running while V2 is
built phase by phase.

> Status: **Phase 3 — Live finance core** (on P1+P2). Transactions, Income and
> Expenses with quick-add modals; the Dashboard now computes real KPIs (income,
> expenses, net, savings rate), an expense-by-category breakdown, and recent
> transactions — all from your entered data via the SmartBudget formulas, with
> neutral empty states when there's no data. Runs on the **local dev backend
> (fake)** with zero credentials; Supabase (Postgres + RLS) wires in later.
> One base currency per user for now — multi-currency conversion arrives with
> the exchange-rate phase.

## Requirements

- Flutter **stable** ≥ 3.27 (Dart ≥ 3.6)
- Chrome (for `-d chrome`)

## Run

```bash
cd app
flutter pub get        # also generates localizations (gen-l10n)
flutter run -d chrome  # launch the web app
```

## Verify

```bash
flutter analyze
flutter test
```

CI runs the same `analyze` + `test` on every push touching `app/**`
(`.github/workflows/flutter-ci.yml`).

## What's here (Phase 1)

- **DGOTIX Design System** (`lib/design_system/`): color/glass/spacing/radius/
  typography tokens as `ThemeExtension`s, `GlassCard`, `KpiCard`, buttons,
  badges, states, and the theme-aware DGOTIX brand lockup.
- **Theme** (dark-first + light), toggled instantly and persisted.
- **Localization** ar/en (RTL/LTR flips with no reload), French-ready.
- **Navigation** shell: responsive sidebar (drawer on mobile), top bar, compact
  footer.
- **Dashboard scaffold**: real SmartBudget KPI structure as empty states.

## Brand assets

The two official DGOTIX SVGs are byte-identical copies of the repository-root
originals (never redrawn/recolored):

| File | Variant | Used in |
|------|---------|---------|
| `assets/brand/dgotix-logo.svg` | Colored | Light mode |
| `assets/brand/dgotix-logo-mono.svg` | Monochrome | Dark mode |

All logo access goes through `BrandAssets` (one place to change files/paths).

## Authentication (Phase 2)

Out of the box the app uses a **local dev backend** — no setup needed. Just run
it: you'll land on the sign-in screen. Enter any valid-looking email and a
password of 6+ characters to sign in (dev fake), or create an account. The
session persists across reloads; sign out from the profile menu (top-right).

### Wiring the real backend (Supabase)

1. Create a Supabase project and run `supabase/schema.sql` (SQL editor or CLI).
2. Copy `dart_define.example.json` → `dart_define.json` (gitignored) and fill in
   `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
3. Run with: `flutter run -d chrome --dart-define-from-file=dart_define.json`.

The Supabase `AuthRepository` implementation is bound in
`lib/features/auth/application/auth_controller.dart` (one line) — no UI changes.
The anon key is public by design; **real protection is Row-Level Security** in
`schema.sql`, which isolates each user's data at the database.

## Configuration

App-level, non-financial settings (support email, brand ordering, links) live in
one file: `lib/core/config/app_config.dart`. The support email is a single
placeholder (`support@YOUR-DOMAIN.com`) — change it there only.

See `docs/ARCHITECTURE.md` for the layering, decisions, and the financial-logic
governance boundary.

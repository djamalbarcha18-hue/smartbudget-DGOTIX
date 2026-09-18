# SmartBudget SaaS — Architecture (living document)

## 1. Goal & principles

Re-engineer SmartBudget (Google Sheets + Apps Script, "V1") into a real Flutter
SaaS ("V2"): premium, fast, secure, scalable, responsive, multilingual,
AI-powered. Web first; the same codebase targets Android/iOS later.

Guiding rules:

- **V1 is never broken.** V2 is built in `app/`, isolated, phase by phase.
- **Clean layering.** No business logic in widgets. Features are self-contained.
- **Design-token driven.** Colors/spacing/typography flow from one place.
- **No fabricated financial data.** Missing data renders empty states.

## 2. Financial-logic governance (the hard boundary)

Two zones govern every change:

- 🟢 **Engineering zone** (decide & implement autonomously): architecture, state
  management, UX/responsive, theming, naming, performance, technical fixes,
  separating legacy from V2.
- 🔴 **Financial zone** (never invent/alter without explicit confirmation):
  accounts, balances, income, expenses, savings, debts, zakat, financial health,
  and any financial KPI or formula. Presentation may change freely; the
  **calculation rule** may not.

The authoritative financial rules are the **existing SmartBudget logic** (V1),
captured as a KPI registry (see the analysis report). V2 re-implements those
rules as pure Dart calculators with unit tests that reproduce V1 results — it
does not redesign them.

### Open financial questions (blocked pending confirmation)

- `_DashboardEngine!H5` ("current assets") = `goals!D2 + O5`, but `goals!D2` is a
  **percentage (0–1)**, not an amount — a probable unit mismatch. `H6`
  ("liabilities") = `debts!D2 + goals!B3 * 12` with a manual, default-0 cell.
  These two cells appear unused by the current 6 dashboard cards. **V2 will not
  surface Assets/Liabilities until the intended rule is confirmed.**
- AI context reads health from `_DashboardEngine!O2:O3`, which V1 removed
  (health now comes from `rng_health_score`). This is a technical fix to apply
  when the AI context is re-implemented (engineering zone).

## 3. Layering

```
lib/
├── core/            cross-cutting: config, router, theme, localization
├── design_system/   DGOTIX DS: tokens (ThemeExtension) · components · brand
├── features/        feature-first modules (shell, dashboard, …)
│   └── <feature>/presentation | application | domain | data
├── app.dart         MaterialApp.router (theme + locale + routing wiring)
└── main.dart        runApp(ProviderScope(...))
```

Later phases add, per feature: `domain/` (entities, repository interfaces,
use-cases — pure, testable), `data/` (DTOs, datasources, repository impls), and
`application/` (Riverpod providers). No dependency points from `domain` outward.

## 4. Technology decisions (Phase 1)

| Concern | Choice | Why |
|---|---|---|
| UI framework | Flutter (Web-first) | One codebase → Web + mobile later |
| State | Riverpod | Testable, granular rebuilds, no BuildContext coupling |
| Routing | go_router | Web URLs, deep links, guards, shell routes |
| i18n | flutter gen-l10n + intl (ARB) | Standard, French-ready; RTL/LTR automatic |
| Logos | flutter_svg + `BrandAssets` | Vector, theme-swapped from one place |
| Prefs | shared_preferences | Per-viewer theme/locale only (never financial) |
| Design tokens | `ThemeExtension` | Swappable palette; reusable across DGOTIX products |

### Proposed for later phases (not built in P1)

- **Backend/DB/Auth:** Supabase (Postgres + Row-Level Security) — relational fit
  for financial aggregation/reporting; RLS gives real per-user data isolation.
- **AI:** Edge Function proxy holding the model key server-side (never on client).
- **Scheduled jobs:** replace Apps Script triggers (snapshots, notifications,
  FX refresh) with cron/Edge scheduled functions.

## 5. Design system

- **Glassmorphism:** moderate — translucent fill, light blur (14–16σ), hairline
  border, soft shadow, subtle gradient, 1px top highlight. No neon/gaming.
- **Dark-first**, plus a genuine light theme (not an inversion).
- **Icons:** Material **outlined** set via a uniform stroke; **no emoji** in UI.
- **Semantics** inherited from V1: income=emerald, expense=red, saving/net=blue/
  cyan, brand=DGOTIX blue `#1680F7` (accent, used sparingly).

## 6. Roadmap (phase gates)

P1 Foundation ✅ → P2 Auth + DB → P3 Dashboard/Transactions/Income/Expenses →
P4 Monthly Budget/Goals/Debts → P5 Financial Health/Reports → P6 Zakat/FX →
P7 AI → P8 Receipt Scanner (architecture-ready) → P9 Subscriptions → P10 Prod →
Android/iOS. Each phase is testable before the next begins.

-- ============================================================================
-- SmartBudget — by DGOTIX · Database foundation (Supabase / PostgreSQL)
-- ----------------------------------------------------------------------------
-- Design notes:
--  • Money is stored as BIGINT MINOR UNITS (e.g. cents) + a currency code, to
--    avoid floating-point error in financial math. Never store money as float.
--  • Every user-owned table carries user_id and is protected by Row-Level
--    Security so a user can only ever read/write their own rows (real data
--    isolation, enforced by the database, not the client).
--  • This mirrors the existing SmartBudget domain (income/expense, goals,
--    debts, zakat, financial health). It does NOT change any financial rule —
--    calculators re-implement V1 logic in the app/service layer.
--
-- Apply with the Supabase SQL editor or CLI migrations. Idempotent-ish: uses
-- IF NOT EXISTS where practical. Review before running in production.
-- ============================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Reference data (global, read-only to clients)
-- ---------------------------------------------------------------------------
create table if not exists currencies (
  code        text primary key,             -- e.g. 'USD', 'DZD'
  name_ar     text not null,
  name_en     text not null,
  symbol      text not null,
  decimals    smallint not null default 2
);

create table if not exists exchange_rates (
  id          uuid primary key default gen_random_uuid(),
  code        text not null references currencies(code),
  rate_vs_usd numeric(18,6) not null,        -- units of `code` per 1 USD
  fetched_at  timestamptz not null default now()
);
create index if not exists idx_rates_code_time on exchange_rates(code, fetched_at desc);

-- Every currency the app offers (lib/core/money/currency.dart). profiles
-- .base_currency references this table, so it must be filled before the
-- first sign-up or creating the profile row fails.
insert into currencies (code, name_ar, name_en, symbol, decimals) values
  ('USD', 'الدولار الأمريكي', 'US Dollar', '$', 2),
  ('DZD', 'الدينار الجزائري', 'Algerian Dinar', 'د.ج', 2),
  ('SAR', 'الريال السعودي', 'Saudi Riyal', 'ر.س', 2),
  ('AED', 'الدرهم الإماراتي', 'UAE Dirham', 'د.إ', 2),
  ('QAR', 'الريال القطري', 'Qatari Riyal', 'ر.ق', 2),
  ('KWD', 'الدينار الكويتي', 'Kuwaiti Dinar', 'د.ك', 3),
  ('BHD', 'الدينار البحريني', 'Bahraini Dinar', 'د.ب', 3),
  ('OMR', 'الريال العماني', 'Omani Rial', 'ر.ع', 3),
  ('JOD', 'الدينار الأردني', 'Jordanian Dinar', 'د.أ', 3),
  ('EGP', 'الجنيه المصري', 'Egyptian Pound', 'ج.م', 2),
  ('MAD', 'الدرهم المغربي', 'Moroccan Dirham', 'د.م', 2),
  ('TND', 'الدينار التونسي', 'Tunisian Dinar', 'د.ت', 3),
  ('LYD', 'الدينار الليبي', 'Libyan Dinar', 'د.ل', 3),
  ('IQD', 'الدينار العراقي', 'Iraqi Dinar', 'د.ع', 3),
  ('LBP', 'الليرة اللبنانية', 'Lebanese Pound', 'ل.ل', 2),
  ('SYP', 'الليرة السورية', 'Syrian Pound', 'ل.س', 2),
  ('SDG', 'الجنيه السوداني', 'Sudanese Pound', 'ج.س', 2),
  ('YER', 'الريال اليمني', 'Yemeni Rial', 'ر.ي', 2),
  ('MRU', 'الأوقية الموريتانية', 'Mauritanian Ouguiya', 'أ.م', 2),
  ('EUR', 'اليورو', 'Euro', '€', 2),
  ('GBP', 'الجنيه الإسترليني', 'Pound Sterling', '£', 2),
  ('JPY', 'الين الياباني', 'Japanese Yen', '¥', 0),
  ('CNY', 'اليوان الصيني', 'Chinese Yuan', '¥', 2),
  ('CHF', 'الفرنك السويسري', 'Swiss Franc', 'Fr', 2),
  ('CAD', 'الدولار الكندي', 'Canadian Dollar', 'C$', 2),
  ('AUD', 'الدولار الأسترالي', 'Australian Dollar', 'A$', 2),
  ('INR', 'الروبية الهندية', 'Indian Rupee', '₹', 2),
  ('TRY', 'الليرة التركية', 'Turkish Lira', '₺', 2),
  ('RUB', 'الروبل الروسي', 'Russian Ruble', '₽', 2),
  ('BRL', 'الريال البرازيلي', 'Brazilian Real', 'R$', 2),
  ('ZAR', 'الراند الجنوب إفريقي', 'South African Rand', 'R', 2),
  ('SGD', 'الدولار السنغافوري', 'Singapore Dollar', 'S$', 2),
  ('KRW', 'الوون الكوري الجنوبي', 'South Korean Won', '₩', 0),
  ('SEK', 'الكرونة السويدية', 'Swedish Krona', 'kr', 2),
  ('MXN', 'البيزو المكسيكي', 'Mexican Peso', 'Mex$', 2)
on conflict (code) do update set
  name_ar = excluded.name_ar, name_en = excluded.name_en,
  symbol = excluded.symbol, decimals = excluded.decimals;

-- ---------------------------------------------------------------------------
-- Profiles (1:1 with auth.users)
-- ---------------------------------------------------------------------------
create table if not exists profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  display_name  text,
  locale        text not null default 'ar',
  theme         text not null default 'dark',
  base_currency text not null default 'USD' references currencies(code),
  plan          text not null default 'free',   -- free | basic | pro | ultimate
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- User taxonomy
-- ---------------------------------------------------------------------------
create table if not exists categories (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  kind        text not null check (kind in ('income','expense')),
  name        text not null,
  is_default  boolean not null default false,
  created_at  timestamptz not null default now()
);
create index if not exists idx_categories_user on categories(user_id);

create table if not exists payment_methods (
  id       uuid primary key default gen_random_uuid(),
  user_id  uuid not null references auth.users(id) on delete cascade,
  name     text not null
);
create index if not exists idx_payment_methods_user on payment_methods(user_id);

-- ---------------------------------------------------------------------------
-- Transactions (unified income/expense ledger)
-- ---------------------------------------------------------------------------
create table if not exists transactions (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  txn_date      date not null,
  type          text not null check (type in ('income','expense')),
  category_id   uuid references categories(id) on delete set null,
  description   text,
  amount_minor  bigint not null check (amount_minor >= 0),
  currency      text not null references currencies(code),
  payment_method_id uuid references payment_methods(id) on delete set null,
  notes         text,
  created_at    timestamptz not null default now()
);
create index if not exists idx_txn_user_date on transactions(user_id, txn_date desc);
create index if not exists idx_txn_user_type on transactions(user_id, type);

-- ---------------------------------------------------------------------------
-- Monthly budgets (planned amounts per category)
-- ---------------------------------------------------------------------------
create table if not exists budgets (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  year          smallint not null,
  month         smallint not null check (month between 1 and 12),
  category_id   uuid references categories(id) on delete set null,
  planned_minor bigint not null default 0,
  unique (user_id, year, month, category_id)
);
create index if not exists idx_budgets_user on budgets(user_id, year, month);

-- ---------------------------------------------------------------------------
-- Goals & savings
-- ---------------------------------------------------------------------------
create table if not exists goals (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  name          text not null,
  target_minor  bigint not null check (target_minor >= 0),
  currency      text not null references currencies(code),
  deadline      date,
  created_at    timestamptz not null default now()
);
create index if not exists idx_goals_user on goals(user_id);

-- Saved amount is DERIVED from allocations (never a hardcoded seed) — matches
-- V1's recalcGoalSavings behavior.
create table if not exists goal_allocations (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  goal_id        uuid not null references goals(id) on delete cascade,
  transaction_id uuid references transactions(id) on delete set null,
  amount_minor   bigint not null,
  alloc_date     date not null default current_date
);
create index if not exists idx_alloc_user_goal on goal_allocations(user_id, goal_id);

-- ---------------------------------------------------------------------------
-- Debts ledger (money lent / borrowed)
-- ---------------------------------------------------------------------------
create table if not exists debts (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  party         text not null,
  type          text not null check (type in ('lent','borrowed')), -- لي / عليّ
  original_minor bigint not null check (original_minor >= 0),
  paid_minor    bigint not null default 0 check (paid_minor >= 0),
  currency      text not null references currencies(code),
  debt_date     date not null default current_date,
  due_date      date,
  notes         text,
  created_at    timestamptz not null default now()
  -- remaining_minor and status are computed in the app/service layer
  -- (remaining = max(0, original - paid); status: active/paid), matching V1.
);
create index if not exists idx_debts_user on debts(user_id);

-- ---------------------------------------------------------------------------
-- Zakat records (historical log, per year)
-- ---------------------------------------------------------------------------
create table if not exists zakat_records (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users(id) on delete cascade,
  year             smallint not null,
  nisab_basis      text not null check (nisab_basis in ('gold','silver')),
  net_zakatable_minor bigint not null default 0,
  nisab_minor      bigint not null default 0,
  due_minor        bigint not null default 0,
  currency         text not null references currencies(code),
  calc_date        timestamptz not null default now(),
  unique (user_id, year)
);

-- ---------------------------------------------------------------------------
-- Financial health snapshots (score + factor breakdown as JSON)
-- ---------------------------------------------------------------------------
create table if not exists financial_health_snapshots (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  period       text not null,             -- e.g. '2026', '2026-Q1'
  score        numeric(5,2) not null,     -- 0..100
  factors      jsonb not null default '{}'::jsonb,
  created_at   timestamptz not null default now()
);
create index if not exists idx_health_user on financial_health_snapshots(user_id, created_at desc);

-- ============================================================================
-- Row-Level Security
-- ============================================================================
alter table profiles                    enable row level security;
alter table categories                  enable row level security;
alter table payment_methods             enable row level security;
alter table transactions                enable row level security;
alter table budgets                     enable row level security;
alter table goals                       enable row level security;
alter table goal_allocations            enable row level security;
alter table debts                       enable row level security;
alter table zakat_records               enable row level security;
alter table financial_health_snapshots  enable row level security;

-- Reference data: readable by any authenticated user, writable by nobody (via
-- client). Rates are refreshed by a trusted scheduled job using the service role.
alter table currencies     enable row level security;
alter table exchange_rates enable row level security;
drop policy if exists currencies_read on currencies;
create policy currencies_read on currencies
  for select using (auth.role() = 'authenticated');
drop policy if exists exchange_rates_read on exchange_rates;
create policy exchange_rates_read on exchange_rates
  for select using (auth.role() = 'authenticated');

-- Profiles: a user sees/edits only their own profile row.
drop policy if exists profiles_self on profiles;
create policy profiles_self on profiles
  for all using (id = auth.uid()) with check (id = auth.uid());

-- Owned tables: full isolation on user_id. One policy per table (same shape).
do $$
declare t text;
begin
  foreach t in array array[
    'categories','payment_methods','transactions','budgets','goals',
    'goal_allocations','debts','zakat_records','financial_health_snapshots'
  ] loop
    execute format('drop policy if exists %1$s_owner on %1$s;', t);
    execute format(
      'create policy %1$s_owner on %1$s for all
         using (user_id = auth.uid()) with check (user_id = auth.uid());', t);
  end loop;
end $$;

-- Auto-provision a profile row on signup.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', null))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

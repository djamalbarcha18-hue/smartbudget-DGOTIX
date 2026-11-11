-- ============================================================================
-- SmartBudget — owner-entered parallel-market rates (run after schema.sql;
-- safe to re-run)
-- ----------------------------------------------------------------------------
-- The parallel ("street") rate of a country has no official feed, and the
-- community sites that publish one come and go. So the OWNER types the day's
-- buy/sell rates in the app (Settings > Parallel rates, shown to admins only)
-- and every user reads them, with the time they were last set.
--
-- Who is an admin: a row in app_admins. Add yourself once, in the SQL editor:
--   insert into app_admins (user_id)
--   select id from auth.users where email = 'you@example.com'
--   on conflict do nothing;
--
-- Clients never touch the tables: they call the three functions below.
--   parallel_rates_for(country)            anyone — the rates of one country
--   is_app_admin()                          signed-in — may I edit?
--   set_parallel_rate(country, currency, buy, sell)   admins only
-- ============================================================================

create table if not exists app_admins (
  user_id  uuid primary key references auth.users (id) on delete cascade,
  added_at timestamptz not null default now()
);
alter table app_admins enable row level security;
revoke all on table app_admins from anon, authenticated;

create table if not exists parallel_rates (
  country    text        not null,          -- ISO alpha-2, lower case: 'dz'
  currency   text        not null,          -- ISO 4217, upper case: 'EUR'
  buy        numeric,                       -- base units per 1 currency
  sell       numeric,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  primary key (country, currency),
  constraint parallel_rates_country_ok  check (country ~ '^[a-z]{2}$'),
  constraint parallel_rates_currency_ok check (currency ~ '^[A-Z]{3,5}$'),
  constraint parallel_rates_has_value   check (buy is not null or sell is not null),
  constraint parallel_rates_buy_ok      check (buy  is null or (buy  > 0 and buy  < 1e9)),
  constraint parallel_rates_sell_ok     check (sell is null or (sell > 0 and sell < 1e9))
);
alter table parallel_rates enable row level security;
revoke all on table parallel_rates from anon, authenticated;

-- May the caller edit the rates?
create or replace function is_app_admin()
returns boolean
language sql stable security definer set search_path = public as $$
  select auth.uid() is not null
     and exists (select 1 from app_admins where user_id = auth.uid());
$$;
revoke all on function is_app_admin() from public, anon;
grant execute on function is_app_admin() to authenticated;

-- The rates of one country, for everyone (they are public figures).
create or replace function parallel_rates_for(p_country text)
returns table (currency text, buy numeric, sell numeric, updated_at timestamptz)
language sql stable security definer set search_path = public as $$
  select r.currency, r.buy, r.sell, r.updated_at
  from parallel_rates r
  where r.country = lower(p_country)
  order by r.currency;
$$;
revoke all on function parallel_rates_for(text) from public;
grant execute on function parallel_rates_for(text) to anon, authenticated;

-- Sets (or, with both values null, removes) one rate. Admins only.
create or replace function set_parallel_rate(
  p_country text, p_currency text, p_buy numeric, p_sell numeric)
returns void
language plpgsql security definer set search_path = public as $$
declare
  c text := lower(coalesce(p_country, ''));
  cur text := upper(coalesce(p_currency, ''));
begin
  if not is_app_admin() then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  if c !~ '^[a-z]{2}$' or cur !~ '^[A-Z]{3,5}$' then
    raise exception 'bad country or currency' using errcode = '22023';
  end if;
  if p_buy is null and p_sell is null then
    delete from parallel_rates where country = c and currency = cur;
    return;
  end if;
  if (p_buy is not null and (p_buy <= 0 or p_buy >= 1e9))
     or (p_sell is not null and (p_sell <= 0 or p_sell >= 1e9)) then
    raise exception 'bad rate' using errcode = '22023';
  end if;
  insert into parallel_rates as r (country, currency, buy, sell, updated_at, updated_by)
  values (c, cur, p_buy, p_sell, now(), auth.uid())
  on conflict (country, currency)
  do update set buy = excluded.buy, sell = excluded.sell,
                updated_at = now(), updated_by = auth.uid();
end $$;
revoke all on function set_parallel_rate(text, text, numeric, numeric) from public, anon;
grant execute on function set_parallel_rate(text, text, numeric, numeric) to authenticated;

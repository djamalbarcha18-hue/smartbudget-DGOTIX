-- Access control tests: run as the database owner on a scratch database after
-- supabase_stub.sql and setup_all.sql (see .github/workflows/security-tests.yml).
-- Each attempt runs as a signed-in user (or signed out) through RLS and the
-- grants Supabase gives clients; the run fails if any attempt gets through.
\set ON_ERROR_STOP on
\set QUIET on
\pset tuples_only on
-- Two accounts with data, seeded as the database owner.
insert into auth.users (id, email) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'a@test'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'b@test');
insert into transactions (user_id, txn_date, type, amount_minor, currency) values
  ('bbbbbbbb-0000-0000-0000-000000000002', '2026-10-01', 'expense', 5000, 'USD');
insert into user_backups (user_id, data) values
  ('bbbbbbbb-0000-0000-0000-000000000002', '{"secret":"B"}');
-- B signed up a month ago; A just now.
update auth.users set created_at = now() - interval '30 days'
  where id = 'bbbbbbbb-0000-0000-0000-000000000002';
insert into subscriptions (user_id, plan, status) values
  ('bbbbbbbb-0000-0000-0000-000000000002', 'pro', 'active');
insert into ai_entitlements (user_id, plan) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'free');
insert into ai_usage_monthly (user_id, month, requests) values
  ('aaaaaaaa-0000-0000-0000-000000000001', '2026-10', 5);

create temp table results (test text, outcome text);
grant all on results to authenticated, anon;

create or replace function pg_temp.attempt(t text, q text, want text) returns void
language plpgsql as $$
declare n int; got text;
begin
  begin
    execute q;
    get diagnostics n = row_count;
    got := 'rows=' || n;
  exception when others then
    got := 'denied';
  end;
  insert into results values (t, case when got = want then 'PASS' else 'FAIL (got ' || got || ', want ' || want || ')' end);
end $$;

-- Everything below runs as signed-in user A.
set role authenticated;
select set_config('request.jwt.claim.sub', 'aaaaaaaa-0000-0000-0000-000000000001', false);

select pg_temp.attempt('A reads B transactions', 'select * from transactions where user_id <> auth.uid()', 'rows=0');
select pg_temp.attempt('A edits B transactions', 'update transactions set amount_minor = 1 where user_id <> auth.uid()', 'rows=0');
select pg_temp.attempt('A deletes B transactions', 'delete from transactions where user_id <> auth.uid()', 'rows=0');
select pg_temp.attempt('A inserts a transaction for B', $q$insert into transactions (user_id, txn_date, type, amount_minor, currency) values ('bbbbbbbb-0000-0000-0000-000000000002','2026-10-02','income',1,'USD')$q$, 'denied');
select pg_temp.attempt('A reads B backup', 'select * from user_backups where user_id <> auth.uid()', 'rows=0');
select pg_temp.attempt('A overwrites B backup', $q$update user_backups set data = '{}' where user_id <> auth.uid()$q$, 'rows=0');
select pg_temp.attempt('A writes a backup as B', $q$insert into user_backups (user_id, data) values ('bbbbbbbb-0000-0000-0000-000000000002', '{}')$q$, 'denied');
select pg_temp.attempt('A writes own backup', $q$insert into user_backups (user_id, data) values (auth.uid(), '{"ok":1}')$q$, 'rows=1');
select pg_temp.attempt('A writes an 11 MB backup', $q$update user_backups set data = jsonb_build_object('x', (select string_agg(md5(i::text), '') from generate_series(1, 360000) i)) where user_id = auth.uid()$q$, 'denied');
select pg_temp.attempt('A reads B subscription', 'select * from subscriptions where user_id <> auth.uid()', 'rows=0');
select pg_temp.attempt('A gives self a subscription', $q$insert into subscriptions (user_id, plan, status) values (auth.uid(), 'pro', 'active')$q$, 'denied');
select pg_temp.attempt('A changes B subscription', $q$update subscriptions set plan = 'free'$q$, 'rows=0');
select pg_temp.attempt('A upgrades own entitlement', $q$update ai_entitlements set plan = 'pro' where user_id = auth.uid()$q$, 'rows=0');
select pg_temp.attempt('A creates a pro entitlement', $q$insert into ai_entitlements (user_id, plan) values (auth.uid(), 'pro') on conflict do nothing$q$, 'denied');
select pg_temp.attempt('A resets own AI usage', 'update ai_usage_monthly set requests = 0 where user_id = auth.uid()', 'rows=0');
select pg_temp.attempt('A deletes own AI usage', 'delete from ai_usage_monthly where user_id = auth.uid()', 'rows=0');
select pg_temp.attempt('A resets own OCR usage', $q$insert into ocr_usage_monthly (user_id, month, scans) values (auth.uid(), '2026-10', -100)$q$, 'denied');
select pg_temp.attempt('A lists coupons', 'select * from coupons', 'denied');
select pg_temp.attempt('A reads price map', 'select * from billing_prices', 'denied');
select pg_temp.attempt('A reads payment events', 'select * from billing_events', 'denied');
select pg_temp.attempt('A reads AI request log', 'select * from ai_request_log', 'denied');
select pg_temp.attempt('A reads coupon attempts', 'select * from coupon_attempts', 'denied');
select pg_temp.attempt('A clears coupon attempts', 'delete from coupon_attempts', 'denied');
select pg_temp.attempt('A sets own profile plan', $q$update profiles set plan = 'pro' where id = auth.uid()$q$, 'denied');
select pg_temp.attempt('A sets own display name', $q$update profiles set display_name = 'A' where id = auth.uid()$q$, 'rows=1');
select pg_temp.attempt('A edits B profile', $q$update profiles set display_name = 'x' where id <> auth.uid()$q$, 'rows=0');
select pg_temp.attempt('A reserves usage directly', $q$select reserve_usage(auth.uid(), 'ai', '2026-10', 999, false, null)$q$, 'denied');
select pg_temp.attempt('A gives back usage directly', $q$select release_usage(auth.uid(), 'ai', '2026-10')$q$, 'denied');
select pg_temp.attempt('A files a report as B', $q$insert into ai_reports (user_id, reason, answer) values ('bbbbbbbb-0000-0000-0000-000000000002', 'other', 'x')$q$, 'denied');
select pg_temp.attempt('A reads reports', 'select * from ai_reports', 'rows=0');
select pg_temp.attempt('A reads payment subscriptions', 'select * from billing_subscriptions', 'denied');
select pg_temp.attempt('A writes a payment subscription', $q$insert into billing_subscriptions (provider, provider_subscription_id, user_id, plan, status) values ('paddle', 'sub_x', auth.uid(), 'pro', 'active')$q$, 'denied');
select pg_temp.attempt('A applies a payment event directly', $q$select apply_subscription_event('paddle', 'sub_x', auth.uid(), 'pro', 'monthly', 'active', null, null, false, now())$q$, 'denied');
select pg_temp.attempt('A reads usage counters', 'select * from usage_daily', 'denied');
select pg_temp.attempt('A resets the shared usage', 'delete from usage_pools', 'denied');
select pg_temp.attempt('A clears own rate limits', 'delete from rate_limits', 'denied');
select pg_temp.attempt('A calls the rate limiter directly', $q$select rate_limit_hit(auth.uid(), 'ai', 60, 1000)$q$, 'denied');
select pg_temp.attempt('A files 20 reports in a day', $q$insert into ai_reports (reason, answer) select 'other', 'x' from generate_series(1, 20)$q$, 'rows=20');
select pg_temp.attempt('A files a 21st report the same day', $q$insert into ai_reports (reason, answer) values ('other', 'x')$q$, 'denied');
select pg_temp.attempt('A (new account) writes a 3 MB backup', $q$update user_backups set data = jsonb_build_object('x', (select string_agg(md5(i::text), '') from generate_series(1, 100000) i)) where user_id = auth.uid()$q$, 'denied');
select pg_temp.attempt('A (new account) writes a 1 MB backup', $q$update user_backups set data = jsonb_build_object('x', (select string_agg(md5(i::text), '') from generate_series(1, 30000) i)) where user_id = auth.uid()$q$, 'rows=1');

-- Signed in as B (an older account).
select set_config('request.jwt.claim.sub', 'bbbbbbbb-0000-0000-0000-000000000002', false);
select pg_temp.attempt('B (month-old account) writes a 3 MB backup', $q$update user_backups set data = jsonb_build_object('x', (select string_agg(md5(i::text), '') from generate_series(1, 100000) i)) where user_id = auth.uid()$q$, 'rows=1');

-- Signed out (anon key only).
reset role;
set role anon;
select set_config('request.jwt.claim.sub', '', false);
select pg_temp.attempt('anon reads backups', 'select * from user_backups', 'rows=0');
select pg_temp.attempt('anon reads subscriptions', 'select * from subscriptions', 'rows=0');
select pg_temp.attempt('anon reads transactions', 'select * from transactions', 'rows=0');
select pg_temp.attempt('anon reserves usage', $q$select reserve_usage('aaaaaaaa-0000-0000-0000-000000000001', 'ai', '2026-10', 999, false, null)$q$, 'denied');
select pg_temp.attempt('anon applies a payment event', $q$select apply_subscription_event('paddle', 'sub_x', 'aaaaaaaa-0000-0000-0000-000000000001', 'pro', 'monthly', 'active', null, null, false, now())$q$, 'denied');
reset role;

select outcome || '  ' || test from results;
select count(*) filter (where outcome = 'PASS') || ' passed, ' || count(*) filter (where outcome <> 'PASS') || ' failed' from results;
do $$
begin
  if exists (select 1 from results where outcome <> 'PASS') then
    raise exception 'access control tests failed';
  end if;
end $$;

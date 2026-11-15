-- Account tombstones (DB-10) and the maintenance functions (DB-6, DB-7).
-- Run after setup_all.sql, like the other SQL tests.
\set ON_ERROR_STOP 1
begin;

insert into auth.users(id, email, email_confirmed_at)
  values ('00000000-0000-0000-0000-0000000000d1', 'Ali.Ben+promo@GoogleMail.com', now());
insert into ai_entitlements(user_id, trial_used_at) values ('00000000-0000-0000-0000-0000000000d1', now())
  on conflict (user_id) do update set trial_used_at = now();
insert into ai_usage_lifetime(user_id, requests) values ('00000000-0000-0000-0000-0000000000d1', 7)
  on conflict (user_id) do update set requests = 7;
insert into ocr_usage_lifetime(user_id, scans) values ('00000000-0000-0000-0000-0000000000d1', 3)
  on conflict (user_id) do update set scans = 3;
select public.record_account_tombstone('00000000-0000-0000-0000-0000000000d1');
delete from auth.users where id = '00000000-0000-0000-0000-0000000000d1';

do $$ begin
  assert (select count(*) from account_tombstones where email_hash ~ '@') = 0,
    'the e-mail is stored only as a hash';
end $$;

-- Signing up again with a variant of the same address.
insert into auth.users(id, email) values ('00000000-0000-0000-0000-0000000000d2', 'alibe.n@gmail.com');
do $$ begin
  assert (select trial_used_at is not null from ai_entitlements
          where user_id = '00000000-0000-0000-0000-0000000000d2'), 'trial stays used';
  assert (select requests from ai_usage_lifetime
          where user_id = '00000000-0000-0000-0000-0000000000d2') = 7, 'AI allowance kept';
  assert (select scans from ocr_usage_lifetime
          where user_id = '00000000-0000-0000-0000-0000000000d2') = 3, 'scan allowance kept';
end $$;

-- Someone else is not affected.
insert into auth.users(id, email) values ('00000000-0000-0000-0000-0000000000d3', 'other@gmail.com');
do $$ begin
  assert not exists (select 1 from ai_entitlements
                     where user_id = '00000000-0000-0000-0000-0000000000d3'
                       and trial_used_at is not null), 'other account untouched';
  assert not exists (select 1 from ai_usage_lifetime
                     where user_id = '00000000-0000-0000-0000-0000000000d3'
                       and requests > 0), 'other account has no usage';
end $$;

-- Usage added in place, twice.
select public.add_ai_usage('00000000-0000-0000-0000-0000000000d3', '2026-11', 1, 10, 20, 0.5);
select public.add_ai_usage('00000000-0000-0000-0000-0000000000d3', '2026-11', 0, 5, 5, 0.25);
do $$ begin
  assert (select (requests, input_tokens, output_tokens, est_cost_usd)::text from ai_usage_monthly
          where user_id = '00000000-0000-0000-0000-0000000000d3') = '(1,15,25,0.75)', 'usage summed';
end $$;

-- Old log rows go, recent ones stay.
insert into ai_request_log(user_id, task, created_at) values
  ('00000000-0000-0000-0000-0000000000d3', 'old', now() - interval '100 days'),
  ('00000000-0000-0000-0000-0000000000d3', 'new', now());
select public.purge_old_rows();
do $$ begin
  assert (select array_agg(task) from ai_request_log
          where user_id = '00000000-0000-0000-0000-0000000000d3') = array['new'], 'retention';
end $$;

-- Clients reach none of it.
set local role authenticated;
do $$ begin
  begin
    perform count(*) from account_tombstones;
    assert false, 'tombstones readable by a client';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.add_ai_usage('00000000-0000-0000-0000-0000000000d3', '2026-11', 1, 1, 1, 1);
    assert false, 'usage writable by a client';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

rollback;
\echo 'maintenance_test: ok'

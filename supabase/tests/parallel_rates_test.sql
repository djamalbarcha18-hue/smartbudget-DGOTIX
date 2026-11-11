-- Owner-entered parallel rates: everyone reads, only an admin writes.
-- Run after supabase_stub.sql + setup_all.sql.
\set ON_ERROR_STOP on
set client_min_messages = notice;

create or replace function assert(ok boolean, what text) returns void
language plpgsql as $$
begin
  if ok then raise notice 'PASS  %', what;
  else raise exception 'FAIL  %', what; end if;
end $$;

-- True when running [sql] raises an error.
create or replace function refuses(sql text) returns boolean
language plpgsql as $$
begin
  execute sql;
  return false;
exception when others then
  return true;
end $$;
grant execute on function assert(boolean, text) to anon, authenticated;
grant execute on function refuses(text) to anon, authenticated;

delete from parallel_rates; delete from app_admins;
delete from auth.users where email like '%@par.test';
insert into auth.users (id, email) values
  ('9a9a9a9a-0000-4000-8000-000000000001', 'owner@par.test'),
  ('9a9a9a9a-0000-4000-8000-000000000002', 'member@par.test');
insert into app_admins (user_id) values ('9a9a9a9a-0000-4000-8000-000000000001');

-- ------------------------------------------------------------- the admin
set role authenticated;
select set_config('request.jwt.claim.sub', '9a9a9a9a-0000-4000-8000-000000000001', false);
select assert(is_app_admin(), 'the owner is an admin');
select set_parallel_rate('DZ', 'eur', 274.5, 276.5);
select set_parallel_rate('dz', 'USD', 242, 245);
select set_parallel_rate('dz', 'GBP', null, 316);
select assert((select count(*) from parallel_rates_for('dz')) = 3,
       'three rates are stored');
select assert((select buy = 274.5 and sell = 276.5 from parallel_rates_for('dz')
               where currency = 'EUR'),
       'country and currency are normalized; the values are kept');
select assert((select buy is null and sell = 316 from parallel_rates_for('dz')
               where currency = 'GBP'),
       'one side alone is allowed');
select set_parallel_rate('dz', 'EUR', 275, 277);
select assert((select buy = 275 from parallel_rates_for('dz') where currency = 'EUR')
              and (select count(*) from parallel_rates_for('dz')) = 3,
       'setting again replaces the rate, never a second row');
select set_parallel_rate('dz', 'GBP', null, null);
select assert((select count(*) from parallel_rates_for('dz')) = 2,
       'both sides empty removes the rate');
select assert(refuses($$select set_parallel_rate('dz', 'EUR', -1, 5)$$),
       'a negative rate is refused');
select assert(refuses($$select set_parallel_rate('dz', 'EUR', 0, null)$$),
       'a zero rate is refused');
select assert(refuses($$select set_parallel_rate('algeria', 'EUR', 1, 2)$$),
       'a malformed country is refused');
select assert(refuses($$select set_parallel_rate('dz', 'E', 1, 2)$$),
       'a malformed currency is refused');

-- ------------------------------------------------------- an ordinary member
select set_config('request.jwt.claim.sub', '9a9a9a9a-0000-4000-8000-000000000002', false);
select assert(not is_app_admin(), 'a member is not an admin');
select assert(refuses($$select set_parallel_rate('dz', 'EUR', 1, 2)$$),
       'a member cannot set a rate');
select assert((select buy = 275 from parallel_rates_for('dz') where currency = 'EUR'),
       'a member reads the rates, unchanged');
select assert(refuses($$select * from parallel_rates$$),
       'a member cannot read the table itself');
select assert(refuses($$insert into parallel_rates (country, currency, buy) values ('dz', 'CAD', 1)$$),
       'a member cannot write the table itself');
select assert(refuses($$select * from app_admins$$),
       'a member cannot see who the admins are');
select assert(refuses($$insert into app_admins (user_id) values ('9a9a9a9a-0000-4000-8000-000000000002')$$),
       'a member cannot make themselves an admin');
reset role;

-- ---------------------------------------------------------- a signed-out visitor
set role anon;
select set_config('request.jwt.claim.sub', '', false);
select assert((select count(*) from parallel_rates_for('dz')) = 2,
       'a visitor reads the rates');
select assert(refuses($$select set_parallel_rate('dz', 'EUR', 1, 2)$$),
       'a visitor cannot set a rate');
select assert(refuses($$select is_app_admin()$$),
       'a visitor cannot even ask whether they are an admin');
select assert(refuses($$select * from parallel_rates$$),
       'a visitor cannot read the table itself');
reset role;

select assert((select count(*) from parallel_rates_for('xx')) = 0,
       'an unknown country has no rates');

delete from parallel_rates; delete from app_admins;
delete from auth.users where email like '%@par.test';
drop function refuses(text);

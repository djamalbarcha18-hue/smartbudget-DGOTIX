-- The anonymous error counts: clients can count but never read, junk is
-- ignored and a day is capped. Run after setup_all.sql.
\set ON_ERROR_STOP on
begin;
delete from error_reports_daily;

-- A good report counts; the same one again adds to it.
select report_error('FormatException@features/x/y.dart:42', '1.0.0', 'web');
select report_error('FormatException@features/x/y.dart:42', '1.0.0', 'web');
do $$ begin
  if (select count from error_reports_daily) <> 2 then
    raise exception 'two reports of one signature should count 2';
  end if;
end $$;

-- Junk is ignored: bad characters (a message could carry text), too long, bad
-- version, unknown platform, empty.
select report_error('Bad message: user typed secret!', '1.0.0', 'web');
select report_error(repeat('a', 121), '1.0.0', 'web');
select report_error('Ok@a.dart:1', 'v1; drop table', 'web');
select report_error('Ok@a.dart:1', '1.0.0', 'toaster');
select report_error('', '1.0.0', 'web');
select report_error(null, '1.0.0', 'web');
do $$ begin
  if (select count(*) from error_reports_daily) <> 1 then
    raise exception 'junk must not add rows';
  end if;
end $$;

-- A day takes at most 500 distinct signatures; known ones still count.
delete from error_reports_daily;
insert into error_reports_daily (day, signature, version, platform, count)
select (now() at time zone 'utc')::date, 'E' || g, '1.0.0', 'web', 1
from generate_series(1, 500) g;
select report_error('Brand new@a.dart:1', '1.0.0', 'web');
select report_error('E1', '1.0.0', 'web');
do $$ begin
  if (select count(*) from error_reports_daily) <> 500 then
    raise exception 'the 501st signature must be refused';
  end if;
  if (select count from error_reports_daily where signature = 'E1') <> 2 then
    raise exception 'a known signature must still count when the day is full';
  end if;
end $$;

-- Clients can call it but cannot read or write the table or the view.
do $$ begin
  if not has_function_privilege('anon', 'public.report_error(text,text,text)', 'execute') then
    raise exception 'anon must be able to report';
  end if;
  if has_table_privilege('anon', 'public.error_reports_daily', 'select')
     or has_table_privilege('authenticated', 'public.error_reports_daily', 'select')
     or has_table_privilege('anon', 'public.error_reports_recent', 'select') then
    raise exception 'clients must not read the error counts';
  end if;
  if has_table_privilege('anon', 'public.error_reports_daily', 'insert') then
    raise exception 'clients must not write the table directly';
  end if;
end $$;
rollback;
\echo error_reports_test: ok

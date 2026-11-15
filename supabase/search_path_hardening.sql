-- ============================================================================
-- SmartBudget — pin the search_path of every SECURITY DEFINER function (run
-- last; safe to re-run)
-- ----------------------------------------------------------------------------
-- These functions run with the owner's rights. With `search_path = public`
-- alone, Postgres still looks in the caller's temporary schema FIRST, so a
-- caller able to create a temp table named like a real one (reward_grants,
-- referrals...) could make the function read it instead. Listing pg_temp
-- explicitly, last, closes that. Applied to every such function in public,
-- including ones created before this file existed.
-- ============================================================================
do $$
declare f record;
begin
  for f in
    select p.oid::regprocedure as sig
      from pg_proc p
      join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public' and p.prosecdef
  loop
    execute format('alter function %s set search_path = public, pg_temp', f.sig);
  end loop;
end $$;

-- SmartBudget — reports on AI assistant answers ("Report this answer").
--
-- Google Play requires apps with generative AI to let users flag offensive
-- or wrong output. Users can only insert their own reports; the owner reviews
-- them in the Supabase dashboard (service role). Run once in the SQL editor.

create table if not exists public.ai_reports (
  id          bigint generated always as identity primary key,
  user_id     uuid not null default auth.uid()
              references auth.users(id) on delete cascade,
  reason      text not null check (reason in ('inaccurate', 'harmful', 'other')),
  answer      text not null check (char_length(answer) <= 8000),
  note        text check (char_length(note) <= 1000),
  created_at  timestamptz not null default now()
);

alter table public.ai_reports enable row level security;

drop policy if exists "ai_reports_insert_own" on public.ai_reports;
create policy "ai_reports_insert_own" on public.ai_reports
  for insert to authenticated
  with check (user_id = auth.uid());

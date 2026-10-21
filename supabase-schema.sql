-- Run this once in your NEW Supabase project: Dashboard → SQL Editor → New query → paste → Run.
-- One row per user per day. Row-level security means every signed-in user can only ever see and change their own rows.

create table if not exists public.journal_entries (
  user_id    uuid        not null default auth.uid() references auth.users (id) on delete cascade,
  entry_date date        not null,
  text       text        not null,
  emo        text        check (emo in ('joy','calm','love','energy','sad','anxious','angry','tired')),
  updated_at timestamptz not null default now(),
  primary key (user_id, entry_date)
);

alter table public.journal_entries enable row level security;

create policy "own entries: select" on public.journal_entries
  for select to authenticated using (user_id = (select auth.uid()));

create policy "own entries: insert" on public.journal_entries
  for insert to authenticated with check (user_id = (select auth.uid()));

create policy "own entries: update" on public.journal_entries
  for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy "own entries: delete" on public.journal_entries
  for delete to authenticated using (user_id = (select auth.uid()));

-- keep updated_at fresh
create or replace function public.touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end $$;

create trigger journal_entries_touch before update on public.journal_entries
  for each row execute function public.touch_updated_at();

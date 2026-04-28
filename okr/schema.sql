-- OKR Task Management System schema
-- Run this in Supabase SQL Editor (or psql) on a fresh project.

-- ─────────────────────────────────────────────────────────────
-- Tables
-- ─────────────────────────────────────────────────────────────

create table if not exists teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  parent_team_id uuid references teams(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  team_id uuid references teams(id) on delete set null,
  avatar_color text not null default '#4361ee',
  created_at timestamptz not null default now()
);

create table if not exists objectives (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  owner_id uuid not null references profiles(id) on delete cascade,
  team_id uuid references teams(id) on delete set null,
  quarter int not null check (quarter between 1 and 4),
  year int not null check (year between 2000 and 2100),
  status text not null default 'active'
    check (status in ('active', 'achieved', 'missed', 'archived')),
  created_at timestamptz not null default now()
);

create table if not exists key_results (
  id uuid primary key default gen_random_uuid(),
  objective_id uuid not null references objectives(id) on delete cascade,
  title text not null,
  metric_type text not null
    check (metric_type in ('number', 'percent', 'currency', 'boolean')),
  start_value numeric not null default 0,
  target_value numeric not null,
  current_value numeric not null default 0,
  unit text,
  owner_id uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists tasks (
  id uuid primary key default gen_random_uuid(),
  key_result_id uuid not null references key_results(id) on delete cascade,
  title text not null,
  status text not null default 'todo'
    check (status in ('todo', 'in_progress', 'done')),
  assignee_id uuid references profiles(id) on delete set null,
  due_date date,
  created_at timestamptz not null default now()
);

create table if not exists check_ins (
  id uuid primary key default gen_random_uuid(),
  key_result_id uuid not null references key_results(id) on delete cascade,
  author_id uuid not null references profiles(id) on delete cascade,
  week_start date not null,
  status text not null
    check (status in ('on_track', 'at_risk', 'off_track')),
  comment text,
  value_at_checkin numeric,
  created_at timestamptz not null default now(),
  unique (key_result_id, author_id, week_start)
);

create index if not exists idx_objectives_team    on objectives(team_id);
create index if not exists idx_objectives_period  on objectives(year, quarter);
create index if not exists idx_kr_objective       on key_results(objective_id);
create index if not exists idx_tasks_kr           on tasks(key_result_id);
create index if not exists idx_checkins_kr        on check_ins(key_result_id);
create index if not exists idx_checkins_week      on check_ins(week_start);

-- ─────────────────────────────────────────────────────────────
-- Auto-create profile when a new auth user signs up
-- ─────────────────────────────────────────────────────────────

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  display_name text;
  palette text[] := array['#4361ee','#06d6a0','#f72585','#7209b7','#f4a261','#3a86ff','#1b9aaa','#e63946'];
begin
  display_name := coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1));
  insert into public.profiles (id, name, avatar_color)
  values (new.id, display_name, palette[1 + floor(random() * array_length(palette, 1))::int]);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ─────────────────────────────────────────────────────────────
-- Row Level Security
-- ─────────────────────────────────────────────────────────────

alter table teams        enable row level security;
alter table profiles     enable row level security;
alter table objectives   enable row level security;
alter table key_results  enable row level security;
alter table tasks        enable row level security;
alter table check_ins    enable row level security;

-- Everyone authenticated can read everything in the org.
create policy teams_read       on teams       for select to authenticated using (true);
create policy profiles_read    on profiles    for select to authenticated using (true);
create policy objectives_read  on objectives  for select to authenticated using (true);
create policy key_results_read on key_results for select to authenticated using (true);
create policy tasks_read       on tasks       for select to authenticated using (true);
create policy check_ins_read   on check_ins   for select to authenticated using (true);

-- Teams: any authenticated user can create teams; only updater of their own team for now.
create policy teams_insert on teams for insert to authenticated with check (true);
create policy teams_update on teams for update to authenticated using (true) with check (true);

-- Profiles: a user can update only their own profile.
create policy profiles_update on profiles
  for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Objectives: owner controls writes.
create policy objectives_insert on objectives
  for insert to authenticated with check (owner_id = auth.uid());
create policy objectives_update on objectives
  for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());
create policy objectives_delete on objectives
  for delete to authenticated using (owner_id = auth.uid());

-- Key Results: owner controls writes.
create policy key_results_insert on key_results
  for insert to authenticated with check (owner_id = auth.uid());
create policy key_results_update on key_results
  for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());
create policy key_results_delete on key_results
  for delete to authenticated using (owner_id = auth.uid());

-- Tasks: assignee or KR owner can write. For simplicity here: assignee or anyone authenticated to insert.
create policy tasks_insert on tasks
  for insert to authenticated with check (true);
create policy tasks_update on tasks
  for update to authenticated
  using (assignee_id = auth.uid() or assignee_id is null
         or exists (select 1 from key_results kr
                    where kr.id = tasks.key_result_id and kr.owner_id = auth.uid()))
  with check (true);
create policy tasks_delete on tasks
  for delete to authenticated
  using (assignee_id = auth.uid()
         or exists (select 1 from key_results kr
                    where kr.id = tasks.key_result_id and kr.owner_id = auth.uid()));

-- Check-ins: author controls writes.
create policy check_ins_insert on check_ins
  for insert to authenticated with check (author_id = auth.uid());
create policy check_ins_update on check_ins
  for update to authenticated
  using (author_id = auth.uid())
  with check (author_id = auth.uid());
create policy check_ins_delete on check_ins
  for delete to authenticated using (author_id = auth.uid());

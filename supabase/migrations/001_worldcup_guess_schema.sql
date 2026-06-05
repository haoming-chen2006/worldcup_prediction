create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Player',
  total_points integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.matches (
  id text primary key,
  match_number integer,
  round text not null check (round in ('group', 'r32', 'r16', 'qf', 'sf', 'third', 'final')),
  matchday text,
  group_label text,
  bracket_pos text not null,
  team_home text,
  team_away text,
  team_home_code text,
  team_away_code text,
  sides_confirmed boolean not null default false,
  kickoff_time timestamptz not null,
  local_time text,
  venue text,
  city text,
  host_country text,
  stadium_capacity integer,
  actual_home_score integer,
  actual_away_score integer,
  actual_winner text,
  created_at timestamptz not null default now()
);

create table if not exists public.players (
  id text primary key,
  team text not null,
  flag text,
  number integer,
  position text,
  name text not null,
  birth_date date,
  age integer,
  caps integer not null default 0,
  international_goals integer not null default 0,
  club text,
  tournament_goals integer not null default 0,
  tournament_assists integer not null default 0,
  yellow_cards integer not null default 0,
  red_cards integer not null default 0,
  minutes_played integer not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.guesses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  match_id text not null references public.matches(id) on delete cascade,
  pred_home_score integer not null check (pred_home_score >= 0),
  pred_away_score integer not null check (pred_away_score >= 0),
  pred_winner text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, match_id)
);

create table if not exists public.player_artifacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  champion_team text,
  top4_teams text[] not null default '{}',
  top_scorer text,
  top_assister text,
  best_player text,
  best_young_player text,
  locked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prediction_states (
  user_id uuid primary key references auth.users(id) on delete cascade,
  group_rankings jsonb not null default '{}'::jsonb,
  bracket_picks jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (user_id, display_name)
  values (new.id, coalesce(split_part(new.email, '@', 1), 'Player'))
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.reject_late_guess()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  match_kickoff timestamptz;
  match_confirmed boolean;
begin
  select kickoff_time, sides_confirmed
    into match_kickoff, match_confirmed
    from public.matches
    where id = new.match_id;

  if match_kickoff <= now() then
    raise exception 'This match has already locked.';
  end if;

  if match_confirmed is not true then
    raise exception 'This match is not available for guesses yet.';
  end if;

  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists guesses_reject_late_guess on public.guesses;
create trigger guesses_reject_late_guess
before insert or update on public.guesses
for each row execute function public.reject_late_guess();

alter table public.profiles enable row level security;
alter table public.matches enable row level security;
alter table public.players enable row level security;
alter table public.guesses enable row level security;
alter table public.player_artifacts enable row level security;
alter table public.prediction_states enable row level security;

drop policy if exists "Profiles are visible to authenticated users" on public.profiles;
create policy "Profiles are visible to authenticated users"
on public.profiles for select
to authenticated
using (true);

drop policy if exists "Users manage their own profile" on public.profiles;
create policy "Users manage their own profile"
on public.profiles for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Matches are readable" on public.matches;
create policy "Matches are readable"
on public.matches for select
to anon, authenticated
using (true);

drop policy if exists "Players are readable" on public.players;
create policy "Players are readable"
on public.players for select
to anon, authenticated
using (true);

drop policy if exists "Users read their own guesses" on public.guesses;
create policy "Users read their own guesses"
on public.guesses for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users write their own guesses" on public.guesses;
create policy "Users write their own guesses"
on public.guesses for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users update their own guesses" on public.guesses;
create policy "Users update their own guesses"
on public.guesses for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users read their own player artifacts" on public.player_artifacts;
create policy "Users read their own player artifacts"
on public.player_artifacts for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users write their own player artifacts" on public.player_artifacts;
create policy "Users write their own player artifacts"
on public.player_artifacts for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users read their own prediction state" on public.prediction_states;
create policy "Users read their own prediction state"
on public.prediction_states for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users write their own prediction state" on public.prediction_states;
create policy "Users write their own prediction state"
on public.prediction_states for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

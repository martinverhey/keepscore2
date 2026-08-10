-- KeepScore 2 — core schema.
--
-- Shape of the domain: a competition contains players (a "dummy" player is one
-- with user_id IS NULL), is divided into calendar-aligned seasons, and holds
-- matches between exactly two teams. Ratings are stored per (season, player),
-- which is what makes the hard season reset free — a new season simply has no
-- rows yet, so everyone reads back as the competition's starting rating.

create extension if not exists pgcrypto with schema extensions;

-- This project carries a broken handle_new_user() from an earlier attempt: it
-- inserts into a public.profiles that no longer exists, so every signup fails.
-- Clear it before installing our own.
drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();

create type public.season_length as enum ('monthly', 'quarterly', 'yearly');
create type public.match_team as enum ('a', 'b');

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------

create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text not null
               check (char_length(btrim(display_name)) between 1 and 60),
  avatar_url   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

comment on table public.profiles is
  'One row per auth user, created automatically on sign-up.';

-- Anonymous users get a profile too, so a guest can join a competition and
-- keep the same row after upgrading to a real account.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
      nullif(btrim(new.raw_user_meta_data ->> 'name'), ''),
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Player'
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- The trigger only fires on INSERT, so accounts that predate this migration
-- would otherwise have no profile and no way to own or join anything.
insert into public.profiles (id, display_name)
select u.id,
       coalesce(
         nullif(btrim(u.raw_user_meta_data ->> 'full_name'), ''),
         nullif(btrim(u.raw_user_meta_data ->> 'name'), ''),
         nullif(btrim(u.raw_user_meta_data ->> 'display_name'), ''),
         nullif(split_part(coalesce(u.email, ''), '@', 1), ''),
         'Player'
       )
  from auth.users u
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- competitions
-- ---------------------------------------------------------------------------

create table public.competitions (
  id              uuid primary key default gen_random_uuid(),
  join_code       text not null unique check (join_code ~ '^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{6}$'),
  name            text not null check (char_length(btrim(name)) between 1 and 60),
  owner_id        uuid not null references public.profiles (id) on delete restrict,
  season_length   public.season_length not null default 'monthly',
  timezone        text not null default 'Europe/Amsterdam',
  -- Rating parameters live on the competition so a group can tune or disable
  -- margin-of-victory without a code change or migration.
  starting_rating integer not null default 1000 check (starting_rating between 100 and 5000),
  k_factor        integer not null default 32 check (k_factor between 1 and 200),
  mov_enabled     boolean not null default true,
  mov_cap         numeric(4, 2) not null default 2.50 check (mov_cap between 1.00 and 5.00),
  allow_draws     boolean not null default true,
  created_at      timestamptz not null default now()
);

comment on column public.competitions.join_code is
  'Six characters from a Crockford-style alphabet — no 0/O/1/I — so a code read aloud is unambiguous.';

-- ---------------------------------------------------------------------------
-- players (also the membership table; the owner is a player too)
-- ---------------------------------------------------------------------------

create table public.players (
  competition_id uuid not null references public.competitions (id) on delete cascade,
  id             uuid primary key default gen_random_uuid(),
  display_name   text not null check (char_length(btrim(display_name)) between 1 and 60),
  -- NULL means an unclaimed dummy player the owner created as a placeholder.
  user_id        uuid references public.profiles (id) on delete set null,
  is_active      boolean not null default true,
  created_at     timestamptz not null default now()
);

create unique index players_competition_user_key
  on public.players (competition_id, user_id)
  where user_id is not null;

create index players_competition_idx on public.players (competition_id);
create index players_user_idx on public.players (user_id) where user_id is not null;

-- ---------------------------------------------------------------------------
-- seasons
-- ---------------------------------------------------------------------------

create table public.seasons (
  id             uuid primary key default gen_random_uuid(),
  competition_id uuid not null references public.competitions (id) on delete cascade,
  starts_at      timestamptz not null,
  ends_at        timestamptz not null,
  created_at     timestamptz not null default now(),
  unique (competition_id, starts_at),
  check (ends_at > starts_at)
);

create index seasons_competition_range_idx
  on public.seasons (competition_id, starts_at desc);

-- ---------------------------------------------------------------------------
-- matches
-- ---------------------------------------------------------------------------

create table public.matches (
  id             uuid primary key default gen_random_uuid(),
  competition_id uuid not null references public.competitions (id) on delete cascade,
  season_id      uuid not null references public.seasons (id) on delete cascade,
  played_at      timestamptz not null default now(),
  team_a_score   integer not null check (team_a_score >= 0),
  team_b_score   integer not null check (team_b_score >= 0),
  -- Snapshot of each side's mean rating at the time, so a match row can be
  -- rendered without recomputing history.
  team_a_rating  numeric(8, 2) not null,
  team_b_rating  numeric(8, 2) not null,
  created_by     uuid references public.profiles (id) on delete set null,
  created_at     timestamptz not null default now()
);

-- The replay in recalc_season() orders by (played_at, id); this index serves
-- both that and the match feed.
create index matches_competition_played_idx
  on public.matches (competition_id, played_at desc, id desc);
create index matches_season_played_idx
  on public.matches (season_id, played_at, id);

create table public.match_players (
  match_id      uuid not null references public.matches (id) on delete cascade,
  player_id     uuid not null references public.players (id) on delete cascade,
  team          public.match_team not null,
  rating_before numeric(8, 2) not null,
  rating_after  numeric(8, 2) not null,
  rating_delta  numeric(8, 2) not null,
  primary key (match_id, player_id)
);

create index match_players_player_idx on public.match_players (player_id);

-- ---------------------------------------------------------------------------
-- player_ratings — the leaderboard's backing table, one row per season+player
-- ---------------------------------------------------------------------------

create table public.player_ratings (
  season_id  uuid not null references public.seasons (id) on delete cascade,
  player_id  uuid not null references public.players (id) on delete cascade,
  rating     numeric(8, 2) not null,
  played     integer not null default 0,
  wins       integer not null default 0,
  losses     integer not null default 0,
  draws      integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (season_id, player_id)
);

create index player_ratings_leaderboard_idx
  on public.player_ratings (season_id, rating desc);

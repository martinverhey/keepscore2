-- KeepScore 2 — Row Level Security.
--
-- Reads are scoped to competitions you belong to. Writes are almost entirely
-- absent by design: there is no INSERT policy on matches, match_players,
-- player_ratings, players or seasons, so the only way to write them is through
-- the SECURITY DEFINER functions in 0002, which run as the owner and bypass
-- RLS after doing their own checks.
--
-- The narrow exception is direct UPDATE on profiles/competitions/players,
-- restricted by column-level GRANTs so an owner can rename things but cannot,
-- for example, reassign a player's user_id.

alter table public.profiles       enable row level security;
alter table public.competitions   enable row level security;
alter table public.players        enable row level security;
alter table public.seasons        enable row level security;
alter table public.matches        enable row level security;
alter table public.match_players  enable row level security;
alter table public.player_ratings enable row level security;

-- Start from nothing rather than trusting the default grants.
revoke all on all tables in schema public from anon, authenticated;

-- Nothing is readable without a session — not even a competition name.
grant select on public.competitions   to authenticated;
grant select on public.profiles       to authenticated;
grant select on public.players        to authenticated;
grant select on public.seasons        to authenticated;
grant select on public.matches        to authenticated;
grant select on public.match_players  to authenticated;
grant select on public.player_ratings to authenticated;

grant update (display_name, avatar_url) on public.profiles to authenticated;
grant update (name, season_length, timezone, starting_rating, k_factor,
              mov_enabled, mov_cap, allow_draws) on public.competitions to authenticated;
grant update (display_name, is_active) on public.players to authenticated;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------

-- SECURITY DEFINER to avoid recursing through the players policy.
create function public.shares_competition(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.players mine
      join public.players theirs
        on theirs.competition_id = mine.competition_id
     where mine.user_id = auth.uid()
       and theirs.user_id = p_profile_id
  );
$$;

create policy profiles_select_self_or_shared
  on public.profiles for select to authenticated
  using (id = auth.uid() or public.shares_competition(id));

create policy profiles_update_self
  on public.profiles for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- ---------------------------------------------------------------------------
-- competitions
-- ---------------------------------------------------------------------------

create policy competitions_select_member
  on public.competitions for select to authenticated
  using (public.is_member(id));

-- Settings are the owner's to change, and only for a real account.
create policy competitions_update_owner
  on public.competitions for update to authenticated
  using (owner_id = auth.uid() and public.is_registered())
  with check (owner_id = auth.uid());

create policy competitions_delete_owner
  on public.competitions for delete to authenticated
  using (owner_id = auth.uid() and public.is_registered());

grant delete on public.competitions to authenticated;

-- ---------------------------------------------------------------------------
-- players
-- ---------------------------------------------------------------------------

create policy players_select_member
  on public.players for select to authenticated
  using (public.is_member(competition_id));

-- Renaming or deactivating a player: the owner for anyone, or a member for
-- their own row. The column grant above is what stops user_id being touched.
create policy players_update_owner_or_self
  on public.players for update to authenticated
  using (
    public.is_registered()
    and (public.is_owner(competition_id) or user_id = auth.uid())
  )
  with check (
    public.is_owner(competition_id) or user_id = auth.uid()
  );

-- ---------------------------------------------------------------------------
-- seasons / matches / ratings — read-only to clients
-- ---------------------------------------------------------------------------

create policy seasons_select_member
  on public.seasons for select to authenticated
  using (public.is_member(competition_id));

create policy matches_select_member
  on public.matches for select to authenticated
  using (public.is_member(competition_id));

create policy match_players_select_member
  on public.match_players for select to authenticated
  using (
    exists (
      select 1 from public.matches m
       where m.id = match_id and public.is_member(m.competition_id)
    )
  );

create policy player_ratings_select_member
  on public.player_ratings for select to authenticated
  using (
    exists (
      select 1 from public.seasons s
       where s.id = season_id and public.is_member(s.competition_id)
    )
  );

-- ---------------------------------------------------------------------------
-- Function privileges
-- ---------------------------------------------------------------------------

-- Internal machinery: reachable only from the RPCs above, never from a client.
revoke all on function
  public.apply_match_ratings(uuid),
  public.recalc_season(uuid),
  public.ensure_season(uuid, timestamptz),
  public.generate_join_code(),
  public.handle_new_user()
from public, anon, authenticated;

-- The client-facing API.
revoke all on function
  public.create_competition(text, public.season_length, text, text),
  public.add_dummy_player(uuid, text),
  public.preview_competition(text),
  public.join_competition(text, text, uuid),
  public.create_match(uuid, uuid[], uuid[], integer, integer, timestamptz),
  public.update_match_score(uuid, integer, integer, timestamptz),
  public.delete_match(uuid)
from public, anon, authenticated;

grant execute on function
  public.create_competition(text, public.season_length, text, text),
  public.add_dummy_player(uuid, text),
  public.preview_competition(text),
  public.join_competition(text, text, uuid),
  public.create_match(uuid, uuid[], uuid[], integer, integer, timestamptz),
  public.update_match_score(uuid, integer, integer, timestamptz),
  public.delete_match(uuid)
to authenticated;

-- Pure helpers the client may read through views.
grant execute on function
  public.elo_delta(numeric, numeric, integer, integer, integer, boolean, numeric),
  public.is_member(uuid),
  public.is_owner(uuid),
  public.is_registered(),
  public.shares_competition(uuid),
  public.season_bounds(timestamptz, public.season_length, text)
to authenticated;

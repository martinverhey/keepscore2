-- KeepScore 2 — leaderboard filter by game type.
--
-- game_type (1v1/2v2/3v3/4v4/mixed) already lives on every match, snapshotted
-- by apply_match_ratings. Elo is order-dependent, so "1v1 ranking" cannot be
-- a post-hoc filter of the existing rating — it needs its own replayed
-- sequence built only from 1v1 matches. player_ratings / leaderboard keep
-- meaning exactly what they mean today (every match, any type — that IS
-- "combined"), and this migration adds a parallel, per-(season, game_type)
-- track fed by the same matches alongside it.

-- ---------------------------------------------------------------------------
-- player_game_type_ratings
-- ---------------------------------------------------------------------------

create table public.player_game_type_ratings (
  season_id  uuid not null references public.seasons (id) on delete cascade,
  game_type  public.game_type not null,
  player_id  uuid not null references public.players (id) on delete cascade,
  rating     numeric(8, 2) not null,
  played     integer not null default 0,
  wins       integer not null default 0,
  losses     integer not null default 0,
  draws      integer not null default 0,
  updated_at timestamptz not null default now(),
  primary key (season_id, game_type, player_id)
);

create index player_game_type_ratings_leaderboard_idx
  on public.player_game_type_ratings (season_id, game_type, rating desc);

alter table public.player_game_type_ratings enable row level security;

revoke all on public.player_game_type_ratings from anon, authenticated;
grant select on public.player_game_type_ratings to authenticated;

create policy player_game_type_ratings_select_member
  on public.player_game_type_ratings for select to authenticated
  using (
    exists (
      select 1 from public.seasons s
       where s.id = season_id and public.is_member(s.competition_id)
    )
  );

alter publication supabase_realtime add table public.player_game_type_ratings;

-- ---------------------------------------------------------------------------
-- Rating application — the per-game-type sibling of apply_match_ratings /
-- recalc_season. Deliberately leaves match_players and matches.team_a_rating
-- / team_b_rating untouched: those stay the combined-track snapshot the
-- match detail page already renders.
-- ---------------------------------------------------------------------------

create function public.apply_match_type_rating(p_match_id uuid)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_match     public.matches;
  v_comp      public.competitions;
  v_rating_a  numeric;
  v_rating_b  numeric;
  v_count_a   integer;
  v_count_b   integer;
  v_delta_a   numeric;
  v_outcome_a integer;
begin
  select * into strict v_match from public.matches where id = p_match_id;
  select * into strict v_comp
    from public.competitions where id = v_match.competition_id;

  select
    avg(coalesce(pgtr.rating, v_comp.starting_rating)), count(*)
    into v_rating_a, v_count_a
    from public.match_players mp
    left join public.player_game_type_ratings pgtr
      on pgtr.player_id = mp.player_id
     and pgtr.season_id = v_match.season_id
     and pgtr.game_type = v_match.game_type
   where mp.match_id = p_match_id and mp.team = 'a';

  select
    avg(coalesce(pgtr.rating, v_comp.starting_rating)), count(*)
    into v_rating_b, v_count_b
    from public.match_players mp
    left join public.player_game_type_ratings pgtr
      on pgtr.player_id = mp.player_id
     and pgtr.season_id = v_match.season_id
     and pgtr.game_type = v_match.game_type
   where mp.match_id = p_match_id and mp.team = 'b';

  if coalesce(v_count_a, 0) = 0 or coalesce(v_count_b, 0) = 0 then
    raise exception 'Both teams need at least one player' using errcode = 'P0001';
  end if;

  v_delta_a := public.elo_delta(
    v_rating_a, v_rating_b,
    v_match.team_a_score, v_match.team_b_score,
    v_comp.k_factor, v_comp.mov_enabled, v_comp.mov_cap
  );

  v_outcome_a := case
    when v_match.team_a_score > v_match.team_b_score then 1
    when v_match.team_a_score < v_match.team_b_score then -1
    else 0
  end;

  insert into public.player_game_type_ratings as pgtr
    (season_id, game_type, player_id, rating, played, wins, losses, draws)
  select
    v_match.season_id,
    v_match.game_type,
    mp.player_id,
    coalesce(existing.rating, v_comp.starting_rating)
      + case when mp.team = 'a' then v_delta_a else -v_delta_a end,
    1,
    case when o.res = 1 then 1 else 0 end,
    case when o.res = -1 then 1 else 0 end,
    case when o.res = 0 then 1 else 0 end
    from public.match_players mp
    left join public.player_game_type_ratings existing
      on existing.player_id = mp.player_id
     and existing.season_id = v_match.season_id
     and existing.game_type = v_match.game_type
    cross join lateral (
      select case when mp.team = 'a' then v_outcome_a else -v_outcome_a end as res
    ) o
   where mp.match_id = p_match_id
  on conflict (season_id, game_type, player_id) do update
     set rating     = excluded.rating,
         played     = pgtr.played + 1,
         wins       = pgtr.wins + excluded.wins,
         losses     = pgtr.losses + excluded.losses,
         draws      = pgtr.draws + excluded.draws,
         updated_at = now();
end;
$$;

create function public.recalc_season_game_type(
  p_season_id uuid,
  p_game_type public.game_type
)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_match_id uuid;
begin
  delete from public.player_game_type_ratings
   where season_id = p_season_id and game_type = p_game_type;

  for v_match_id in
    select id from public.matches
     where season_id = p_season_id and game_type = p_game_type
     order by played_at, id
  loop
    perform public.apply_match_type_rating(v_match_id);
  end loop;
end;
$$;

revoke all on function
  public.apply_match_type_rating(uuid),
  public.recalc_season_game_type(uuid, public.game_type)
from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Backfill: every match already on record predates this track, so each
-- (season, game_type) pair that already has matches needs an initial replay
-- the same way apply_match_ratings/recalc_season already keep player_ratings
-- current for them.
-- ---------------------------------------------------------------------------

do $$
declare
  v_pair record;
begin
  for v_pair in select distinct season_id, game_type from public.matches loop
    perform public.recalc_season_game_type(v_pair.season_id, v_pair.game_type);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- create_match / update_match_score / delete_match now also drive the
-- type-scoped track. create or replace resets EXECUTE to PUBLIC, so grants
-- are re-issued at the end of this section.
-- ---------------------------------------------------------------------------

create or replace function public.create_match(
  p_competition_id uuid,
  p_team_a         uuid[],
  p_team_b         uuid[],
  p_score_a        integer,
  p_score_b        integer,
  p_played_at      timestamptz default now()
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_comp       public.competitions;
  v_season_id  uuid;
  v_match_id   uuid;
  v_game_type  public.game_type;
  v_all        uuid[];
begin
  if not public.is_registered() then
    raise exception 'Create an account to create matches' using errcode = 'P0001';
  end if;
  if not public.is_member(p_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  select * into strict v_comp
    from public.competitions where id = p_competition_id;

  if coalesce(array_length(p_team_a, 1), 0) = 0
     or coalesce(array_length(p_team_b, 1), 0) = 0 then
    raise exception 'Both teams need at least one player' using errcode = 'P0001';
  end if;

  if p_score_a < 0 or p_score_b < 0 then
    raise exception 'Scores cannot be negative' using errcode = 'P0001';
  end if;

  if p_score_a = p_score_b and not v_comp.allow_draws then
    raise exception 'This competition does not allow draws' using errcode = 'P0001';
  end if;

  v_all := p_team_a || p_team_b;

  -- Catches both a duplicate within one team and a player listed on both.
  if (select count(distinct x) from unnest(v_all) x) <> array_length(v_all, 1) then
    raise exception 'A player can only appear once in a match'
      using errcode = 'P0001';
  end if;

  if exists (
    select 1 from unnest(v_all) x
     where not exists (
       select 1 from public.players p
        where p.id = x and p.competition_id = p_competition_id and p.is_active
     )
  ) then
    raise exception 'All players must be active members of this competition'
      using errcode = 'P0001';
  end if;

  v_season_id := public.ensure_season(p_competition_id, p_played_at);

  -- Rating and game_type columns are placeholders; apply_match_ratings fills
  -- them in below.
  insert into public.matches (
    competition_id, season_id, played_at,
    team_a_score, team_b_score, team_a_rating, team_b_rating, game_type, created_by
  )
  values (
    p_competition_id, v_season_id, p_played_at,
    p_score_a, p_score_b, 0, 0, 'mixed', auth.uid()
  )
  returning id into v_match_id;

  insert into public.match_players
    (match_id, player_id, team, rating_before, rating_after, rating_delta, outcome)
  -- The enum needs an explicit cast: in a UNION branch an untyped literal is
  -- resolved as text before it reaches the column.
  select v_match_id, x, 'a'::public.match_team, 0, 0, 0, 'draw'::public.match_outcome
    from unnest(p_team_a) x
  union all
  select v_match_id, x, 'b'::public.match_team, 0, 0, 0, 'draw'::public.match_outcome
    from unnest(p_team_b) x;

  perform public.apply_match_ratings(v_match_id);

  select game_type into v_game_type from public.matches where id = v_match_id;
  perform public.apply_match_type_rating(v_match_id);

  -- A back-dated match lands in the middle of the season's history, so the
  -- rest of it has to be replayed on top.
  if exists (
    select 1 from public.matches
     where season_id = v_season_id
       and (played_at, id) > (p_played_at, v_match_id)
  ) then
    perform public.recalc_season(v_season_id);
  end if;

  if exists (
    select 1 from public.matches
     where season_id = v_season_id
       and game_type = v_game_type
       and (played_at, id) > (p_played_at, v_match_id)
  ) then
    perform public.recalc_season_game_type(v_season_id, v_game_type);
  end if;

  return v_match_id;
end;
$$;

create or replace function public.update_match_score(
  p_match_id  uuid,
  p_score_a   integer,
  p_score_b   integer,
  p_played_at timestamptz default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_match      public.matches;
  v_comp       public.competitions;
  v_new_season uuid;
begin
  select * into v_match from public.matches where id = p_match_id;
  if not found then
    raise exception 'Match not found' using errcode = 'P0001';
  end if;

  if not public.is_registered()
     or not (v_match.created_by = auth.uid()
             or public.is_owner(v_match.competition_id)) then
    raise exception 'Only the person who logged this match, or the competition owner, can change it'
      using errcode = 'P0001';
  end if;

  select * into strict v_comp
    from public.competitions where id = v_match.competition_id;

  if p_score_a < 0 or p_score_b < 0 then
    raise exception 'Scores cannot be negative' using errcode = 'P0001';
  end if;
  if p_score_a = p_score_b and not v_comp.allow_draws then
    raise exception 'This competition does not allow draws' using errcode = 'P0001';
  end if;

  -- Moving a match in time can move it into a different season entirely.
  v_new_season := case
    when p_played_at is null then v_match.season_id
    else public.ensure_season(v_match.competition_id, p_played_at)
  end;

  update public.matches
     set team_a_score = p_score_a,
         team_b_score = p_score_b,
         played_at    = coalesce(p_played_at, played_at),
         season_id    = v_new_season
   where id = p_match_id;

  perform public.recalc_season(v_match.season_id);
  if v_new_season <> v_match.season_id then
    perform public.recalc_season(v_new_season);
  end if;

  -- A score edit never touches the roster, so game_type is unchanged.
  perform public.recalc_season_game_type(v_match.season_id, v_match.game_type);
  if v_new_season <> v_match.season_id then
    perform public.recalc_season_game_type(v_new_season, v_match.game_type);
  end if;
end;
$$;

create or replace function public.delete_match(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_match public.matches;
begin
  select * into v_match from public.matches where id = p_match_id;
  if not found then
    raise exception 'Match not found' using errcode = 'P0001';
  end if;

  if not public.is_registered()
     or not (v_match.created_by = auth.uid()
             or public.is_owner(v_match.competition_id)) then
    raise exception 'Only the person who logged this match, or the competition owner, can remove it'
      using errcode = 'P0001';
  end if;

  delete from public.matches where id = p_match_id;
  perform public.recalc_season(v_match.season_id);
  perform public.recalc_season_game_type(v_match.season_id, v_match.game_type);
end;
$$;

revoke all on function
  public.create_match(uuid, uuid[], uuid[], integer, integer, timestamptz),
  public.update_match_score(uuid, integer, integer, timestamptz),
  public.delete_match(uuid)
from public, anon, authenticated;

grant execute on function
  public.create_match(uuid, uuid[], uuid[], integer, integer, timestamptz),
  public.update_match_score(uuid, integer, integer, timestamptz),
  public.delete_match(uuid)
to authenticated;

-- ---------------------------------------------------------------------------
-- game_type_leaderboard — the per-type sibling of the leaderboard view.
--
-- Unlike leaderboard, this is not driven from the full roster: a player who
-- hasn't played this game type this season simply doesn't appear, rather
-- than showing everyone tied at starting_rating for a type nobody's played.
-- ---------------------------------------------------------------------------

create view public.game_type_leaderboard
with (security_invoker = true) as
select
  s.id                     as season_id,
  s.competition_id,
  pgtr.game_type,
  pgtr.player_id,
  p.display_name,
  (p.user_id is not null)  as is_claimed,
  pgtr.rating,
  pgtr.played,
  pgtr.wins,
  pgtr.losses,
  pgtr.draws,
  rank() over (
    partition by s.id, pgtr.game_type
    order by pgtr.rating desc, pgtr.wins desc, p.display_name asc
  )                        as rank
from public.player_game_type_ratings pgtr
join public.seasons s on s.id = pgtr.season_id
join public.players p on p.id = pgtr.player_id and p.is_active;

grant select on public.game_type_leaderboard to authenticated;

-- KeepScore 2 — remove the per-game-type Elo track.
--
-- game_type stays exactly what it was before 20260812140000: a column
-- snapshotted per match (matches.game_type, compute_game_type(), the
-- game_type enum, match_feed's game_type column all untouched) so the
-- Matches list can still filter by it. Everything built on top of that column
-- since then — a second, parallel Elo track keyed by (season, game_type),
-- its own leaderboard/history/medal views, and every profile stat split by
-- type — is removed. This migration is additive (a new file, not an edit to
-- an already-applied one), matching how this project handles schema changes.

-- ---------------------------------------------------------------------------
-- Read models built on the per-type track — drop children before parents.
-- ---------------------------------------------------------------------------

drop view if exists public.game_type_player_medals;
drop view if exists public.game_type_season_history;
drop view if exists public.game_type_leaderboard;
drop view if exists public.game_type_leaderboard_base;
drop view if exists public.player_game_type_totals;

-- ---------------------------------------------------------------------------
-- The table itself, and the per-match snapshot columns that fed it.
-- ---------------------------------------------------------------------------

drop table if exists public.player_game_type_ratings;

alter table public.match_players
  drop column if exists type_rating_before,
  drop column if exists type_rating_after,
  drop column if exists type_rating_delta;

-- ---------------------------------------------------------------------------
-- Rating application / replay for the per-type track — no replacement.
-- ---------------------------------------------------------------------------

drop function if exists public.apply_match_type_rating(uuid);
drop function if exists public.recalc_season_game_type(uuid, public.game_type);
drop function if exists public.recalc_season_game_type_from(uuid, public.game_type, timestamptz, uuid);

-- ---------------------------------------------------------------------------
-- Stat functions — each had an optional trailing p_game_type param added.
-- create or replace cannot narrow a signature, so these are dropped and
-- recreated at the two-argument shape they had before that param existed.
--
-- player_streak and player_today_delta are created as new (2-arg) overloads
-- alongside their still-live 3-arg originals first, since `leaderboard` has
-- a hard view dependency on the 3-arg versions — the view is repointed at
-- the new overloads right after both exist, and only then are the 3-arg
-- originals dropped, further down.
-- ---------------------------------------------------------------------------

create or replace function public.player_streak(
  p_season_id  uuid,
  p_player_id  uuid
)
returns table (streak_type text, streak_count integer)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_competition_id uuid;
  v_count          integer := 0;
  v_type           text;
  rec              record;
begin
  select competition_id into v_competition_id
    from public.players where id = p_player_id;
  if v_competition_id is null then
    raise exception 'Player not found' using errcode = 'P0001';
  end if;

  if not public.is_member(v_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  for rec in
    select mp.outcome
      from public.match_players mp
      join public.matches m on m.id = mp.match_id
     where mp.player_id = p_player_id
       and m.season_id = p_season_id
     order by m.played_at desc, m.id desc
  loop
    if v_count = 0 then
      if rec.outcome = 'draw' then
        exit;
      end if;
      v_type := rec.outcome::text;
      v_count := 1;
    elsif rec.outcome::text = v_type then
      v_count := v_count + 1;
    else
      exit;
    end if;
  end loop;

  streak_type := coalesce(v_type, 'none');
  streak_count := v_count;
  return next;
end;
$$;

revoke all on function public.player_streak(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.player_streak(uuid, uuid)
  to authenticated;

create or replace function public.player_today_delta(
  p_season_id  uuid,
  p_player_id  uuid
)
returns numeric
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_competition_id uuid;
  v_timezone       text;
  v_day_start      timestamptz;
  v_delta          numeric;
begin
  select p.competition_id, c.timezone
    into v_competition_id, v_timezone
    from public.players p
    join public.competitions c on c.id = p.competition_id
   where p.id = p_player_id;

  if v_competition_id is null then
    raise exception 'Player not found' using errcode = 'P0001';
  end if;

  if not public.is_member(v_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  v_day_start := date_trunc('day', now() at time zone v_timezone) at time zone v_timezone;

  select coalesce(sum(mp.rating_delta), 0)
    into v_delta
    from public.match_players mp
    join public.matches m on m.id = mp.match_id
   where mp.player_id = p_player_id
     and m.season_id = p_season_id
     and m.played_at >= v_day_start;

  return v_delta;
end;
$$;

revoke all on function public.player_today_delta(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.player_today_delta(uuid, uuid)
  to authenticated;

-- ---------------------------------------------------------------------------
-- The 3-arg originals can't just be dropped: their trailing p_game_type
-- param defaults to null, so calling either name with 2 positional args is
-- ambiguous between the old (3-arg, default) and new (2-arg) overloads —
-- they cannot coexist under the same name. CASCADE drops the dependent
-- `leaderboard` view along with the 3-arg functions; it's recreated
-- immediately after, now resolving unambiguously to the 2-arg overloads.
-- ---------------------------------------------------------------------------

drop function if exists public.player_streak(uuid, uuid, public.game_type) cascade;
drop function if exists public.player_today_delta(uuid, uuid, public.game_type) cascade;

create or replace view public.leaderboard
with (security_invoker = true) as
select
  b.season_id,
  b.competition_id,
  b.player_id,
  b.display_name,
  b.is_claimed,
  b.rating,
  b.played,
  b.wins,
  b.losses,
  b.draws,
  b.rank,
  coalesce(st.streak_type, 'none')        as streak_type,
  coalesce(st.streak_count, 0)            as streak_count,
  b.is_owner,
  coalesce(public.player_today_delta(b.season_id, b.player_id), 0) as today_delta
from public.leaderboard_base b
left join lateral
  public.player_streak(b.season_id, b.player_id) st
  on true;

grant select on public.leaderboard to authenticated;

drop function if exists public.player_best_streaks(uuid, public.game_type);

create or replace function public.player_best_streaks(
  p_player_id  uuid
)
returns table (best_win_streak integer, best_loss_streak integer)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_competition_id  uuid;
  v_best_win        integer := 0;
  v_best_loss       integer := 0;
  v_current_win     integer := 0;
  v_current_loss    integer := 0;
  rec               record;
begin
  select competition_id into v_competition_id
    from public.players where id = p_player_id;
  if v_competition_id is null then
    raise exception 'Player not found' using errcode = 'P0001';
  end if;

  if not public.is_member(v_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  for rec in
    select mp.outcome
      from public.match_players mp
      join public.matches m on m.id = mp.match_id
     where mp.player_id = p_player_id
     order by m.played_at asc, m.id asc
  loop
    if rec.outcome = 'win' then
      v_current_win := v_current_win + 1;
      v_current_loss := 0;
      if v_current_win > v_best_win then
        v_best_win := v_current_win;
      end if;
    elsif rec.outcome = 'loss' then
      v_current_loss := v_current_loss + 1;
      v_current_win := 0;
      if v_current_loss > v_best_loss then
        v_best_loss := v_current_loss;
      end if;
    else
      v_current_win := 0;
      v_current_loss := 0;
    end if;
  end loop;

  best_win_streak := v_best_win;
  best_loss_streak := v_best_loss;
  return next;
end;
$$;

revoke all on function public.player_best_streaks(uuid)
  from public, anon, authenticated;
grant execute on function public.player_best_streaks(uuid)
  to authenticated;

drop function if exists public.player_recent_played(uuid, uuid, public.game_type);

create or replace function public.player_recent_played(
  p_season_id  uuid,
  p_player_id  uuid
)
returns table (today_played integer, week_played integer)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_competition_id uuid;
  v_timezone       text;
  v_day_start      timestamptz;
  v_week_start     timestamptz;
begin
  select p.competition_id, c.timezone
    into v_competition_id, v_timezone
    from public.players p
    join public.competitions c on c.id = p.competition_id
   where p.id = p_player_id;

  if v_competition_id is null then
    raise exception 'Player not found' using errcode = 'P0001';
  end if;

  if not public.is_member(v_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  v_day_start := date_trunc('day', now() at time zone v_timezone) at time zone v_timezone;
  v_week_start := date_trunc('week', now() at time zone v_timezone) at time zone v_timezone;

  select
    count(*) filter (where m.played_at >= v_day_start)::integer,
    count(*) filter (where m.played_at >= v_week_start)::integer
    into today_played, week_played
    from public.match_players mp
    join public.matches m on m.id = mp.match_id
   where mp.player_id = p_player_id
     and m.season_id = p_season_id;

  return next;
end;
$$;

revoke all on function public.player_recent_played(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.player_recent_played(uuid, uuid)
  to authenticated;

drop function if exists public.player_best_rating(uuid, public.game_type);

create or replace function public.player_best_rating(
  p_player_id  uuid
)
returns numeric
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_competition_id uuid;
  v_best           numeric;
begin
  select competition_id into v_competition_id
    from public.players where id = p_player_id;
  if v_competition_id is null then
    raise exception 'Player not found' using errcode = 'P0001';
  end if;

  if not public.is_member(v_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  select max(rating) into v_best
    from public.player_ratings
   where player_id = p_player_id;

  return coalesce(v_best, 0);
end;
$$;

revoke all on function public.player_best_rating(uuid)
  from public, anon, authenticated;
grant execute on function public.player_best_rating(uuid)
  to authenticated;

drop function if exists public.player_profile_stats(uuid, uuid, public.game_type);

create or replace function public.player_profile_stats(
  p_player_id  uuid,
  p_season_id  uuid
)
returns table (
  total_played     integer,
  best_win_streak  integer,
  best_loss_streak integer,
  best_rating      numeric,
  streak_type      text,
  streak_count     integer,
  today_played     integer,
  week_played      integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_competition_id uuid;
  v_best           record;
  v_streak         record;
  v_recent         record;
begin
  select competition_id into v_competition_id
    from public.players where id = p_player_id;
  if v_competition_id is null then
    raise exception 'Player not found' using errcode = 'P0001';
  end if;

  if not public.is_member(v_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  select pt.total_played into total_played
    from public.player_totals pt where pt.player_id = p_player_id;
  total_played := coalesce(total_played, 0);

  select * into v_best from public.player_best_streaks(p_player_id);
  best_win_streak := v_best.best_win_streak;
  best_loss_streak := v_best.best_loss_streak;

  best_rating := public.player_best_rating(p_player_id);

  select * into v_streak
    from public.player_streak(p_season_id, p_player_id);
  streak_type := v_streak.streak_type;
  streak_count := v_streak.streak_count;

  select * into v_recent
    from public.player_recent_played(p_season_id, p_player_id);
  today_played := v_recent.today_played;
  week_played := v_recent.week_played;

  return next;
end;
$$;

revoke all on function public.player_profile_stats(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.player_profile_stats(uuid, uuid)
  to authenticated;

-- ---------------------------------------------------------------------------
-- head_to_head — same 2-argument signature, but no longer grouped by
-- game_type: one aggregate row instead of one row per type.
-- ---------------------------------------------------------------------------

drop function if exists public.head_to_head(uuid, uuid);

create function public.head_to_head(p_player_id uuid, p_opponent_id uuid)
returns table (
  wins   integer,
  losses integer,
  draws  integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_competition_id uuid;
begin
  select competition_id into v_competition_id
    from public.players where id = p_player_id;
  if v_competition_id is null then
    raise exception 'Player not found' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from public.players
     where id = p_opponent_id and competition_id = v_competition_id
  ) then
    raise exception 'Players are not in the same competition' using errcode = 'P0001';
  end if;

  if not public.is_member(v_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  return query
    select
      count(*) filter (where mp.outcome = 'win')::integer,
      count(*) filter (where mp.outcome = 'loss')::integer,
      count(*) filter (where mp.outcome = 'draw')::integer
      from public.matches m
      join public.match_players mp
        on mp.match_id = m.id and mp.player_id = p_player_id
      join public.match_players opp
        on opp.match_id = m.id and opp.player_id = p_opponent_id and opp.team <> mp.team;
end;
$$;

revoke all on function public.head_to_head(uuid, uuid) from public, anon, authenticated;
grant execute on function public.head_to_head(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- head_to_head_match_ids — drop the game-type filter, keep the rest.
-- ---------------------------------------------------------------------------

drop function if exists public.head_to_head_match_ids(uuid, uuid, public.game_type, integer);

create function public.head_to_head_match_ids(
  p_player_id   uuid,
  p_opponent_id uuid,
  p_limit       integer default 3
)
returns table (match_id uuid)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_competition_id uuid;
begin
  select competition_id into v_competition_id
    from public.players where id = p_player_id;
  if v_competition_id is null then
    raise exception 'Player not found' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from public.players
     where id = p_opponent_id and competition_id = v_competition_id
  ) then
    raise exception 'Players are not in the same competition' using errcode = 'P0001';
  end if;

  if not public.is_member(v_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  return query
    select m.id
      from public.matches m
      join public.match_players mp
        on mp.match_id = m.id and mp.player_id = p_player_id
      join public.match_players opp
        on opp.match_id = m.id and opp.player_id = p_opponent_id and opp.team <> mp.team
     order by m.played_at desc, m.id desc
     limit p_limit;
end;
$$;

revoke all on function public.head_to_head_match_ids(uuid, uuid, integer)
  from public, anon, authenticated;
grant execute on function public.head_to_head_match_ids(uuid, uuid, integer)
  to authenticated;

-- ---------------------------------------------------------------------------
-- create_match / update_match_score / delete_match — drop every call into
-- the per-type track, keep the incremental recalc_season_from boundary
-- logic (20260816110000) unchanged otherwise.
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

  perform public.recalc_season_from(v_season_id, p_played_at, v_match_id);

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
  v_match          public.matches;
  v_comp           public.competitions;
  v_new_season     uuid;
  v_new_played_at  timestamptz;
  v_boundary       timestamptz;
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

  v_new_played_at := coalesce(p_played_at, v_match.played_at);

  -- Moving a match in time can move it into a different season entirely.
  v_new_season := case
    when p_played_at is null then v_match.season_id
    else public.ensure_season(v_match.competition_id, p_played_at)
  end;

  update public.matches
     set team_a_score = p_score_a,
         team_b_score = p_score_b,
         played_at    = v_new_played_at,
         season_id    = v_new_season
   where id = p_match_id;

  if v_new_season = v_match.season_id then
    -- Same match id either side, so the tuple boundary comparison reduces to
    -- the earlier of the two timestamps: whichever position moves first is
    -- where anything downstream could start differing.
    v_boundary := least(v_match.played_at, v_new_played_at);
    perform public.recalc_season_from(v_match.season_id, v_boundary, p_match_id);
  else
    perform public.recalc_season_from(
      v_match.season_id, v_match.played_at, p_match_id
    );
    perform public.recalc_season_from(v_new_season, v_new_played_at, p_match_id);
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

  perform public.recalc_season_from(
    v_match.season_id, v_match.played_at, v_match.id
  );
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

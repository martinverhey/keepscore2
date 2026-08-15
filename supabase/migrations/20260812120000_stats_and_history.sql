-- KeepScore 2 — matches played, streaks, medals, season history, head-to-head.
--
-- game_type and match_players.outcome are snapshotted at write time, the same
-- way team_a_rating/team_b_rating and rating_before/after/delta already are:
-- a match's roster and final score never change after apply_match_ratings has
-- run for it, so both facts are safe to persist once and never recompute.
--
-- season_history / player_medals stay views. There is no "a season just
-- closed" event anywhere in this schema — a season is just a row whose
-- ends_at has passed — so materializing medals would mean inventing that
-- event (a cron/trigger that can fall behind). A view over player_ratings,
-- which recalc_season already keeps correct, has nothing to go stale.

create type public.game_type as enum ('1v1', '2v2', '3v3', '4v4', 'mixed');
create type public.match_outcome as enum ('win', 'loss', 'draw');

alter table public.matches add column game_type public.game_type;
alter table public.match_players add column outcome public.match_outcome;

create function public.compute_game_type(p_team_a_size integer, p_team_b_size integer)
returns public.game_type
language sql
immutable
set search_path = ''
as $$
  select case
    when p_team_a_size = p_team_b_size and p_team_a_size between 1 and 4
      then (p_team_a_size || 'v' || p_team_b_size)::public.game_type
    else 'mixed'::public.game_type
  end;
$$;

revoke all on function public.compute_game_type(integer, integer)
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Backfill existing rows before either column is made NOT NULL.
-- ---------------------------------------------------------------------------

update public.matches m
   set game_type = public.compute_game_type(sizes.a_size, sizes.b_size)
  from (
    select match_id,
           count(*) filter (where team = 'a')::integer as a_size,
           count(*) filter (where team = 'b')::integer as b_size
      from public.match_players
     group by match_id
  ) sizes
 where sizes.match_id = m.id;

update public.match_players mp
   set outcome = case
     when mp.team = 'a' and m.team_a_score > m.team_b_score then 'win'
     when mp.team = 'a' and m.team_a_score < m.team_b_score then 'loss'
     when mp.team = 'b' and m.team_b_score > m.team_a_score then 'win'
     when mp.team = 'b' and m.team_b_score < m.team_a_score then 'loss'
     else 'draw'
   end::public.match_outcome
  from public.matches m
 where m.id = mp.match_id;

alter table public.matches alter column game_type set not null;
alter table public.match_players alter column outcome set not null;

-- ---------------------------------------------------------------------------
-- apply_match_ratings now also snapshots game_type and outcome. This is a
-- create-or-replace on an existing function, which resets EXECUTE to PUBLIC —
-- the revoke at the end restores its internal-only status.
-- ---------------------------------------------------------------------------

create or replace function public.apply_match_ratings(p_match_id uuid)
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

  update public.match_players mp
     set rating_before = coalesce(
           (select pr.rating
              from public.player_ratings pr
             where pr.player_id = mp.player_id
               and pr.season_id = v_match.season_id),
           v_comp.starting_rating
         )
   where mp.match_id = p_match_id;

  select avg(rating_before), count(*) into v_rating_a, v_count_a
    from public.match_players where match_id = p_match_id and team = 'a';
  select avg(rating_before), count(*) into v_rating_b, v_count_b
    from public.match_players where match_id = p_match_id and team = 'b';

  if coalesce(v_count_a, 0) = 0 or coalesce(v_count_b, 0) = 0 then
    raise exception 'Both teams need at least one player' using errcode = 'P0001';
  end if;

  -- Team rating is the mean of its members, and every member takes the same
  -- delta.
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

  update public.match_players
     set rating_delta = case when team = 'a' then v_delta_a else -v_delta_a end,
         rating_after = rating_before
                        + case when team = 'a' then v_delta_a else -v_delta_a end,
         outcome = case
           when team = 'a' and v_outcome_a = 1 then 'win'
           when team = 'a' and v_outcome_a = -1 then 'loss'
           when team = 'b' and v_outcome_a = 1 then 'loss'
           when team = 'b' and v_outcome_a = -1 then 'win'
           else 'draw'
         end::public.match_outcome
   where match_id = p_match_id;

  update public.matches
     set team_a_rating = round(v_rating_a, 2),
         team_b_rating = round(v_rating_b, 2),
         game_type     = public.compute_game_type(v_count_a, v_count_b)
   where id = p_match_id;

  insert into public.player_ratings as pr
    (season_id, player_id, rating, played, wins, losses, draws)
  select v_match.season_id,
         mp.player_id,
         mp.rating_after,
         1,
         case when o.res = 1 then 1 else 0 end,
         case when o.res = -1 then 1 else 0 end,
         case when o.res = 0 then 1 else 0 end
    from public.match_players mp
    cross join lateral (
      select case when mp.team = 'a' then v_outcome_a else -v_outcome_a end as res
    ) o
   where mp.match_id = p_match_id
  on conflict (season_id, player_id) do update
     set rating     = excluded.rating,
         played     = pr.played + 1,
         wins       = pr.wins + excluded.wins,
         losses     = pr.losses + excluded.losses,
         draws      = pr.draws + excluded.draws,
         updated_at = now();
end;
$$;

revoke all on function public.apply_match_ratings(uuid)
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- create_match's initial insert needs a placeholder game_type now that the
-- column is NOT NULL — apply_match_ratings overwrites it immediately after,
-- the same way it already does for team_a_rating/team_b_rating.
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
  v_comp      public.competitions;
  v_season_id uuid;
  v_match_id  uuid;
  v_all       uuid[];
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

  -- A back-dated match lands in the middle of the season's history, so the
  -- rest of it has to be replayed on top.
  if exists (
    select 1 from public.matches
     where season_id = v_season_id
       and (played_at, id) > (p_played_at, v_match_id)
  ) then
    perform public.recalc_season(v_season_id);
  end if;

  return v_match_id;
end;
$$;

revoke all on function
  public.create_match(uuid, uuid[], uuid[], integer, integer, timestamptz)
from public, anon, authenticated;

grant execute on function
  public.create_match(uuid, uuid[], uuid[], integer, integer, timestamptz)
to authenticated;

-- ---------------------------------------------------------------------------
-- Read models
-- ---------------------------------------------------------------------------

create view public.season_history
with (security_invoker = true) as
select
  l.*,
  s.starts_at,
  s.ends_at,
  case l.rank when 1 then 'gold' when 2 then 'silver' when 3 then 'bronze' end as medal
from public.leaderboard l
join public.seasons s on s.id = l.season_id
where s.ends_at <= now();

create view public.player_medals
with (security_invoker = true) as
select
  competition_id,
  player_id,
  count(*) filter (where medal = 'gold')   as gold,
  count(*) filter (where medal = 'silver') as silver,
  count(*) filter (where medal = 'bronze') as bronze
from public.season_history
where medal is not null
group by competition_id, player_id;

create view public.player_totals
with (security_invoker = true) as
select
  s.competition_id,
  pr.player_id,
  sum(pr.played)::integer as total_played
from public.player_ratings pr
join public.seasons s on s.id = pr.season_id
group by s.competition_id, pr.player_id;

grant select on public.season_history to authenticated;
grant select on public.player_medals  to authenticated;
grant select on public.player_totals  to authenticated;

-- ---------------------------------------------------------------------------
-- head_to_head / player_streak
-- ---------------------------------------------------------------------------

create function public.head_to_head(p_player_id uuid, p_opponent_id uuid)
returns table (
  game_type public.game_type,
  wins      integer,
  losses    integer,
  draws     integer
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
    select m.game_type,
           count(*) filter (where mp.outcome = 'win')::integer,
           count(*) filter (where mp.outcome = 'loss')::integer,
           count(*) filter (where mp.outcome = 'draw')::integer
      from public.matches m
      join public.match_players mp
        on mp.match_id = m.id and mp.player_id = p_player_id
      join public.match_players opp
        on opp.match_id = m.id and opp.player_id = p_opponent_id and opp.team <> mp.team
     group by m.game_type;
end;
$$;

create function public.player_streak(p_season_id uuid, p_player_id uuid)
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

revoke all on function public.head_to_head(uuid, uuid) from public, anon, authenticated;
revoke all on function public.player_streak(uuid, uuid) from public, anon, authenticated;

grant execute on function public.head_to_head(uuid, uuid) to authenticated;
grant execute on function public.player_streak(uuid, uuid) to authenticated;

-- KeepScore 2 — let the profile sheet filter its whole overview (rating
-- trend, streak) by game type, not just the standings table.
--
-- player_streak's outcome sequence is a fact about the match itself (who won,
-- independent of which Elo track is being read), so it only needs an extra
-- WHERE clause. The rating trend is different: match_players.rating_before/
-- after/delta is the combined-track snapshot, and per the parallel-track
-- design in 20260812140000_leaderboard_game_type.sql a type-filtered slice of
-- the combined track is not the type-track's rating. apply_match_type_rating
-- already computes that track's per-match delta (v_delta_a below) but only
-- ever persisted the running total to player_game_type_ratings — never a
-- per-match snapshot — so there was nothing to chart. type_rating_before/
-- after/delta on match_players is that missing snapshot, filled in the same
-- two-step way apply_match_ratings already fills rating_before/after/delta
-- for the combined track.

alter table public.match_players
  add column type_rating_before numeric(8, 2),
  add column type_rating_after  numeric(8, 2),
  add column type_rating_delta  numeric(8, 2);

create or replace function public.apply_match_type_rating(p_match_id uuid)
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
     set type_rating_before = coalesce(
           (select pgtr.rating
              from public.player_game_type_ratings pgtr
             where pgtr.player_id = mp.player_id
               and pgtr.season_id = v_match.season_id
               and pgtr.game_type = v_match.game_type),
           v_comp.starting_rating
         )
   where mp.match_id = p_match_id;

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

  update public.match_players mp
     set type_rating_delta = case when mp.team = 'a' then v_delta_a else -v_delta_a end,
         type_rating_after = mp.type_rating_before
                              + case when mp.team = 'a' then v_delta_a else -v_delta_a end
   where mp.match_id = p_match_id;

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

revoke all on function public.apply_match_type_rating(uuid)
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- Backfill: every match applied before this migration is missing the new
-- type_rating_* snapshot, so replay every (season, game_type) pair once,
-- exactly like the original per-type migration backfilled player_game_type_ratings.
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
-- player_streak: an optional game-type filter on the same outcome sequence.
--
-- create or replace cannot widen an existing function's argument list — an
-- added parameter is a different signature, so it would just create a second,
-- overloaded player_streak(uuid, uuid) alongside this one, and PostgREST
-- cannot reliably pick between overloads that only differ by a defaulted
-- trailing argument. This has to end with exactly one player_streak, which
-- means dropping the two-argument original — but the leaderboard view's
-- lateral join still calls that exact signature, so the view is repointed at
-- the new one first, then the drop has nothing left depending on it.
-- ---------------------------------------------------------------------------

create function public.player_streak(
  p_season_id  uuid,
  p_player_id  uuid,
  p_game_type  public.game_type default null
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
       and (p_game_type is null or m.game_type = p_game_type)
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

revoke all on function public.player_streak(uuid, uuid, public.game_type)
  from public, anon, authenticated;
grant execute on function public.player_streak(uuid, uuid, public.game_type)
  to authenticated;

-- Repoint the view at the new three-argument function before the old one is
-- dropped. Identical to the definition in 20260812130000_leaderboard_streaks.sql
-- except for the explicit third argument on the lateral call.
create or replace view public.leaderboard
with (security_invoker = true) as
select
  s.id                                    as season_id,
  s.competition_id,
  p.id                                    as player_id,
  p.display_name,
  (p.user_id is not null)                 as is_claimed,
  coalesce(pr.rating, c.starting_rating)  as rating,
  coalesce(pr.played, 0)                  as played,
  coalesce(pr.wins, 0)                    as wins,
  coalesce(pr.losses, 0)                  as losses,
  coalesce(pr.draws, 0)                   as draws,
  rank() over (
    partition by s.id
    order by coalesce(pr.rating, c.starting_rating) desc,
             coalesce(pr.wins, 0) desc,
             p.display_name asc
  )                                       as rank,
  coalesce(st.streak_type, 'none')        as streak_type,
  coalesce(st.streak_count, 0)            as streak_count
from public.seasons s
join public.competitions c
  on c.id = s.competition_id
join public.players p
  on p.competition_id = s.competition_id
 and p.is_active
left join public.player_ratings pr
  on pr.season_id = s.id
 and pr.player_id = p.id
left join lateral public.player_streak(s.id, p.id, null::public.game_type) st on true;

grant select on public.leaderboard to authenticated;

drop function public.player_streak(uuid, uuid);

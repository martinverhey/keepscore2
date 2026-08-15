-- KeepScore 2 — skip no-op writes during rating replay.
--
-- recalc_season/recalc_season_game_type replay every match in a season on
-- every edit or delete, not just the ones after the change (that's a bigger,
-- separate fix — see the plan). Most of those replayed matches recompute the
-- exact same rating_before/rating_after/team ratings they already had, since
-- nothing upstream of them changed. apply_match_ratings and
-- apply_match_type_rating used to UPDATE matches and match_players
-- unconditionally regardless, which still writes a fresh row version (WAL,
-- storage churn, and — for matches, which is in the realtime publication — a
-- postgres_changes event) for a value that didn't actually change. Guarding
-- each UPDATE with IS DISTINCT FROM makes those replays no-ops in practice
-- for every match before the affected point.
--
-- player_ratings / player_game_type_ratings are deliberately NOT guarded
-- here: recalc_season deletes them for the whole season up front and rebuilds
-- every row via incrementing upserts, so every row is genuinely new on every
-- replay regardless — there's nothing to compare against without also making
-- the replay itself incremental (a separate, larger change).

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

  with intended as (
    select mp.player_id,
           coalesce(pr.rating, v_comp.starting_rating) as rating_before
      from public.match_players mp
      left join public.player_ratings pr
        on pr.player_id = mp.player_id
       and pr.season_id = v_match.season_id
     where mp.match_id = p_match_id
  )
  update public.match_players mp
     set rating_before = intended.rating_before
    from intended
   where mp.match_id = p_match_id
     and mp.player_id = intended.player_id
     and mp.rating_before is distinct from intended.rating_before;

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

  with intended as (
    select mp.player_id,
           case when mp.team = 'a' then v_delta_a else -v_delta_a end
             as rating_delta,
           mp.rating_before
             + case when mp.team = 'a' then v_delta_a else -v_delta_a end
             as rating_after,
           case
             when mp.team = 'a' and v_outcome_a = 1  then 'win'
             when mp.team = 'a' and v_outcome_a = -1 then 'loss'
             when mp.team = 'b' and v_outcome_a = 1  then 'loss'
             when mp.team = 'b' and v_outcome_a = -1 then 'win'
             else 'draw'
           end::public.match_outcome as outcome
      from public.match_players mp
     where mp.match_id = p_match_id
  )
  update public.match_players mp
     set rating_delta = intended.rating_delta,
         rating_after = intended.rating_after,
         outcome      = intended.outcome
    from intended
   where mp.match_id = p_match_id
     and mp.player_id = intended.player_id
     and (mp.rating_delta is distinct from intended.rating_delta
          or mp.rating_after is distinct from intended.rating_after
          or mp.outcome is distinct from intended.outcome);

  update public.matches m
     set team_a_rating = round(v_rating_a, 2),
         team_b_rating = round(v_rating_b, 2),
         game_type     = public.compute_game_type(v_count_a, v_count_b)
   where m.id = p_match_id
     and (m.team_a_rating is distinct from round(v_rating_a, 2)
          or m.team_b_rating is distinct from round(v_rating_b, 2)
          or m.game_type is distinct from
             public.compute_game_type(v_count_a, v_count_b));

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

  with intended as (
    select mp.player_id,
           coalesce(pgtr.rating, v_comp.starting_rating) as type_rating_before
      from public.match_players mp
      left join public.player_game_type_ratings pgtr
        on pgtr.player_id = mp.player_id
       and pgtr.season_id = v_match.season_id
       and pgtr.game_type = v_match.game_type
     where mp.match_id = p_match_id
  )
  update public.match_players mp
     set type_rating_before = intended.type_rating_before
    from intended
   where mp.match_id = p_match_id
     and mp.player_id = intended.player_id
     and mp.type_rating_before is distinct from intended.type_rating_before;

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

  with intended as (
    select mp.player_id,
           case when mp.team = 'a' then v_delta_a else -v_delta_a end
             as type_rating_delta,
           mp.type_rating_before
             + case when mp.team = 'a' then v_delta_a else -v_delta_a end
             as type_rating_after
      from public.match_players mp
     where mp.match_id = p_match_id
  )
  update public.match_players mp
     set type_rating_delta = intended.type_rating_delta,
         type_rating_after = intended.type_rating_after
    from intended
   where mp.match_id = p_match_id
     and mp.player_id = intended.player_id
     and (mp.type_rating_delta is distinct from intended.type_rating_delta
          or mp.type_rating_after is distinct from intended.type_rating_after);

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

-- KeepScore 2 — surface each player's rating change for the current day.
--
-- match_players.rating_delta is per-match and matches.played_at is a
-- timestamptz, so "today" has to be computed, not read off a snapshot —
-- player_ratings only carries the running total. player_today_delta mirrors
-- player_streak's shape (security definer, checks membership itself, called
-- straight from the view) but returns a single numeric instead of a row, so
-- it drops straight into the select list with no lateral join needed. The
-- day boundary reuses season_bounds' idiom: truncate "now" to midnight in
-- the competition's own timezone, not the caller's.

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

revoke all on function public.player_today_delta(p_season_id uuid, p_player_id uuid) from public, anon, authenticated;
grant execute on function public.player_today_delta(p_season_id uuid, p_player_id uuid) to authenticated;

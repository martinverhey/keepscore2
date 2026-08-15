-- KeepScore 2 — matches played today and this (ISO) week, for the profile
-- sheet's expanded games row.
--
-- Same day-boundary idiom as player_today_delta: truncate "now" to midnight
-- in the competition's own timezone, not the caller's. date_trunc('week', …)
-- gives the Monday-start week boundary the same way, in the same timezone.
-- Both counts come out of one pass over the season's matches for this
-- player, current season only — same scope as player_streak and the
-- existing "Season games" stat it sits next to.

create function public.player_recent_played(
  p_season_id  uuid,
  p_player_id  uuid,
  p_game_type  public.game_type default null
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
     and m.season_id = p_season_id
     and (p_game_type is null or m.game_type = p_game_type);

  return next;
end;
$$;

revoke all on function public.player_recent_played(uuid, uuid, public.game_type)
  from public, anon, authenticated;
grant execute on function public.player_recent_played(uuid, uuid, public.game_type)
  to authenticated;

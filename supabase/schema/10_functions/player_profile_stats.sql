-- The profile overview's scalar stats in one round trip.
--
-- totalMatchesPlayed, bestStreaks, currentStreak, recentPlayed and bestRating
-- are all single-row results for the same (player, season), so they come back
-- as one row here. leaderboards/recentForPlayer/medals/ratingHistory stay
-- separate calls — those are genuinely different, list-shaped fetches.
--
-- The membership check happens once, up front, and it is load-bearing:
-- player_totals is a plain security_invoker view with no check of its own
-- (it has only ever been queried directly by an already-RLS-scoped client),
-- unlike player_best_streaks/player_streak/player_recent_played. Everything
-- else defers to those existing functions and views rather than restating
-- their logic.
--
-- p_season_id may be null, meaning no season has started yet; player_streak
-- and player_recent_played already read that as "no matches" and return
-- zeroes, so there is nothing to special-case.

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

revoke all on function public.player_profile_stats(p_player_id uuid, p_season_id uuid) from public, anon, authenticated;
grant execute on function public.player_profile_stats(p_player_id uuid, p_season_id uuid) to authenticated;

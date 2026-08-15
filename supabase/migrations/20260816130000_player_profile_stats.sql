-- KeepScore 2 — bundle the profile overview's scalar stats into one RPC.
--
-- ProfileOverviewCubit fired up to 9 parallel Supabase round trips on every
-- open and every game-type filter change. Four of them — totalMatchesPlayed,
-- bestStreaks, currentStreak, recentPlayed — plus the newer bestRating
-- (20260815160000) are all single-row results for the same (player, season,
-- game_type); leaderboards/recentForPlayer/medals/ratingHistory stay
-- separate calls, since those are genuinely different, list-shaped fetches.
--
-- player_profile_stats does the membership check once, up front (the
-- authorization gate this needs before touching player_totals/
-- player_game_type_totals, which — unlike player_best_streaks/player_streak/
-- player_recent_played — have no membership check of their own; they're
-- plain security_invoker views that have only ever been queried directly by
-- an already-RLS-scoped client), then calls the existing, already-tested
-- functions/views for everything else and folds their results into one row.
-- p_season_id may be null (no season has started yet): player_streak/
-- player_recent_played already treat "season_id = null" as "no matches",
-- returning zeroes — nothing extra to special-case here.

create function public.player_profile_stats(
  p_player_id  uuid,
  p_season_id  uuid,
  p_game_type  public.game_type default null
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

  if p_game_type is null then
    select pt.total_played into total_played
      from public.player_totals pt where pt.player_id = p_player_id;
  else
    select pgtt.total_played into total_played
      from public.player_game_type_totals pgtt
     where pgtt.player_id = p_player_id and pgtt.game_type = p_game_type;
  end if;
  total_played := coalesce(total_played, 0);

  select * into v_best from public.player_best_streaks(p_player_id, p_game_type);
  best_win_streak := v_best.best_win_streak;
  best_loss_streak := v_best.best_loss_streak;

  best_rating := public.player_best_rating(p_player_id, p_game_type);

  select * into v_streak
    from public.player_streak(p_season_id, p_player_id, p_game_type);
  streak_type := v_streak.streak_type;
  streak_count := v_streak.streak_count;

  select * into v_recent
    from public.player_recent_played(p_season_id, p_player_id, p_game_type);
  today_played := v_recent.today_played;
  week_played := v_recent.week_played;

  return next;
end;
$$;

revoke all on function
  public.player_profile_stats(uuid, uuid, public.game_type)
from public, anon, authenticated;

grant execute on function
  public.player_profile_stats(uuid, uuid, public.game_type)
to authenticated;

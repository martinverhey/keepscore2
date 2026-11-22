-- Removes the tournament track (20260911120000_tournaments) from the database.
-- leaderboard is dropped and recreated rather than replaced, because create or
-- replace cannot remove its trailing trophies column; its body matches
-- supabase/schema/20_views/20_leaderboard.sql, and the grants restore the ACL
-- it carried before the drop.

drop view public.leaderboard;

drop function public.start_tournament(uuid, uuid[]);
drop function public.set_tournament_result(uuid, integer, integer);
drop function public.cancel_tournament(uuid);

drop view public.player_trophies;
drop view public.tournament_bracket;

drop table public.tournament_matches;
drop table public.tournaments;

drop type public.tournament_status;

create view public.leaderboard
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

grant all on public.leaderboard to anon, authenticated, service_role;

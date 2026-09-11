-- Column order must match the view's existing shape exactly — create or
-- replace can only append trailing columns, not reorder existing ones — so
-- this lists leaderboard_base's columns explicitly (streak_type/streak_count
-- slot in before is_owner, matching the order they were added in) rather
-- than `b.*`. trophies is last because it was added last; anything new goes
-- after it, never between.

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
  coalesce(public.player_today_delta(b.season_id, b.player_id), 0) as today_delta,
  coalesce(tr.trophies, 0)                as trophies
from public.leaderboard_base b
left join lateral
  public.player_streak(b.season_id, b.player_id) st
  on true
left join public.player_trophies tr
  on tr.season_id = b.season_id
 and tr.player_id = b.player_id;

grant select on public.leaderboard to authenticated;

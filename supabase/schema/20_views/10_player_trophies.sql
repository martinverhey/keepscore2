-- player_trophies — how many tournaments a player has won, per season. Seasons
-- hard-reset, and a trophy belongs to the season it was won in, so the
-- leaderboard's trophy count resets with everything else.
--
-- The 10_ prefix is load-bearing: 20_leaderboard joins this.

create or replace view public.player_trophies
with (security_invoker = true) as
select
  t.season_id,
  t.winner_player_id as player_id,
  count(*)::integer  as trophies
from public.tournaments t
where t.status = 'completed'
  and t.winner_player_id is not null
group by t.season_id, t.winner_player_id;

grant select on public.player_trophies to authenticated;

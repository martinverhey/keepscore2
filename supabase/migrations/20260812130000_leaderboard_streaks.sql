-- KeepScore 2 — leaderboard streaks.
--
-- Surfaces each player's current win/loss streak directly on the leaderboard
-- view so the client can render it without one round trip per player. Reuses
-- player_streak (20260812120000_stats_and_history.sql) rather than
-- duplicating its walk over match_players — one lateral call per row, same
-- cost as the client calling the RPC once per player, just server-side.

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
left join lateral public.player_streak(s.id, p.id) st on true;

grant select on public.leaderboard to authenticated;

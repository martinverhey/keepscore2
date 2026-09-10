-- KeepScore 2 — stop paying for streak/today-delta on historical seasons.
--
-- leaderboard's streak_type/streak_count (player_streak(), a scan of a
-- player's match_players) and today_delta (player_today_delta(), another
-- scan) exist for the live current-season leaderboard — leaderboard_row.dart
-- renders both. season_history and player_medals were built as `select l.*
-- … from leaderboard l … where s.ends_at <= now()`, which meant every row of
-- every *closed* season also ran both scans, even though SeasonStanding
-- (season_history's Dart model) never reads streak_type/streak_count/
-- today_delta/is_owner at all — they were computed and shipped over the wire
-- purely to be discarded. This gets worse every time a season closes, since
-- seasons hard-reset on a calendar cadence and season_history spans all of
-- them, unfiltered, on every fetch.
--
-- The fix: split the shared, cheap columns (rating/played/wins/losses/draws/
-- rank, plus is_owner — a plain comparison, no function call) into
-- leaderboard_base / game_type_leaderboard_base. `leaderboard` and
-- `game_type_leaderboard` (the live, current-season views) still add
-- streak/today-delta on top, unchanged in shape. `season_history` and
-- `game_type_season_history` are now built from the *_base views directly —
-- siblings of `leaderboard`, not derived from it — so they never run those
-- scans, and `player_medals` / `game_type_player_medals` inherit that for
-- free since they're built from season_history in turn.
--
-- create or replace view cannot drop columns, only append trailing ones, so
-- season_history / player_medals (and the game_type siblings) are dropped
-- and recreated rather than replaced in place.
-- leaderboard_base — combined track, no streak/today-delta.

create or replace view public.leaderboard_base
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
  (p.user_id is not null
    and p.user_id = c.owner_id)           as is_owner
from public.seasons s
join public.competitions c
  on c.id = s.competition_id
join public.players p
  on p.competition_id = s.competition_id
 and p.is_active
left join public.player_ratings pr
  on pr.season_id = s.id
 and pr.player_id = p.id;

grant select on public.leaderboard_base to authenticated;

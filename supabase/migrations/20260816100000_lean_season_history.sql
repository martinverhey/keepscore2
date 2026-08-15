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

-- ---------------------------------------------------------------------------
-- leaderboard_base — combined track, no streak/today-delta.
-- ---------------------------------------------------------------------------

create view public.leaderboard_base
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

-- Column order must match the view's existing shape exactly — create or
-- replace can only append trailing columns, not reorder existing ones — so
-- this lists leaderboard_base's columns explicitly (streak_type/streak_count
-- slot in before is_owner, matching the order they were added in) rather
-- than `b.*`.
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
  coalesce(
    public.player_today_delta(b.season_id, b.player_id, null::public.game_type),
    0
  )                                       as today_delta
from public.leaderboard_base b
left join lateral
  public.player_streak(b.season_id, b.player_id, null::public.game_type) st
  on true;

grant select on public.leaderboard to authenticated;

-- ---------------------------------------------------------------------------
-- game_type_leaderboard_base — per-type track, no is_owner/today-delta.
-- ---------------------------------------------------------------------------

create view public.game_type_leaderboard_base
with (security_invoker = true) as
select
  s.id                     as season_id,
  s.competition_id,
  pgtr.game_type,
  pgtr.player_id,
  p.display_name,
  (p.user_id is not null)  as is_claimed,
  pgtr.rating,
  pgtr.played,
  pgtr.wins,
  pgtr.losses,
  pgtr.draws,
  rank() over (
    partition by s.id, pgtr.game_type
    order by pgtr.rating desc, pgtr.wins desc, p.display_name asc
  )                        as rank
from public.player_game_type_ratings pgtr
join public.seasons s on s.id = pgtr.season_id
join public.players p on p.id = pgtr.player_id and p.is_active;

grant select on public.game_type_leaderboard_base to authenticated;

create or replace view public.game_type_leaderboard
with (security_invoker = true) as
select
  b.*,
  (p.user_id is not null and p.user_id = c.owner_id) as is_owner,
  coalesce(
    public.player_today_delta(b.season_id, b.player_id, b.game_type), 0
  )                                                   as today_delta
from public.game_type_leaderboard_base b
join public.players p on p.id = b.player_id
join public.competitions c on c.id = b.competition_id;

grant select on public.game_type_leaderboard to authenticated;

-- ---------------------------------------------------------------------------
-- season_history / player_medals — rebuilt on the lean base, not leaderboard.
-- ---------------------------------------------------------------------------

drop view public.player_medals;
drop view public.season_history;

create view public.season_history
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
  s.starts_at,
  s.ends_at,
  case b.rank when 1 then 'gold' when 2 then 'silver' when 3 then 'bronze' end as medal
from public.leaderboard_base b
join public.seasons s on s.id = b.season_id
where s.ends_at <= now();

create view public.player_medals
with (security_invoker = true) as
select
  competition_id,
  player_id,
  count(*) filter (where medal = 'gold')   as gold,
  count(*) filter (where medal = 'silver') as silver,
  count(*) filter (where medal = 'bronze') as bronze
from public.season_history
where medal is not null
group by competition_id, player_id;

grant select on public.season_history to authenticated;
grant select on public.player_medals  to authenticated;

-- ---------------------------------------------------------------------------
-- game_type_season_history / game_type_player_medals — same split.
-- ---------------------------------------------------------------------------

drop view public.game_type_player_medals;
drop view public.game_type_season_history;

create view public.game_type_season_history
with (security_invoker = true) as
select
  b.season_id,
  b.competition_id,
  b.game_type,
  b.player_id,
  b.display_name,
  b.is_claimed,
  b.rating,
  b.played,
  b.wins,
  b.losses,
  b.draws,
  b.rank,
  s.starts_at,
  s.ends_at,
  case b.rank when 1 then 'gold' when 2 then 'silver' when 3 then 'bronze' end as medal
from public.game_type_leaderboard_base b
join public.seasons s on s.id = b.season_id
where s.ends_at <= now();

create view public.game_type_player_medals
with (security_invoker = true) as
select
  competition_id,
  game_type,
  player_id,
  count(*) filter (where medal = 'gold')   as gold,
  count(*) filter (where medal = 'silver') as silver,
  count(*) filter (where medal = 'bronze') as bronze
from public.game_type_season_history
where medal is not null
group by competition_id, game_type, player_id;

grant select on public.game_type_season_history to authenticated;
grant select on public.game_type_player_medals  to authenticated;

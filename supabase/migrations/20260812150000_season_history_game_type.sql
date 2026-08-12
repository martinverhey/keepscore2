-- KeepScore 2 — season history filtered by game type.
--
-- Parallel to season_history, but built on game_type_leaderboard instead of
-- leaderboard — the same relationship game_type_leaderboard already has to
-- leaderboard (20260812140000_leaderboard_game_type.sql). Not roster-backed,
-- same as its source: a player who never played a given type in a season
-- just doesn't have a row there, so they don't get a season-history row for
-- it either.

create view public.game_type_season_history
with (security_invoker = true) as
select
  l.*,
  s.starts_at,
  s.ends_at,
  case l.rank when 1 then 'gold' when 2 then 'silver' when 3 then 'bronze' end as medal
from public.game_type_leaderboard l
join public.seasons s on s.id = l.season_id
where s.ends_at <= now();

grant select on public.game_type_season_history to authenticated;

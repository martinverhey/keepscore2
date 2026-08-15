-- KeepScore 2 — medals filtered by game type.
--
-- Parallel to player_medals, but built on game_type_season_history instead
-- of season_history — the same relationship game_type_season_history already
-- has to season_history (20260812150000_season_history_game_type.sql).

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

grant select on public.game_type_player_medals to authenticated;

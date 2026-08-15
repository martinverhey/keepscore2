-- KeepScore 2 — all-time totals per game type, the type-scoped sibling of
-- player_totals (which stays combined, across all types, unchanged).

create view public.player_game_type_totals
with (security_invoker = true) as
select
  s.competition_id,
  pgtr.player_id,
  pgtr.game_type,
  sum(pgtr.played)::integer as total_played
from public.player_game_type_ratings pgtr
join public.seasons s on s.id = pgtr.season_id
group by s.competition_id, pgtr.player_id, pgtr.game_type;

grant select on public.player_game_type_totals to authenticated;

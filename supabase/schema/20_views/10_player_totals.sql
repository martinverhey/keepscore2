create or replace view public.player_totals
with (security_invoker = true) as
select
  s.competition_id,
  pr.player_id,
  sum(pr.played)::integer as total_played
from public.player_ratings pr
join public.seasons s on s.id = pr.season_id
group by s.competition_id, pr.player_id;

grant select on public.player_totals  to authenticated;

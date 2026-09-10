create or replace view public.player_medals
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

grant select on public.player_medals  to authenticated;

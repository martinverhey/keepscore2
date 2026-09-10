-- Read models

create or replace view public.season_history
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

grant select on public.season_history to authenticated;

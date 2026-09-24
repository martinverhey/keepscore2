-- tournament_bracket — every slot of a bracket with both sides' names already
-- resolved, so the whole thing is one fetch rather than a match read plus a
-- roster read the client has to join itself.

create or replace view public.tournament_bracket
with (security_invoker = true) as
select
  tm.id,
  tm.tournament_id,
  t.competition_id,
  tm.round,
  tm.slot,
  tm.player_a_id,
  pa.display_name as player_a_name,
  tm.player_b_id,
  pb.display_name as player_b_name,
  tm.score_a,
  tm.score_b,
  tm.winner_player_id,
  tm.played_at
from public.tournament_matches tm
join public.tournaments t
  on t.id = tm.tournament_id
left join public.players pa
  on pa.id = tm.player_a_id
left join public.players pb
  on pb.id = tm.player_b_id;

grant select on public.tournament_bracket to authenticated;

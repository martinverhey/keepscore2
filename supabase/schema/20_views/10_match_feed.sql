-- KeepScore 2 — expose game_type on match_feed so the matches list can be
-- filtered by it client-side, the same way the leaderboard and profile
-- already filter by game_type.
--
-- game_type is appended as the last column rather than placed next to
-- season_id: `create or replace view` can only add trailing columns, not
-- insert or reorder existing ones.

create or replace view public.match_feed
with (security_invoker = true) as
select
  m.id,
  m.competition_id,
  m.season_id,
  m.played_at,
  m.team_a_score,
  m.team_b_score,
  m.team_a_rating,
  m.team_b_rating,
  m.created_by,
  m.created_at,
  team_players.team_a,
  team_players.team_b,
  m.game_type
from public.matches m
cross join lateral (
  select
    coalesce(jsonb_agg(entry) filter (where team = 'a'), '[]'::jsonb) as team_a,
    coalesce(jsonb_agg(entry) filter (where team = 'b'), '[]'::jsonb) as team_b
  from (
    select
      mp.team,
      jsonb_build_object(
        'player_id',    mp.player_id,
        'display_name', pl.display_name,
        'rating_before', mp.rating_before,
        'rating_delta',  mp.rating_delta
      ) as entry
    from public.match_players mp
    join public.players pl on pl.id = mp.player_id
    where mp.match_id = m.id
    order by pl.display_name
  ) ordered
) team_players;

grant select on public.match_feed to authenticated;

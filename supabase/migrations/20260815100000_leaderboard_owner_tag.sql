-- KeepScore 2 — surface the competition owner on the leaderboard.
--
-- The leaderboard already flags a row as "You"; it has no way to also flag
-- "Owner" because is_claimed only says a player is linked to *some* user,
-- not which one. Both leaderboard and game_type_leaderboard already carry a
-- join back to competitions (leaderboard directly, game_type_leaderboard
-- added here) so comparing p.user_id to c.owner_id costs nothing extra.

create or replace view public.leaderboard
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
  coalesce(st.streak_type, 'none')        as streak_type,
  coalesce(st.streak_count, 0)            as streak_count,
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
 and pr.player_id = p.id
left join lateral public.player_streak(s.id, p.id, null::public.game_type) st on true;

grant select on public.leaderboard to authenticated;

create or replace view public.game_type_leaderboard
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
  )                        as rank,
  (p.user_id is not null
    and p.user_id = c.owner_id) as is_owner
from public.player_game_type_ratings pgtr
join public.seasons s on s.id = pgtr.season_id
join public.competitions c on c.id = s.competition_id
join public.players p on p.id = pgtr.player_id and p.is_active;

grant select on public.game_type_leaderboard to authenticated;

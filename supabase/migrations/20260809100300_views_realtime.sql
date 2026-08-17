-- KeepScore 2 — read models and realtime.
--
-- Both views are security_invoker, so the caller's RLS still applies: a view
-- is a convenience for the client, not a way around the policies in 0003.

-- ---------------------------------------------------------------------------
-- leaderboard
-- ---------------------------------------------------------------------------

-- Driven from players rather than from player_ratings, so someone who has not
-- played yet this season still appears — at the competition's starting rating,
-- which is exactly what the hard season reset means.
create view public.leaderboard
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
  )                                       as rank
from public.seasons s
join public.competitions c
  on c.id = s.competition_id
join public.players p
  on p.competition_id = s.competition_id
 and p.is_active
left join public.player_ratings pr
  on pr.season_id = s.id
 and pr.player_id = p.id;

-- ---------------------------------------------------------------------------
-- match_feed
-- ---------------------------------------------------------------------------

-- Each team's players are aggregated into JSON so the match list is a single
-- round trip instead of an N+1 over match_players.
create view public.match_feed
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
  team_players.team_b
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

grant select on public.leaderboard to authenticated;
grant select on public.match_feed to authenticated;

-- ---------------------------------------------------------------------------
-- Current season lookup
-- ---------------------------------------------------------------------------

-- The season row only exists once a match has been played in it, so the app
-- needs the computed window even when season_id comes back NULL.
create function public.season_window(
  p_competition_id uuid,
  p_at             timestamptz default now()
)
returns table (
  season_id         uuid,
  season_starts_at  timestamptz,
  season_ends_at    timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_comp   public.competitions;
  v_bounds record;
begin
  if not public.is_member(p_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  select * into strict v_comp
    from public.competitions where id = p_competition_id;

  select * into v_bounds
    from public.season_bounds(p_at, v_comp.season_length, v_comp.timezone);

  season_starts_at := v_bounds.starts_at;
  season_ends_at   := v_bounds.ends_at;

  select s.id into season_id
    from public.seasons s
   where s.competition_id = p_competition_id
     and s.starts_at = v_bounds.starts_at;

  return next;
end;
$$;

revoke all on function public.season_window(uuid, timestamptz)
  from public, anon, authenticated;
grant execute on function public.season_window(uuid, timestamptz) to authenticated;

-- ---------------------------------------------------------------------------
-- Realtime
-- ---------------------------------------------------------------------------

-- postgres_changes honours RLS, so subscribers only receive rows they could
-- have selected anyway.
alter publication supabase_realtime add table public.matches;
alter publication supabase_realtime add table public.player_ratings;
alter publication supabase_realtime add table public.players;

-- Deletes carry only the primary key unless the replica identity is full;
-- the match list needs the competition_id to know whether a delete is its own.
alter table public.matches replica identity full;

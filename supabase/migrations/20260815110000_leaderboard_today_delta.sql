-- KeepScore 2 — surface each player's rating change for the current day.
--
-- match_players.rating_delta is per-match and matches.played_at is a
-- timestamptz, so "today" has to be computed, not read off a snapshot —
-- player_ratings only carries the running total. player_today_delta mirrors
-- player_streak's shape (security definer, checks membership itself, called
-- straight from the view) but returns a single numeric instead of a row, so
-- it drops straight into the select list with no lateral join needed. The
-- day boundary reuses season_bounds' idiom: truncate "now" to midnight in
-- the competition's own timezone, not the caller's.

create or replace function public.player_today_delta(
  p_season_id  uuid,
  p_player_id  uuid,
  p_game_type  public.game_type default null
)
returns numeric
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_competition_id uuid;
  v_timezone       text;
  v_day_start      timestamptz;
  v_delta          numeric;
begin
  select p.competition_id, c.timezone
    into v_competition_id, v_timezone
    from public.players p
    join public.competitions c on c.id = p.competition_id
   where p.id = p_player_id;

  if v_competition_id is null then
    raise exception 'Player not found' using errcode = 'P0001';
  end if;

  if not public.is_member(v_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  v_day_start := date_trunc('day', now() at time zone v_timezone) at time zone v_timezone;

  select coalesce(sum(mp.rating_delta), 0)
    into v_delta
    from public.match_players mp
    join public.matches m on m.id = mp.match_id
   where mp.player_id = p_player_id
     and m.season_id = p_season_id
     and m.played_at >= v_day_start
     and (p_game_type is null or m.game_type = p_game_type);

  return v_delta;
end;
$$;

grant execute on function public.player_today_delta(uuid, uuid, public.game_type) to authenticated;

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
    and p.user_id = c.owner_id)           as is_owner,
  coalesce(
    public.player_today_delta(s.id, p.id, null::public.game_type), 0
  )                                       as today_delta
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
    and p.user_id = c.owner_id) as is_owner,
  coalesce(
    public.player_today_delta(s.id, pgtr.player_id, pgtr.game_type), 0
  )                        as today_delta
from public.player_game_type_ratings pgtr
join public.seasons s on s.id = pgtr.season_id
join public.competitions c on c.id = s.competition_id
join public.players p on p.id = pgtr.player_id and p.is_active;

grant select on public.game_type_leaderboard to authenticated;

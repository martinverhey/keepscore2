-- KeepScore 2 — the actual matches behind a head_to_head tally.
--
-- head_to_head (20260812120000_stats_and_history.sql) aggregates wins/losses/
-- draws per game type; the versus tab also wants the underlying recent
-- matches, filtered the same way the rest of the profile is — by game type,
-- via a fresh query, not by slicing an unfiltered "recent" list after the
-- fact (a limited page of the unfiltered feed may simply not contain any
-- match of the selected type, same reasoning as the per-game-type
-- leaderboard). Same membership checks as head_to_head, duplicated rather
-- than shared — head_to_head already does the same.

create function public.head_to_head_match_ids(
  p_player_id   uuid,
  p_opponent_id uuid,
  p_game_type   public.game_type default null,
  p_limit       integer default 3
)
returns table (match_id uuid)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_competition_id uuid;
begin
  select competition_id into v_competition_id
    from public.players where id = p_player_id;
  if v_competition_id is null then
    raise exception 'Player not found' using errcode = 'P0001';
  end if;

  if not exists (
    select 1 from public.players
     where id = p_opponent_id and competition_id = v_competition_id
  ) then
    raise exception 'Players are not in the same competition' using errcode = 'P0001';
  end if;

  if not public.is_member(v_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  return query
    select m.id
      from public.matches m
      join public.match_players mp
        on mp.match_id = m.id and mp.player_id = p_player_id
      join public.match_players opp
        on opp.match_id = m.id and opp.player_id = p_opponent_id and opp.team <> mp.team
     where p_game_type is null or m.game_type = p_game_type
     order by m.played_at desc, m.id desc
     limit p_limit;
end;
$$;

revoke all on function
  public.head_to_head_match_ids(uuid, uuid, public.game_type, integer)
from public, anon, authenticated;

grant execute on function
  public.head_to_head_match_ids(uuid, uuid, public.game_type, integer)
to authenticated;

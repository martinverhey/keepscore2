-- The actual matches behind a head_to_head tally.
--
-- head_to_head returns the wins/losses/draws; the versus tab also wants the
-- matches themselves, which it gets from a query of their own rather than by
-- slicing a general "recent matches" page — a limited page of the feed may
-- simply not contain a match between these two players at all. The ordering
-- lives here in SQL, so the caller cannot get it wrong. Membership checks are
-- duplicated from head_to_head rather than shared, the way that function
-- already does it.

create or replace function public.head_to_head_match_ids(
  p_player_id   uuid,
  p_opponent_id uuid,
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
     order by m.played_at desc, m.id desc
     limit p_limit;
end;
$$;

revoke all on function public.head_to_head_match_ids(p_player_id uuid, p_opponent_id uuid, p_limit integer) from public, anon, authenticated;
grant execute on function public.head_to_head_match_ids(p_player_id uuid, p_opponent_id uuid, p_limit integer) to authenticated;

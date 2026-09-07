-- KeepScore 2 — the two bragging-rights scorelines behind a head-to-head tally.
--
-- head_to_head (20260819100000_remove_game_type_tracks.sql) returned the
-- win/loss/draw counts alone. The Versus tab also names the win with the
-- largest margin ("Biggest humiliation"), the highest win in which the
-- opponent scored nothing at all ("Ultimate disrespect") and how many of
-- those shutouts there have been ("Total disrespects"), so all three are
-- answered by the same round trip rather than by a second RPC.
--
-- biggest_win_score / biggest_win_opponent_score are NULL together when the
-- player has never beaten the opponent, and biggest_shutout_score is NULL
-- until one of those wins was a shutout; every membership check is unchanged.

drop function if exists public.head_to_head(uuid, uuid);

create function public.head_to_head(p_player_id uuid, p_opponent_id uuid)
returns table (
  wins                        integer,
  losses                      integer,
  draws                       integer,
  biggest_win_score           integer,
  biggest_win_opponent_score  integer,
  biggest_shutout_score       integer,
  shutout_wins                integer
)
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
    with duel as (
      select
        mp.outcome as outcome,
        m.played_at as played_at,
        m.id as match_id,
        case when mp.team = 'a' then m.team_a_score else m.team_b_score end as own_score,
        case when mp.team = 'a' then m.team_b_score else m.team_a_score end as other_score
        from public.matches m
        join public.match_players mp
          on mp.match_id = m.id and mp.player_id = p_player_id
        join public.match_players opp
          on opp.match_id = m.id and opp.player_id = p_opponent_id and opp.team <> mp.team
    ),
    best as (
      select d.own_score, d.other_score
        from duel d
       where d.outcome = 'win'
       order by d.own_score - d.other_score desc, d.own_score desc,
                d.played_at desc, d.match_id desc
       limit 1
    )
    select
      count(*) filter (where duel.outcome = 'win')::integer,
      count(*) filter (where duel.outcome = 'loss')::integer,
      count(*) filter (where duel.outcome = 'draw')::integer,
      (select best.own_score from best),
      (select best.other_score from best),
      max(duel.own_score) filter (
        where duel.outcome = 'win' and duel.other_score = 0
      )::integer,
      count(*) filter (
        where duel.outcome = 'win' and duel.other_score = 0
      )::integer
      from duel;
end;
$$;

revoke all on function public.head_to_head(uuid, uuid) from public, anon, authenticated;
grant execute on function public.head_to_head(uuid, uuid) to authenticated;

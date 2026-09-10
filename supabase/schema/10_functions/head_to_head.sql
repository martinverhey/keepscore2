-- head_to_head / player_streak

create or replace function public.head_to_head(p_player_id uuid, p_opponent_id uuid)
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

revoke all on function public.head_to_head(p_player_id uuid, p_opponent_id uuid) from public, anon, authenticated;
grant execute on function public.head_to_head(p_player_id uuid, p_opponent_id uuid) to authenticated;

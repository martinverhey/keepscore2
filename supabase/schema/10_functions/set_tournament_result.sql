-- set_tournament_result — score one bracket slot and advance the winner.
--
-- Draws are refused whatever competitions.allow_draws says: a bracket slot has
-- to produce somebody to put in the next round. Correcting a score is allowed,
-- but only while it cannot orphan the bracket -- flipping a winner whose
-- follow-up match has already been played is refused, since the player standing
-- in that later match would no longer be the one who earned the place.

create or replace function public.set_tournament_result(
  p_tournament_match_id uuid,
  p_score_a             integer,
  p_score_b             integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_match      public.tournament_matches;
  v_tournament public.tournaments;
  v_rounds     integer;
  v_winner     uuid;
  v_parent     public.tournament_matches;
begin
  select * into v_match
    from public.tournament_matches where id = p_tournament_match_id;
  if not found then
    raise exception 'Tournament match not found' using errcode = 'P0001';
  end if;

  select * into strict v_tournament
    from public.tournaments where id = v_match.tournament_id;

  if not public.is_registered() then
    raise exception 'Create an account to enter a tournament score' using errcode = 'P0001';
  end if;
  if not public.is_member(v_tournament.competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  if v_match.player_a_id is null or v_match.player_b_id is null then
    raise exception 'This match is still waiting for both players'
      using errcode = 'P0001';
  end if;

  if p_score_a < 0 or p_score_b < 0 then
    raise exception 'Scores cannot be negative' using errcode = 'P0001';
  end if;

  if p_score_a = p_score_b then
    raise exception 'A tournament match needs a winner' using errcode = 'P0001';
  end if;

  v_winner := case when p_score_a > p_score_b
                   then v_match.player_a_id else v_match.player_b_id end;

  select * into v_parent
    from public.tournament_matches
   where tournament_id = v_match.tournament_id
     and round = v_match.round + 1
     and slot = v_match.slot / 2;

  if v_parent.id is not null
     and v_parent.winner_player_id is not null
     and v_match.winner_player_id is distinct from v_winner then
    raise exception 'The next match has already been played'
      using errcode = 'P0001';
  end if;

  update public.tournament_matches
     set score_a          = p_score_a,
         score_b          = p_score_b,
         winner_player_id = v_winner,
         played_at        = now()
   where id = p_tournament_match_id;

  if v_parent.id is not null then
    update public.tournament_matches
       set player_a_id = case when v_match.slot % 2 = 0
                              then v_winner else player_a_id end,
           player_b_id = case when v_match.slot % 2 = 1
                              then v_winner else player_b_id end
     where id = v_parent.id;
    return;
  end if;

  select max(round) into v_rounds
    from public.tournament_matches
   where tournament_id = v_match.tournament_id;

  if v_match.round = v_rounds then
    update public.tournaments
       set status           = 'completed',
           winner_player_id = v_winner,
           completed_at     = now()
     where id = v_tournament.id;
  end if;
end;
$$;

revoke all on function public.set_tournament_result(p_tournament_match_id uuid, p_score_a integer, p_score_b integer) from public, anon, authenticated;
grant execute on function public.set_tournament_result(p_tournament_match_id uuid, p_score_a integer, p_score_b integer) to authenticated;

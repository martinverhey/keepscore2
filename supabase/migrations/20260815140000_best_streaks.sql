-- KeepScore 2 — best win/loss streaks, all-time across seasons.
--
-- player_streak only looks at the current season and stops at the first
-- non-matching outcome walking backward from the latest match — it answers
-- "am I on a streak right now". This answers a different question: the
-- longest run of consecutive wins, and the longest run of consecutive
-- losses, the player has ever put together in this competition, scanning
-- every match chronologically regardless of which season it landed in
-- (seasons hard-reset ratings, not the historical fact of who won). Both
-- maxima come out of a single pass over the same outcome sequence, so one
-- function returns both rather than scanning twice. Same optional
-- game-type filter as player_streak, same membership check.

create function public.player_best_streaks(
  p_player_id  uuid,
  p_game_type  public.game_type default null
)
returns table (best_win_streak integer, best_loss_streak integer)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_competition_id  uuid;
  v_best_win        integer := 0;
  v_best_loss       integer := 0;
  v_current_win     integer := 0;
  v_current_loss    integer := 0;
  rec               record;
begin
  select competition_id into v_competition_id
    from public.players where id = p_player_id;
  if v_competition_id is null then
    raise exception 'Player not found' using errcode = 'P0001';
  end if;

  if not public.is_member(v_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  for rec in
    select mp.outcome
      from public.match_players mp
      join public.matches m on m.id = mp.match_id
     where mp.player_id = p_player_id
       and (p_game_type is null or m.game_type = p_game_type)
     order by m.played_at asc, m.id asc
  loop
    if rec.outcome = 'win' then
      v_current_win := v_current_win + 1;
      v_current_loss := 0;
      if v_current_win > v_best_win then
        v_best_win := v_current_win;
      end if;
    elsif rec.outcome = 'loss' then
      v_current_loss := v_current_loss + 1;
      v_current_win := 0;
      if v_current_loss > v_best_loss then
        v_best_loss := v_current_loss;
      end if;
    else
      v_current_win := 0;
      v_current_loss := 0;
    end if;
  end loop;

  best_win_streak := v_best_win;
  best_loss_streak := v_best_loss;
  return next;
end;
$$;

revoke all on function public.player_best_streaks(uuid, public.game_type)
  from public, anon, authenticated;
grant execute on function public.player_best_streaks(uuid, public.game_type)
  to authenticated;

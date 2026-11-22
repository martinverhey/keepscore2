-- KeepScore 2 — best rating a player has ever held, all seasons combined.
--
-- Read from match_players, not player_ratings: player_ratings.rating is only
-- each season's *current* total, so a max over it misses every peak reached
-- mid-season and, in the season you are in, simply returns today's rating.
-- Every match records the rating going in and coming out, so the max over
-- both is every value the player actually held — rating_before included, so
-- a season's starting rating counts even for a player who has only lost.

create or replace function public.player_best_rating(
  p_player_id  uuid
)
returns numeric
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_competition_id uuid;
  v_best           numeric;
begin
  select competition_id into v_competition_id
    from public.players where id = p_player_id;
  if v_competition_id is null then
    raise exception 'Player not found' using errcode = 'P0001';
  end if;

  if not public.is_member(v_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  select max(greatest(mp.rating_before, mp.rating_after)) into v_best
    from public.match_players mp
   where mp.player_id = p_player_id;

  return coalesce(v_best, 0);
end;
$$;

revoke all on function public.player_best_rating(p_player_id uuid) from public, anon, authenticated;
grant execute on function public.player_best_rating(p_player_id uuid) to authenticated;

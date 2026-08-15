-- KeepScore 2 — best rating a player has ever held, all seasons combined.
--
-- Added for the profile sheet's Overview tab: it used to derive this by
-- fetching every finished season's standing and folding max(rating) over
-- them client-side, just to show one number. player_ratings.rating is
-- already live-updated on every match (not just at season close), so
-- max(rating) across a player's player_ratings rows already covers the
-- current in-progress season too — no need to also look at the live
-- leaderboard fetch the way the client-side fold used to. This lets the
-- Overview tab stop depending on the season-history list entirely.

create function public.player_best_rating(
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

  if p_game_type is null then
    select max(rating) into v_best
      from public.player_ratings
     where player_id = p_player_id;
  else
    select max(rating) into v_best
      from public.player_game_type_ratings
     where player_id = p_player_id and game_type = p_game_type;
  end if;

  return coalesce(v_best, 0);
end;
$$;

revoke all on function public.player_best_rating(uuid, public.game_type)
  from public, anon, authenticated;
grant execute on function public.player_best_rating(uuid, public.game_type)
  to authenticated;

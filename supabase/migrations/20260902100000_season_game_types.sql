-- KeepScore 2 — which game types have actually been played this season.
--
-- The Matches filter offers every game type the enum has, including ones
-- nobody in this competition has ever played. This answers the narrower
-- question the filter really wants: what is there to filter by right now.
--
-- Scoped by the season window rather than by matches.season_id, so it is
-- correct before the current season's first match exists (season_window
-- returns the computed bounds with a null season_id in that case).

create function public.season_game_types(p_competition_id uuid)
returns table (game_type public.game_type)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_window record;
begin
  if not public.is_member(p_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  select * into v_window from public.season_window(p_competition_id);

  return query
    select distinct m.game_type
      from public.matches m
     where m.competition_id = p_competition_id
       and m.played_at >= v_window.season_starts_at
       and m.played_at <  v_window.season_ends_at;
end;
$$;

revoke all on function public.season_game_types(uuid)
  from public, anon, authenticated;
grant execute on function public.season_game_types(uuid) to authenticated;

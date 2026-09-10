-- Rebuilds a season from its matches. This is the source of truth for
-- correctness after any edit or delete — cheaper to replay a season than to
-- invert an Elo chain.

create or replace function public.recalc_season(p_season_id uuid)
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_match_id uuid;
begin
  delete from public.player_ratings where season_id = p_season_id;

  for v_match_id in
    select id from public.matches
     where season_id = p_season_id
     order by played_at, id
  loop
    perform public.apply_match_ratings(v_match_id);
  end loop;
end;
$$;

revoke all on function public.recalc_season(p_season_id uuid) from public, anon, authenticated;

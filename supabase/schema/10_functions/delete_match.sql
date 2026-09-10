-- delete_match — boundary is the deleted match's own (now-vacated) position.

create or replace function public.delete_match(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_match public.matches;
begin
  select * into v_match from public.matches where id = p_match_id;
  if not found then
    raise exception 'Match not found' using errcode = 'P0001';
  end if;

  if not public.is_registered()
     or not (v_match.created_by = auth.uid()
             or public.is_owner(v_match.competition_id)) then
    raise exception 'Only the person who logged this match, or the competition owner, can remove it'
      using errcode = 'P0001';
  end if;

  delete from public.matches where id = p_match_id;

  perform public.recalc_season_from(
    v_match.season_id, v_match.played_at, v_match.id
  );
end;
$$;

revoke all on function public.delete_match(p_match_id uuid) from public, anon, authenticated;
grant execute on function public.delete_match(p_match_id uuid) to authenticated;

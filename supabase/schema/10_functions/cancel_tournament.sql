-- cancel_tournament — the way out of a bracket nobody finished. Without it an
-- abandoned tournament stays pinned to the Matches page forever, since the
-- partial unique index refuses a second active one.

create or replace function public.cancel_tournament(p_tournament_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tournament public.tournaments;
begin
  select * into v_tournament
    from public.tournaments where id = p_tournament_id;
  if not found then
    raise exception 'Tournament not found' using errcode = 'P0001';
  end if;

  if not public.is_registered()
     or not (v_tournament.created_by = auth.uid()
             or public.is_owner(v_tournament.competition_id)) then
    raise exception 'Only the person who started this tournament, or the competition owner, can cancel it'
      using errcode = 'P0001';
  end if;

  delete from public.tournaments where id = p_tournament_id;
end;
$$;

revoke all on function public.cancel_tournament(p_tournament_id uuid) from public, anon, authenticated;
grant execute on function public.cancel_tournament(p_tournament_id uuid) to authenticated;

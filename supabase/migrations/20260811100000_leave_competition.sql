-- leave_competition — a member unclaims and deactivates their own player row.
--
-- players.user_id is deliberately excluded from the client column-grant (see
-- 0003_rls.sql) and there is no delete policy on players, so this has to be a
-- security definer function, mirroring join_competition's claim logic in
-- reverse. No is_registered() gate: guests can join without one, so they must
-- be able to leave without one too.

create or replace function public.leave_competition(p_competition_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_owner_id uuid;
  v_player_id uuid;
begin
  select owner_id into v_owner_id
    from public.competitions where id = p_competition_id;
  if not found then
    raise exception 'Competition not found' using errcode = 'P0001';
  end if;

  if v_owner_id = auth.uid() then
    raise exception 'The competition owner cannot leave — delete the competition instead'
      using errcode = 'P0001';
  end if;

  select id into v_player_id from public.players
    where competition_id = p_competition_id and user_id = auth.uid();
  if not found then
    raise exception 'You are not a member of this competition' using errcode = 'P0001';
  end if;

  update public.players set user_id = null, is_active = false
    where id = v_player_id;
end;
$$;

revoke all on function public.leave_competition(uuid) from public, anon, authenticated;
grant execute on function public.leave_competition(uuid) to authenticated;

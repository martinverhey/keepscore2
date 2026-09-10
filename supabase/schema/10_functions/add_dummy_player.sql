create or replace function public.add_dummy_player(p_competition_id uuid, p_display_name text)
returns public.players
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_player public.players;
  v_name   text;
begin
  if not public.is_registered() then
    raise exception 'Create an account to add players' using errcode = 'P0001';
  end if;
  if not public.is_owner(p_competition_id) then
    raise exception 'Only the competition owner can add players'
      using errcode = 'P0001';
  end if;

  v_name := btrim(p_display_name);

  if exists (
    select 1 from public.players p
     where p.competition_id = p_competition_id
       and lower(btrim(p.display_name)) = lower(v_name)
  ) then
    raise exception 'A player named "%" already exists in this competition', v_name
      using errcode = 'P0001';
  end if;

  insert into public.players (competition_id, display_name, user_id)
  values (p_competition_id, v_name, null)
  returning * into v_player;

  return v_player;
end;
$$;

revoke all on function public.add_dummy_player(p_competition_id uuid, p_display_name text) from public, anon, authenticated;
grant execute on function public.add_dummy_player(p_competition_id uuid, p_display_name text) to authenticated;

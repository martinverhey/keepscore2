create or replace function public.create_competition(
  p_name          text,
  p_season_length public.season_length default 'monthly',
  p_timezone      text default 'Europe/Amsterdam',
  p_display_name  text default null
)
returns public.competitions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_comp public.competitions;
  v_name text;
begin
  if not public.is_registered() then
    raise exception 'Create an account to start a competition'
      using errcode = 'P0001';
  end if;

  insert into public.competitions (join_code, name, owner_id, season_length, timezone)
  values (public.generate_join_code(), btrim(p_name), auth.uid(), p_season_length, p_timezone)
  returning * into v_comp;

  select coalesce(nullif(btrim(p_display_name), ''), p.display_name)
    into v_name
    from public.profiles p where p.id = auth.uid();

  -- The owner is a player in their own competition.
  insert into public.players (competition_id, display_name, user_id)
  values (v_comp.id, coalesce(v_name, 'Player'), auth.uid());

  return v_comp;
end;
$$;

revoke all on function public.create_competition(p_name text, p_season_length season_length, p_timezone text, p_display_name text) from public, anon, authenticated;
grant execute on function public.create_competition(p_name text, p_season_length season_length, p_timezone text, p_display_name text) to authenticated;

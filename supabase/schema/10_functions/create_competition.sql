create or replace function public.create_competition(
  p_name          text,
  p_season_length public.season_length default 'quarterly',
  p_timezone      text default 'Europe/Amsterdam',
  p_display_name  text default null,
  p_k_factor      integer default 60,
  p_mov_enabled   boolean default true,
  p_mov_cap       numeric default 10,
  p_shutout_bonus boolean default true,
  p_shutout_multiplier numeric default 2
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

  insert into public.competitions
    (join_code, name, owner_id, season_length, timezone, k_factor, mov_enabled, mov_cap,
     shutout_bonus, shutout_multiplier)
  values
    (public.generate_join_code(), btrim(p_name), auth.uid(), p_season_length, p_timezone,
     p_k_factor, p_mov_enabled, p_mov_cap, p_shutout_bonus, p_shutout_multiplier)
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

revoke all on function public.create_competition(p_name text, p_season_length season_length, p_timezone text, p_display_name text, p_k_factor integer, p_mov_enabled boolean, p_mov_cap numeric, p_shutout_bonus boolean, p_shutout_multiplier numeric) from public, anon, authenticated;
grant execute on function public.create_competition(p_name text, p_season_length season_length, p_timezone text, p_display_name text, p_k_factor integer, p_mov_enabled boolean, p_mov_cap numeric, p_shutout_bonus boolean, p_shutout_multiplier numeric) to authenticated;

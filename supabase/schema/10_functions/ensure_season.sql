create or replace function public.ensure_season(p_competition_id uuid, p_at timestamptz)
returns uuid
language plpgsql
set search_path = ''
as $$
declare
  v_comp   public.competitions;
  v_bounds record;
  v_id     uuid;
begin
  select * into v_comp from public.competitions where id = p_competition_id;
  if not found then
    raise exception 'Competition not found' using errcode = 'P0001';
  end if;

  select * into v_bounds
    from public.season_bounds(p_at, v_comp.season_length, v_comp.timezone);

  select id into v_id
    from public.seasons
   where competition_id = p_competition_id
     and starts_at = v_bounds.starts_at;

  if v_id is null then
    insert into public.seasons (competition_id, starts_at, ends_at)
    values (p_competition_id, v_bounds.starts_at, v_bounds.ends_at)
    on conflict (competition_id, starts_at) do update
      set ends_at = excluded.ends_at
    returning id into v_id;
  end if;

  return v_id;
end;
$$;

revoke all on function public.ensure_season(p_competition_id uuid, p_at timestamp with time zone) from public, anon, authenticated;

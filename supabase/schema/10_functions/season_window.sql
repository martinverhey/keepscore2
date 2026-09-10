-- Current season lookup
-- The season row only exists once a match has been played in it, so the app
-- needs the computed window even when season_id comes back NULL.

create or replace function public.season_window(
  p_competition_id uuid,
  p_at             timestamptz default now()
)
returns table (
  season_id         uuid,
  season_starts_at  timestamptz,
  season_ends_at    timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_comp   public.competitions;
  v_bounds record;
begin
  if not public.is_member(p_competition_id) then
    raise exception 'You are not in this competition' using errcode = 'P0001';
  end if;

  select * into strict v_comp
    from public.competitions where id = p_competition_id;

  select * into v_bounds
    from public.season_bounds(p_at, v_comp.season_length, v_comp.timezone);

  season_starts_at := v_bounds.starts_at;
  season_ends_at   := v_bounds.ends_at;

  select s.id into season_id
    from public.seasons s
   where s.competition_id = p_competition_id
     and s.starts_at = v_bounds.starts_at;

  return next;
end;
$$;

revoke all on function public.season_window(p_competition_id uuid, p_at timestamp with time zone) from public, anon, authenticated;
grant execute on function public.season_window(p_competition_id uuid, p_at timestamp with time zone) to authenticated;

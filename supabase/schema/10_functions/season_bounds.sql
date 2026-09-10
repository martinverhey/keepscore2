-- Seasons

create or replace function public.season_bounds(
  p_at       timestamptz,
  p_length   public.season_length,
  p_timezone text
)
returns table (starts_at timestamptz, ends_at timestamptz)
language plpgsql
stable
set search_path = ''
as $$
declare
  v_local       timestamp;
  v_unit        text;
  v_step        interval;
  v_start_local timestamp;
begin
  -- Seasons are calendar-aligned in the competition's own timezone, so
  -- "this month" means what the members think it means.
  v_local := p_at at time zone p_timezone;

  v_unit := case p_length
    when 'monthly'   then 'month'
    when 'quarterly' then 'quarter'
    when 'yearly'    then 'year'
  end;

  -- date_trunc understands 'quarter'; the interval type does not.
  v_step := case p_length
    when 'monthly'   then interval '1 month'
    when 'quarterly' then interval '3 months'
    when 'yearly'    then interval '1 year'
  end;

  v_start_local := date_trunc(v_unit, v_local);

  starts_at := v_start_local at time zone p_timezone;
  ends_at   := (v_start_local + v_step) at time zone p_timezone;
  return next;
end;
$$;

revoke all on function public.season_bounds(p_at timestamp with time zone, p_length season_length, p_timezone text) from public, anon, authenticated;
grant execute on function public.season_bounds(p_at timestamp with time zone, p_length season_length, p_timezone text) to anon, authenticated;

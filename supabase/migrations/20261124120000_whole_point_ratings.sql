-- Moves every competition onto the whole-point rating rule in elo_delta
-- (supabase/schema/10_functions/elo_delta.sql), which must be applied first.
-- mov_cap changes meaning from a multiplier (1.0-5.0) to the most extra
-- points a margin can add, so every row is converted, not just the defaults,
-- and every season is replayed so stored ratings follow the new rule.

alter table public.competitions drop constraint competitions_mov_cap_check;

alter table public.competitions
  alter column k_factor set default 60,
  alter column mov_cap set default 10;

update public.competitions set k_factor = 60, mov_cap = 10;

alter table public.competitions
  add constraint competitions_mov_cap_check
  check (mov_cap >= 1 and mov_cap <= 50);

do $$
declare
  v_season_id uuid;
begin
  for v_season_id in select id from public.seasons loop
    perform public.recalc_season(v_season_id);
  end loop;
end;
$$;

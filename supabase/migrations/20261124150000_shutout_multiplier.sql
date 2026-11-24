-- Makes the shutout factor on the margin bonus configurable per competition
-- (shutout_bonus stays the on/off switch). Same mechanics as
-- 20261124140000_shutout_bonus: competition_overview selects c.*, and
-- elo_delta / create_competition gain a parameter, so all three are dropped
-- here and recreated by --apply-schema.

drop view public.competition_overview;

drop function public.elo_delta(numeric, numeric, integer, integer, integer, boolean, numeric, boolean);
drop function public.create_competition(text, public.season_length, text, text, integer, boolean, numeric, boolean);

alter table public.competitions
  add column shutout_multiplier numeric(4,2) not null default 2
  constraint competitions_shutout_multiplier_check
  check (shutout_multiplier >= 1 and shutout_multiplier <= 10);

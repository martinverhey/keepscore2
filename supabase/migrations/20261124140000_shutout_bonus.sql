-- Makes the shutout doubling of the margin bonus a per-competition setting,
-- and makes quarterly the default season length.
--
-- competition_overview selects c.*, so a new competitions column would land
-- in the middle of the view's column list, which create or replace refuses;
-- it is dropped here and recreated by --apply-schema. elo_delta and
-- create_competition gain a parameter, which is a new overload rather than a
-- replacement, so the old signatures are dropped too.

drop view public.competition_overview;

drop function public.elo_delta(numeric, numeric, integer, integer, integer, boolean, numeric);
drop function public.create_competition(text, public.season_length, text, text, integer, boolean, numeric);

alter table public.competitions
  add column shutout_bonus boolean not null default true;

alter table public.competitions
  alter column season_length set default 'quarterly';

-- Draws are always allowed: the per-competition allow_draws switch goes.
--
-- competition_overview selects c.*, so it is dropped here and recreated
-- without the column by --apply-schema.

drop view public.competition_overview;

alter table public.competitions
  drop column allow_draws;

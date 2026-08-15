-- KeepScore 2 — a cheap list of a competition's finished seasons.
--
-- SeasonHistoryPage (the competition-wide season history screen) used to
-- fetch season_history unfiltered by season_id — every finished season ×
-- every player, in one response, every time the page opened — even though
-- SeasonSheet only ever displays one season's standings at a time. As a
-- competition ages (seasons hard-reset on a calendar cadence) that grows
-- without bound. This view lets the client fetch just the season list
-- (O(seasons), off the seasons table's own index) up front, then fetch one
-- season's standings via season_history's existing season_id filter only
-- when it's actually selected.
--
-- "Finished" mirrors season_history's own ends_at <= now() boundary exactly,
-- computed server-side rather than against the client's clock.

create view public.finished_seasons
with (security_invoker = true) as
select
  id as season_id,
  competition_id,
  starts_at,
  ends_at
from public.seasons
where ends_at <= now();

grant select on public.finished_seasons to authenticated;

-- Runs first on every --apply-schema.
--
-- check_function_bodies = off stops Postgres resolving identifiers inside a
-- function body at CREATE time, which is what makes the rest of this directory
-- order-independent: create_match may reference recalc_season_from before that
-- file has been read, and the two SQL-language helpers may reference tables the
-- baseline owns. Views still need real ordering, and carry a numeric prefix for
-- it — leaderboard_base before leaderboard, season_history before player_medals.
--
-- Turning it off does not weaken anything at run time: a body that references
-- something missing still fails on first execution. It only moves the check.

set check_function_bodies = off;

-- Hard backstop for the uniqueness check added in 0009: a case- and
-- whitespace-insensitive unique index on (competition_id, display_name).
-- join_competition and add_dummy_player already raise a friendly P0001
-- before hitting this; a violation here means two requests raced past that
-- check at once, which the client still turns into a ValidationFailure (see
-- guard() in core/error/failure.dart), just with Postgres's own wording
-- instead of ours.
--
-- Applied to a live project that had accumulated a handful of duplicate
-- names from earlier manual testing — cleaned up by hand (deleted inert
-- leftover test players with no match or rating history, renamed the one
-- real collision) immediately before this migration, so it is not repeated
-- here as a data migration.

create unique index players_competition_id_display_name_key
  on public.players (competition_id, lower(btrim(display_name)));

-- Base-table privileges. The tables themselves live in the baseline migration,
-- but their grants sit here so one --apply-schema restores the whole intended
-- privilege set rather than half of it.
--
-- Note what is deliberately absent: no revoke against anon. Supabase's own
-- default privileges hand anon and authenticated ALL on every newly created
-- table and view, so the eight views in 20_views/ currently carry INSERT,
-- UPDATE, DELETE and TRUNCATE for both roles. Nothing reaches data through
-- them — every view is security_invoker, so a read re-enters the base table's
-- RLS, and every policy is TO authenticated — and narrowing them is a
-- behaviour change, not part of this split.

-- The revokes undo Supabase's default privileges, which grant anon and
-- authenticated ALL on anything newly created. The migrations did this once as
-- "revoke all on all tables in schema public", which caught the seven tables
-- that existed that day and nothing since -- which is exactly why the views
-- above still carry the defaults. Naming the tables makes the result the same
-- whatever order this file runs in, and leaves the views alone deliberately.

revoke all on public.competitions   from anon, authenticated;
revoke all on public.players        from anon, authenticated;
revoke all on public.profiles       from anon, authenticated;
revoke all on public.matches        from anon, authenticated;
revoke all on public.match_players  from anon, authenticated;
revoke all on public.player_ratings from anon, authenticated;
revoke all on public.seasons        from anon, authenticated;
revoke all on public.tournaments        from anon, authenticated;
revoke all on public.tournament_matches from anon, authenticated;

grant select on public.competitions   to authenticated;
grant delete on public.competitions   to authenticated;
grant update (name, season_length, timezone, starting_rating, k_factor,
              mov_enabled, mov_cap, allow_draws) on public.competitions to authenticated;

grant select on public.players        to authenticated;
grant update (display_name, is_active) on public.players to authenticated;

grant select on public.profiles       to authenticated;
grant update (display_name, avatar_url) on public.profiles to authenticated;

grant select on public.matches        to authenticated;
grant select on public.match_players  to authenticated;
grant select on public.player_ratings to authenticated;
grant select on public.seasons        to authenticated;
grant select on public.tournaments        to authenticated;
grant select on public.tournament_matches to authenticated;

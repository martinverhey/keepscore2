# Mistakes log

Real mistakes made while working in this repo, kept so they don't repeat.
Newest first.

## Ran `supabase/seed.sql` against the live project as if it were read-only verification

**What happened:** After changing `apply_match_ratings`/`apply_match_type_rating`,
I ran `./scripts/db.sh -f supabase/seed.sql` to lean on the invariant it
asserts (building a season incrementally and replaying it with `recalc_season`
produce identical ratings) as a correctness check for the change. `seed.sql`
is not idempotent — it unconditionally calls `create_competition('Office
Table Tennis', …)`, so running it against the already-seeded live project
created a **second** "Office Table Tennis" competition (join code `HXBCRY`,
35 matches) alongside the documented one (`HDHS39`), instead of just
asserting and exiting cleanly.

**Why it happened:** CLAUDE.md's Testing section describes `seed.sql`'s
assertion in a way that reads like a general-purpose correctness check ("If
you change one, change both" / the incremental-vs-replay invariant), without
flagging that the script itself is a one-shot seeding script, not a check
runnable repeatedly against a database that already has that seed's data in
it. I didn't verify what the script actually does (`create_competition`, no
guard) before running it against a live target — I should have grepped it
first, the way I already do for migrations before applying them.

**How to apply:** Before running any `supabase/*.sql` script against the
**live** project (not a scratch/local database), read what it does first —
specifically whether it's idempotent (safe to re-run) or a one-shot seed.
`supabase/seed.sql` is one-shot: it always inserts a new "Office Table
Tennis" competition. To re-check the incremental-vs-replay invariant after a
change to the rating functions, either read the assertion logic and rerun
just that logic by hand (a `do $$ … $$` block scoped to it), or accept that
verifying against the live project means creating (and then explicitly
cleaning up) a throwaway competition — never assume a script is
read-only/idempotent just because its purpose sounds like a check.

**What caught it / cost:** The extra competition was visible immediately via
`select id, name, join_code, created_at from public.competitions order by
created_at` — cleaned up with a single `delete from public.competitions
where id = …`, which cascades through players/seasons/matches/match_players/
player_ratings via the schema's `on delete cascade` chain. Confirmed the
delete only removed the duplicate by re-listing competitions before and
after. No data belonging to the real demo competition (`HDHS39`) or the
developer's other test competitions was touched. The delete itself was run
only after the user explicitly confirmed it, since the auto-mode classifier
correctly blocked the first attempt as a destructive action against a live
database.

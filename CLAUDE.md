# KeepScore 2

Flutter (iOS / Android / Web) + Supabase app for running competition ladders:
log 1v1–NvM matches, get an Elo leaderboard per season.

**Design reference (Elo formula, schema, architecture rationale):**
`.claude/plans/build-plan.md`

## Status

| Step | State |
|---|---|
| 1. Scaffold, theme, adaptive layer, l10n | Done |
| 2. Database (migrations + seed + RLS checks) | Done, applied to the live project |
| 3. Auth (email OTP, guest, upgrade, Apple/Google) | Done |
| 4. Competitions (list, create, join + claim) | Done |
| 5. Players (roster, add placeholders, owner settings, share code) | Done |
| 6. Matches (team builder, Elo preview, submit, list, edit, delete) | Done |
| 7. Leaderboard + seasons + realtime | Done |
| 8. Polish, Dutch copy pass, app icons | Done |

`/upgrade` turns a guest into a real account in place: same `SignInCubit`, built
with `SignInMode.upgrade`, which routes the two email steps to
`upgradeGuestWithEmail` / `verifyUpgradeCode` (Supabase `updateUser` + an
`emailChange` OTP) instead of a fresh sign-in. Every place that refuses a guest
renders `GuestNotice`, which carries the refusal *and* the way out; the page pops
itself when `AuthBloc` reports the user is no longer anonymous.

`/competition/:id` is the tab shell (`features/competition/.../competition_detail_page.dart`):
Leaderboard (default), Matches, Players. The leaderboard tab carries the season
switcher; the season list is `seasons` plus, stitched in front of it, the
current calendar window — which has no row until the first match lands in it.

`/competition/:id/match/new` builds the teams and submits; `/competition/:id/match/:matchId` shows
the per-player before → after and lets the creator or the owner change the
score or delete the match. Both are pushed on top of the shell, so they build
their own cubits; the shell reloads its list and overview whenever one of them
pops.

## Product decisions (already settled — do not relitigate)

- **Two teams per match**, arbitrary sizes each side.
- **Team rating = mean of members**; every member takes the same delta. Zero-sum.
- **Margin of victory is ON**, with an autocorrelation damper and a cap.
  `k_factor` / `mov_enabled` / `mov_cap` are per-competition columns so it can
  be tuned or disabled without a migration.
- **Seasons hard-reset** everyone to `starting_rating` (1000). Calendar-aligned
  monthly / quarterly / yearly in the competition's timezone.
- **Draws allowed**, scored 0.5.
- **No match confirmation** — a submitted result counts immediately.
- **Edits/deletes replay the season** via `recalc_season`.
- **Auth**: Apple, Google, email OTP code. No passwords.
- **Guests** (Supabase anonymous) may join a competition and read it. They may
  not create competitions, add players, or log matches. Enforced in Postgres.
- Online only. English + Dutch. Cupertino on iOS/macOS, Material 3 elsewhere.

## Architecture

```
lib/
  app/          router (+ auth redirect), DI, app shell, splash screen
  core/         config, error, theme, widgets/adaptive, widgets/state_views
  features/<name>/
    domain/     entities + abstract repository
    data/       Supabase-backed repository implementation
    presentation/ cubit/ (state) + pages + widgets
  l10n/         app_en.arb, app_nl.arb (+ generated app_localizations*.dart)
```

Coding conventions (no comments, no freezed, cubit/state file layout,
adaptive widgets, error handling, l10n, DI registration, realtime, RLS) live
in the `guidelines` skill (`.claude/skills/guidelines/SKILL.md`), not here —
load it before writing or reviewing `lib/**` or `supabase/**` code.

## Commands

```bash
flutter analyze                 # must stay clean
flutter test                    # 110 tests at time of writing
flutter gen-l10n                # after editing any .arb

python3 scripts/generate_icon.py   # redraw assets/icon/*.png
dart run flutter_launcher_icons     # then push them into ios/ android/ web/
flutter run -d chrome           # web
flutter build web --no-tree-shake-icons
flutter build apk --debug        # verified green

./scripts/db.sh -c "select 1"                 # ad-hoc SQL
./scripts/db.sh -f supabase/migrations/X.sql  # apply a migration
./scripts/db.sh -f supabase/seed.sql          # reseed + run assertions
./scripts/db.sh -f supabase/tests/rls_check.sql      # RLS verification, rolls back
./scripts/db.sh -f supabase/tests/players_check.sql  # roster + settings writes
```

## Database workflow — read this before touching SQL

`supabase link` needs a Management API access token we do not have, so
**migrations are applied with `psql` via `scripts/db.sh`, not `supabase db
push`.** The script reads `SUPABASE_PROJECT_REF` and `SUPABASE_DB_PASSWORD`
from the project-root `.env`.

- The project's direct DB host is **IPv6-only**; the `aws-0`/`aws-1` poolers
  reject this tenant. `scripts/db.sh` already targets the right host.
- After applying a migration by hand, record it:
  `insert into supabase_migrations.schema_migrations (version, name) values (…)`
  so a future `supabase db push` picks up cleanly.
- **Re-applying a `create or replace function` drops its grants.** Always
  re-issue `grant execute on function … to authenticated` afterwards.

SQL gotchas (OUT-parameter shadowing, enum casts in `UNION`, PostgREST's
`""` → `NULL` coercion) live in the `guidelines` skill, alongside the Dart
conventions.

### Two `.env` files — do not confuse them

- `assets/.env` — **bundled into the app**, readable by anyone, and **tracked
  in git on purpose**. Client config only (`SUPABASE_URL`,
  `SUPABASE_PUBLISHABLE_KEY`, the `AUTH_*` flags) — safe to ship, since RLS is
  what protects the data, not this key. `Env.load()` throws in debug if a
  password/secret/token key ever appears here, so a real secret can't land in
  it by accident.
- `.env` (project root) — tooling secrets (`SUPABASE_DB_PASSWORD`). Gitignored,
  never bundled, no template committed.

## Testing

- `EloCalculator` (Dart) mirrors `public.elo_delta` (SQL). **The same fixture
  values are asserted in both** — `test/features/match/elo_calculator_test.dart`
  and `supabase/seed.sql`. If you change one, change both.
- `supabase/seed.sql` asserts that building a season incrementally and replaying
  it with `recalc_season` produce identical ratings. That invariant is what
  makes edits and deletes safe.
- `supabase/tests/rls_check.sql` runs as `authenticated` inside a rolled-back
  transaction and proves outsiders see nothing and direct writes are refused.
  It caught nothing that the seed did, because the seed runs as `postgres` —
  **server-side assertions do not exercise the client path.** Verify RPCs over
  REST with a real token as well.
- **The guest → account upgrade is the one flow still unverified server-side.**
  It cannot be checked the way the RPCs were: `verifyUpgradeCode` needs a token
  that only arrives by email. Seeding `auth.users.email_change_token_new` by
  hand and calling `/auth/v1/verify` does not work — GoTrue rejected the raw
  value via both `token_hash` and `email`+`token`, and rejected sha224 and
  sha256 of `email+otp` too, always as `otp_expired`. Minting a real token needs
  `admin/generate_link`, which needs a service-role key that is not in `.env`.
  So it is either that key, or a real send to a readable inbox.
- The step 6 RPCs were checked that way against the live project: sign in
  anonymously over `/auth/v1/signup`, flip `auth.users.is_anonymous` to false,
  refresh the token, then call `join_competition` → `create_match` →
  `update_match_score` → `delete_match`. It confirms the part psql cannot:
  `uuid[]` parameters coerce from a JSON array, and a guest's `create_match`
  fails with our own `P0001` message rather than a PostgREST signature error.
  Snapshot `md5(string_agg(player_id||rating))` over `player_ratings` before
  and after — deleting the probe match must restore it exactly.
- Realtime was verified the same way, with a throwaway `dart run` script using
  the `supabase` package (`client.realtime.setAuth(token)`, then
  `onPostgresChanges` on `player_ratings` filtered by `season_id` and on
  `matches` filtered by `competition_id`). Both channels deliver to a member
  through RLS. `flutter test` cannot cover this: the cubits are tested against
  a `StreamController`, which proves the debounce and the refetch but says
  nothing about whether the server actually publishes.

## Live project

- Ref `ycyydncwwoxmcxibyeuk`. Seeded demo competition **"Office Table Tennis"**,
  join code **HDHS39**, 5 players, 11 matches, 3 unclaimed placeholders.
- Anonymous sign-ins: enabled. Apple/Google: **not** configured, so those
  buttons stay hidden behind `AUTH_APPLE_ENABLED` / `AUTH_GOOGLE_ENABLED`.

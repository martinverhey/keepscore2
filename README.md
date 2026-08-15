# KeepScore 2

Create your own competition ladder — create matches, get an Elo leaderboard.

A Flutter (iOS / Android / Web) + Supabase app for tracking 1v1–NvM matches
within a competition ("Office Table Tennis", a running D&D group, whatever)
and ranking players with Elo, per season.

## Features

- **Competitions** — create one, share a join code, invite players.
- **Players** — a roster per competition, including placeholders for people
  who haven't claimed an account yet.
- **Matches** — build two teams of any size, get a live Elo preview, submit.
  Edit or delete afterwards; the season is transparently replayed.
- **Leaderboard** — Elo per competition, with a combined track and a separate
  track per game type (1v1 / 2v2 / 3v3 / 4v4 / mixed).
- **Seasons** — calendar-aligned (monthly / quarterly / yearly), hard reset,
  with a history view of past seasons, medals, and streaks.
- **Auth** — Apple, Google, or email OTP. Guests (anonymous accounts) can join
  and read a competition, then upgrade to a real account in place without
  losing anything.
- Online only. English + Dutch. Cupertino on iOS/macOS, Material 3 elsewhere.

## Design

The Elo formula (with margin-of-victory), database schema, and architecture
rationale are written up in
[`.claude/plans/build-plan.md`](.claude/plans/build-plan.md). Product
decisions that are already settled — team ratings, season resets, guest
restrictions, no match confirmation — are recorded in
[`CLAUDE.md`](CLAUDE.md) along with the full coding conventions.

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

Features: `auth`, `competition`, `player`, `match`, `leaderboard`, `profile`,
`settings`.

## Getting started

### Prerequisites

- Flutter (Dart SDK `^3.10.7`)
- A Supabase project, with the schema in `supabase/migrations` applied
- `assets/.env` — client config (`SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`,
  the `AUTH_*` feature flags). This file is bundled into the app and safe to
  commit; RLS protects the data, not this key.
- `.env` (project root) — tooling secrets (`SUPABASE_DB_PASSWORD`,
  `SUPABASE_PROJECT_REF`) used by `scripts/db.sh` to reach the database
  directly. Gitignored, never bundled.

### Run it

```bash
flutter pub get
flutter run -d chrome     # or an attached iOS/Android device/simulator
```

## Development

```bash
flutter analyze                 # must stay clean
flutter test                    # runs the full suite
flutter gen-l10n                # after editing any .arb file

python3 scripts/generate_icon.py    # redraw assets/icon/*.png
dart run flutter_launcher_icons     # push icons into ios/ android/ web/

flutter build web --no-tree-shake-icons
flutter build apk --debug
```

### Database

Migrations are applied by hand with `psql` via `scripts/db.sh` (the project's
direct DB host is IPv6-only and `supabase db push` isn't wired up here).

```bash
./scripts/db.sh -c "select 1"                        # ad-hoc SQL
./scripts/db.sh -f supabase/migrations/<file>.sql     # apply a migration
./scripts/db.sh -f supabase/seed.sql                  # reseed + run assertions
./scripts/db.sh -f supabase/tests/rls_check.sql       # RLS verification, rolls back
./scripts/db.sh -f supabase/tests/players_check.sql   # roster + settings writes
```

See the "Database workflow" and "Testing" sections of `CLAUDE.md` for the
gotchas (grants, OUT-parameter shadowing, why RLS checks and the seed test
different things).

## Status

All planned steps — scaffold, database, auth, competitions, players,
matches, leaderboard/seasons, polish — are done. See the status table in
`CLAUDE.md` for detail.

## License

No license file yet — all rights reserved by default.

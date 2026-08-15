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

`/competition/:id` is the tab shell (`features/competition/.../competition_detail.page.dart`):
Leaderboard (default), Matches, Players. The leaderboard tab always shows the
current calendar window — which has no row until the first match lands in it —
and carries a game-type filter (`GameTypeFilterDropdown`, next to the title in
the scaffold's `trailing`) — combined (default) or one of
`1v1`/`2v2`/`3v3`/`4v4`/`mixed`. It has no season picker: that moved to
`/competition/:id/settings/history` (`SeasonHistoryPage`), which shows one
finished season at a time — `SeasonSheet` picks among `SeasonHistoryState.groups`
(the already-loaded, already-finished seasons; no separate fetch) — and
carries its own, independent `GameTypeFilterDropdown`, same placement.

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

## Coding conventions — read this before writing `lib/**`

These are the conventions the codebase already follows. Match them in new
code; don't relitigate them.

- **No comments. The default is none, and `lib/**` and `test/**` currently
  contain zero.** This is a strong, explicit user preference — do not "helpfully"
  reintroduce them, and strip any you find while editing a file.
  - **Doc comments (`///`) count as comments**, including on public APIs,
    repository methods, cubit states and domain models. So do section banners,
    `// TODO`, and commented-out code.
  - Naming and structure carry the explanation. If a line seems to need a
    comment, that is a signal to rename something or extract a well-named
    helper instead.
  - The bar for the rare exception is *absolute necessity*: something the code
    genuinely cannot express, such as a non-obvious external constraint or a
    workaround whose removal would silently break behaviour. Prefer capturing
    that here in `CLAUDE.md` over putting it in the source.
  - Analyzer directives (`// ignore:`, `// ignore_for_file:`) are not comments
    in this sense — they are functional and may stay.
- **No freezed, no build_runner, no json_serializable.** Plain classes with
  `Equatable` and hand-written `fromMap`. (Explicit user preference.)
- **No usecase layer.** Blocs call repositories directly.
- **One class or enum per file.** This applies to Cubit states and to domain
  enums/models alike:
  - **Every Cubit's state lives in its own `<name>_state.dart` file**, next to
    `<name>_cubit.dart` (e.g. `players_cubit.dart` / `players_state.dart`).
    The state file holds the state class, its companion status enum(s), and
    any private helper used only by the state (e.g. a `copyWith`-adjacent
    formatter). This applies to Cubits. `AuthBloc` is a `Bloc` (state *and*
    events tightly coupled, one small file) and stays as-is.
  - **Domain enums and secondary models get their own file too**, out of
    whichever file originally bundled them (e.g. `match_team.enum.dart` and
    `match_participant.model.dart` came out of `match_entry.model.dart`;
    `season_length.enum.dart` and `competition_overview.model.dart` came out
    of `competition.model.dart`). A private helper used by more than one of
    the split files (e.g. a `_toDouble` map coercion) is duplicated into each
    file that needs it rather than shared — matching how the codebase already
    handled this before the split.
  - **An enum used from more than one file gets its own file** (e.g.
    `adaptive_button_kind.enum.dart`, `adaptive_glyph.enum.dart`,
    `sign_in_mode.enum.dart`). **An enum referenced only within the single
    file that declares it may stay there** — a tab enum like `CompetitionTab`
    in `competition_detail.page.dart` or `ProfileTab` in `profile_sheet.dart`
    doesn't earn its own file just for being an enum. Either way, **name it
    `Enum`, never `_Enum`** — Dart privacy is per-file, so a leading
    underscore would block the file-splitting `export` pattern above the
    moment a second file needs it; starting public avoids a rename later.
  - **The file that keeps the original name re-`export`s the ones that moved
    out of it**, so every other file's import of it keeps working unchanged —
    e.g. `import '.../competition.model.dart'` still yields `SeasonLength` and
    `CompetitionOverview`. `import` what you actually reference directly in
    that file (a type in a cast, a method parameter, a constructor arg type);
    don't rely on the split-out file's own imports being visible
    transitively — `export` only re-exports what the exported file declares,
    not what it imports. A re-exporting file importing a file that imports it
    back (e.g. `competition.model.dart` ⇄ `competition_overview.model.dart`)
    is a cycle Dart permits; if in doubt, `flutter analyze` will catch
    anything it doesn't.
  - **Filenames carry what kind of file it is, as a dotted suffix before
    `.dart`.** A domain file whose only declaration is a plain data
    class (`Equatable`, `fromMap`, no behaviour beyond that) is
    `<name>.model.dart` (e.g. `leaderboard.model.dart`, `season.model.dart`,
    `player.model.dart`). A file whose only declaration is an enum is
    `<name>.enum.dart` (e.g. `game_type.enum.dart`, `medal.enum.dart`,
    `streak_type.enum.dart`) — this applies everywhere a dedicated enum file
    exists, not just under `domain/`. A widget that is the root of a routed
    page, or that fills an entire tab the way `LeaderboardPage` and
    `MatchesPage` do inside the competition shell, is `<name>.page.dart`
    (e.g. `competition_detail.page.dart`, `leaderboard.page.dart`,
    `matches.page.dart`). Repository interfaces, calculators/services, and
    widgets that are neither a page nor a tab stay unsuffixed
    (`leaderboard_repository.dart`, `elo_calculator.dart`,
    `leaderboard_row.dart`).
- **Feature code never imports `package:flutter/cupertino.dart` or Material
  widgets directly.** Everything platform-specific goes through
  `core/widgets/adaptive/adaptive.dart`. `AppPlatform.useCupertino` is the
  single switch, and `AppPlatform.debugOverrideCupertino` pins it in tests.
- **The accent and team colours are resolved through `AdaptiveColors`, never
  read off `AppColors` directly.** Each carries a second value for dark
  surfaces; a saturated mid-tone sits near 4:1 on a dark background whatever
  its hue. `test/core/adaptive_colors_test.dart` asserts the ratios against
  the app's own surface — note that surface is a warm tint, not white, so
  measuring against `#FFFFFF` flatters a colour by roughly 0.2.
- **All repository methods wrap their body in `guard()`** from
  `core/error/failure.dart`, which converts Postgrest/socket exceptions into
  a sealed `Failure`. UI renders them via `failure.localized(l10n)`.
- Messages raised by our own SQL (`RAISE EXCEPTION 'Create an account to log
  matches'`) are written for humans and pass through to the UI unchanged.
- **Every user-facing string goes through `AppLocalizations`.** Add to both
  ARB files, then `flutter gen-l10n`.
- Blocs that hold form state are `registerFactory`; session-wide ones are
  `registerLazySingleton`; ones scoped to a single competition are
  `registerFactoryParam<T, String, void>` and take the id as a constructor
  argument (`getIt<PlayersCubit>(param1: id)`). See
  `lib/app/dependency_injection/injector.dart`. `MatchDetailCubit` uses both
  slots (`param1` match id, `param2` competition id) because it needs the
  owner to decide who may delete.
- **Realtime is a tick, never a payload.** `core/data/realtime.dart` turns a
  `postgres_changes` subscription into a `Stream<void>`; the cubit debounces
  it by 400 ms and refetches. This is not laziness: one `create_match` on the
  demo competition emitted **36** `player_ratings` events and 14 `matches`
  events, because a back-dated match replays the whole season and every
  replayed match rewrites its own rating snapshot. Reconciling that stream
  row by row would cost more than the refetch and could not keep `rank`
  consistent anyway.
- **A write blocked by an RLS policy is not an error.** `update … where`
  simply matches no rows, so repositories end those calls with
  `.select().maybeSingle()` and raise `PermissionFailure` on null. Getting
  this wrong looks like a silent success. `supabase/tests/players_check.sql`
  asserts the premise.

### Things the source no longer says out loud

Kept here because the code cannot express them and they cost real debugging:

- **Derive a season's label from `Season.midpoint`, never from `startsAt`.**
  The boundaries are midnight in the *competition's* timezone, so on a device
  further west "August" starts on 31 July and a naive label is off by a month.
- **`AppTheme` uses `DynamicSchemeVariant.fidelity`** so the generated primary
  stays on the seed colour. The default variant pulls the saturated orange most
  of the way to brown.
- **Widget tests that pump the same tree twice under a different theme must key
  the probe per brightness.** Without it the second pump reuses the element tree
  and reports the *previous* theme's colours — a green test asserting nothing.
- **The current calendar season has no `seasons` row until its first match is
  created** (`season_window()` returns `season_id = null`), so the `leaderboard`
  view — inner-joined from `seasons` — cannot be queried for it. Before a
  season starts, `SupabaseLeaderboardRepository.standings()` falls back to a
  roster read (`players` embedding `competitions(starting_rating)`) so the
  page still shows everyone at the starting rating instead of an empty list.
  `Leaderboard.seasonId` is nullable for exactly this synthetic case.
- **The per-game-type leaderboard is a second, parallel Elo track, not a
  filter on the existing one.** Elo is order-dependent, so "1v1 ranking"
  can't be derived by filtering `player_ratings` after the fact — it needs
  its own replay built only from 1v1 matches. `player_game_type_ratings`
  (`apply_match_type_rating` / `recalc_season_game_type`, driven alongside
  the combined track by `create_match` / `update_match_score` /
  `delete_match`) is that second track, keyed by `(season_id, game_type,
  player_id)`. `player_ratings` / `leaderboard` are unchanged and remain
  "combined" (every match, any type) — that's what "all game types
  combined" already meant before this existed. Unlike `leaderboard`, the
  `game_type_leaderboard` view is not roster-backed: a player who hasn't
  played a given type this season doesn't appear in it, rather than
  showing everyone tied at `starting_rating` for a type nobody's played.
- **`game_type_season_history`** is the same trick one level up: `select
  l.*, s.starts_at, s.ends_at, medal … from game_type_leaderboard l join
  seasons s … where s.ends_at <= now()`, exactly how `season_history` is
  built from `leaderboard`. `SeasonHistoryPage` carries its own
  `GameTypeFilterDropdown`/`selectGameTypeFilter`, independent of the
  leaderboard tab's filter — they're different cubits with their own
  `selectedGameType`.

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

### SQL gotchas (Postgres / Supabase functions)

- OUT parameters shadow column names — **table-qualify everything** inside
  functions with `RETURNS TABLE`.
- An untyped enum literal in a `UNION` branch resolves as `text`; cast it
  (`'a'::public.match_team`).
- PostgREST coerces `""` to `NULL` for `uuid` params, so an empty string is
  not a validation error — it is a missing argument.

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

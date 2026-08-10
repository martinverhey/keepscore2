---
name: guidelines
description: Coding conventions and style guidelines for KeepScore 2 (Dart/Flutter and SQL) — file layout for cubits/states, no-comments rule, no freezed/codegen, adaptive-widget rule, localization, DI registration, SQL gotchas. Load this before writing or editing any lib/**.dart or supabase/**.sql code in this repo, or before reviewing such a diff.
---

# KeepScore 2 — coding guidelines

These are the conventions the codebase already follows. Match them in new
code; don't relitigate them. For product decisions, architecture rationale,
and the database workflow, see `CLAUDE.md` — this file is style only.

## Dart / Flutter

- **No comments.** Only write one when it is absolutely necessary — something
  the code genuinely cannot express itself. Doc comments count as comments.
  Naming and structure carry the explanation. (Explicit user preference.)
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
    whichever file originally bundled them (e.g. `match_team.dart` and
    `match_participant.dart` came out of `match_entry.dart`; `season_length.dart`
    and `competition_overview.dart` came out of `competition.dart`). A private
    helper used by more than one of the split files (e.g. a `_toDouble` map
    coercion) is duplicated into each file that needs it rather than shared —
    matching how the codebase already handled this before the split.
  - **The file that keeps the original name re-`export`s the ones that moved
    out of it**, so every other file's import of it keeps working unchanged —
    e.g. `import '.../competition.dart'` still yields `SeasonLength` and
    `CompetitionOverview`. `import` what you actually reference directly in
    that file (a type in a cast, a method parameter, a constructor arg type);
    don't rely on the split-out file's own imports being visible
    transitively — `export` only re-exports what the exported file declares,
    not what it imports. A re-exporting file importing a file that imports it
    back (e.g. `competition.dart` ⇄ `competition_overview.dart`) is a cycle
    Dart permits; if in doubt, `flutter analyze` will catch anything it doesn't.
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
  argument (`getIt<PlayersCubit>(param1: id)`). See `lib/app/di/injector.dart`.
  `MatchDetailCubit` uses both slots (`param1` match id, `param2` competition
  id) because it needs the owner to decide who may delete.
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

## SQL (Postgres / Supabase functions)

- OUT parameters shadow column names — **table-qualify everything** inside
  functions with `RETURNS TABLE`.
- An untyped enum literal in a `UNION` branch resolves as `text`; cast it
  (`'a'::public.match_team`).
- PostgREST coerces `""` to `NULL` for `uuid` params, so an empty string is
  not a validation error — it is a missing argument.

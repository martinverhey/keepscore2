# KeepScore 2

Flutter (iOS / Android / Web) + Supabase app for running competition ladders:
log 1v1–NvM matches, get an Elo leaderboard per season.

**Design reference (Elo formula, schema, architecture rationale):**
`.claude/plans/build-plan.md` — a local working note, gitignored, not part
of the checked-in repo. If it's missing on your machine, this file (`CLAUDE.md`)
is the up-to-date source of truth regardless.

## Status

| Step | State |
|---|---|
| 1. Scaffold, theme, adaptive layer, l10n | Done |
| 2. Database (migrations + seed + RLS checks) | Done, applied to the live project |
| 3. Auth (email OTP, guest, upgrade, Apple/Google) | Done |
| 4. Competitions (list, create, join + claim) | Done |
| 5. Players (player list, add placeholders, owner settings, share code) | Done |
| 6. Matches (team builder, submit, list, edit, delete) | Done |
| 7. Leaderboard + seasons + realtime | Done |
| 8. Polish, Dutch copy pass, app icons | Done |

Theme and language are app-wide, competition-independent preferences, both
persisted to `SharedPreferences` and read back in `main()` before `runApp`.
`LanguagePreference.locale` feeds `MaterialApp`/`CupertinoApp`'s `locale`, with
`system` meaning "no override, follow the device", and `/settings/language` is a
real page reached from the settings page's System section (and from the wide-web
sidebar's account section).

**Theme is deliberately *not* a page** — it's a toggle rendered inline
in both of those places (settings page System section, sidebar account section),
so `ThemePreference` is `{light, dark}` with no `system` value and there is no
`Routes.theme`. Losing `system` means there is nothing left for the device to
follow at runtime, so the device's brightness is instead read *once*, as the
seed for the very first launch: `ThemeCubit`'s initial state and its `load()`
fallback both come from `WidgetsBinding.instance.platformDispatcher.platformBrightness`
(seeding the initial state too, not just `load()`, is what stops a dark-mode
device flashing light for one frame before the store answers). After that first
tap the stored value wins forever. Both surfaces render an `AdaptiveSwitch`
(`core/widgets/adaptive/adaptive_switch.dart`) — on for dark, off for light —
with both the switch's own `onChanged` and the whole row's `onTap` calling
`ThemeCubit.toggle()`, the same double-wired pattern Flutter's own
`SwitchListTile` uses; neither call site passes a
callback down, which is why `Sidebar` reads `ThemeCubit` from context itself
rather than taking an `onToggleTheme` prop (every one of its call sites would
have passed the identical closure — the same reasoning that later moved
`AuthBloc` and every navigation callback inside it too, see the sidebar
section below). The cost of that is that **every widget test mounting a
`Sidebar`, or a page composed with one, now needs a `ThemeCubit` and an
`AuthBloc` in scope** — in the app both come from `KeepScoreApp`'s root
`MultiBlocProvider`, but `sidebar_test.dart`, `settings_page_test.dart` and
`competition_content_page_test.dart` each provide their own (the test file kept
its old name across the rename below — it now pumps a `StatefulShellRoute` and
asserts against `LeaderboardPage`).

`/upgrade` turns a guest into a real account in place: same `SignInCubit`, built
with `SignInMode.upgrade`, which routes the two email steps to
`upgradeGuestWithEmail` / `verifyUpgradeCode` (Supabase `updateUser` + an
`emailChange` OTP) instead of a fresh sign-in. Every place that refuses a guest
renders `GuestNotice`, which carries the refusal *and* the way out; the page pops
itself when `AuthBloc` reports the user is no longer anonymous.

`/competition/:id` redirects to `/competition/:id/leaderboard` — Leaderboard and Matches are
each a real route, not a tab switch inside one page: a `StatefulShellRoute.indexedStack` with
one branch per route (`features/competition/.../competition_shell.dart`'s `CompetitionShell`
wraps the `navigationShell`; see "Leaderboard and Matches are routes, not tabs" below for why
and how). `LeaderboardPage` (`features/leaderboard/presentation/widgets/leaderboard.page.dart`,
join code + invite + `ProfileSection` + the actual ranked list, which is `LeaderboardList` in
the same directory's `leaderboard_list.dart`) and `MatchesPage`
(`features/match/presentation/widgets/matches.page.dart`) are each a full routed page — own
`AdaptiveScaffold`, own `LeaderboardCubit`/`MatchListCubit` loaded in their own `initState`.
Players has its own settings route, not a third branch — see "Leaderboard and Matches are
routes, not tabs" for why. The leaderboard tab always shows the
current calendar window — which has no row until the first match lands in it.
It has no season picker: that moved to
`/competition/:id/settings/history` (`HistoryPage`), which shows one
finished season at a time — `SeasonSheet` picks among `HistoryState.seasons`
(the lean, already-loaded season list — id/starts_at/ends_at only, no
leaderboards — so the picker itself needs no separate fetch), and selecting one
fetches just that season's leaderboard. Neither tab filters by game type —
that's Matches-only, see below.

Logging a match, inspecting one, and joining a competition are all sheets, not
routes — there is no `match/*` route, no `Routes.match` and no
`Routes.joinCompetition`, so none of them is deep-linkable, and each builds its
own cubit inside the `showAdaptiveSheet` builder rather than in a `GoRoute`.
`showJoinCompetitionSheet` returns the joined competition's id (or null), and
`CompetitionsPage` is what refreshes `CompetitionListCubit` and pushes the
competition — the sheet itself never navigates. `showNewMatchSheet` builds the teams and submits.
`TeamPickerSheet`'s "Manage players" button opens `showManagePlayersSheet`
(`player/presentation/widgets/manage_players_sheet.dart`) on top of the picker
rather than popping and pushing `Routes.players` — the sheet builds its own
`PlayersCubit` via `getIt` (a nested sheet route inherits no providers from the
route underneath it), and `NewMatchSheet._managePlayers` refreshes
`MatchFormCubit` afterwards and hands the picker back its freshly filtered
player list through `TeamPickerSheet.onManagePlayers`, so a player added there
is selectable without closing anything.
`showMatchDetailSheet` (`match/presentation/widgets/match_detail_sheet.dart`)
renders the same `MatchCard` the list does, then a "Player rank" card (each
player's rating going in, Team A left / Team B right, divided off from the two
team averages) and a "Win chance" card (`EloCalculator.winChance`, the expected
score the delta is already computed from, formatted with
`NumberFormat.percentPattern`), and lets the creator or the owner change the
score or delete the match from the sheet's primary/secondary buttons. Nothing
refreshes the list when either sheet closes — realtime does it.

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
- **Edits/deletes replay the season from the affected match forward** via
  `recalc_season_from`, not from scratch — see the note under Testing.
- **Auth**: Apple, Google, email OTP code. No passwords.
- **Guests** (Supabase anonymous) may join a competition and read it. They may
  not create competitions, add players, or create matches. Enforced in Postgres.
- Online only. English + Dutch. Cupertino on iOS/macOS, Material 3 elsewhere.

### Guest-gated features

Enforced in Postgres (source of truth) and mirrored in the UI at every
write-capable surface, gated on `session.canWrite` from `AuthBloc` (passed
down as `isRegistered`). Keep this list current when a gated surface is added
or moved:

- **Create competition** — `competitions.page.dart`, `canCreate: session.canWrite`.
- **Add/manage players, owner settings** — `players.page.dart` →
  `widgets/players.dart`, `isRegistered: session.canWrite`.
- **Create a match** — the "new match" bottom tab item is omitted entirely for
  guests in `competition_tab_bar.dart`; `matches.page.dart` shows
  `GuestNotice` instead of the log affordance.
- **Edit/delete a match** — `match_detail_sheet.dart`,
  `session.canWrite && state.isManageableBy(session.user?.id)` (creator or
  owner only, not just registered).
- **History** (`settings.page.dart`) is deliberately *outside*
  this gate — it's read-only historical data a guest may read. Competition
  Settings and Manage players in the same menu stay gated.

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

`features/settings/` is the one deliberate exception to "a feature owns the
domain it presents": alongside its own theme-preference domain, it also holds
the presentation for the competition-admin menu — `SettingsPage`,
`ConfigurationPage`/`ConfigurationCubit`, `HistoryPage`/
`HistoryCubit` — even though those read `CompetitionRepository`/
`LeaderboardRepository`, which stay put in `competition`/`leaderboard`. They
moved here because they're conceptually "settings" screens, not because they
own any data. Player management stayed in `features/player/` despite being
reachable from the same menu: `PlayersCubit` is also read directly by
`LeaderboardPage`/`MatchesPage` for player data, not just by the management
screen, so it's a real cross-feature dependency rather than a settings-only
concern.

### The current competition is app-wide

`CompetitionCubit` is a `registerLazySingleton`, provided in `KeepScoreApp`'s
root `MultiBlocProvider` next to `AuthBloc`/`ThemeCubit`/`LanguageCubit`/
`GameTypeFilterCubit`. It is the single answer to "which competition is the
user in", available to every page and to the sidebar whether or not the
current route is competition-scoped. Before this it was a
`registerFactoryParam` created by the `/competition/:id` `ShellRoute`, which
meant the two routes outside that subtree (`/` and `/settings/language`)
could not see it — so the sidebar's competition was flattened into a
`HomeSidebarCompetition` and smuggled to them as go_router `extra`. The
concept existed three times over (`RecentCompetitionStore`, the route-scoped
cubit, and that `extra` copy); hoisting collapsed it to one and deleted the
`extra` threading, `HomeSidebarCompetition`, and `CompetitionsPage`/
`LanguagePage`'s `sidebarCompetition` constructor params.

**The route drives the cubit, never the reverse.** `CompetitionScope`
(`features/competition/presentation/widgets/competition_scope.dart`) is the
only caller of `select(id)` — the `ShellRoute` wraps the competition subtree
in it, and it calls `select` from `initState`/`didUpdateWidget` so the URL
always wins over whatever the cubit happens to be holding.

Route scoping used to make staleness structurally impossible: a different id
was a different subtree (`KeyedSubtree(key: ValueKey(id))`), so a stale
competition could not survive. A singleton trades that guarantee for
discipline, and these three rules are what replace it — all four covered in
`competition_cubit_test.dart`:

- `select(id)` with a **different** id resets to `CompetitionLoading` before
  fetching, so competition A's name is never painted over competition B's
  data. With the **same** id it is a silent `refresh()` instead, which is
  also what reloads a competition on re-entry.
- Every `await` in `load()` is followed by a `competitionId != _competitionId`
  guard, so a slow response for a competition the user has already navigated
  away from is dropped rather than emitted.
- The cubit subscribes to `AuthBloc` in its constructor and clears itself
  when the session stops being authenticated. Without that, signing out and
  back in as someone else leaves the previous user's competition in the
  sidebar — the router's recent-competition redirect catches the *routing*
  side of that, but not the in-memory copy. `CompetitionsPage` calls
  `clearIfSelected(id)` after a successful leave/delete for the same reason.

"No competition selected" is deliberately **not** a fifth state: it is never
rendered. Only pages inside the competition subtree switch on
`CompetitionState`, and `CompetitionScope` has always called `select` before
they build, so `CompetitionLoading` is the honest initial (and post-`clear`)
value. The sidebar reads `state.competition` opportunistically and treats
`null` as "hide the competition group".

### The competition list is a cache, not a fetch-on-open

`CompetitionListCubit` is a `registerLazySingleton`, provided from
`KeepScoreApp`'s root `MultiBlocProvider` alongside `CompetitionCubit`. It
used to be a `registerFactory` built by the `/` route's own `BlocProvider`,
which meant every visit to the competitions list threw the previous list
away, dropped to `CompetitionListLoading`, and painted a full-page spinner
over a fetch that measures ~85 ms end to end (4.9 ms of it in Postgres). The
data was never the slow part; the state wipe was.

`CompetitionsPage.initState` therefore calls `ensureLoaded()`, not `load()`:
it fetches only when there is no data yet, dedupes concurrent callers onto
one in-flight request, and returns immediately once `CompetitionListReady`
holds a list. A failure is not cached — `CompetitionListFailed` is not
`Ready`, so the next `ensureLoaded()` retries.

Because the list is now cached, **every write to it has to say so**. `rename`/
`leave`/`delete` already refreshed through `_mutate`; `CreateCompetitionPage`
and `JoinCompetitionPage` now call `CompetitionListCubit.refresh()` in their
success listeners. Both `context.push` the new competition on top of `/`, so
the home page's `State` survives and `initState` never re-runs — without that
explicit refresh the new competition would be missing from the list on the
way back. (It already was, before the cache: nothing but pull-to-refresh ever
refetched it.)

The cubit subscribes to `AuthBloc` and resets to `CompetitionListLoading` when
the session stops being authenticated, for the same reason `CompetitionCubit`
does — otherwise signing out and back in as someone else serves the previous
user's competitions from cache.

**The router's recent-competition redirect reads this cubit instead of making
its own request.** `resolveRecentCompetitionTarget` in `app_router.dart` used
to call `CompetitionRepository.overview(recentId)` to confirm membership, and
`redirect` **awaits** it before `/` may build — so a cold start with a stale
recent id paid `overview` and then `myCompetitions` in series, two round trips
against the same view, with the route blocked throughout. It now awaits
`CompetitionListCubit.ensureLoaded()` and asks `isMember(recentId)`: one
request, and its result is already in the cubit by the time `CompetitionsPage`
builds, so `ensureLoaded()` there is a no-op. `test/app/app_router_test.dart`
asserts exactly one `myCompetitions()` call and zero `overview()` calls.

The distinction that test file exists to protect: **only a load that actually
succeeded may clear `RecentCompetitionStore`.** The check is
`state is! CompetitionListReady` first, `isMember` second — a `Failed` state
means "we don't know", so the stored id survives a network blip instead of
being wiped and dumping the user on the list page permanently.

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
- **Awaiting several independent repository calls in a cubit starts each one
  first, unawaited, then `await`s each in turn — never `Future.wait<Object?>`
  with positional-index casts.** `final a = repo.one(); final b = repo.two();
  final resultA = await a; final resultB = await b;` keeps the same
  concurrency as `Future.wait` (every call starts before the first `await`)
  while each variable comes back its own real type, so there's no `results[0]
  as Foo` to keep in sync by hand as calls are added, reordered, or made
  conditional. A call that's only sometimes needed (guarded on a nullable id,
  say) is a nullable `Future<T>?` local, awaited with `!` inside the same
  guard, rather than an `if (cond) ...` list entry — see
  `ProfileOverviewCubit.load`. Reach for actual `Future.wait` only
  when the futures are `Future<void>` with nothing to unpack (e.g.
  `LeaderboardPage._refresh`/`MatchesPage._refresh`).
- **Widget structure:**
  - Nested `Row`/`Column`/`Wrap`/`Stack` with multiple children or a
    conditional gets extracted into a small private method named for what it
    renders, not its widget type (`_playerName(context)`, not `_row1()`).
    Leave single, already-flat widget calls inline — `build()` itself should
    read as a short, flat assembly of these named pieces.
  - **A local `final` variable that holds a widget is the same extraction,
    spelled wrong — it becomes a private method instead**, even when it's
    used only once later in the same `build()`/helper. `final scrollView =
    CustomScrollView(...)` becomes a `Widget _scrollView(...) { return
    CustomScrollView(...); }` called where the variable would have been used.
    A local var reads as scratch state; a named method reads as part of the
    widget's structure and shows up next to the other `_foo(context)` helpers
    instead of buried inline. **Prefer a zero-arg method (`Widget
    _content() { ... }`) over a zero-arg getter (`Widget get _content`)** —
    even when it takes no parameters, a trailing `()` at every call site
    reads as "this does work", which is what it's doing; keep `get` for
    values that are genuinely just stored-field lookups.
  - **Private methods/getters are ordered by proximity to use, not by the
    order they were written or alphabetically.** `build()` is followed
    immediately by the methods it dispatches to, in the order it calls
    them — in `adaptive_scaffold.dart`, that's `_cupertino` then
    `_material`, not the lower-level sliver plumbing they both happen to
    consume as a passed-in parameter. Each of those is in turn immediately
    followed by the helpers it calls, so the file reads top-down as
    decreasing levels of abstraction. A helper called from more than one
    place (`_bareBar`) sits after the last of its callers, grouped with
    other shared/leaf helpers toward the bottom of the class.
  - **The same top-down ordering applies to plain top-level functions in a
    non-widget file** (e.g. `match_day_group.dart`'s `groupByDay` and its
    `_newestFirst` comparator): the public entry point goes first, followed
    by the private helper(s) it calls, not the other way around.
  - **A file that pairs a widget with top-level helper functions keeps that
    same ordering, and a helper used only by that widget's `build()` is a
    private top-level function below the class, not a private method on
    it.** `rating_delta.dart` is the template: `_formatDelta`/`_deltaColor`
    are used only by `RatingDelta.build()`, so they sit below the class as
    private top-level functions rather than `_formatDelta`/`_deltaColor`
    methods on `RatingDelta` itself. (`formatRating`, the file's other
    original helper, didn't fit this shape at all — see the extension bullet
    below for where it went instead.)
  - A new private local widget (`class _Foo extends StatelessWidget` /
    `StatefulWidget` inside a feature file) that takes only
    primitives/`Color`/callbacks — no `Player`, `Match`, `Competition`, etc. —
    and isn't tied to one screen's layout gets promoted to its own public file
    under `core/widgets/` (or `core/widgets/adaptive/` for a Cupertino/Material
    split) and imported back. Keep it private otherwise.
  - **New modal sheets build on `core/widgets/sheet.dart`'s `Sheet`**, not ad
    hoc `Column`s: title/subtitle/avatar pinned at top, `content` scrolls in
    between (capped at 85% of screen height), primary/secondary buttons
    pinned at bottom. For an action-sheet shape (a variable-length column of
    choices plus Cancel), the choice column is `content` and only Cancel is
    `secondaryButton`.
  - **A raw `TextEditingController`'s text never lives in cubit state.**
    `MatchScoreSheet` and `NewMatchPage`'s score fields both keep the
    controller itself as page-local state and redraw with a bare
    `setState(() {})` in `onChanged`; the cubit only ever receives the
    parsed value at the moment of commit — `MatchDetailCubit.updateScore(
    scoreA:, scoreB:)`, `MatchFormCubit.submit(scoreA:, scoreB:)` — never a
    per-keystroke callback. `NewMatchPage` used to route score through
    `MatchFormCubit` instead (`scoreAChanged`/`scoreBChanged` emitting on
    every keystroke, plus a `BlocConsumer` `listener` writing the emitted
    value back into the same controller it came from to keep the two in
    sync); that round-trip existed only because the text lived in the wrong
    layer, and the sync code disappeared entirely once it moved local — a
    plain `BlocBuilder` was enough again. A business-rule check that
    genuinely needs the live text (`MatchFormReady.canSubmit`/
    `scoresAreValid`/`drawIsRefused`) takes the parsed value as a
    `{required int? scoreAValue, ...}` parameter instead of reading a field
    off state, with the page computing it from its own controller
    (`_scoreAValue`/`_scoreBValue` getters, `int.tryParse` on the
    trimmed text) each time it's needed — the same shape `ratingOf`/
    `teamRating` already use for values that depend on more than just the
    state's own fields.
- **One class or enum per file.** This applies to Cubit states and to domain
  enums/models alike:
  - **Every Cubit's state lives in its own `<name>_state.dart` file**, next to
    `<name>_cubit.dart` (e.g. `players_cubit.dart` / `players_state.dart`).
    The state file holds the state class, its companion status enum(s), and
    any private helper used only by the state (e.g. a `copyWith`-adjacent
    formatter). This applies to Cubits. `AuthBloc` is a `Bloc` (state *and*
    events tightly coupled, one small file) and stays as-is.
  - **Every cubit state is a `sealed` hierarchy of subclasses, not one flat
    `status`-enum-plus-nullable-fields class** — "one class per file" is
    about not scattering a type across the codebase, not about how many
    related classes one state file may declare. `match_form_state.dart`
    was the first cubit built this way and is still the template:
    `MatchFormLoading`/`MatchFormMissing`/`MatchFormFailed`/`MatchFormReady`
    each live there instead of one `MatchFormState` with a `status` field
    and every phase's fields all nullable at once. The shape a given cubit
    needs falls into one of four recurring buckets — grep an existing
    `<name>_state.dart` for the closest match before inventing a new shape:
    - **Fetch one thing, with a "not found" case** (`CompetitionState`,
      `ConfigurationState`, `MatchDetailState`): `XLoading`/`XMissing`/
      `XFailed(failure)`/`XReady(...)`. A field that was nullable purely to
      mean "not loaded yet" becomes non-nullable on `XReady` — e.g.
      `MatchFormReady.competition`/`MatchDetailReady.match` — so
      `ratingOf`/`isManageableBy` read it straight, no `?? 1000`/`!`. A
      field that's genuinely optional *even once ready* (e.g.
      `MatchDetailReady.competition` — a match can exist with no
      resolvable competition) stays nullable there. When outside callers
      need a value regardless of phase (`CompetitionState.competition`/
      `.myPlayerId`, read opportunistically by five different sibling
      pages before their own cubit has loaded), declare it as a virtual
      getter on the sealed base returning `null`, overridden non-null on
      `XReady` only — cheaper than every call site pattern-matching or
      importing an extension.
    - **Fetch a list/aggregate, no "not found" case** (`CompetitionListState`,
      `LeaderboardState`, `MatchListState`, `PlayersState`, `HistoryState`,
      `ProfileHistoryState`, `ProfileOverviewState`, `ProfileVersusState`):
      `XLoading`/`XFailed(failure)`/`XReady(...)` — `XFailed` only ever
      for a load with *no* prior data; a silent background refresh
      (`load(silent: true)`) or reactive re-fetch
      (`GameTypeFilterCubit`-driven `_applyGameType`) that fails while
      `XReady` already has data just keeps that `XReady` unchanged rather
      than transitioning anywhere, dropping the failure silently — check
      the widget first, since in every one of these cubits the page never
      actually rendered that failure while data was on screen anyway (only
      `actionFailure`, a genuine mutation-error field on `XReady`, ever
      renders). If the background op sets a `busy`-style flag first, still
      reset it back on failure so the spinner doesn't stick — see
      `HistoryCubit.selectSeason`/`MatchListCubit._applyGameType`.
    - **Multi-step wizard, steps carry different data** (`SignInState`:
      chooser/email/code; `JoinCompetitionState`: code/confirm): one
      subclass per step (`SignInChooser`/`SignInEmailStep`/`SignInCodeStep`,
      `JoinCode`/`JoinConfirm`), carrying only what that step needs — this
      is the shape that most directly removes real `!`-unwraps
      (`JoinConfirm.preview` is non-null, where the old flat
      `JoinCompetitionState.preview` needed `!` at every read). A mutator
      like `emailChanged`/`codeChanged` only compiles against the step
      that has that field, so calling it from the wrong step is a
      structural no-op, not a hybrid state with the wrong fields set — see
      `SignInCubit.emailChanged`/`codeChanged` guarding on `_email`/
      `_codeStep`. `back()`-style transitions construct the target step's
      subclass, carrying over the fields that survive it (`email` survives
      code→email; `code` does not). A helper like `SignInCubit._run` that
      needs to toggle `busy`/`failure` regardless of which step is current
      dispatches on the concrete subtype with a small `switch (state) {
      XStepA stepA => stepA.copyWith(...), XStepB stepB =>
      stepB.copyWith(...), ... }` — the pattern variable is named for the
      step, not a single letter, even though every branch does the same
      mechanical `copyWith`.
    - **Single form with a terminal "succeeded" case**
      (`CreateCompetitionState`): `XEditing(...)` / `XCreated(result)` — the
      editable fields and the result never coexist, unlike the old flat
      class's `created` field sitting nullable next to `name`/`busy` the
      whole time.

    `canSubmit`/`scoresAreValid`/`isDraw`/`drawIsRefused`-style checks that
    need the live value of a `TextEditingController` live as methods taking
    that value as a parameter, not getters, on whichever `Ready`/step
    subclass they belong to — see the `TextEditingController` bullet above.
    Every mutator that isn't `load()` now has to check the current phase
    before doing anything, where a flat state needed that check in exactly
    one place: a private getter per relevant subclass (`_ready`, or
    `_email`/`_codeStep` for a wizard), **re-read after every `await` rather
    than captured once**, so a mutation that lands mid-request (`assign`/
    `setTeam` while `submit` is in flight) isn't clobbered by a stale copy —
    see `MatchFormCubit._ready`.

    **`ThemeState` and `LanguageState` are the deliberate exceptions, left
    flat.** Neither is ever anything but a fully-formed, synchronously-available
    value — `ThemeCubit`'s `load()`/`toggle()` and `LanguageCubit`'s
    `load()`/`select()` all `emit` a
    complete state directly, with no failure path and no "not ready yet" moment
    worth modeling. There's no `!`/`?? fallback` a sealed split would remove, and
    a sealed hierarchy with exactly one variant isn't the pattern — reach
    for this exception only when a cubit's state genuinely has no phases at
    all, not merely "usually loads fast."
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
    `sign_in_mode.enum.dart`, `competition_tab.enum.dart` — `CompetitionTab`
    moved out of `competition_content.page.dart` into its own file once
    `CompetitionTabBar` and both routed tab pages needed it, not just the one
    page that used to render both tabs inline). **An enum referenced only
    within the single file that declares it may stay there** — a tab enum
    like `ProfileTab` in `profile_sheet.dart` doesn't earn its own file just
    for being an enum. Either way, **name it
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
    page, or that fills an entire tab-as-route the way `LeaderboardPage` and
    `MatchesPage` do, is `<name>.page.dart` (e.g. `leaderboard.page.dart`,
    `matches.page.dart`). `competition_shell.dart` stays unsuffixed despite
    living next to these — it's the `StatefulShellRoute`'s `builder`, not
    itself a routed destination, see "Leaderboard and Matches are routes, not
    tabs". Repository interfaces, calculators/services, and
    widgets that are neither a page nor a tab stay unsuffixed
    (`leaderboard_repository.dart`, `elo_calculator.dart`,
    `leaderboard_row.dart`).
- **The same small piece of logic showing up as a private helper in more than
  one file becomes an extension in `core/extensions/`, not a copy in each
  file or a shared static helper.** Filed as `<type>.extension.dart`, named
  for the extended type in snake_case — **every extension on a given type
  lives together in that one file**, not split one-per-concept. Each
  individual extension block inside it is still named `<Type><Concept>`
  (e.g. `BuildContextL10n` and `BuildContextLocale.languageTag` both live in
  `build_context.extension.dart`; `ThemePreferenceMode` and
  `ThemePreferenceBrightness` both live in
  `theme_preference.extension.dart`; `StreakTypeTier` on `StreakType` is
  currently alone in `streak_type.extension.dart` but a second extension on
  `StreakType` would join it there rather than get its own file).
  `core/extensions/` may import a feature's domain type to extend it
  (`core/data/game_type_filter_store.dart` already does this for `GameType`)
  — extending a type is not a layering violation the way a core file
  depending on feature *behaviour* would be. **A single already-shared
  top-level function that formats/derives a value off a primitive gets the
  same treatment**, even with no literal duplicate to fold in — it just
  wasn't discovered as a getter on the type it operates on yet.
  `formatRating(double value) => value.round().toString()` used to live as a
  bare top-level function in `rating_delta.dart`, called from half a dozen
  files; it's now `double.ratingLabel` (`DoubleRatingLabel` in
  `double.extension.dart`), and every call site reads the value off the
  number itself instead of wrapping it in a function call.
  This applies just as much to a repeated expression chain (`x.y().z()`) as
  to a repeated block of statements — don't wait for the duplication to grow
  before extracting it.
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
- **Text styling goes through `AppTypography` (`core/theme/app_tokens.dart`),
  never a raw `TextStyle(fontSize: N, ...)` literal.** It's a fixed scale —
  `displayLarge`/`headlineLarge`/`headlineMedium`/`titleLarge`/`titleMedium`/
  `titleSmall`/`bodyLarge`/`bodyMedium`/`bodySmall`/`labelLarge`/`eyebrow`,
  plus three colour-baked muted variants (`caption`/`captionSmall`/
  `labelTiny`, all `AppColors.neutral`) for the "secondary text" role that
  showed up identically in a dozen files before this existed. Each carries
  its own weight (`titleSmall` is bold, `bodyLarge` is semibold, etc.) since
  that pairing was already consistent across the app wherever a given size
  showed up. A call site needing a different colour/weight/feature than the
  token's default calls `.copyWith(...)` on it rather than constructing a new
  `TextStyle` — `AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700,
  color: color)`, not a fresh literal that happens to share bodyMedium's size.
  `AppTypography.tabularFigures` is the shared `[FontFeature.tabularFigures()]`
  list for the same reason — every rating/score number spliced it in via
  copyWith instead of redeclaring the literal. A handful of reusable widgets
  parametrize their own `fontSize` at the call site
  (`RatingDelta`/`MedalChip`, used at a couple of different sizes depending on
  context) — those default to and get overridden with the matching
  `AppTypography.*Size` scalar (`bodySmallSize`, `captionSmallSize`, …)
  rather than a bare number, so the scale still has exactly one source. The
  one deliberate exception is `InitialsCircle`, whose `fontSize: size * 0.36`
  is computed from the avatar's own diameter, not picked from the scale.
- **The same tokenization applies to translucency: `AppOpacity`
  (`core/theme/app_tokens.dart`, alongside `AppTypography`) is the only
  source for a `.withValues(alpha: N)` literal in `lib/**`.** `cardFillFaint`/
  `surfaceFill`/`accentFill`/`selectedFill`/`tintedButtonFill`/`badgeFill`
  cover background washes, `accentBorder`/`controlBorder`/`fieldBorder`/
  `winnerBorder` cover outlines. Two call sites had drifted onto a slightly
  different value than everywhere else doing the same job — a match's own
  row in the leaderboard was highlighted at 0.12 while every other
  "selected/highlighted row" (picker rows, the sidebar's current section)
  used 0.14, and one dropdown's border sat at 0.22 next to another card's
  otherwise-identical 0.25 — both were folded onto the shared token rather
  than kept as their own one-off value; every other call site kept its exact
  existing alpha. `AppColors.neutral.withValues(alpha: AppOpacity.surfaceFill)`
  was, verbatim, the single most-repeated color expression in the app (a
  neutral card/row background, a dozen-odd call sites) — instead of routing
  every one of those through the opacity token individually, it's
  pre-combined once as `AppColors.neutralSurface`, and `AppColors.fireBadgeFill`
  is the same move for the streak-badge background. `AppColors.white`/
  `AppColors.transparent` name the two raw hex literals (`0xFFFFFFFF`,
  `0x00000000`) that show up where a *theme-independent* color is genuinely
  needed — the QR code's white quiet zone has to stay white in dark mode for
  scanners to read it, and `0x00000000` is `Colors.transparent` reached
  through a file that can't import `material.dart` for it.
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
  argument (`getIt<PlayersCubit>(param1: id)`). `CompetitionCubit` and
  `CompetitionListCubit` are the exceptions — both are session-wide, see
  "The current competition is app-wide" and "The competition list is a
  cache, not a fetch-on-open".
  See
  `lib/app/dependency_injection/injector.dart`. `MatchDetailCubit` uses both
  slots (`param1` match id, `param2` competition id) because it needs the
  owner to decide who may delete.
- **Realtime is a tick, never a payload.** `core/data/realtime.dart` turns a
  `postgres_changes` subscription into a `Stream<void>`; the cubit debounces
  it by 400 ms and refetches. This is not laziness: reconciling a stream of
  per-row payloads would cost more than the refetch and could not keep `rank`
  consistent anyway — a single write's fan-out can still be many rows, even
  after `recalc_season_from`/no-op write guards (20260815170000,
  20260816110000) cut the `matches`/`match_players` side of it down to just
  the affected match(es): `player_ratings` is still fully deleted and
  rebuilt per season on every edit/delete (see the comment on
  `recalc_season_from`), so every player in the season still gets a fresh
  event on every write, back-dated or not.
- **A write blocked by an RLS policy is not an error.** `update … where`
  simply matches no rows, so repositories end those calls with
  `.select().maybeSingle()` and raise `PermissionFailure` on null. Getting
  this wrong looks like a silent success. `supabase/tests/players_check.sql`
  asserts the premise.

### Web vs. native UI (`AppPlatform.useWideWeb`)

`AppPlatform.useCupertino` only ever splits iOS/macOS from everything else —
`kIsWeb` always resolves it to `false`, so web inherited the plain Material
*phone* branch verbatim. A resizable desktop browser window isn't a phone, so
there's a second, independent axis: `AppPlatform.useWideWeb(BuildContext)` —
`kIsWeb && MediaQuery.sizeOf(context).width >= wideWebBreakpoint` (720). A
phone-width browser tab deliberately keeps the exact same chrome as native
(bottom tabs, sheets, collapsing title) — only a desktop-sized web window gets
the treatment below. Mirrors `debugOverrideCupertino` with
`AppPlatform.debugOverrideWideWeb` for tests.

- **Custom tappable rows get hover/cursor feedback everywhere, not just wide
  web.** Every hand-rolled `GestureDetector(behavior: opaque, onTap: …)` around
  a row/tile (`LeaderboardRow`, `NavRow`, `SelectableRow`, `PillDropdown`,
  `MatchTile`, `CompetitionTile`, `ProfileSection`, the team-picker tile, the
  competition-name header) is `AdaptiveTappable` instead
  (`core/widgets/adaptive/adaptive_tappable.dart`): `InkWell` (hover cursor +
  ripple, clipped to the same `borderRadius` as the row's own decoration) on
  Material, plain `GestureDetector` on Cupertino. A mouse on any width benefits
  from this, so it isn't gated on `useWideWeb`.
- **The browser tab title is dynamic, and can't be done through
  `onGenerateTitle`.** go_router's `Router` subtree rebuilds independently of
  the ancestor `Title`/`WidgetsApp` widget that `onGenerateTitle` lives on, so
  navigating via `context.go`/`context.push` never re-invokes it — a per-route
  title needs each page to set it directly. `setPageTitle(context, label)`
  (`core/widgets/page_title.dart`) calls
  `SystemChrome.setApplicationSwitcherDescription`, which is what the Flutter
  web engine uses under the hood to set `document.title`. **It is guarded by
  `if (!kIsWeb) return;`, and that guard is load-bearing on Android** — the
  framework always sends `primaryColor` on the platform channel, `null` when
  `ApplicationSwitcherDescription` wasn't given one, and the Android
  embedding's handler reads it back with `JSONObject.getInt("primaryColor")`,
  which throws on a JSON null. Unguarded, every routed page's title call
  raised `PlatformException(error, Value null at primaryColor ... cannot be
  converted to int)` from an unawaited future — logged by the Dart VM, fatal
  to nothing, and therefore invisible outside `adb logcat`. Setting a
  per-page label in the Android recents list was never wanted anyway, and iOS
  ignores the call entirely, so the guard costs no behaviour. Passing a real
  `primaryColor` would also silence it, at the price of tinting the recents
  entry. Every routed page calls it once per relevant build, formatting
  `'$label · ${l10n.appTitle}'`.
  `LeaderboardPage`/`MatchesPage` are the one exception to the format: each
  puts the competition name *ahead of* its own tab name
  (`'${competition.name} · ${context.l10n.leaderboardTitle}'`, respectively
  `matchesTitle`) because that's the field that disambiguates several
  same-shaped tabs open at once, and browsers truncate a long tab title from
  the end, not the front. Being separate routed pages rather than one shell
  switching on a tab enum, each computes and sets its own title independently
  — there's no longer a single call site that could do this once for both.
- **`showAdaptiveSheet` grew a third, wide-web-only branch that swaps the
  bottom sheet for a centered dialog** (`showDialog` + `Dialog`, capped at
  480px) instead of `showModalBottomSheet` — a panel sliding up from the
  bottom of a wide desktop window reads as disconnected from whatever button
  opened it. Every existing call site (game type filter, player/competition
  row action sheets, invite sheet, rename, match score edit, team picker,
  profile sheet, season picker) gets this automatically, since they all
  already funnel through `showAdaptiveSheet`/`Sheet` — no call-site changes
  needed when adding a new sheet.
- **`AdaptiveScaffold`'s Material app bar stops collapsing on wide web.**
  `SliverAppBar.large` (a big title that shrinks into a small pinned bar on
  scroll) is a one-handed-phone-scrolling affordance; on wide web it's a
  plain, fixed-height, `pinned: true` `SliverAppBar` instead — mouse/trackpad
  scrolling has no reason to animate the title away, and doing so anyway reads
  as an unintentional phone skin on a desktop window.
- **Three widths are stacked on wide web, and only the middle one is 640.**
  The sidebar is a fixed `Sidebar._width = 232`, with the page `Expanded`
  beside it, so the *pane* — and with it the whole `AdaptiveScaffold`:
  `Scaffold` background, `SliverAppBar`, `floatingAction`, `bottomBar` — is
  `viewport - 232`. Inside that, `AdaptiveScaffold._content` centers **`body`
  alone** in a `ConstrainedBox(maxWidth: kContentMaxWidth)` (640,
  `core/theme/app_tokens.dart`). Pages then add their own `AppSpacing.md`
  horizontal padding inside that box, so the actual text/row width is 608.
  The app bar's ends and the FAB are **not** part of `body`, so nothing
  centers them for free — `leading`/`actions` sit in the `SliverAppBar`'s
  own slots and the FAB is `Scaffold.floatingActionButton`, all three
  measured off the pane, which on a 1440px window left ~280px of gutter
  between them and the content column. They are pulled back in by
  **padding, never by constraining anything**: `AdaptiveScaffold.build`
  wraps the Material branch in a `LayoutBuilder`, reads
  `BoxConstraints.contentGutter` (`max((paneWidth - 640) / 2, 0)`, in
  `core/extensions/box_constraints.extension.dart` next to the
  `contentHorizontalInset` that is now defined in terms of it), and threads
  that one double down to `_leading`, `_actions`, `_bareBar` and
  `_floatingAction`, each of which spends it as extra `EdgeInsets` on top
  of the inset it already had. The gutter is `0` unless
  `AppPlatform.useWideWeb`, so native and phone-width web keep their exact
  previous edge insets and the `SliverAppBar.large` branch is untouched in
  practice.
  Two things that are load-bearing here:
  - **`leadingWidth` has to grow by the gutter whenever `leading` is
    padded.** `AppBar` hands its leading slot a fixed 56px
    (`_leadingSlotWidth` mirrors that framework default), so a
    `Padding(left: gutter)` inside an unadjusted slot leaves the child
    `56 - gutter` and overflows. The implied back button cannot be padded
    this way at all — it is built by `AppBar` itself — but under the
    sidebar `SuppressedBackButtonScope` has already removed it, and
    off-web the gutter is `0`, so there is nothing to align.
  - **Only the bar's *contents* move; its surface still spans the pane.**
    Wrapping the `SliverAppBar` in a `SliverPadding` would align everything
    in one line, but it also narrows the bar's background and scroll-under
    tint to 640, leaving it reading as a floating card over the empty
    gutters. Chrome stays full-bleed; only what sits in it is columnized.
  `sidebar_test.dart`'s "keeps the app bar ends and the FAB inside the
  content column" pumps a real `AdaptiveScaffold` at 1440x900 under
  `debugOverrideWideWeb` and asserts all three `getRect`s fall inside
  `[516, 1156]`. It is the only thing watching this — see the
  `kIsWeb`-is-always-false note in the sidebar section.
- **`AdaptiveScaffold(hasScrollBody: true)` hands `body` the sliver's full
  remaining space, unconstrained, and expects `body` to own a scrollable and
  center its own content — it deliberately does not wrap `body` in the usual
  `constrainWidth` `Center`/`ConstrainedBox`.** Two desktop-only bugs forced
  this, both invisible on native/touch:
  - Flutter's `SliverFillRemaining(hasScrollBody: true)` reports its
    `scrollExtent` as the *full viewport height* regardless of the child's
    actual size — built for `NestedScrollView`'s coordinator to absorb. Used
    bare in `AdaptiveScaffold`'s plain `CustomScrollView`, that phantom range
    made the outer `CustomScrollView` independently scrollable over empty
    space next to the content — a second, uncoordinated scroll region with
    its own desktop scrollbar, on top of `body`'s real one.
    `AdaptiveScaffold._ownScrollSliver` replaces it: a `SliverLayoutBuilder`
    measures the actual remaining space and hands `body` exactly that height
    through a `SliverToBoxAdapter`, so its `scrollExtent` is honest and
    `body`'s own internal `ListView`/`SingleChildScrollView` is the only
    thing that scrolls.
  - Wrapping `body` in `Center`/`ConstrainedBox(maxWidth: kContentMaxWidth)`
    the way `constrainWidth` normally does would narrow `body`'s own
    scrollable down to the centered column's render box — and a
    `Scrollable`'s hit-test region is exactly its own render box, so a mouse
    wheel over the pane's side margins would stop reaching it. **This is the
    reason no wide-web width fix may wrap a scrollable in a
    `ConstrainedBox`; reach for inset padding instead**, which is still part
    of the scrollable's render box — the same reason the app bar and FAB
    above are padded rather than constrained. `history.page.dart`'s `_ready` — the
    only `hasScrollBody: true` caller left — does exactly that, centering
    itself with `BoxConstraints.contentHorizontalInset`
    (`core/extensions/box_constraints.extension.dart`, `max((maxWidth - 640)
    / 2, AppSpacing.md)`) applied as padding inside its own scrollable.
    `LeaderboardPage`/`MatchesPage` used to be callers too, back when they
    were one `CompetitionContent` page; neither passes the flag any more —
    `LeaderboardPage` is a plain `constrainWidth` `body` page, and
    `MatchesPage` takes the `slivers` route below.
- **`AdaptiveScaffold` takes either a `body` box or a `slivers` list, never
  both** (asserted in the constructor). The sliver form exists for the
  Matches list's sticky day headers: `PinnedHeaderSliver` pins against the
  scroll view that owns the app bar, so the page's content has to *be*
  slivers in `AdaptiveScaffold`'s own `CustomScrollView` — a box handed to
  `SliverFillRemaining` has nothing to pin to, and `hasScrollBody: true`
  would give it a nested scrollable that neither pull-to-refresh nor the
  collapsing app bar can see. `MatchesPage` wraps each day in a
  `SliverMainAxisGroup` of a `PinnedHeaderSliver(DayHeader)` plus that day's
  `MatchCard`s, so a header pins only while its own day is on screen and the
  next day pushes it off; `DayHeader` paints an opaque
  `AdaptiveColors.pageBackground` for the cards to scroll under.
  `constrainWidth` still applies, but through a `SliverLayoutBuilder` +
  `SliverPadding` off `crossAxisExtent.contentGutter` (`double.extension.dart`,
  which `BoxConstraints.contentGutter` now delegates to) rather than a
  `Center`/`ConstrainedBox` — pad, never constrain, for the same reason as
  the app bar and FAB above. `test/features/match/matches_page_test.dart`
  is the only thing watching any of it, wide-web column included.
- **Web gets one deliberate page-transition, not whatever the host OS
  happens to use.** `ThemeData.pageTransitionsTheme`'s default is keyed by
  `defaultTargetPlatform`, and on Flutter Web that reflects the *browsing
  device's* OS (from the user agent) — so unmodified, the exact same web
  build plays a full iOS-style edge-slide on a Mac browser and a Material
  zoom/fade on Windows/Linux, an inconsistency nobody chose. `AppTheme.material()`
  overrides `pageTransitionsTheme` to `FadeForwardsPageTransitionsBuilder` for
  every `TargetPlatform` key, gated on `kIsWeb` (not `useWideWeb` — this one
  applies at phone-browser widths too, since mobile Safari/Chrome already
  reserve the edge-swipe gesture for their own tab back/forward, so an
  OS-style in-canvas slide competes with it). Native builds are untouched.
- **Competition-scoped navigation is a persistent left sidebar on wide web,
  not tabs bolted onto the header.** An earlier iteration tried squeezing an
  `AdaptiveSegmented` tab switcher, a "New match" button, the game-type
  filter, and a settings popover all into one `trailing` row — cramped, and
  still left Players/History as menu items instead of first-class
  destinations. `Sidebar`
  (`features/competition/presentation/widgets/sidebar.dart`) is a
  thin wrapper — `if (!AppPlatform.useWideWeb(context)) return child;`,
  otherwise a fixed-width sidebar `Row`-ed next to `Expanded(child: child)`.
  **It takes `current`, `onSelectSection` and `child` — nothing else**, and
  renders exactly once, from a `ShellRoute` above every page that has one
  (see "The sidebar is a shell, not a per-page wrapper" below); no page
  composes it. It reads `AuthBloc`, `ThemeCubit` and `CompetitionCubit` off
  the context itself and owns its own sign-out, because every call site was
  otherwise passing back the identical closure or the identical data.
  Getting there needed three things:
  `SidebarSection` (`sidebar_section.enum.dart`) enumerating **every**
  destination the sidebar can reach — leaderboard, matches, newMatch,
  players, history, configuration, competitions, language — not just the
  competition-scoped ones (it is named for the sidebar, not the competition,
  because `competitions`/`language`/`newMatch` are not competition sections);
  `current` covering all of them, so "you are already here" is a
  `section == current` early return rather than the `onOpenLanguage: () {}` /
  `onNewMatch: () {}` null-object callbacks each page used to pass; and an
  app-wide `CompetitionCubit` (see "The current competition is app-wide"
  below) the sidebar reads directly, replacing the three flattened props
  (`competitionId`/`competitionName`/`canManageSettings`) it used to be
  splatted into and the `HomeSidebarCompetition` value object that later
  bundled them.
  `CompetitionsPage` (the top-level competitions list, outside any
  competition) composes it too, always with
  `current: SidebarSection.competitions`. Whether it also shows the
  per-competition group (New match button,
  leaderboard/matches/settings/history/players, "Competition" section label)
  is simply whether `CompetitionCubit` currently holds one — so the sidebar
  the user leaves behind is exactly the one they land on, with nothing in the
  per-competition group highlighted and "Competitions" highlighted instead,
  letting them jump straight back in without a second trip through the list.
  Landing on `/` on a fresh launch, or after signing out, leaves the cubit
  empty, so the group is hidden — there's nothing to carry over. This used to
  be threaded from page to page as go_router `extra`; hoisting the cubit
  deleted that plumbing along with `HomeSidebarCompetition` itself.
  The sidebar's own account section (competition
  settings, the theme toggle, language, sign out) replaced the old gear-icon popover entirely, so
  `AdaptiveMenuButton` was deleted rather than left unused. A page pushed
  underneath the sidebar (History, Players, Settings, NewMatch — reached via
  `context.push`) would otherwise still get an auto-implied back button from
  `AdaptiveScaffold`'s app bar, since `Navigator.canPop()` is true regardless
  of the sidebar being visually present; the sidebar *is* the way back, so a
  second back arrow next to it is redundant. `Sidebar` wraps `child` in
  `SuppressedBackButtonScope` (`core/widgets/adaptive/suppressed_back_button_scope.dart`)
  whenever it renders the wide-web layout, and `AdaptiveScaffold` reads that
  ambient marker to pass `automaticallyImplyLeading: false` to both the
  Cupertino and Material app bars — this is automatic for any current or
  future page composed with `Sidebar`, no per-page opt-in needed.
  `adaptiveModalPage` (`core/widgets/adaptive/adaptive_page.dart`) is
  wide-web-aware for the same reason: native/narrow web still gets a true
  `fullscreenDialog` page (used by `match/new`), but on wide web it defers to
  `adaptivePage` instead, so New Match reads as an in-place page inside the
  sidebar rather than a modal takeover of the whole viewport.
### The sidebar is a shell, not a per-page wrapper

`Sidebar` is rendered once, by `SidebarShell`
(`features/competition/presentation/widgets/sidebar_shell.dart`) from a
go_router `ShellRoute` that wraps `/`, `/settings/language`, `/create`,
`/upgrade`, and the whole `/competition/:id` subtree. Only `/splash` and
`/sign-in` stay outside it and have no sidebar. Pages therefore
compose only their own `AdaptiveScaffold`; none of them mention `Sidebar`.
A page that is a *task* rather than a destination has to carry its own way
back, since the shell's `SuppressedBackButtonScope` kills the implied one:
`CreateCompetitionPage._backButton` returns an `AdaptiveIconButton` only when
`SuppressedBackButtonScope.of(context)` is true, so native and narrow web keep
the platform's own arrow untouched; `UpgradeAccountPage` already passes an
explicit `leading` on every step, and an explicit `leading` bypasses the
suppression outright. Highlighting a sidebar section for such a page is *not*
the alternative — `Sidebar._select` early-returns on `section == current`, so
marking `/create` as `SidebarSection.competitions` would make the row that
leads back out unclickable.
`SettingsPage` and `MatchDetailPage` gain a sidebar on wide web as a
side effect of living in that subtree — `SettingsPage` is unreachable there
anyway (its rows are sidebar items), and a full-viewport match detail next to
a sidebar-shaped app was the odd one out.

**`SidebarShell` owns navigation; `Sidebar` no longer navigates at all.**
`Sidebar._select` is `if (section == current) return; onSelectSection(section)`
and nothing else — `onSelectSection` is required, and the shell is its only
caller. The shell derives `current` purely from `state.uri.path` — a
`location.endsWith('/leaderboard')`/`'/matches'` check, now that each tab is
its own route (see "Leaderboard and Matches are routes, not tabs" below) —
and navigates with **`context.go`, never `push`/`pop`**: with a
sidebar that is always on screen, a section is a destination, not something
stacked on top of what came before, so `go` sets the whole stack
deterministically and the browser's back button walks it. This deleted the
previous hub-and-spoke arrangement wholesale — `Sidebar` popping a
`SidebarSection` back to a `CompetitionContent` that was awaiting it,
`_openAndReload` re-applying whatever came back, and the null-object
`onSelectSection` overrides — along with the class of bug that produced (a
`pushReplacement` completing the replaced route's popped future with `null`,
so a section picked two pages deep never arrived).

Two things had to move for `go` to be safe here:

- **The `settings/*` routes are declared as siblings, not children of
  `settings`.** `go` builds a page for every route in the matched chain, so
  nesting them under `/competition/:id/settings` would have put `SettingsPage`
  in the stack underneath Players/History/Configuration — and had it call
  `setPageTitle` on the way past. The paths are unchanged
  (`path: 'settings/players'` under `/competition/:id`); only the nesting is.
- **`PlayersCubit` moved up to the competition `ShellRoute`**, so every
  sub-page shares one instance rather than building its own. `go` keeps that
  `ShellRoute` mounted underneath whatever page it navigates to, so without
  this `PlayersCubit` would still be holding the player list from before you
  opened the Players page — it has no realtime subscription to save it,
  unlike `MatchListCubit`/`LeaderboardCubit` (which didn't need the same
  hoist; see "Leaderboard and Matches are routes, not tabs" for why). Sharing
  removes the staleness at the source, which is why there is no
  refresh-on-return machinery for it: nothing refetches `PlayersCubit` after
  a navigation, only pull-to-refresh does. The one thing outside that shared
  instance is the competition itself (a rename in Configuration), so
  `SidebarShell._select` calls `CompetitionCubit.refresh()` on every hop.

Native and narrow web are untouched by all of this: `Sidebar` still returns
`child` unchanged below the breakpoint, so the bottom tab bar, `SettingsPage`
menu and every `context.push` still behave exactly as they did.

### Leaderboard and Matches are routes, not tabs

`/competition/:id/leaderboard` and `/competition/:id/matches` are each a real
`GoRoute`, branches of one `StatefulShellRoute.indexedStack` — not, as they
used to be, one `CompetitionContent` page switching on a `CompetitionTabCubit`
enum. `CompetitionTabCubit` is gone entirely: a shell above the page used to
need somewhere to put "which tab" state a page's own `setState` couldn't
reach, but a route *is* that state now, and `StatefulShellRoute` already
tracks which branch was last active without a cubit. Opening a different
competition still always lands on the leaderboard, but that's now just where
the bare `/competition/:id` URL redirects to, not a cubit `CompetitionScope`
resets on entry.

The trigger was the sidebar itself: a route it could highlight and deep-link
to, matching how Players/History/Configuration already worked, rather than a
shared page with an internal tab enum the sidebar had to reach into.
`LeaderboardCubit`/`MatchListCubit` each moved into their own branch's leaf
`GoRoute` rather than the shared competition `ShellRoute` `PlayersCubit`
sits in — each branch already keeps its own state alive across a tab switch
(that's what `StatefulShellRoute.indexedStack` is *for*), so there's no
staleness to guard against there the way there was for `PlayersCubit` under
a plain `push`/`pop`-style sub-page.

Two non-obvious things this needed, both load-bearing and covered by nothing
else in the suite:

- **The bare `/competition/:id` `GoRoute`'s `redirect` must check
  `state.matchedLocation == state.uri.path` before firing, not redirect
  unconditionally.** go_router calls a route's `redirect` for *every* route in
  the matched chain, not just the terminal one — an unconditional
  `redirect: (_, state) => '${state.matchedLocation}/leaderboard'` bounces
  every navigation under `/competition/:id` (settings, `match/new`, even the
  branches themselves) straight back to `/leaderboard`, since that ancestor
  route is still part of the chain on every one of those. Comparing
  `matchedLocation` (this route's own matched segment) against `uri.path`
  (the full requested location) is what limits the redirect to the bare path.
- **Switching *competitions*, not tabs, does NOT tear the branches down, and
  each branch's `BlocProvider` has to carry `key: ValueKey(id)` to compensate.**
  go_router derives a page's key from the *route pattern*, not the resolved
  location (`RouteMatchBase.match` → `pageKey: ValueKey(newMatchedPath)`,
  where `newMatchedPath` is built from `route.path`), so
  `/competition/c1/leaderboard` and `/competition/c2/leaderboard` produce the
  identical `ValueKey('/competition/:id/leaderboard')`. `Navigator`'s page
  diffing therefore *updates* the existing route in place instead of
  replacing it, `LeaderboardPage`'s `State` survives, and `BlocProvider`'s
  `create` — which only ever runs once per element — keeps handing out the
  previous competition's `LeaderboardCubit`. Same for `MatchesPage`/
  `MatchListCubit`. Keying the `BlocProvider` by the competition id is what
  forces a new element, hence a new cubit and a fresh `initState` `load()`.
  The competition `ShellRoute`'s `KeyedSubtree(key: ValueKey(id))` does *not*
  save this: everything below it is a `GlobalKey`'d Navigator
  (`ShellRoute.navigatorKey`, `StatefulShellBranch.navigatorKey`,
  `StatefulShellRoute._shellStateKey`, all created once per route *config*),
  so an id change reparents those elements intact rather than rebuilding
  them. It only reaches as far as the `MultiBlocProvider` it directly wraps,
  which is why `PlayersCubit` alone gets a genuinely fresh instance from it.
  Re-keying the competition `ShellRoute`'s own page instead is not an option
  — the outgoing and incoming pages would both be mounted during the
  transition, each claiming those same Navigator `GlobalKey`s.
  `test/flow/switch_competition_flow_test.dart` walks the real mobile path
  (leaderboard → `push('/')` → `go('/competition/c2')`) and asserts both
  cubits and the player list actually followed.

`CompetitionShell` (`features/competition/presentation/pages/competition_shell.dart`)
is what the `StatefulShellRoute`'s `builder` returns, wrapping
`navigationShell` — it replaced `CompetitionContent` and shrank to just
`RecentCompetitionStore.set`/`PlayersCubit.load()` (from `initState` *and*
`didUpdateWidget`, since for the reason above it is updated, not remounted,
when the competition id changes — without the second call the freshly built
`PlayersCubit` would sit in `PlayersLoading` forever) and a `BlocListener`
bouncing to `Routes.home` on `CompetitionMissing`.
`CompetitionTabBar` (`features/competition/presentation/widgets/competition_tab_bar.dart`)
is the bottom tab bar both pages render: it takes only primitives
(`competitionId`, `current`, `isRegistered`) and navigates itself via
`context.go`/`push` rather than `onSelectTab`/`onNewMatch` callbacks — every
call site would have passed the identical closure, the same reasoning that
has `Sidebar` read `ThemeCubit` from context instead of a callback prop.
`CompetitionSettingsButton` is the same move for the settings icon both
pages show in their (non-wide-web) app bar trailing slot.

  **The competition the sidebar renders must come from `CompetitionCubit`,
  never from the page's own cubit** — which is now structural, since the
  sidebar reads that cubit itself and takes no competition prop at all.
  `ConfigurationCubit`/`HistoryCubit`/etc. all start out `loading` with their
  own `competition` field `null` even though `CompetitionCubit` already has
  the answer. Sourcing `canManageSettings` from the page's own cubit instead
  briefly evaluates to `false` while that cubit's own fetch is in flight, so
  an owner-only nav row (e.g. "Competition settings") visibly disappears and
  reappears a moment later.
  **Almost no test exercises this** — `kIsWeb` is always `false`
  under `flutter test`, so `useWideWeb` never trips regardless of the pumped
  viewport size, which is exactly why `AppPlatform.debugOverrideWideWeb`
  exists: `sidebar_test.dart` is the one file in the suite that sets it, and
  it caught a real `RenderFlex` overflow (a nav-item label missing its
  `Expanded`) on the first run — a reminder that this whole surface is otherwise invisible to
  `flutter test` and worth exercising explicitly whenever it changes. Two of
  its tests pump a real `GoRouter` around `SidebarShell` rather than `Sidebar`
  alone, since the shell's location-to-`current` mapping and its `go` calls
  are the parts with nothing else watching them. The sidebar's own background/border colours
  come from `AdaptiveColors.surfaceTint`/`divider` (`colorScheme.surfaceContainerLow`/
  `outlineVariant`), not a translucent tint over nothing — the sidebar sits
  outside `AdaptiveScaffold`'s own themed background, so a low-alpha neutral
  fill there blends against the page canvas rather than the app's actual
  surface colour and reads as stuck-in-light-mode regardless of theme.

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
- **`SliverAppBar.large` mounts its title widget for both the collapsed and
  expanded app bar at once**, so a widget test finding a page's plain title
  text legitimately gets two matches (`findsWidgets`, not `findsOneWidget`) —
  `history_page_test.dart`'s season-picker test is the one that depends on
  this: the dropdown that replaces the title in the picked state is the thing
  actually asserted `findsOneWidget`, the plain title text is deliberately
  `findsWidgets`.
- **The current calendar season has no `seasons` row until its first match is
  created** (`season_window()` returns `season_id = null`), so the `leaderboard`
  view — inner-joined from `seasons` — cannot be queried for it. Before a
  season starts, `SupabaseLeaderboardRepository.leaderboards()` falls back to a
  players read (`players` embedding `competitions(starting_rating)`) so the
  page still shows everyone at the starting rating instead of an empty list.
  `Leaderboard.seasonId` is nullable for exactly this synthetic case.
- **A sheet that guards its own dismissal needs `showAdaptiveSheet(
  confirmsDismissal: true)`, not just a `PopScope`.** `NewMatchSheet` asks
  before throwing away a half-filled match, via a `PopScope` whose `canPop`
  is `!_hasUnsavedInput(state)`. Barrier taps, the Android back button, and
  our own `ScrollDismissibleSheet` drag all route through
  `Navigator.maybePop`, which consults that `PopScope` — but Flutter's
  Material `showModalBottomSheet` has a *second*, built-in drag-to-close
  whose `onClosing` calls `Navigator.pop(context)` directly
  (`_ModalBottomSheetState.build` in `bottom_sheet.dart`), so it slips
  straight past the guard and `ModalBottomSheetRoute.enableDrag` is `final`
  and cannot be flipped once the route exists. `confirmsDismissal` is
  therefore decided at show time and does exactly one thing: pass
  `enableDrag: false` on the Material branch, leaving `ScrollDismissibleSheet`
  (which uses `maybePop`) as that sheet's only drag path. Cupertino and the
  wide-web dialog branch need nothing — neither has a drag of its own.
  `_submit` pops with a bare `Navigator.pop`, which ignores `PopScope`, so a
  successful save never prompts.

- **`GameTypeFilterCubit` is a `registerLazySingleton`, scoped to the
  Matches list alone.** It's the one thing in the app that still cares about
  `game_type` beyond storing it on the match row — `MatchListCubit` is its
  only subscriber, re-fetching `MatchRepository.feed(gameType:)` on every
  emission (`MatchListCubit._applyGameType`). Leaderboard, History, and
  Profile read only the combined (all game types) track and take no
  `gameType` parameter anywhere in their repositories — there used to be a
  second, parallel per-game-type Elo track (`player_game_type_ratings`, the
  `game_type_leaderboard`/`game_type_season_history`/`game_type_player_medals`
  views, a `gameType` param threaded through every match-derived repository
  method) feeding a shared game-type filter across all four screens; it was
  removed as unnecessary scope, and `game_type` reverted to being purely a
  per-match snapshot plus the Matches-list filter. Don't reintroduce a
  `gameType` parameter on `LeaderboardRepository`/`ProfileRepository`
  methods, or a second `game_type_*` sibling view, without deciding that
  scope is coming back on purpose.
- **`ProfileSheet` has three cubits, one per tab, not one `ProfileCubit`.**
  Overview, Versus, and History are never visible at once, so only
  Overview (the default tab) loads eagerly, the same way the old single
  cubit did. `ProfileVersusCubit`/`ProfileHistoryCubit` are built
  lazily by `ProfileSheet` itself via `getIt` — the first time a tab is
  actually opened, not when the sheet is — and closed by the sheet's
  `dispose()` since nothing else owns them; a tab that's never opened never
  fetches anything. `ProfileOverviewCubit.hasOpponent` is computed once at
  `load()` time from `viewerPlayerId != playerId` — no fetch needed to
  decide whether the Versus segment even appears.
  `ProfileOverviewCubit.profileStats` bundles what used to be five separate
  round trips (`totalMatchesPlayed`/`bestStreaks`/`bestRating`/
  `currentStreak`/`recentPlayed`, all single-row results for the same
  `(player, season)`) into one `player_profile_stats` RPC (20260816130000);
  `leaderboards`/`recentForPlayer`/`medals`/`ratingHistory` stay separate
  calls, since those are genuinely different, list-shaped fetches.
  `ProfileRepository.profileStats` accepts a nullable `seasonId` — the RPC
  treats "no season yet" as "no matches" (same as `player_streak`/
  `player_recent_played` already did), so the Dart side no longer needs to
  gate this specific call on `seasonId != null` the way `leaderboards`/
  `ratingHistory` still do.

## Commands

```bash
flutter analyze                 # must stay clean
flutter test                    # 247 tests at time of writing
flutter gen-l10n                # after editing any .arb

python3 scripts/generate_icon.py   # redraw assets/icon/*.png
dart run flutter_launcher_icons     # then push them into ios/ android/ web/
flutter run -d chrome           # web
flutter build web
flutter build apk --debug        # verified green

./scripts/db.sh -c "select 1"                 # ad-hoc SQL
./scripts/db.sh -f supabase/migrations/X.sql  # apply a migration
./scripts/db.sh -f supabase/seed.sql          # reseed + run assertions
./scripts/db.sh -f supabase/tests/rls_check.sql      # RLS verification, rolls back
./scripts/db.sh -f supabase/tests/players_check.sql  # players + settings writes
./scripts/db.sh -f supabase/tests/no_op_recalc_check.sql  # no-op write guards, rolls back
./scripts/db.sh -f supabase/tests/incremental_recalc_check.sql  # boundary-scoped replay, rolls back
```

## Git workflow

- Commit messages follow **Conventional Commits**: `<type>(<scope>): <description>`
  (e.g. `feat(competition): add leave-competition action`, `fix(auth): ...`).
  Common types: feat, fix, refactor, chore, docs, test, style, perf, build, ci.
- **Commit straight to `main`.** This is a solo repo — skip branching before
  committing even though `main` is the default branch.
- **When a chunk of work is done and the user starts on a new feature or
  area, ask whether to commit before continuing.** Don't commit unprompted —
  offer, and wait for a yes.
- **A pile of unrelated changes gets split into multiple logical commits**,
  not one big one — group by feature/fix/copy/docs the way a reviewer would
  expect to see them. Still no branches for this: stage per group with `git
  add <files>` and commit, and reach for `git stash` (push/pop, or `git stash
  push -- <paths>`) when a single file mixes changes that belong in different
  commits and need to land separately.

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
- **`supabase/seed.sql` is a one-shot seeding script, not a repeatable check** —
  it unconditionally calls `create_competition`, so re-running it against a
  database that already has its data creates a duplicate competition rather
  than just asserting and exiting. Read what a script actually does before
  running it against the live project; don't assume "asserts an invariant"
  means "safe to re-run." (See `MISTAKES.md`.)
- `supabase/tests/no_op_recalc_check.sql` proves `apply_match_ratings`'s
  `IS DISTINCT FROM` guards actually skip no-op writes — replaying an
  already-consistent season must rewrite zero `matches`/`match_players` rows
  (checked via `xmin`), not just arrive at the same final ratings.
  Self-contained (creates its own throwaway competition), rolls back.
- **`recalc_season` (full, from-scratch replay) is no longer on any write
  path** — `create_match`/`update_match_score`/`delete_match` call
  `recalc_season_from` instead, which seeds `player_ratings` from each
  player's state as of the last match strictly before the boundary (their
  `rating_after` plus a `played`/`wins`/`losses`/`draws` count over
  everything before it — the only historical record available, since
  `player_ratings` itself only ever stores the current total) and then
  replays only matches at/after it. The boundary is the earliest position the
  write could possibly affect: the new match's own position for a create, the
  earlier of a match's old/new position for a score edit (same match id
  either side, so the tuple comparison reduces to comparing `played_at`), the
  deleted match's old position for a delete, and — if a score edit moves a
  match to a different season — both seasons replayed independently from
  their own boundary. `player_ratings` itself is still fully deleted and
  rebuilt per season on every write (that part wasn't worth the extra
  complexity to make incremental too); it's `matches`/`match_players` that
  this actually shrinks, from every row in the season down to just the
  affected match(es). `recalc_season` stays available as a genuine
  full-rebuild primitive — `supabase/seed.sql`'s incremental-build-equals-replay
  invariant exercises it directly, and nothing else calls it.
  `supabase/tests/incremental_recalc_check.sql` is the correctness gate:
  after every write RPC's boundary-scoped replay, a from-scratch
  `recalc_season` on the same season must land on byte-identical
  `player_ratings` and `match_players` — checked at several boundary
  positions (an ordinary create, a back-dated create, editing an early
  match, deleting a non-final match, moving a match to a different season)
  plus once more directly against the live seeded competition's real match
  history. Self-contained, rolls back.
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

### Web hosting — TODO, not yet set up

`main.dart` calls `usePathUrlStrategy()`, so deep links look like
`/competition/abc123` instead of `/#/competition/abc123`. That only works if
the web host rewrites unknown paths to `index.html` (routing happens
client-side) — a hard refresh or a shared link to a nested route will 404
otherwise. Whichever static host ends up serving `flutter build web`'s output
needs that rewrite rule configured before going live; not done yet.

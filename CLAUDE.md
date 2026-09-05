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

`/competition/:id` redirects to `/competition/:id/leaderboard` — Leaderboard, Matches and
Competitions are each a real route, not a tab switch inside one page: a
`StatefulShellRoute.indexedStack` with
one branch per route (`features/competition/.../competition_shell.dart`'s `CompetitionShell`
wraps the `navigationShell`; see "Leaderboard and Matches are routes, not tabs" below for why
and how). `LeaderboardPage` (`features/leaderboard/presentation/pages/leaderboard.page.dart`,
join code + invite + `ProfileSection` + the actual ranked list, which is `LeaderboardList` in
the feature's `presentation/widgets/leaderboard_list.dart`) and `MatchesPage`
(`features/match/presentation/pages/matches.page.dart`) are each a full routed page — own
`AdaptiveScaffold`, own `LeaderboardCubit`/`MatchListCubit` loaded in their own `initState`.
Players has its own settings route, not a branch — see "Leaderboard and Matches are
routes, not tabs" for why. The leaderboard tab always shows the
current calendar window — which has no row until the first match lands in it.
It has no season picker: that moved to
`/competition/:id/settings/history` (`HistoryPage`), which shows one
finished season at a time — `SeasonFilterButton` in the app bar's `trailing`
slot opens `SeasonSheet`, which picks among `HistoryState.seasons` (the lean,
already-loaded season list — id/starts_at/ends_at only, no leaderboards — so
the picker itself needs no separate fetch), selecting one fetches just that
season's leaderboard, and the chosen season heads the list as a `ListHeader`
— the same title-plus-subtitle block `LeaderboardList._seasonBar` uses, so
both pages name their season identically; only the subtitle differs
(`Ends <date>` for the running season, the finished season's date range in
History). Neither tab filters by game type —
that's Matches-only, see below.

Logging a match, inspecting one, and joining or creating a competition are all
sheets, not routes — there is no `match/*` route, no `Routes.match`, no
`Routes.joinCompetition` and no `Routes.createCompetition`, so none of them is
deep-linkable, and each builds its own cubit inside the `showAdaptiveSheet`
builder rather than in a `GoRoute`. `showJoinCompetitionSheet` and
`showCreateCompetitionSheet` each return the competition's id (or null), and
`CompetitionsPage` is what refreshes `CompetitionListCubit` and goes to the
competition — neither sheet navigates. `CreateCompetitionSheet`
(`competition/presentation/pages/create_competition_sheet.dart`) replaced
`CreateCompetitionPage` and the `/create` route outright: same
`CreateCompetitionCubit`, same name field and season-length segmented control,
with the submit button in `Sheet.primaryButton` (labelled
`competitionsCreateShort` — the sheet's own title already says "Create
competition", which is what retired the `competitionCreateSubmit` key) and
Cancel beside it. `showNewMatchSheet` builds the teams and submits.

**Join opens the camera first, and the code field is the way out of it.**
`CompetitionsPage._join` shows `showJoinScannerSheet`
(`competition/presentation/pages/join_scanner_sheet.dart`) and only then
`showJoinCompetitionSheet`, so the six-character code is the fallback rather
than the front door — the QR a competition already shows off every
`CompetitionCard`, `InviteSheet` and `ActiveCompetitionCard` encodes nothing
but that code (`JoinQrImage(code: code)`), which is what makes scanning and
typing the same flow. The scanner pops a `JoinScanResult`: `scanned(code)`
from the camera, `manualEntry()` (a null `code`) from the "Enter code
manually" button, and `null` from Cancel or a dismissal — that third case is
the only reason the result is a type rather than a `String?`, since the page
must tell "the user backed out" from "the user wants to type it". A
non-null code is handed to `showJoinCompetitionSheet(code:)`, which calls
`JoinCompetitionCubit.lookUpCode` in the provider's `create`.

**One sheet route, one file per step.** `showJoinCompetitionSheet` opens a
single `showAdaptiveSheet`; `JoinCompetitionSheet`
(`join_competition_sheet.dart`) is the stateless `BlocConsumer` inside it that
maps `JoinCompetitionState` onto `JoinCodeSheet` (`join_code_sheet.dart`),
`JoinLookUpSheet` (`join_look_up_sheet.dart`) or `JoinConfirmSheet`
(`join_confirm_sheet.dart`), and each of those pops the route itself with a
`JoinResult`. The steps are *widgets in one route*, not routes of their own —
`JoinCompetitionCubit.back()` moves confirm → code without any navigation, so
splitting them into pushed sheets would put a second, parallel back path next
to it. Only `JoinCodeSheet` is stateful, since the
`TextEditingController` is the code step's alone; it seeds from
`JoinCode.code` in a `late final`, which is load-bearing now that
`back()` from the confirm step builds a *fresh* `JoinCodeSheet` rather than
returning to a `State` that still held the text.

**A scanned code never shows the code field, and `Back` goes back to the
camera.** With `code != null` the sheet is confirm-shaped throughout
(`isScanned`): the `JoinCode` phase renders `JoinLookUpSheet` — a spinner, or
the lookup's failure — rather than `JoinCodeSheet`, and `Back` pops the sheet
with `JoinResult.back()` instead of calling `JoinCompetitionCubit.back()`.
`CompetitionsPage._scanAndJoin` loops on that: scanner → sheet → `back()` →
a *fresh* scanner sheet. It has to be fresh rather than a sheet stacked on
the live one, because `DetectionSpeed.noDuplicates` would refuse to re-read
the QR still in frame; a new `QrScannerView` is a new controller with no
memory of it. Hence `showJoinCompetitionSheet` returns a `JoinResult` rather
than a `String?` — the same reasoning as `JoinScanResult` above, since
`null` (Cancel, or a drag/barrier dismissal) has to end the flow where
`back()` restarts it. In manual-entry mode `isScanned` is false, nothing ever
returns `back()`, and the code step's Cancel closes as it always did.
`String.isJoinCode` (`core/extensions/string.extension.dart`) is the one
definition of "six characters once normalized", shared by `JoinCode.codeIsValid`
and the scanner — a QR carrying anything else (a URL, someone's WiFi) is
**ignored rather than rejected**, so the camera simply keeps scanning instead
of erroring on every poster it sees.

`QrScannerView` (`core/widgets/qr_scanner_view.dart`) is the only file in
`lib/**` that imports `package:mobile_scanner`. It drives the controller
itself — `autoStart: false` plus its own `start()` in `initState` — rather
than letting `MobileScanner` start one, because a start that throws (camera
permission denied, no camera, no plugin) is the case worth rendering: both
that catch and the widget's `errorBuilder` land on the same
`unavailableMessage`, and the "Enter code manually" button is right there
under it. `DetectionSpeed.noDuplicates` plus the sheet's own `_closing` guard
are what stop a held-up QR popping the sheet twice. **`flutter test` never
gets past the placeholder**: under the test binding `start()` never resolves,
so the square renders empty and neither the message nor a live preview is
reachable — `join_scanner_sheet_test.dart` therefore drives scanning by
calling `QrScannerView.onCode` off the widget directly, and nothing in the
suite covers the camera itself. iOS needs `NSCameraUsageDescription` in
`ios/Runner/Info.plist`; Android needs nothing (the plugin's own manifest
declares `CAMERA`, and its minSdk 23 is under Flutter's default 24). The
bundled ML Kit model is left bundled — `dev.steenbakker.mobile_scanner.useUnbundled=true`
would cut ~3-10 MB off the APK at the price of a Play-Services download before
the first scan works.
`TeamPickerSheet`'s "Manage players" button opens `showManagePlayersSheet`
(`player/presentation/pages/manage_players_sheet.dart`) on top of the picker
rather than popping and pushing `Routes.players` — the sheet builds its own
`PlayersCubit` via `getIt` (a nested sheet route inherits no providers from the
route underneath it), and `NewMatchSheet._managePlayers` refreshes
`MatchFormCubit` afterwards and hands the picker back the refreshed player
list through `TeamPickerSheet.onManagePlayers`, so a player added there
is selectable without closing anything (the picker does its own
already-on-the-other-side filtering now, so what it gets back is every active
player, not one side's selectable subset).

**The new match sheet opens on a `1v1` / `Teams` toggle
(`AdaptiveSegmented<MatchEntryMode>`), and that mode drives the whole form.**
`MatchEntryMode` (`presentation/cubit/match_entry_mode.enum.dart`, exported
through `match_form_state.dart`) lives on `MatchFormReady`; it defaults to
`oneVsOne`. In `oneVsOne` the two `TeamArea`s are titled Player 1 / Player 2 and
say `matchTapToSelectPlayer`, and the score fields' labels follow the same
`_sideLabel` — in the form the mode is never re-derived from how many players
happen to be on a side. Switching to `oneVsOne` clears any side already holding
more than one player (`MatchFormCubit.setMode` → `_withoutCrowdedSides`); a side
holding exactly one survives.
**The sides are numbered, not lettered** — `Team 1`/`Team 2`, `Player 1`/
`Speler 1` — while the l10n *keys* still read `matchTeamA`/`matchPlayerB`, so
don't read a letter off a key name and assume it reaches the screen.

**Everywhere else that names a side asks the match, not a mode.**
`MatchTeam.label(context, isOneVsOne:)`
(`core/extensions/match_team.extension.dart`) is the single mapping from side +
one-v-one-ness to a string; `MatchDetailSheet._teamArea` and `MatchScoreSheet`
pass `MatchEntry.isOneVsOne` (both sides hold exactly one player) where the new
match form passes `MatchFormReady.isOneVsOne` (the toggle). So a 1v1 logged in
the form still reads Player 1 / Player 2 when it is opened again from the feed,
without the match row having to store which mode it was entered in.

**`TeamPickerSheet` is one sheet with two steps, not one sheet per side.** It
takes both sides' initial selections plus a `startSide`, keeps `_selected` for
both, slides between them inside its own `AnimatedSwitcher` (start-aligned
`Stack` layout builder, direction from `_forward` — the transition builder
compares each child's `ValueKey<MatchTeam>` against the current side so the
outgoing step leaves by the opposite edge, which `AnimatedSwitcher` cannot
work out on its own), and pops a single `TeamPickerResult(teamA, teamB,
isComplete)` that `NewMatchSheet` applies in one `MatchFormCubit.setTeams`.
Because both sides live in the sheet, "a player already on the other side is
not offered here" is now a live check against `_selected`, not a list filtered
once at open time. In `teams` the steps are advanced by the buttons — `Next`
on A, `Previous`/`Next` side by side on B, where B's `Next` finishes; in
`oneVsOne` picking a name *is* the advance, so step A has no button at all and
step B carries only `Previous`. `isComplete` distinguishes finishing from
dismissing: both keep the selections, only finishing pulls focus into the
Team A score field (`_scoreAFocus`, hence `AdaptiveTextField.focusNode`). One
consequence of the spec: on `oneVsOne`'s step B with a selection already
made, re-tapping that same name is what confirms it, since there is no `Next`
there.
`Sheet.primaryButton`/`secondaryButton` are `Widget?` rather than
`AdaptiveButton?` for this — B's step needs a `Row` of two — and every other
call site still passes a plain `AdaptiveButton`.
`showMatchDetailSheet` (`match/presentation/pages/match_detail_sheet.dart`)
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
- **A claimed player's name belongs to the person behind it.** The owner may
  rename an *unclaimed* player and their own row, and may deactivate or
  restore anyone; renaming a row somebody has claimed is that person's alone,
  even for the owner. `Players._canRename`/`_canRemove` are the UI half —
  `PlayerRow` shows its Edit button when either is true, so an owner still
  reaches a claimed player's action sheet, it just holds no Rename.
  Enforced by the `players_guard_rename` trigger (20260902110000), **not** by
  RLS: `players_update_owner_or_self` still admits the owner's UPDATE, since
  a policy sees either the existing row (`USING`) or the incoming one
  (`WITH CHECK`) and never both, and this rule is a comparison between them.
  So it is the one player write refused with a `P0001` exception rather than
  by matching no rows — the silent-`maybeSingle()` premise the rest of
  `players_check.sql` rests on does not apply to it. `auth.uid()` is null
  outside a request, which makes the guard's condition `NULL` rather than
  true, so psql and service-role renames deliberately still pass.
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

- **Create competition** — `competitions.page.dart`, `canCreate: session.canWrite`,
  which is whether the bar's create action is rendered at all; the join action
  is always there.
- **Add/manage players, owner settings** — `players.page.dart` →
  `widgets/players.dart`, `isRegistered: session.canWrite`. **Every entry
  point *into* player management is a step stricter than that: owner-only,
  `session.canWrite && competition.isOwnedBySession(session)`** — the
  Settings row and the sidebar's Players row (`canManageSettings`, the same
  flag Configuration uses), the leaderboard's Manage players button
  (`LeaderboardList.isOwner`), and the team picker's
  (`TeamPickerSheet.canManagePlayers`). A registered non-owner reaching the
  sheet another way still sees the roster and may rename themselves —
  `Players` keeps its own finer-grained `_canRename`/`_canRemove`, and this
  gate is about not advertising a screen whose actions are all owner-only.
- **Create a match** — the "new match" bottom tab item is omitted entirely for
  guests in `competition_tab_bar.dart`; `matches.page.dart` shows
  `GuestNotice` instead of the new-match affordance.
- **Edit/delete a match** — `match_detail_sheet.dart`,
  `session.canWrite && state.isManageableBy(session.user?.id)` (creator or
  owner only, not just registered).
- **History** (`settings.page.dart`) is deliberately *outside*
  this gate — it's read-only historical data a guest may read. Competition
  Settings and Manage players in the same menu stay gated, both to the owner.

## Architecture

```
lib/
  app/          router (+ auth redirect), DI, app shell, splash screen
  core/         config, error, theme, widgets/adaptive, widgets/state_views
  features/<name>/
    domain/     entities + abstract repository
    data/       Supabase-backed repository implementation
    presentation/ cubit/ (state) + pages (routed pages and sheets) + widgets
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
  `clearIfSelected(id)` after a successful leave/delete for the same reason,
  though that one emits `CompetitionMissing` rather than `CompetitionLoading`
  — see below.

**Leaving or deleting a competition resets two things.**
`CompetitionsPage._forget` is that reset, shared by both actions:
`CompetitionCubit.clearIfSelected(id)` and
`RecentCompetitionStore.clearIfRecent(id)`. The list itself needs nothing,
since `CompetitionListCubit._mutate` already refreshes. Clearing the recent id
here rather than leaving it to the router's launch-time `isMember` check
matters because that check deliberately keeps the stored id when the list load
*fails* — a network blip must not wipe it — so "we actually know it is gone"
has to be recorded at the moment we know.

**Leaving or deleting the competition whose shell you are standing in drops
you out of that shell, and `clearIfSelected` emitting `CompetitionMissing` is
the whole mechanism.** Both entry points are on the competitions list itself —
the spotlight card's Manage button, reachable at `/` and at the in-shell
`/competition/:id/competitions` branch — so the page you land on is the list
you were already looking at, minus the tab bar. Nothing in `CompetitionsPage`
navigates: it clears the cubit, and `CompetitionShell`'s existing
`BlocListener` on `CompetitionMissing` (which already handles a competition
that vanished server-side) clears the recent id and `go`es to `Routes.home`.
`Missing` is the honest state — `overview()` would return null for a
competition you are no longer a member of — and routing the departure through
it is what avoids a second, parallel "the competition went away" path.

`clearIfSelected` used to emit `CompetitionLoading` instead, and the shell was
deliberately left to stay put. The cost was not survivable: the shell kept
rendering `CompetitionTabBar` for the dead id, so Leaderboard and Matches
stayed one tap away serving their branch cubits' stale pre-departure data over
a dead realtime channel, `CompetitionScope` could not re-`select` because the
route's id never changed, and `CompetitionCubit` sat in `CompetitionLoading`
with a null `_competitionId` — so `load()` early-returned forever and every
page reading it spun. The same thing happened on wide web, where the sidebar
kept the departed competition's group.

**Sign-out is the one clear that must *not* go through `Missing`.**
`_onSession` resets to `CompetitionLoading` on its own rather than reusing
`clearIfSelected`'s emit, because the shell's listener would otherwise race
`go(Routes.home)` against the router's own redirect to `/sign-in`. The two
paths are spelled out separately in the cubit for that reason; the shared
`_clear()` helper they used to call was hiding the distinction.
`test/flow/leave_competition_flow_test.dart` walks the real path (leaderboard
→ Competitions branch → Manage → Leave) and is the only thing watching it.

"No competition selected" is deliberately **not** a fifth state: it is never
rendered. Only pages inside the competition subtree switch on
`CompetitionState`, and `CompetitionScope` has always called `select` before
they build, so `CompetitionLoading` is the honest initial (and post-sign-out)
value; leaving or deleting lands on `CompetitionMissing` instead, per above. The sidebar reads `state.competition` opportunistically and treats
`null` as "hide the competition group".

**The competitions page spotlights the active competition above the list.**
`ActiveCompetitionCard`
(`competition/presentation/widgets/active_competition_card.dart`) is the
hero `CompetitionsPage` renders first — **surfaced rather than tinted**: a
solid `AdaptiveColors.modalSurface` fill on `AppRadius.lg` corners inside a
plain grey hairline (`AppColors.neutral` at `AppOpacity.controlBorder`). No
accent wash and no accent border — the accent survives only in the eyebrow
text and the code badge, so the card is marked by being the one opaque,
outlined surface in a list where every `CompetitionCard` is a borderless
translucent neutral. It carries an eyebrow row of
"Active competition" against the join code as a `JoinCodeTag` — the same
badge a `CompetitionCard` wears, at the same size — then the
name and the player/match counts across the **full** card width beneath it,
then a 200px `JoinQrImage` centred below all of it, big enough to scan off the
page. The code shares the eyebrow's row rather than the name's precisely so
that a long name gets the whole card to wrap into instead of a column beside a
badge; `competitions_page_test.dart` pins that by asserting the name's row
reaches past the code's left edge. So
"which competition am I in" and "how does someone else get in" are both
answered without opening anything. **The QR carries no tap of its own** — it
is a thing to scan, not a button, and a nested tap target inside a card that
is itself one tap only made the card's own destination ambiguous;
`InviteSheet` renders this very card, and is still reached from every
`CompetitionCard`'s invite button (see below). Which competition that is comes from
`CompetitionCubit`, the same app-wide answer the sidebar reads, matched
against the already-loaded `CompetitionListReady.competitions` for the counts
and ownership — so the page makes no extra request, and renders no hero at all
when the cubit is empty (a fresh launch, or after signing out) or when it
holds a competition the user has since left. That competition is then
**dropped from the list below**, with the rest headed by a
`ListHeader(competitionsOther)`; the card carries its own Manage button so
rename/leave/delete stay reachable for it. Tapping the card is
`go(Routes.competition(id))` exactly like a `CompetitionCard`, anywhere on it.
`JoinQrImage` is the white quiet-zone box `JoinQrCard` was built around,
split out so the hero can render the same code at its own size.

**`InviteSheet` is that same card with its open affordances taken off, and
that is the whole sheet.** `showInviteSheet` takes a `CompetitionOverview`
rather than a bare code, and renders `ActiveCompetitionCard` with a null
`onOpen` — which drops the "Active competition" eyebrow, the chevron and the
tap in one, since all three say "this is a destination" and in a sheet it is
not one. **The code badge then moves down into the name's row**, where the
chevron would have been: with no eyebrow left to share, a lone badge on its
own line held an empty band open above the name. That is also why `_nameWithCode` is
its own row rather than the hero's: the name is `Expanded` so the badge is
right-aligned beside it rather than trailing it the way the chevron does, and
the row is `crossAxisAlignment: start` so the badge stays level with the
name's *first* line when a long name wraps to two. `onManage` is left off for the same reason. It replaced a
`JoinQrCard` over a `JoinCodeCard`, so the invite sheet and the competitions
page now show the competition the same way rather than two different ways.
`SettingsPage` still renders `JoinCodeCard`/`JoinQrCard`, which is why both
survive. Sourcing the overview is what put `CompetitionOverview? get overview`
on `CompetitionState`'s sealed base — `LeaderboardPage` had only the
`Competition` and needs the counts the card shows.

**The join code copies itself wherever it is shown.** `JoinCodeTag`
(`competition/presentation/widgets/join_code_tag.dart`) is the one code badge
— the competitions list card, the hero card and the leaderboard's own header
all render it — and tapping it writes the code to the clipboard and swaps its
own label to `competitionCodeCopied` for two seconds. Inside a tappable card
the inner tap wins, so pressing the badge copies rather than opening the
competition; that is the point, and it is why the badge is the affordance
rather than a separate Copy button. The timer/clipboard half is
`core/widgets/copyable.dart`'s `Copyable`, a builder widget handing its child
`(copied, copy)` — `JoinCodeCard`'s Copy button is the other caller, and the
two had the same fifteen lines each before it existed.

**The competitions page's two actions live in the bar, and it has no floating
action and no sign out.** `trailing` is a `Row` of two `AdaptiveBarAction`s —
create (`AdaptiveGlyph.add`, opening
`showCreateCompetitionSheet`, rendered only when `session.canWrite`) and **join,
which is the word `Join` rather than a glyph** (`competitionsJoinShort`;
`competitionsJoin`, "Join competition", stays as its `semanticLabel`), always
rendered. That order is mirrored by the tail insets below — swap one and the
other has to follow. Three icons were tried for
join and none read — `#` for the six-character code, an arrow entering a wall,
a person with a plus badge — which is what the label variant on
`AdaptiveBarAction` below exists for. Note `competitionsJoinShort` and
`joinConfirm` are the same word in both languages (`Join` / `Deelnemen`), so a
widget test that has the join sheet open must scope its `find.text` to the
sheet — `join_competition_from_competition_flow_test.dart` does. It replaced an `AdaptiveFloatingAction`
that opened a `CompetitionAddSheet` chooser; that sheet existed only to split
one button into two, so it and `CompetitionAddAction` were deleted with it.
Unlike every other page's `trailing`,
this one is **not** gated on `AppPlatform.useWideWeb` — the sidebar has no
create or join row, so the bar is the only way in at every width.

**The empty state is two speech bubbles hanging off the bar, over a
placeholder line.** `_emptySection` is `_joinBubble` / `_createBubble` at the
top, then `Spacer`/`EmptyState(competitionsPlaceholder)`/`Spacer`, then
`_signOutButton`; the empty branch is `Expanded` so those spacers have height
to take — the body is a non-scrolling `SliverFillRemaining`, which gives the
column the viewport's remaining extent as its minimum, so the line sits
centred and sign out is pinned to the bottom of the screen. Each bubble is a
`SpeechBubble` (`core/widgets/speech_bubble.dart`) carrying an accent
`AppTypography.eyebrow` header naming the action and a `caption` body saying
what to press. **The header of the join bubble is `competitionsJoinShort`,
literally the same key the bar button renders**, so the two can never drift
apart — which also means `find.text('Join')` now matches twice on this page,
and `competitions_page_test.dart`'s `_barAction` helper scopes to
`AdaptiveBarActionGroup` for that reason (this is the third collision on that
word, after `joinConfirm`).

**The tail is the pointer, and its inset is what aims it.**
`SpeechBubble.tailInset` is measured from the bubble's *right* edge, so
`_joinTailInset` (10) lands under the rightmost bar action, `Join`, and
`_createTailInset` (90) under the `+` beside it, and the two bubbles read as
speech from two different buttons rather than as a stack of cards. **The
smaller inset always belongs to whichever action the bar renders last**, so
reordering `_actions` means swapping these two constants with it. The path is
one `Path` — an `RRect` plus the triangle, filled once — because
`AppColors.neutralSurface` is translucent and two overlapping opaque shapes
would seam along the join. `_bubblePath` clamps the tail inside the corner
radii so a narrow bubble cannot grow a tail out of its own rounded corner —
**that clamp floors the effective inset at `AppRadius.lg + _tailWidth` (38)**,
so any smaller value, `_joinTailInset`'s 10 included, renders at 38 and
tuning below that does nothing.
Aiming is approximate by nature: the bar actions differ in size between glass,
Material and wide web, so the headers are what actually disambiguate and the
tails carry direction.

**A bubble may hang the other way up, or off the side.** `SpeechBubble.tail`
(`SpeechBubbleTail.top`/`bottom`/`left`, defaulting to `top`) moves the
triangle to another edge and flips which side of the padding makes room for
it. **`tailInset` is always measured from the corner nearest whatever the
bubble points at** — from the *right* edge for a `top`/`bottom` tail, since
both of those hang under a bar action at the top right, and from the *top*
edge for `left`, which points at the sidebar's New match button near the top
of the screen. `_verticalTailPath` and `_sideTailPath` are separate paths
rather than one generalized one; each clamps its tail inside the corner radii
along its own axis, so the `AppRadius.lg + _tailWidth` (38) floor described
above applies to a `left` tail's distance from the *top*. Matches' empty
state is the one call site for both `bottom` (native and narrow web) and
`left` (wide web) — see "Matches' own empty state" below. There is no `right`
member: nothing points that way, and the codebase does not keep unused
enum members around (`CurvedArrowDirection` is the precedent).

`competitionsEmpty` ("You're not in any competition yet") is gone — a
first-time user already knows the list is empty, and the screen's one chance to
teach was being spent restating it. Three earlier shapes were built here and
rejected, so don't rebuild any of them: copies of the create/join actions *in*
the empty state (a filled Join over a tinted Create); a `CurvedArrow` per bar
action with the action's name as its caption (which is why
`CurvedArrowDirection` briefly had an `up` member, then a `down` one, and the
enum went entirely — and `CurvedArrow` itself is now gone too, deleted with
Matches' sidebar hint, its last call site); and a single
explanatory paragraph naming both buttons in prose. Nothing here persists a
"has seen it" flag and nothing needs to — the empty state *is* the first-run
state, and it disappears the moment the user joins.

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
`leave`/`delete` already refreshed through `_mutate`; `CompetitionsPage`
calls `CompetitionListCubit.refresh()` itself when either the create or the
join sheet comes back with an id. The page's `State` survives that — a sheet
is not a route change, and `initState` never re-runs — so without that
explicit refresh the new competition would be missing from the list. (It already was, before the cache: nothing but pull-to-refresh ever
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
  - **`core/widgets/failure_text.dart`'s `FailureText` is the one error line
    under a form or a sheet's content** — the `AppSpacing.md`-topped
    `failure.localized(l10n)` in `AppColors.negative` that a dozen files each
    hand-rolled as their own `_failureText`/`_actionFailureText`/
    `_submitFailureText` helper. Every one of them now renders it, as
    `if (state.actionFailure case final failure?) FailureText(failure)`, so
    the null check sits at the call site and the widget itself always has a
    failure. `textAlign` is its only parameter, for the two sheets that centre
    theirs. `AuthFailureText` stays a widget of its own on top of it: it
    `context.select`s the failure off `SignInCubit` rather than being handed
    one, which is what lets three sign-in steps render it as a `const`.
  - **A feature's own sheets live in its `presentation/pages/`, not
    `presentation/widgets/`.** A sheet is a destination — it has a title, it
    is what the user is looking at, and it is opened rather than composed —
    so `join_confirm_sheet.dart`, `new_match_sheet.dart`, `profile_sheet.dart`
    and the rest sit beside the routed `*.page.dart` files, while
    `presentation/widgets/` keeps the pieces those screens are built from
    (cards, rows, bar buttons, result types, enums) — every feature's
    `pages/` now holds all of its screens, sheets included, and no
    `*.page.dart` is left in a `widgets/` folder. They keep the
    `_sheet.dart` suffix rather than taking `.page.dart` — that one is for a
    routed destination, and a sheet is not routed. The generic sheet
    machinery stays in core: `core/widgets/sheet.dart`'s `Sheet`,
    `text_entry_sheet.dart` and `showAdaptiveSheet` are widgets, not pages.
    A button that opens a sheet stays in `widgets/` with the other chrome
    (`GameTypeFilterButton`, `SeasonFilterButton`), which is why
    `GameTypeFilterSheet` moved out of `game_type_filter_button.dart` into
    its own file and took `GameTypeFilterOption` out with it.
  - **New modal sheets build on `core/widgets/sheet.dart`'s `Sheet`**, not ad
    hoc `Column`s: title/subtitle/avatar pinned at top, `content` scrolls in
    between (capped at 85% of screen height), primary/secondary buttons
    pinned at bottom. **The `AppSpacing.lg` under the header is the scroll
    view's own `padding`, not a `SizedBox` between the two**, so every sheet
    gets it for free at rest and it scrolls away with the content instead of
    holding a fixed band open under a pinned header. Nothing else in `Sheet`
    may become scroll-view padding on that reasoning: the buttons' gaps
    separate two pinned things, and a gap that scrolled out from under the
    content would let it run into them. For an action-sheet shape (a variable-length column of
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
  plus four colour-baked muted variants (`caption`/`captionStrong`/
  `captionSmall`/`labelTiny`, all `AppColors.neutral`; `captionStrong` is
  `caption` at `w700`, shared by Matches' `DayHeader` and the top bar's day
  subtitle so the two always read as the same label) for the "secondary text" role that
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
- **An empty state names what will appear there, never what is missing.**
  "Matches will show up here", not "No matches yet" — the user can already
  see that the list is empty, so a line restating it spends the screen's one
  sentence saying nothing. Every one of them is phrased that way now, in both
  languages, and on the same pattern: `<subject> will show up here.` /
  `<subject> verschijnen hier.` — `competitionsPlaceholder`, `matchesEmpty`,
  `playersEmpty`, `historyEmpty`, `profileVersusEmpty` (which keeps its
  `{name}` placeholder) and `profileHistoryEmpty`. Match it when adding a
  sixth. The same reasoning is what retired `competitionsEmpty` outright —
  see "The empty state is two speech bubbles" above, where the teaching moved
  into the bubbles instead.
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
- **Three tables are watched, and `players` is one of them.** `matches`
  (filtered by `competition_id`, feeding `MatchListCubit`), `player_ratings`
  (by `season_id`, or unfiltered before the season has a row, feeding
  `LeaderboardCubit`), and `players` (by `competition_id`, feeding both
  `PlayersCubit` and `LeaderboardCubit`). The third one was missing for a
  long time and the gap was invisible from the leaderboard's own data:
  `join_competition` writes **only** a `players` row — it creates no
  `player_ratings` row, since that table is written exclusively by
  `apply_match_ratings`/`recalc_season_from` — so a second person joining
  produced no event on either of the other two channels, and the first
  player's leaderboard sat on one row until pull-to-refresh. A tab switch
  did not fix it either: `LeaderboardCubit` lives in its own
  `StatefulShellBranch` leaf route and survives one. The refetch was always
  correct — `public.leaderboard` is deliberately driven *from* `players`
  with a `left join player_ratings`, so a joiner appears at
  `starting_rating` — it was purely the trigger that was absent. The same
  channel also covers a rename, a deactivate/restore and a leave (which is
  an `update … set is_active = false`, not a delete, so `players` needs no
  `replica identity full` the way `matches` did).
- **`LeaderboardCubit` keeps two watchers, not one.** `_watcher` is keyed on
  `_watchedSeasonId` and is torn down and rebuilt whenever the season id
  changes (notably null → real, when the season's first match lands);
  `_playersWatcher` is started once and never re-keyed, because the roster
  channel has nothing to do with the season and rebuilding it on every
  season change would drop and re-subscribe for no reason.
  `leaderboard_cubit_test.dart` pins both halves — a players tick refetches,
  and a season change calls `watchLeaderboards` twice against
  `watchPlayers`' once.
- **The leaderboard and the roster subscribe to `players` separately, on
  purpose.** `LeaderboardRepository.watchPlayers` and
  `PlayerRepository.watch` are two channels on the same table with the same
  filter, which is one more than strictly necessary. Folding them into one
  would mean either `LeaderboardCubit` taking a `PlayerRepository`
  dependency, or it listening to `PlayersCubit` — and `PlayersCubit` is a
  `registerFactoryParam`, so asking `getIt` for one inside the leaderboard's
  factory yields a *different* instance from the shared one on the
  competition `ShellRoute`, not the one that is actually loaded. Each cubit
  owning its own trigger is the cheaper trade.
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
  a row/tile (`LeaderboardRow`, `NavRow`, `SelectableRow`, `MatchTile`,
  `CompetitionCard`, `ProfileSection`, the team-picker tile, the
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
  `Scaffold` background, `SliverAppBar`, `floatingAction` — is
  `viewport - 232`. (Wide web has no bottom bar at all; the shell passes
  `bar: null` and the sidebar is the navigation.) Inside that, `AdaptiveScaffold._content` narrows **`body`
  alone** to `kContentMaxWidth` (640, `core/theme/app_tokens.dart`). Pages
  then add their own `AppSpacing.md` horizontal padding inside that, so the
  actual text/row width is 608. **It gets there by padding, not by a
  `ConstrainedBox`**, and that is load-bearing rather than stylistic:
  `RenderSliverFillRemaining.performLayout` sizes the non-scrolling body from
  `child.getMaxIntrinsicHeight(constraints.crossAxisExtent)` — the *viewport's*
  width, not the child's — so a `ConstrainedBox` narrowing 1440 down to 640
  underneath it made that measurement a lie. Any text that wraps to one more
  line at 640 than it does at the full pane width was measured short, and the
  sliver then laid the body out at exactly the measured extent: a page taller
  than the window **overflowed and clipped instead of scrolling**, since
  `SliverFillRemaining` only grows for a child it measured as taller. So
  `_bodySliver` wraps that branch in a `SliverLayoutBuilder`, takes the true
  `crossAxisExtent.contentGutter`, and `_content` spends it as symmetric
  `Padding` inside a `Center` — `RenderPadding` subtracts its own insets before
  asking the child, so the intrinsic is finally measured at the width the child
  will actually get. The `Center` stays for the vertical centring it was
  already doing; the horizontal result is identical to the old
  `ConstrainedBox` at every width. This is the same "pad, never constrain"
  rule the app bar, the FAB and `_constrainedSlivers` already follow, and the
  competitions page's spotlight card is what first made a page tall enough to
  expose it.
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

### Liquid glass is iOS-only (`AppPlatform.useLiquidGlass`)

A third platform axis, independent of both `useCupertino` and `useWideWeb`:
`!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS`, mirrored by
`AppPlatform.debugOverrideLiquidGlass` for tests. **It is deliberately not
derived from `useCupertino`** — that would hand glass to macOS (a different
idiom, untested) and, worse, to the ~15 test files that pin
`debugOverrideCupertino = true`. Because `defaultTargetPlatform` is forced to
`android` whenever `FLUTTER_TEST` is set (`foundation/_platform_io.dart`),
glass is off in every test that doesn't ask for it, and
`test/core/adaptive_glass_test.dart` is the one file that asks — the same
arrangement `sidebar_test.dart` has with `debugOverrideWideWeb`, and the same
blind spot: nothing else in the suite renders a lens.

**Exactly one file in `lib/**` may import `package:liquid_glass_easy`:**
`core/widgets/adaptive/adaptive_glass.dart`. It re-exports the handful of
package types the other adaptive widgets name, so every glass branch elsewhere
imports the seam, never the package. `main()` calls `AdaptiveGlass.warmUp()`
(a no-op off iOS) rather than `LiquidGlassShaders.ensureLoaded()` directly, so
the first frame showing glass isn't the frame that compiles the shader. The
package is pure Dart plus six fragment shaders declared in its own pubspec —
no Podfile, no `IPHONEOS_DEPLOYMENT_TARGET` change, no native setup — and it is
constrained `^4.2.0`: every widget rename in its history landed in a major, so
the caret is what protects the call sites. Widening past `^4` means re-reading
its changelog first.

`AdaptiveGlass.isEnabled(context)` is the runtime check the widgets branch on,
not the bare `AppPlatform.useLiquidGlass` getter: it also refuses glass under
`MediaQuery.highContrastOf` (iOS "Increase Contrast"). Flutter exposes **no**
reduce-transparency flag, so that setting alone cannot turn glass off — this
is the closest proxy available. Colours come from
`AdaptiveColors.glassTint`/`AppGlass` like every other themed value; the
package's own defaults are never used raw.

**Glass is chrome, never content.** The package's own guidance is that a lens
belongs above scrolling content, not inside it — a lens placed as a list item
fights the backdrop read and hits overscroll artefacts. So bars, floating
buttons and panels may be glass; `LeaderboardRow`/`MatchCard` may not.

**The glass tab bar floats; the opaque one takes layout space.** That is the
whole structural difference, and it is what `AdaptiveBottomBarHost`
(`core/widgets/adaptive/adaptive_bottom_bar_host.dart`) exists to express:
given a `child` and an optional `bar`, the opaque path is a `SafeArea` +
`Column` over the page background, the glass path is a `Stack` of the page
under a `Positioned.fill` bar, because a lens with nothing painted behind it
has nothing to refract. **`AdaptiveScaffold` has no `bottomBar` parameter** —
it only reads `AdaptiveBottomBarHost.insetOf(context)`, the room the floating
bar needs (`glassInset` = `AppGlass.barHeight + barMargin`, and `0` whenever
the bar takes layout space instead), to inset its own body and lift its FAB.
**How** that inset is applied depends on the body's shape — `_bodySliver`
picks:
- a `SliverPadding` for the `slivers` form (Matches), so the last card scrolls
  clear of the bar;
- a box `Padding` for both box forms, because a **trailing `SliverPadding`
  does not shrink `SliverFillRemaining`** — `RenderSliverPadding` only takes
  leading padding off the child's `remainingPaintExtent`, so a non-scrolling
  body would still paint its full viewport height underneath the bar and only
  gain scrollable slack below it. `test/core/adaptive_glass_test.dart`'s
  "leaves room below the body for the bar" is what caught that.
Both helpers return the child untouched at inset `0`, so every off-glass tree
is byte-identical to what it was.

`AdaptiveBottomTabBar`'s glass branch must use **`LiquidGlassTabBar.withImpeller`**,
not the default constructor: the plain one expects to sit in a
`LiquidGlassScaffold` that owns the capture pipeline, while `.withImpeller`
renders the bodyless morph-pill overlay that samples the live backdrop — which
is what we have. That overlay fills the whole stack rather than sitting at the
bottom (it positions the capsule itself, safe area included, from `margin` /
`alignment`), so it goes in as `Positioned.fill` and **taps still reach the
content underneath it** — asserted, since a full-screen overlay swallowing
hits would otherwise be a silent, total loss of interaction. Icons go through
`iconBuilder` rather than `icon` so `AdaptiveIcon` stays the one source of
glyph truth.

**The rim is the one part of the glass look with a dark variant, and it needs
one.** A lens's bright edge comes from `LiquidGlassShape`'s
`lightColor`/`lightIntensity` plus `OpticalBorder.ambientIntensity` — all
theme-independent in the package, tuned for glass over light content
(`0xB2FFFFFF` at full intensity). Left at those defaults on a near-black
surface they read as a hard white outline around the capsule, the action and
the sheet, which is what shipped in the first TestFlight build.
`AdaptiveGlass.shapeOf(context, cornerRadius:)` is now the single place a shape
is built, and it resolves all three per brightness —
`AdaptiveColors.glassRim` (white at `AppOpacity.glassRim`/`glassRimOnDark`),
`AppGlass.rimIntensity`/`rimIntensityOnDark` and
`AppGlass.rimAmbient`/`rimAmbientOnDark`. **Ambient is the one that matters
most**: it brightens the rim uniformly all the way round, so it is what turns
an edge highlight into an outline. The shipped values are far below the
package's defaults on both themes — they were tuned against a real device, so
treat them as measured, not as a starting guess.
`AdaptiveGlass.actionStyle(context, cornerRadius:)` is the one composition
every glass button goes through — `LiquidGlassTabBarAction.defaultStyle` with
its shape swapped for that themed rim and its body filled per brightness, so
the action keeps its tuned refraction and changes only those two facets, the
pattern the `style`-replaces-wholesale note below describes.
`AdaptiveGlass.barActionStyle` is that call at the bar action's own radius,
and `AdaptiveFloatingAction` makes it at `AppGlass.barHeight / 2`.

**The body of a glass button is white in light mode and clear in dark.**
`LiquidGlassTabBarAction.defaultStyle` ships a fully transparent body — the
refraction alone — which over a light page leaves the button all but
invisible; every control the eye is meant to find (the bar actions, the
capsule they group into, the labelled action's lens, the FAB and the tab
action) sits on `AdaptiveColors.glassActionTint`, white at
`AppOpacity.glassActionFill` (0.45), well above the `glassFill` (0.22) the
tab bar capsule's *surface* uses — a button has to out-read the bar it sits
next to. `glassActionTintOnDark` is `AppColors.transparent`, i.e. the
package default left exactly as it was: over a near-black page the rim and
the refraction already carry the shape, and a white body there reads as a
grey blob. It is the one `AdaptiveColors` pair whose dark half is a
deliberate no-op.

**A glass action on iOS is a FAB everywhere else — they are the same thing.**
`AdaptiveFloatingAction` is the single widget for "the primary action on this
screen": a `LiquidGlassTabBarAction` at `AppGlass.barHeight` on iOS, a Material
`FloatingActionButton` or the Cupertino accent circle elsewhere. So every FAB
in the app (competitions, players) reads as a glass action on iOS, and
conversely **"New match" is a FAB on Android**, never a third tab. Do not add a
`LiquidGlassFab`, a bespoke glass circle, or a tab-shaped action to one of
these surfaces without the other — the mapping is the rule.

**"New match" is an action beside the capsule, not a tab inside it.** The
capsule groups the two destinations (Leaderboard, Matches); logging a match is
a separate circular button at the right edge — the arrangement iOS 26 itself
uses (a left-hugging pill plus a standalone button), and the package's own
Photos showcase. That action belongs to `AdaptiveBottomBarHost`
(`AdaptiveBottomBarAction`: glyph, label, callback), **not** to
`AdaptiveBottomTabBar`, because only the host spans enough of the screen to
place it: on glass it sits beside the capsule at the bar's own baseline, and
without glass it floats above the bar inside the page area, where a Material
FAB belongs. A bar-owned action could only paint outside its own strip, and
Flutter rejects hit tests outside a render box — it would have been visible and
dead. The bar still needs to know the action is there, to narrow the capsule
and hug the left: that is `reservesTrailingAction`, the one deliberate
redundancy, passed from the same `isRegistered` the host's `action` is. This
arrangement is also what removed `CompetitionTabBar`'s old index juggling
(`isRegistered ? 2 : 1`, plus an `index == 1` special case in `_select`).

**Hosting a bar means taking the bottom padding off the page, the way
`Scaffold` did.** `Scaffold` passes its body `removeBottomPadding:
bottomNavigationBar != null` (`material/scaffold.dart`), so while the bar lived
in the page's own `Scaffold` the body's `SliverSafeArea(top: false)` added
nothing. Hoisting the bar out silently handed that padding back, and a
scrolling list ended an inset-sized band *above* the bar — read on device as
"the tab bar got taller", though the bar had not changed by a pixel.
`AdaptiveBottomBarHost._stacked` therefore wraps the page in
`MediaQuery.removePadding(removeBottom: true)`. The glass path deliberately
does **not**: there the bar floats, and the page's own padding plus
`glassInset` is exactly the bar's height above the screen edge.
Note what hid this: a probe with a `SliverFillRemaining` body showed no
difference at all, because trailing sliver padding does not shrink that sliver
(see `_bodySliver` above). Only a *scrolling* body reveals it, which is why the
test asserts the invariant directly — `MediaQuery.paddingOf` inside the hosted
page has `bottom == 0` with a bar, and keeps the inset without one.

**A hosted bar needs its top padding removed, or it inflates by the status
bar.** Material's `NavigationBar` wraps its own content in a full `SafeArea`
(`material/navigation_bar.dart`) — top included — and `Scaffold` compensates by
handing its `bottomNavigationBar` slot `removeTopPadding: true`. Hosting the bar
ourselves dropped that, so the bar reserved the *status bar / camera cutout*
inset **above its own icons**: on a 480dpi emulator that measured 179dp against
a `Scaffold`'s 114dp, with 65dp of dead bar-coloured space above the labels.
`AdaptiveBottomBarHost._bar` therefore wraps the bar in
`MediaQuery.removePadding(removeTop: true)`, mirroring what `Scaffold` did.
This is the third distinct thing `Scaffold` was silently doing for the bar
(the others: not removing the *bottom* padding from the bar, and removing it
from the body). When a test harness says a hoisted widget is unchanged, check
what the widget it came out of was passing it.
**Every bar test must supply a top inset**, or it cannot see this: the first
three harnesses set only `padding.bottom` and reported a perfect match while
the device was visibly wrong.

**Never wrap a bottom bar in `SafeArea`.** Both `CupertinoTabBar` and Material's
`NavigationBar` add `MediaQuery.viewPaddingOf(context).bottom` to their own
height, and `SafeArea` removes `padding`, **not** `viewPadding` — so wrapping
one leaves the bar its full height *and* a dead inset-sized band beneath it,
which reads as a taller bar. `AdaptiveBottomBarHost._stacked` is therefore a
bare `Column`, exactly what `Scaffold.bottomNavigationBar` used to give it.
`adaptive_glass_test.dart` measures the hosted bar against the same bar inside
a plain `Scaffold` under a 34px inset; the wrapped version rendered 80 against
the reference 114.
**iOS sheets sit on a glass panel, at a much heavier tint than the bar.**
`showAdaptiveSheet`'s Cupertino branch swaps its opaque `Container` for an
`AdaptiveGlass` whose tint is `AdaptiveColors.glassSheetTint` — the modal
surface at `AppOpacity.glassSheetFill` (0.75), where the bar uses 0.22/0.28.
A sheet is a reading surface: at the bar's tint the leaderboard behind it
shows through the text. The refraction and the edge still read as glass; the
body stays legible. Only the Cupertino branch changes — the Material sheet and
the wide-web dialog are unreachable on iOS. `AdaptiveGlass` grew a `tint`
override for this, threaded into `styleOf`. The `ScrollDismissibleSheet` /
`PopScope` / `confirmsDismissal` arrangement is untouched: the lens replaces
the surface *inside* it, so the drag and barrier paths still route through
`Navigator.maybePop`, and `adaptive_glass_test.dart` asserts a guarded glass
sheet survives a barrier tap.

**The scroll edge band is part of the host, not of any page.**
`AdaptiveBottomBarHost._floating` stacks a `LiquidGlassScrollEdge` between the
page and the bar — content fades into the page colour as it slides under the
floating capsule, which is what keeps a dense list from showing through it as
noise. It is tinted `AdaptiveColors.scrollEdgeTint` (the page background at
`AppOpacity.scrollEdgeFill`), **not** the package's default 54%-black dim: a
black band reads as a shadow in light mode, where the effect should look like
content dissolving into the background. Its height covers the bar, the home
indicator and `AppGlass.scrollEdgeFade` of extra ramp above them (currently
`0` — the band stops at the bar). It is wrapped in
`IgnorePointer` — it is decoration, and a full-width band that ate taps would
silently kill the bottom of every list.

**The top bar floats too, and the large title is the price.** A
`LiquidGlassLens` refracts *what is painted behind it*, so anything meant to
be glass has to have the content behind it — which rules out every
arrangement that keeps `CupertinoSliverNavigationBar`. A lens behind the
scroll view has nothing to refract (the page background paints over it); a
lens `Positioned` over the scroll view refracts and blurs the nav bar's own
title and buttons; and a top `LiquidGlassScrollEdge` cannot be slipped
*between* the body slivers and the pinned nav bar from outside the scroll
view at all. So on the glass path `AdaptiveScaffold._cupertinoGlass` drops the
nav bar entirely and stacks `AdaptiveTopBar`
(`core/widgets/adaptive/adaptive_top_bar.dart`) over the content. **iOS
therefore has no large titles any more**, and no collapse-on-scroll; that was
accepted deliberately in exchange for the lens. Off glass (and under Increase
Contrast, since the gate is `AdaptiveGlass.isEnabled`) the
`CupertinoSliverNavigationBar` branch is untouched, and a page with no `title`
at all (Sign in, Upgrade) keeps `_bareBar` on both paths.

**The title is not glass; the buttons are** — the iOS 26 Photos arrangement,
and the one place the shape deliberately departs from the bottom bar. A
capsule around the title was built first and rejected: a lens is a *control*
surface, and wrapping a page's name in one reads as a button that cannot be
pressed. So `AdaptiveTopBar` is a plain `Row` — bare title text in
`AppTypography.barTitle`, `leading`/`trailing` beside it — over its own
top-edge `LiquidGlassScrollEdge` band, which is what keeps that unglassed text
legible as content passes beneath it (the same `Positioned.fill` +
`IgnorePointer` shape `AdaptiveBottomBarHost._floating` uses at the bottom).
The band is the only thing standing between the title and the list; do not
remove it while the title is bare.

**The bar carries a `subtitle`, and on Matches that subtitle is the day you
are looking at.** `AdaptiveScaffold.subtitle` is a `Widget?` threaded to
`AdaptiveTopBar` and read **only** by `_cupertinoGlass` — the
`CupertinoSliverNavigationBar`, `SliverAppBar.large` and wide-web
`SliverAppBar` branches ignore it entirely, so this is an iOS-glass-only
affordance and every other platform is byte-identical to what it was. That is
deliberate: iOS under Increase Contrast falls back to the nav bar, so the day
has to stay in the list as well (see below) or that user loses it, and
`MatchCard` itself shows no date at all.

**The bar grows downward for it; nothing above the subtitle may move.** The
title and the actions share one fixed row of `AppGlass.topBarHeight`, and a
subtitle adds a second band of `AppGlass.topBarSubtitleHeight` (20) *below*
it, tucked back up into that row's slack by `AppGlass.topBarSubtitleRise` (16)
— **that rise is the only knob for how close the caption sits to the title**,
since the visible gap is otherwise just the leftover of centring a 40.8px line
box in a 60px row. Raising it pulls the caption up and shortens the bar by the
same amount; nothing above it moves, which is why the two live in a `Stack`
rather than a `Column` — a column would have to grow the title's own box to
place the caption. `barHeightFor(hasSubtitle:)` is that arithmetic, resolved
once and asked for by `AdaptiveScaffold`'s pinned spacer through `insetFor` as
well, so the reserved room and the bar agree. The bar was one centred `Column` of title-plus-subtitle
until this: a taller bar re-centred that column, so Matches' title sat a few
pixels off Leaderboard's, and — because the row's height also constrained its
children — a `barActionSize` action on a subtitle-less page was squashed from
a circle into an ellipse. Hence the two rules the layout now encodes: the
title row is `topBarHeight` (60) whatever else the bar carries, and **an
action never takes its height from that row** — `_row` is
`crossAxisAlignment: start`, so the subtitle band cannot drag the actions
down with it, and each action sits in `_actionSlot`, a `topBarHeight`-tall
`Center`, so it keeps its own `barActionSize` (52) square and still rides
the title's centre line. `topBarHeight` used to *be* `barActionSize`, which
made the slot unnecessary; shrinking the actions without shortening the bar
split them, and `adaptive_glass_test.dart`'s "centres an action smaller than
the title row on it" is what holds the pair together now.
Room for the title was measured, not guessed: Permanent Marker's own metrics
(`asc 1136`, `desc -325`, `gap 31` over a 1024 em) put the 28px brand title's
line box at **40.8px**, so the 60px row tolerates about 1.47× Dynamic Type and
the 20px band about 1.25× before either overflows.

**Matches keeps its day headers on glass; they just stop pinning.**
`_dayHeaderSlivers` returns a `PinnedHeaderSliver` off glass (unchanged) and a
plain `SliverToBoxAdapter` on it — a pinned header directly under the floating
band guillotined whatever card was passing behind it, and with the day now
named in the bar there is nothing left for it to pin *for*. Note this makes
the pinned spacer sliver's original justification obsolete (nothing stacks
under it on Matches any more) but **not** the spacer itself: it still has to
be a `PinnedHeaderSliver` so `CupertinoSliverRefreshControl`, which follows
it, lands below the bar rather than under it.

**Which day is under the bar comes from the sliver protocol, not from
probing render boxes.** Each day group is preceded by a zero-extent
`SliverLayoutBuilder` marker that records `constraints.precedingScrollExtent`
into `_dayHeaderStarts` — where that day's `DayHeader` begins, absolute and
stable regardless of scroll position, and correct through both
`SliverPadding` and `SliverMainAxisGroup` since each adds its own leading
extent to what it passes down. A `NotificationListener<ScrollNotification>`
around the scaffold then picks the last group whose start has passed the
caption line, and writes it to a `ValueNotifier<DateTime?>` that only the
subtitle's `ValueListenableBuilder` listens to, so a day change repaints the
caption and nothing else.

**The handover point is a geometric alignment, not a tuned number.** The day
changes at exactly the scroll offset where the list's own day label lands on
the row the bar's caption occupies — `_dayAtCaptionLine`'s threshold is
`pixels + padding.top + AdaptiveTopBar.subtitleTop - DayHeader.textInset`,
the two insets that separate each label from its own box's top. Both labels
are `AppTypography.captionStrong`, so aligning their tops aligns them
outright: the caption appears in the same pixel row the header label just
vacated, and the list header dissolves into the scroll-edge band exactly as
its copy lights up in the bar. `matches_page_test.dart` measures that
directly — it scrolls to the caption line and asserts the two `getRect` tops
match within half a pixel — with a second pair of tests pinning the flip to
that same offset ±1px.

Two earlier attempts at this, both rejected on device, are worth not
repeating: `insetFor` (the bar's height *plus* `barMargin`) names a day whose
header is still a margin's worth below the glass, and even `barHeightFor`
(the painted bottom edge) fires while the header is fully readable. The two
constants above are the knob — nothing else in the page needs a magic
offset — but note that at any real scroll velocity the 200 ms
`AnimatedSwitcher` fade moves the *perceived* moment far more than a few
pixels of threshold do, which is why nudging the threshold by hand feels
like it does almost nothing.

The caption cross-fades through an `AnimatedSwitcher`, and that switcher
needs `layoutBuilder: _startAlignedStack` — the default one stacks the
outgoing child on the incoming one with `alignment: Alignment.center`, so a
shorter day name visibly jumps sideways to sit centred over the longer one
for the length of the fade. A start-aligned `Stack` is the whole fix, and
`matches_page_test.dart` pins it by comparing both names' `left` mid-fade.

**`null` is a real value here**: before the first header clears that edge
nothing has scrolled behind the bar, so the subtitle is empty rather than
naming the day the list happens to start with. The bar keeps its taller
`hasSubtitle` height either way — `subtitle` is the always-present
`ValueListenableBuilder`, so an empty caption is not a layout change.
Three things this shape is deliberately avoiding:
- **`GlobalKey`s per group with `localToGlobal` on every scroll do not
  work here.** The group you want is usually the one that has just scrolled
  *off* the top, and a lazy `SliverList`'s box children are collected once
  they leave the cache extent — so it reports correctly for about 250px and
  then silently names the wrong day. Marker *slivers* have no such problem:
  every sliver in a viewport is laid out each frame, however far off-screen,
  because the viewport needs its extent to place the next one.
- **Recomputing `groupByDay` inside the scroll handler**, which would rebuild
  the whole grouping on every scroll frame. The day list is memoized by
  `_rememberDays` where the groups are already being computed for the build.
- **Resolving from `MatchesPage.build`.** The list arrives through an inner
  `BlocBuilder`, which rebuilds *without* rebuilding the page — a post-frame
  hook registered in `build` therefore fires once, on the loading state, and
  never again. `_rememberDays` is called from `_matchesSection`, the one place
  that actually knows the content changed.

**Two or more *glyph* bar actions share one capsule, via
`AdaptiveBarActionGroup`.**
On glass it wraps the row in a single `LiquidGlassLens` and a
`GroupedBarActionScope`; each `AdaptiveBarAction` reads that scope and renders
as a bare tappable slot instead of its own lens, so two lenses never sit
edge to edge. Below two actions, off glass, or as soon as **any** member is a
labelled action (`_isLabelled`, the private top-level check below the class),
it is just the `Row` and each member keeps its own lens. That check reads the
`label` off an `AdaptiveBarAction` in the list itself, so a member wrapped in
anything else (a `BlocBuilder`, `CompetitionSettingsButton`,
`GameTypeFilterButton`) counts as a glyph — which is what every wrapper in the
app is. **Build a labelled action inline in the `actions` list**, the way
`CompetitionsPage._joinButton` does; hidden behind a wrapper it would be
capsuled anyway. The
capsule's style is `AdaptiveGlass.barActionStyle(context)` —
`LiquidGlassTabBarAction.defaultStyle` with its shape swapped for the themed
rim and its body for the themed fill — which is the one expression the group,
the lone lens and the labelled lens all share.

**`AdaptiveBarAction` is the small sibling of `AdaptiveFloatingAction`**, and
the two together are the whole glass-control vocabulary: an accent-free
`LiquidGlassTabBarAction` carrying `AdaptiveColors.glassGlyph`, at
`AppGlass.barActionSize` (52) rather than `barHeight` (64) — smaller than the
top bar's own 60px row, which is what `_actionSlot` centres it in, above.
Every bar button
goes through it — `CompetitionSettingsButton`, `GameTypeFilterButton`,
`CompetitionsPage`'s create/join pair, and
`AdaptiveScaffold._glassLeading`'s hand-built back button — so the top bar's
controls, the tab action and the FAB are all the same untinted lens with the
same black/white glyph. Off glass it is exactly the `AdaptiveIconButton` those
call sites used before, which is what a bar button already is on every other
platform; that is how it satisfies the "a glass action is a FAB everywhere
else" pairing rule without inventing an Android affordance.
**It takes either a `glyph` or a `label`, never both** (asserted, the same
shape `AdaptiveScaffold` uses for `body`/`slivers`) — a bar action whose
meaning no icon carries says the word instead. The label variant is a bare
padded text slot at `AppGlass.barActionSize` tall inside its own
`LiquidGlassLens`, and off glass an `AdaptiveButton(kind: plain,
expand: false)` — a `TextButton` on Material, a medium `CupertinoButton` on
Cupertino, which is what a bar text button already is on both. It is a
`LiquidGlassLens` rather than a `LiquidGlassTabBarAction` on the glass path
because that component takes a single `size` and paints a circle, which
no word fits.

**Every glass slot the lens does not tap for itself brings its own ink.**
`LiquidGlassTabBarAction` wraps its child in a transparent `Material` plus a
circle-clipped `InkWell`, so a lone glyph action splashes on press for free —
but the labelled action and every member of a capsule are bare slots inside a
lens we built, and those used to be an `AdaptiveTappable`, which is a plain
`GestureDetector` on Cupertino and therefore on every glass path. They pressed
dead next to a `+` that did not. `AdaptiveBarAction._grouped` is now the same
`Material`/`InkWell` pair the package uses, clipped by `_inkShape()` — a
`CircleBorder` for a glyph slot, a `StadiumBorder` for a labelled one, which
at `barActionSize` tall is exactly the lens's own `barActionSize / 2` corner.
`adaptive_bar_action_test.dart` pins both borders. **A labelled action never joins a capsule** — it is always that
lone lens, and its presence is what drops the whole group back to a plain
`Row` (see the group above). A pill-shaped word stretched into a capsule
beside a circular glyph reads as one wide button with a stray icon in it
rather than as two controls, and `CompetitionsPage`'s create/join pair is
where that showed: the glyph keeps its circle, the word keeps its pill, and
`AppSpacing.xs` sits between them.

**Two or more bar actions go in one `AdaptiveBarActionGroup`, never a bare
`Row` — which is one capsule-shaped lens with the glyphs inside it, the iOS 26
toolbar grouping, whenever every one of them is a glyph, and the plain `Row`
of individual lenses otherwise.** The capsule is a plain `LiquidGlassLens` carrying the same
`LiquidGlassTabBarAction.defaultStyle.copyWith(shape: AdaptiveGlass.shapeOf(…,
cornerRadius: barActionSize / 2))` a lone `AdaptiveBarAction` gives its own
lens, so a group is exactly one bar action stretched over both glyphs — same
tuned appearance, same light/dark rim. Its members must then *not* paint glass
of their own, which is what `GroupedBarActionScope` says: `AdaptiveBarAction`
reads it and renders a bare `barActionSize` square of glyph over the shared
lens instead of its own `LiquidGlassTabBarAction`. Below two actions there is
nothing to group and the widget is the plain `Row` — as it is off glass, where
the call sites' old `Row` is all this ever was, and as it is for any set
carrying a labelled action. The group still owns every one of those cases, so
call sites keep handing it the actions and never branch themselves.

**`LiquidGlassGroup`/`LiquidGlassBlender` is the road not taken here, and it
was tried first.** It is the package's own answer for this (its docs point it
straight at a toolbar of buttons): every member gives up its individual pass,
the group draws them as one sheet — one backdrop read and one material for
the set — and a `smoothness` fuses them through a metaball bridge into a
capsule. On device it rendered **nothing at all**: no capsule and no
per-action glass either, because the members had already handed their glass
over to a shared pass that never painted. The failure is silent by
construction — `LiquidGlassBlender` swallows a shader load/compile failure
("keep the descendant content usable and simply omit the experimental glass
pass"), and its surface also paints nothing whenever fewer than
`minLensCount` (2) members are registered — so there is no error to find, on
device or in a test. `flutter test` cannot see any of it either: without
Impeller the blender warns and falls back to per-member frosted glass, so the
grouped tree *passes* while the device shows bare glyphs. One lens we build
ourselves has none of that surface area, and it is the same widget every
other glass control in the app already renders. Reach for the blender again
only with a way to see the result on a device.

**A page filter is an `AdaptiveBarAction` carrying `AdaptiveGlyph.filter` in
the scaffold's `trailing` slot, opening a sheet, with the active value named
by a `ListHeader` above the list rather than by the button — on every
platform, glass or not — and the button itself marked `active` while a filter
is on.** `SeasonFilterButton` (History) and
`GameTypeFilterButton` (Matches) are both exactly that, and a third filter
should be too. Each replaced a `PillDropdown` labelled with its own current
value; that label is the heading now, so nothing was lost and `PillDropdown`
itself is gone. (`SeasonFilterButton` was `SeasonDropdown`, and
`GameTypeFilterButton` was `GameTypeFilterDropdown`, until each stopped being
one.)
Matches heads the list only when a game type is actually picked — "All" is
the unfiltered list and heading it would be noise — which is why the
game-type-specific empty message went away with the pill: the header names
the filter, so the body says only `matchesEmpty`.

**Matches' own empty state centres that line and hangs a bubble off the edge
the new-match action is on.** `_matchesSection` returns a non-scrolling
`SliverFillRemaining` when the list is empty, and `_emptyState` is a `Stack` of
a `Center`ed `EmptyState` under a `Positioned` `SpeechBubble` whose header is
`matchNew` — the same key the
new-match action itself renders, the way the competitions page's join bubble
reuses `competitionsJoinShort`. The old `matchesCreateHintTabBar` line and its
downward `CurvedArrow` are gone; the bubble's tail is what points now.
**Which edge is the one thing `_newMatchBubble` branches on.** Native and
narrow web put the action at the bottom right, so the bubble is
`bottom: 0` with a `SpeechBubbleTail.bottom` at `_newMatchTailInset` (32 from
the right). Wide web has no bottom bar at all — the action is the button near
the *top of the sidebar* — so the same bubble goes `top: 0` with a
`SpeechBubbleTail.left` at `_sidebarTailInset` (38 from the top, which is the
clamp floor: as high up the bubble's left edge as the corner radius allows).
Both are `left: 0, right: 0`, so only the vertical anchor, the tail, the
inset and the body's one line of copy differ, and one bubble serves every
platform. The `CurvedArrow`-plus-caption `_sidebarHint` it replaced is gone,
along with the old `matchesCreateHintSidebar`. **The body names the direction
the tail points**, so it is the same `pointsAtSidebar` branch:
`matchesCreateTipSidebar` ("Press the + on the left" / "de +-knop hiernaast")
on wide web, `matchesCreateTip` ("below" / "hieronder") everywhere else — a
bubble hanging off the sidebar cannot tell the user to press the button
below it.
**`_bottomInset` is the one number the page has to compute itself, and it
insets the whole empty state — the centring as well as the bubble.** A
`SliverFillRemaining` sizes itself from `viewportMainAxisExtent -
precedingScrollExtent`, so it always runs to the *viewport's* bottom edge:
neither `AdaptiveScaffold`'s trailing bottom-inset `SliverPadding` nor its
`SliverSafeArea` shrinks it (see `_bodySliver`), and the bottom bar is not in
the page's tree at all. Left uncorrected the glass capsule covered the bubble,
and `Center` centred the line in a region a bar and a home indicator taller
than what the user can see — visibly low, which is how both were found. The
two cases: on glass, `AdaptiveBottomBarHost.insetOf` plus the safe area; off
glass the action floats *over* the page at `AppSpacing.md`, so it is
`AdaptiveFloatingAction.diameter` plus that margin.
**It has to be read in `build`, not in the empty state itself**, and that is
why it is threaded down through `_body`/`_list`/`_matchesSection` rather than
resolved where it is used: `SliverSafeArea` wraps its sliver in
`MediaQuery.removePadding`, and `removePadding` takes the removed inset off
`viewPadding` as well as `padding`, so *both* read as `0` from anywhere
inside the slivers. `MatchesPage.build` sits above the scaffold, where they
are still the device's own.
**On wide web `_bottomInset` is `0`, and that is a real branch rather than a
value that happens to fall out.** The `barInset > 0` test is false there
because the shell passes `bar: null`, so without the explicit
`useWideWeb` early return the FAB fallback applied a floating action's worth
of bottom padding to a page that has no floating action — the centred line sat
~80px high for no reason. Every other platform is untouched.
**Both of the bubble's dimensions have to be forced here, unlike on the
competitions page.** Its `Column` needs `MainAxisSize.min` because the `Stack`
hands it a bounded height to expand into, where the competitions page's
`Column` child had an unbounded one; and it is `Positioned` across the full
width rather than `Align`ed, because a shrink-wrapped bubble moves its own
right edge — which is the edge `tailInset` is measured from on the `bottom`
tail, so the tail would no longer point at the action. (The `left` tail is
measured from the top instead and would survive shrink-wrapping, but the two
share one `Positioned` and full width is what makes them read as the same
bubble.) `matches_page_test.dart` pins the width, the
height and the clearance together, a second test pumps the page inside a
real `AdaptiveBottomBarHost` under a 34px bottom inset — the only way to see
either overlap, since a bare `MatchesPage` hosts no bar — and a third pumps
the empty state under `debugOverrideWideWeb` for the tail flip.
`ListHeader` (`core/widgets/list_header.dart`) is the shared block: a
`titleSmall` title over an optional `captionSmall` subtitle. History and the
Leaderboard's running season pass both; Matches passes a title alone.
Only Matches passes `active` — History always has a season selected, so
"filtering" is not a state it can be out of.

**`AdaptiveBarAction.active` is ours, not the package's.** No component in
`liquid_glass_easy` that we use carries a selected state: `LiquidGlassTabBarAction`
takes only `icon`/`child`, `onTap`, `foregroundColor`, `size`, `style`,
`visibility` and `touch`, and `LiquidGlassButton`/`LiquidGlassFab` are the
same. Selection exists there only in widgets whose whole job is selection
(`LiquidGlassTabBar.selectedIndex`, the segmented controls, `LiquidGlassSwitch`)
plus `LiquidGlassControlTile`, whose `active`/`activeColor` tint the lens.
**That tint is deliberately not what `active` does here — the glass stays
exactly as it is and only the glyph changes colour**, to
`AdaptiveColors.accent`. Tinting the lens was built first and dropped: a
filled accent lens is the same flat-orange-circle read that got the accent
FAB rejected, and it makes the button louder than the heading naming the
filter. So the lens keeps whatever `AdaptiveGlass.barActionStyle` gives it,
active or not, and `active` is one line in `_glyphColor` — accent when
on, `glassGlyph` (black on light, white on dark) when off. Off glass,
`AdaptiveIconButton` does the identical thing plus Material's own
`isSelected`; both paths mark `Semantics(selected:)`. One rule, both
platforms. `test/core/adaptive_bar_action_test.dart` pins it, the unchanged
lens body included, and is the second file in the suite to set
`debugOverrideLiquidGlass`.

**`AdaptiveSwitch` is the one glass control that is not chrome.** On the glass
path it is the package's own `LiquidGlassSwitch` — the iOS-26 sliding switch,
whose thumb is picked up and carried rather than snapped — so the dark-mode
toggle in `SettingsPage`'s System section (and any future `AdaptiveSwitch`)
reads as glass on iOS. Three things it does *not* do, each deliberate:
- **It passes no `style`** — alone among the glass controls, since
  `LiquidGlassSwitch.defaultStyle` is a thumb-tuned clear
  pill (near-zero blur, a tucked-in contact shadow tied to the morph, a
  softened grey rim rather than the package's usual `0xB2FFFFFF`), and a
  style handed in wholesale would drop all of it. The rim's light/dark split
  that `AdaptiveGlass.shapeOf` exists for is not applied here: the thumb's
  rim is already the soft grey, and it sits on its own coloured track rather
  than over page content, so it does not read as the outline a bar-sized lens
  did.
- **It keeps the package's `activeColor`/`inactiveColor`/`thumbColor`
  defaults**, which are the iOS system values `CupertinoSwitch` was already
  painting — the switch does not change colour when it becomes glass, only
  shape and behaviour.
- **It drops the `SizedBox`/`OverflowBox`/`FittedBox` wrapper** the platform
  branch scales a native switch with, and takes the layout's own 63×28 track
  instead. `reserveSwellRoom` stays `false`: the held thumb swells past the
  track on purpose, and no ancestor between it and the scroll viewport clips.
A `null` `onChanged` falls back to the platform switch even under glass —
`LiquidGlassSwitch.onChanged` is non-nullable and has no disabled rendering,
where `CupertinoSwitch`/`Switch` both do.
**The platform branch is scaled to sit beside it.** `CupertinoSwitch` renders
59×39 and Material's `Switch` 60×40 (with `shrinkWrap`), and
`AdaptiveSwitch`'s wrapper paints both at 51×34 inside a 52×28 footprint —
`FittedBox` fits the native control into `_visualHeight`, and the shorter
`_height` is what the row actually reserves, so the switch overflows its own
footprint vertically into the row's padding and never horizontally into the
label. It was 34×20 (painting ~36×24, overhanging the label by 2 px) until
the glass switch's 63-wide track made every other platform look undersized
next to it. Numbers measured, not derived: `Switch` returns 60×40 even under
`MaterialTapTargetSize.shrinkWrap`.
**Wide web runs one size down** — 44×29 painted in a 44×24 footprint — the
one place a switch is driven by a mouse rather than a thumb. The gate is
`AppPlatform.useWideWeb`, not `kIsWeb`, so a phone-width browser tab keeps
the native size along with the rest of the native chrome; a tap target is
the wrong thing to shrink where the pointer is a finger.
`adaptive_widgets_test.dart` pins both pairs — it is the only thing watching
them, and the wide-web half needs `debugOverrideWideWeb` to see anything at
all (`kIsWeb` is always `false` under `flutter test`).

**A tight parent breaks it**: the switch's internal `OverflowBox` asserts on
non-normalized constraints if it is given a tight box larger than the track
(a `min` above the track's own size), which is why
`adaptive_glass_test.dart` pumps it inside a `Center`. In the app it is
always a `Row` child, which is loose.

**The spacer sliver that makes room for the band is `PinnedHeaderSliver`, not
a plain `SliverToBoxAdapter`, and it has to be both things at once.** A
scrolling spacer looks identical on the Leaderboard and is wrong on Matches:
with nothing pinned above them, that page's `PinnedHeaderSliver` day headers
pin at viewport `y = 0`, hidden behind the floating chrome.
`PinnedHeaderSliver` reports `paintOrigin: constraints.overlap` and
`maxScrollObstructionExtent: childExtent`, so a pinned spacer makes every
later pinned header stack *below* it — while its `layoutExtent` still clamps
to `0` as it scrolls, which is what lets content pass under the band and give
the lenses something to refract. Take either property away and one of the two
breaks. `CupertinoSliverRefreshControl` goes after the spacer, exactly where
it already sat after the nav bar.

**A floating bar has no `automaticallyImplyLeading`, so the back button is
built by hand** — `AdaptiveScaffold._glassLeading` returns an explicit
`AdaptiveBarAction` off `ModalRoute.of(context)?.canPop`, deferring to a
page's own `leading` and to `SuppressedBackButtonScope` first, mirroring what
the Cupertino nav bar did for free. Labelling it pulled `context.l10n` into
`AdaptiveScaffold`, which means **any test pumping a glass scaffold on a
poppable route needs `AppLocalizations.localizationsDelegates` on its
`CupertinoApp`** or it throws a null check inside `AppLocalizations.of`.

**One tab bar lives above both branches, not one per page.** `CompetitionShell`
renders the single `CompetitionTabBar` through `AdaptiveBottomBarHost`, wrapping
`navigationShell`, and derives `current` from `navigationShell.currentIndex`;
`LeaderboardPage`/`MatchesPage` pass no `bottomBar` at all. This is load-bearing
for the glass bar, not a tidy-up. `LiquidGlassTabBar`'s Impeller path is
stateful (`LiquidGlassAnimatedNavBar`): a tap sets its own `_tabIndex`, and its
`didUpdateWidget` resyncs **only when `selectedIndex` differs from the previous
widget's**. With a bar per page that prop was a *constant* (`current:
CompetitionTab.leaderboard` on one page, `.matches` on the other), so the
resync could never fire — after tapping "Matches" on the leaderboard's bar that
bar's pill sat on Matches forever, and returning to the page showed the wrong
tab highlighted until you tapped it again. One shared bar whose prop actually
changes 0↔1 fixes that at the source *and* is what earns the morph pill its
travel animation, which no per-page arrangement can produce: the bar you tap
would be the one leaving the screen.
**`flutter test` cannot see the bug this fixes**:
`ui.ImageFilter.isShaderFilterSupported` is false there, so the bar falls back
to its *stateless* Skia path, which reads `selectedIndex` directly and was
always right. `adaptive_glass_test.dart` pins the invariant that survives both
paths — the highlight follows `selectedIndex` and the bar's element is *not*
remounted, since a remount would kill the travel — and
`competition_content_page_test.dart` asserts a single `CompetitionTabBar`
across a tab switch.

Geometry, on both render paths (`resolveBarPosition` on Impeller, the
`Align`/`Padding` fallback on Skia): with an action the capsule takes
`alignment: bottomLeft` and a left margin, sized
`min(screen - 2 × barMargin - (barHeight + sm), 420)`, and the action is
`Positioned` at `right: barMargin, bottom: viewPadding.bottom + barMargin`
matching what `LiquidGlassScaffold` does for its own action slot. Without an
action the capsule keeps `bottomCenter` and a bottom-only margin, which is the
one shape that lets `resolveBarPosition` return `null` and leave the package's
default centring untouched.

The FAB and the tab action are **accent-free glass with a label-coloured
glyph** — a white body in light mode, no accent anywhere on them. A filled accent lens read as a flat orange
circle rather than as glass, and an accent glyph on clear glass read as
orange too; both were rejected on sight. `AdaptiveColors.glassGlyph` is black
on light and white on dark (what iOS itself uses for a glass control's
symbol), which is also why the package's own `foregroundColor` default of
plain white is not enough — it vanishes over a light page.
`AdaptiveFloatingAction` changes only the rim and the body fill, through
`AdaptiveGlass.actionStyle`, so the package's tuned refraction applies as
shipped. The tab action carries `AdaptiveGlyph.add`, the same bare `+` as the competitions
and players FABs, rather than `newMatch`'s filled plus-in-a-circle.

**A component's `style` replaces its tuned appearance and refraction
wholesale — only `shape`/`adaptivity` fall back.** `LiquidGlassStyle.merge`
takes `other.appearance`/`other.refraction` outright, so handing a component
an `AdaptiveGlass.styleOf` style silently drops the contact shadow and tuned
optical border it ships with. Pass no style to keep the component's own look
(`AdaptiveSwitch` does); to change one facet, compose from its
`defaultStyle` with `copyWith` rather than building a style from scratch. The
tab bar capsule is the one place we do override wholesale, because its tint
has to follow our light/dark tokens.

### The sidebar is a shell, not a per-page wrapper

`Sidebar` is rendered once, by `SidebarShell`
(`features/competition/presentation/widgets/sidebar_shell.dart`) from a
go_router `ShellRoute` that wraps `/`, `/settings/language`, `/upgrade`, and
the whole `/competition/:id` subtree. Only `/splash` and
`/sign-in` stay outside it and have no sidebar. Pages therefore
compose only their own `AdaptiveScaffold`; none of them mention `Sidebar`.
A page that is a *task* rather than a destination has to carry its own way
back, since the shell's `SuppressedBackButtonScope` kills the implied one:
`UpgradeAccountPage` passes an explicit `leading` on every step, and an
explicit `leading` bypasses the suppression outright. A page may also read
`SuppressedBackButtonScope.of(context)` and render its own
`AdaptiveIconButton` only when it is true, leaving native and narrow web the
platform's own arrow — `CreateCompetitionPage` did that until it became a
sheet, and nothing does now. Highlighting a sidebar section for such a page is
*not* the alternative — `Sidebar._select` early-returns on
`section == current`, so marking a task route as
`SidebarSection.competitions` would make the row that leads back out
unclickable.
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
  opened the Players page — at the time it had no realtime subscription to
  save it, unlike `MatchListCubit`/`LeaderboardCubit` (which didn't need the
  same hoist; see "Leaderboard and Matches are routes, not tabs" for why).
  Sharing removes the staleness at the source, and that is still the reason
  there is no refresh-on-return machinery for it. It does watch `players`
  now (see "Three tables are watched" above), but that covers somebody
  *else's* write, not a stale instance of your own. The one thing outside that shared
  instance is the competition itself (a rename in Configuration), so
  `SidebarShell._select` calls `CompetitionCubit.refresh()` on every hop.

Native and narrow web are untouched by all of this: `Sidebar` still returns
`child` unchanged below the breakpoint, so the bottom tab bar, `SettingsPage`
menu and every `context.push` still behave exactly as they did.

### Leaderboard and Matches are routes, not tabs

`/competition/:id/leaderboard`, `/competition/:id/matches` and
`/competition/:id/competitions` are each a real
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
- **Entering a competition is always `go`, never `push`** — from the
  competition card, after joining (`CompetitionsPage._join`) and after
  creating (`CompetitionsPage._create`) alike. `push` keeps
  the existing stack and mounts the *whole* new match chain on top of it, so
  a second competition route mounts the competition `ShellRoute`'s
  `navigatorKey`, both `StatefulShellBranch.navigatorKey`s and
  `StatefulShellRoute`'s `_shellStateKey` a second time — the same
  once-per-route-config `GlobalKey`s the bullet above turns on. The framework
  tears the loser down and **nothing is left to paint: a black screen, no
  crash and no error widget** (release's `RenderErrorBox` is light grey, so a
  thrown exception looks nothing like this). It only bites when a competition
  route is already below — launch → recent-competition redirect into A → any
  `push(Routes.home)` (Settings' "All competitions"; the leaderboard's
  competition-name button used to be the other one, see the Competitions
  branch below) → join → black. A fresh launch with no recent
  competition has only `/` beneath, so the identical tap works, which is what
  made it look intermittent and kept it off the simulator.
  `test/flow/join_competition_from_competition_flow_test.dart` drives the real
  `CompetitionsPage` and join sheet from inside competition c1 and is the only
  thing watching this; `guest_join_competition_flow_test.dart` starts from a
  bare `/home` stub and cannot see it.

`CompetitionShell` (`features/competition/presentation/pages/competition_shell.dart`)
is what the `StatefulShellRoute`'s `builder` returns, wrapping
`navigationShell` — it replaced `CompetitionContent` and shrank to just
`RecentCompetitionStore.set`/`PlayersCubit.load()` (from `initState` *and*
`didUpdateWidget`, since for the reason above it is updated, not remounted,
when the competition id changes — without the second call the freshly built
`PlayersCubit` would sit in `PlayersLoading` forever), a `BlocListener`
bouncing to `Routes.home` on `CompetitionMissing`, and the one
`AdaptiveBottomBarHost`/`CompetitionTabBar` both branches share. It takes the
`StatefulNavigationShell` itself, not a bare `child`, because the bar's
`current` comes from `navigationShell.currentIndex`.
`CompetitionTabBar` (`features/competition/presentation/widgets/competition_tab_bar.dart`)
is the bottom tab bar, rendered once by the shell rather than by either page
(see "One tab bar lives above both branches" in the liquid glass section for
why): it takes only primitives (`competitionId`, `current`, `isRegistered`) and
navigates itself via `context.go`/`push` rather than `onSelectTab`/`onNewMatch`
callbacks — every call site would have passed the identical closure, the same
reasoning that has `Sidebar` read `ThemeCubit` from context instead of a
callback prop.
`CompetitionSettingsButton` is the same move for the settings icon, which
only the Leaderboard shows (in its non-wide-web app bar trailing slot) —
Matches carries the game type filter alone, so the settings action is offered
once per competition rather than on every tab.

**The third branch is Competitions, and it renders the same `CompetitionsPage`
that `/` does — deliberately, so the tab bar survives the tap.** It used to be
a `NavRow` in `SettingsPage`'s User section pushing `Routes.home`; that row is
gone, and so is that section's `SectionLabel`. A tab item that navigated to `/` would have left the bar
behind on arrival, since `/` sits outside the competition `ShellRoute`
entirely; a branch at `/competition/:id/competitions` keeps the user inside
competition `:id`'s shell, so Leaderboard and Matches are still one tap away
without picking anything. **The leaderboard's competition-name button leads
here too** — `LeaderboardPage._competitionButton` is
`go(Routes.competitions(competitionId))`, not a `push(Routes.home)`, for
exactly the reason the branch exists: sending it to `/` dropped the tab bar
on arrival, and pushing a second competition-adjacent stack is what the
black-screen bullet above is about. Picking a tile from there is the usual
`context.go(Routes.competition(id))` and lands on that competition's
leaderboard. **`CompetitionShell._newMatch` is live on this branch like every
other one**, because `CompetitionsPage` no longer has a floating action of its
own to collide with it (see "The competitions page's two actions live in the
bar" below). It used to return `null` here — `AdaptiveBottomBarHost`'s action
and `AdaptiveScaffold.floatingAction` both sit bottom-right, so the new-match
action would have stacked under the page's add-competition FAB — which is also
why `reservesTrailingAction` was never narrowed to match: it stays
`isRegistered`, so the glass capsule's width and alignment never change across
a tab switch.
`AdaptiveGlyph.competitions` is the stack glyph
(`CupertinoIcons.rectangle_stack_fill` / `Icons.layers`), shared with the
sidebar's Competitions row.

**The sidebar mirrors that order: Competitions sits directly under Matches,
inside `_competitionNavItems`, above the divider and the Competition admin
group.** It used to be the lone row under a "User" `SectionLabel` at the
bottom of the nav list; with it moved up, that label headed nothing and went
away, which retired `competitionSettingsSectionUser` from both ARBs — it was
the last user of the key once `SettingsPage`'s own User section went. The row
is still rendered when there is *no* competition (the `else` branch of
`_navList`'s `hasCompetition`), where it is the whole nav list — hence
`_competitionsItem`, called from both places rather than spelled out twice.

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

### Every app icon comes from `ios/Runner/AppIcon.icon`

That Icon Composer document (copied in from `~/Documents/KeepScore 2.icon`) is
the single source for all three platforms. **iOS renders it directly**:
`flutter_launcher_icons` is set `ios: false`, there is no `AppIcon.appiconset`,
and the `.icon` is wired into `project.pbxproj` as a `folder.iconcomposer.icon`
file reference in the Runner group and in the Resources build phase, which is
all `actool` needs. `ASSETCATALOG_COMPILER_APPICON_NAME` was already `AppIcon`.

- **This is what makes the Clear (Liquid Glass) appearance possible, and it is
  the only thing that does.** An `appiconset` has exactly three appearance slots
  — any, dark, tinted. A `.icon` compiles to `IconImageStack`/`IconGroup`
  renditions per appearance, the layered form iOS 26 composes at runtime.
- **A `.icon` and an `appiconset` of the same name do not conflict; the `.icon`
  silently wins.** `actool` reports no error and emits the `.icon`'s output, so
  a stale `appiconset` would look live and be dead. Hence it was deleted.
- **Nothing is lost on the iOS 15 deployment target.** The compile emits a
  legacy loose `AppIcon60x60@2x.png` and a `CFBundleIconFiles` entry alongside
  the `Assets.car` renditions.

Verify iOS without a full build: `xcrun actool ios/Runner/Assets.xcassets
ios/Runner/AppIcon.icon --compile <dir> --platform iphoneos
--minimum-deployment-target 15.0 --app-icon AppIcon
--output-partial-info-plist <plist>`, then `xcrun assetutil --info
<dir>/Assets.car` — the `AppIcon` entries should include `IconImageStack` under
`UIAppearanceLight`, `UIAppearanceDark` and `ISAppearanceTintable`.

**Android and web were derived from that document's own layers, once, by hand.**
`scripts/generate_icon.py` — which drew the whole icon analytically because
there was no source image to start from — is gone, and the three
`assets/icon/*.png` are committed outputs, not generated ones. The layers live
in `AppIcon.icon/Assets` and `icon.json` carries their transforms on a 1024pt
canvas: `App Icon-selection-4.png` is the white mark at scale 1, and `-5`/`-6`
are plain white circles at 10% and 25% alpha, scaled 0.89/0.86 and translated
`(180, -75)`/`(180, -92)` (positive y is down). To redo them:

- `app_icon_foreground.png` is `App Icon-selection-4.png` copied verbatim. It is
  already the mark alone on transparency at 1024, which is exactly the shape an
  adaptive foreground wants.
- `app_icon_background.png` is `#F45D01` full bleed with `-5` and `-6`
  composited over it **at their own scale, not the foreground's**.
- `app_icon.png` is all three layers over that same fill at their `icon.json`
  transforms, flattened opaque.

**Compose from the layers; do not convert the exported PNGs.** Icon Composer's
appearance exports carry an iCCP Display P3 profile *and* have the squircle
already cut out, so they need both a colour conversion and a corner fill. The
layers are tagged sRGB and the mark is used at scale 1, so composing touches no
crisp edge and needs no conversion at all. `#F45D01` is `icon.json`'s own
`display-p3:0.88886,0.40482,0.16646` fill converted to sRGB; sampling an export
instead gives `#E3672A`, the same colour still P3-encoded and much duller once
treated as sRGB.

**The mark is scaled by the adaptive inset; the background wash is not.** A
launcher shows only the central 72 of 108dp, so `adaptive_icon_foreground_inset`
is pinned at `16` — the mark lands at 0.68 and the whole logo survives any mask.
Two things were tried and rejected, both visible only in a masked render:

- **Full bleed (`inset: 0`), matching iOS exactly.** iOS masks a squircle
  inscribed in the full canvas; a launcher's circle is far more aggressive, and
  it cuts the trophy into something unrecognisable.
- **Scaling the wash by 0.68 too, to keep it in register with the mark.** The
  circles are finite, so shrinking them stops them bleeding off the canvas and
  their complete edge floats inside the icon. Full bleed is what an adaptive
  background is for.

What survives is one inherited artifact: the trophy's right handle is cut off by
the edge of the source artwork. At iOS scale it reads as bleeding off the icon;
at 0.68 it is a detached white lozenge beside the cup. Fixing it means editing
the artwork in Icon Composer, not the pipeline.

`AppColors.seed` (`#BC4D08`) is deliberately **not** part of any of this. It is
the app's accent, and the web manifest's `background_color`/`theme_color` track
it rather than the icon, so they stay `#BC4D08` even though the icon ground is
the brighter `#F45D01`.

### Things the source no longer says out loud

Kept here because the code cannot express them and they cost real debugging:

- **Derive a season's label from `Season.midpoint`, never from `startsAt`.**
  The boundaries are midnight in the *competition's* timezone, so on a device
  further west "August" starts on 31 July and a naive label is off by a month.
  `SeasonRangeLabel.rangeLabel` (History's subtitle) has the same problem at
  both ends and solves it the same way: it formats `startsAt + 12h` and
  `endsAt - 12h`, never the boundaries themselves. Two separate things are
  going on there. `seasons.ends_at` is **exclusive** — `functions.sql` sets it
  to `v_start_local + v_step`, i.e. the next period's midnight — so a raw
  format reads "Jul 1 – Aug 1" for July; and the device's own offset can drag
  either boundary onto the neighbouring calendar day. Nudging half a day
  inward fixes both at once, and `history_page_test.dart` pins the result
  (`Jul 1 – Jul 31, 2026`) off UTC fixtures that are Amsterdam midnights, so
  it would fail if either correction were dropped. The Leaderboard's own
  `Ends {date}` / `Loopt tot {date}` is deliberately *not* nudged: that string
  is phrased for the exclusive boundary.
- **A `GestureDetector` that handles a drag merges its entire subtree into one
  semantics node**, the same way a tappable row deliberately reads as a single
  item. Wrapped around a whole page or sheet body that collapses every label
  under it into one node — VoiceOver reads the tab body as a single run-on
  item, and `find.bySemanticsLabel` stops matching the widget that declared
  the label. `SwipeNavigator` therefore passes `excludeFromSemantics: true`:
  a swipe is a touch shortcut for the tab bar and the segmented control, and
  those stay the accessible affordance. It is why the profile sheet's
  `TodayDeltaBadge` assertion broke the moment the sheet gained a swipe, and
  `swipe_navigator_test.dart` pins the tree it must leave alone.
- **`RatingTrendChart` splits itself in two on purpose: the graph is painted,
  the readout is a widget.** `_TrendGeometry` (points + size → the point
  offsets, the two gridline positions and `indexAt(dx)`) is built by the
  widget's `LayoutBuilder` and again inside `paint`, so the scrub hit-test,
  the tooltip's anchor and the painted curve all agree without the painter
  handing anything back. The curve is monotone-cubic (Fritsch–Carlson
  tangents, `_tangentLimit`), not Catmull-Rom, so a spike between two matches
  cannot overshoot into a rating the player never had. The tooltip is a real
  widget positioned by a `CustomSingleChildLayout` rather than canvas text —
  it reuses `RatingDelta`, and `find.text` can see it, which is what
  `rating_trend_chart_test.dart` uses to pin oldest-left/newest-right (the
  ordering bug above is invisible to any assertion the painter could make).
  A tap toggles that readout and a drag scrubs it; neither clears on release,
  since a readout that vanished with the finger could never be read.

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
  this: `historyTitle` is deliberately asserted `findsWidgets`, while the
  season label — body text, mounted once — stays `findsOneWidget`. An app bar
  *action* is mounted once too, so a `trailing` widget is safe to assert
  exactly.
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

- **`showAdaptiveSheet`'s Material branch passes `useRootNavigator: true`, and
  it is the only one of the three that has to say so.** `showModalBottomSheet`
  is the one Flutter entry point here that defaults to `false`;
  `showCupertinoModalPopup` and `showDialog` already default to `true`, which
  is why leaving it out was an Android-only bug. Since the tab bar was hoisted
  out of the pages into `CompetitionShell`, it sits *above* `navigationShell`
  and therefore outside every `StatefulShellBranch` navigator — so a sheet
  opened from a page went onto the branch's overlay, stopping at the top of
  the bar with the bar left undimmed and tappable beside it. While the bar
  still lived in each page's own `Scaffold.bottomNavigationBar` the nearest
  navigator did cover it, which is why nothing had ever needed the flag.
  `sheet_test.dart`'s "covers a bottom bar that sits outside the nested
  navigator" pins it, and is the only thing watching it — no page-level test
  pumps a bar outside a nested navigator.

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
  scope is coming back on purpose. **The filter sheet only lists the game
  types actually played in the current season** — `season_game_types`
  (20260902100000) answers that in one call, scoped by `season_window`'s
  computed bounds rather than by `matches.season_id` so it is also correct
  before the season's first match exists; `MatchListCubit.load` fetches it
  alongside the feed and parks it on `MatchListReady.seasonGameTypes` (a
  virtual getter on the sealed base, since `MatchesPage`'s app bar reads it
  whatever phase the list is in). "All" is always offered, and so is the
  currently selected type even when nobody has played it this season —
  otherwise a filter remembered from last season would be invisible in the
  sheet that is the only way to clear it.
- **`ProfileSheet`'s tab switcher goes in `Sheet`'s `header` slot, not at the
  top of `content`.** `Sheet` pins `header` above its `SingleChildScrollView`
  and scrolls `content`, so a segmented control placed first in `content`
  scrolled away with the tab body it switches. The header slot is already
  exactly "the pinned top region", so the fix is where it is rendered, not a
  second pinned slot on `Sheet` — one that behaved identically to `header`
  would just be "`header` can be a `Column`". `_header` therefore returns
  `_identity(state)` plus, once `ProfileOverviewReady`, the tabs; `_ready` is
  the tab body alone. `profile_sheet_test.dart` pins it by dragging the sheet's
  scroll view and asserting the segmented control's rect is unchanged while the
  body's moved. The tabs being last in the header is also why `Sheet`'s header
  gap moved inside the scroll view (see the `Sheet` bullet under Coding
  conventions) — as a fixed `SizedBox` it held 24px of dead space open under a
  pinned control.
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
flutter test                    # 377 tests at time of writing
flutter gen-l10n                # after editing any .arb

dart run flutter_launcher_icons     # assets/icon/*.png into android/ web/ (not ios/)
flutter run -d chrome           # web
flutter build web
flutter build apk --debug        # verified green

./scripts/db.sh -c "select 1"                 # ad-hoc SQL
./scripts/db.sh -f supabase/migrations/X.sql  # apply a migration
./scripts/db.sh -f supabase/seed.sql          # reseed + run assertions
./scripts/db.sh -f supabase/tests/rls_check.sql      # RLS verification, rolls back
./scripts/db.sh -f supabase/tests/players_check.sql  # players + settings writes
./scripts/db.sh -f supabase/tests/player_rename_guard_check.sql  # claimed names, rolls back
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
- **`order` on a *referenced* table sorts rows inside the embed, not the rows
  you get back**, and for a to-one embed (one row) it is a silent no-op.
  `ProfileRepository.ratingHistory` read `match_players` and asked for
  `.order('played_at', referencedTable: 'matches')`: the top-level rows came
  back in physical order, `.limit(10)` then kept an arbitrary ten of them, and
  the profile's trend chart drew a zigzag for a player on a 25-match win
  streak. There is a spelling that orders the parent by an embedded column
  (`order=matches(played_at).desc`), but the rule now is simpler — **query
  the table that owns the column you sort by.** That method reads `matches`
  with an inner-joined `match_players` filtered to the player, ordered
  `played_at desc, id desc` (the same tuple `recalc_season_from` replays on),
  and reverses the page into oldest-first for the chart.
  **`MatchRepository.recentForPlayer` had the identical bug and is now the
  same shape** — it read `match_players` with
  `.order('played_at', referencedTable: 'matches')` and `.limit(3)`, so the
  profile sheet's Recent matches were three arbitrary matches sorted by date
  rather than the player's three most recent (on the live data: 15 Aug and
  15 Jan for a player whose last three were all on 2 Sep). It now reads
  `matches` with an inner-joined `match_players`, takes the ids, and fetches
  those from `match_feed` — the two-step stays because `match_feed`
  aggregates participants into `jsonb`, so there is no player column to
  filter the view by. `recentBetweenPlayers` was never affected: its ids come
  from the `head_to_head_match_ids` RPC, which orders in SQL.
  **Nothing in `flutter test` can see any of this** — every caller mocks the
  repository, so both bugs shipped green.

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

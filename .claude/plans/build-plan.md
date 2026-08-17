# KeepScore 2 — Build Plan (design reference)

> This is the original design document from the from-scratch build: the Elo
> formula, the schema shape, and the intended architecture. Steps 1–8 are done
> — for current status, conventions, the database workflow, and what's been
> verified, read `CLAUDE.md` first; it is the up-to-date handoff doc. Where
> this file and the code disagree, the code wins — treat this as "why it was
> designed this way," not as a checklist.
>
> Deviations from this plan made during the build: no freezed/build_runner/
> json_serializable (user preference, plain classes + Equatable instead);
> migrations applied via `scripts/db.sh` rather than `supabase db push` (no
> Management API token); the join code is copied to the clipboard rather than
> opened in a share sheet, which keeps `share_plus` out of the dependency
> list; removing a player deactivates them rather than deleting, because
> their matches are part of everyone else's rating history; the team builder
> assigns players with A/B toggle buttons rather than drag and drop, which
> needs no gesture affordance on the web build and works the same on all
> three targets; a match's players cannot be edited after the fact (change the
> score, or delete and log it again), matching the SQL API; realtime
> refetches on a debounced tick instead of animating individual rows, because
> a season replay emits dozens of events for one logged match and `rank` is a
> property of the whole table.

## Context

KeepScore 2 is a Flutter app for iOS, Android and Web where groups of people
run their own competition ladder — log 1v1/2v2/3v3/4v4 (or NvM) matches, and
get an Elo-based leaderboard per season.

### Decisions locked in

| Area | Decision |
|---|---|
| Match shape | Exactly 2 teams, arbitrary sizes per side (NvM allowed) |
| Team Elo | Team rating = mean of member ratings; same delta applied to every member |
| Season rollover | Hard reset — everyone starts each new season at 1000 |
| Elo compute | Postgres (PL/pgSQL) inside the transaction, not client, not Edge Function |
| Margin of victory | Yes — MOV multiplier scales the delta |
| Draws | Allowed, scored 0.5 |
| Edit/delete | Allowed → triggers full chronological replay of that season |
| Confirmation | None; a submitted match counts immediately |
| Auth | Apple, Google, and email OTP (magic code). No password login. |
| Anonymous | Supabase anonymous sign-in, upgradeable in place to a real account |
| Dummy players | Claimable at join time (inherits rating + history) |
| Who logs matches | Any registered member of the competition |
| Realtime | Yes — Supabase Realtime on leaderboard + match list |
| Languages | English + Dutch (ARB from day one) |
| Offline | Online only, with explicit error/retry states |
| UI | Adaptive: Cupertino on iOS/macOS, Material 3 on Android + Web |

**One flagged concern (proceeding as chosen):** MOV is inherently
game-dependent — a 21-3 badminton set and a 3-0 football game are not
comparable. Mitigation: `k_factor`, `mov_enabled` and `mov_cap` are
per-competition columns, so a competition can dial it down or switch to plain
win/loss without a code change or migration.

---

## Part 1 — Database design

The real migrations live in `supabase/migrations/`; this is the design intent
behind them.

### Schema

```
profiles            id (=auth.users.id) PK, display_name, avatar_url, created_at
competitions        id, join_code (unique, 6 chars, Crockford-ish alphabet, no 0/O/1/I),
                    name, owner_id → profiles, season_length ('monthly'|'quarterly'|'yearly'),
                    timezone text default 'Europe/Amsterdam',
                    starting_rating int default 1000, k_factor int default 32,
                    mov_enabled bool default true, mov_cap numeric default 2.5,
                    allow_draws bool default true, created_at
players             id, competition_id → competitions, display_name,
                    user_id → profiles NULL,          -- NULL means dummy/unclaimed
                    is_active bool default true, created_at
                    unique(competition_id, user_id) where user_id is not null
seasons             id, competition_id, index int, starts_at, ends_at
                    unique(competition_id, index), unique(competition_id, starts_at)
matches             id, competition_id, season_id, played_at default now(),
                    team_a_score int, team_b_score int,
                    team_a_rating numeric, team_b_rating numeric,   -- snapshot, for display
                    created_by → profiles, created_at
match_players       match_id, player_id, team char check in ('a','b'),
                    rating_before numeric, rating_after numeric, rating_delta numeric
                    PK(match_id, player_id)
player_ratings      season_id, player_id, rating numeric, played int, wins, losses, draws
                    PK(season_id, player_id)
```

`players` doubles as the competition membership table — the owner is a player
too. A dummy player is simply a player with `user_id IS NULL`.

### Functions

- **`elo_delta(rating_a, rating_b, score_a, score_b, k, mov_enabled, mov_cap) → numeric`** — pure, immutable:
  ```
  expected_a = 1 / (1 + 10 ^ ((rating_b - rating_a) / 400))
  actual_a   = 1.0 win | 0.5 draw | 0.0 loss
  margin     = abs(score_a - score_b)
  mov        = 1.0                                  when draw or not mov_enabled
             = least(mov_cap, greatest(1.0,
                 (ln(margin + 1) / ln(2))           -- margin 1→1.0, 3→2.0, 7→3.0
                 * (2.2 / (0.001 * winner_rating_advantage + 2.2))   -- autocorrelation damper
               ))
  delta_a    = k * mov * (actual_a - expected_a)
  ```
  The damper stops an already-dominant player from running away on blowouts.
- **`season_bounds(anchor timestamptz, length, tz) → (starts_at, ends_at)`** — calendar-aligned (`date_trunc` on month/quarter/year in the competition's timezone), so "current season" means the current calendar month/quarter/year.
- **`ensure_season(competition_id, at timestamptz) → uuid`** — finds or creates the season row covering `at`.
- **`create_match(p_competition_id, p_played_at, p_team_a uuid[], p_team_b uuid[], p_score_a int, p_score_b int) → uuid`** — `SECURITY DEFINER`. Validates: caller is a non-anonymous member; both teams non-empty; no player on both sides; all players belong to this competition; draw allowed if scores equal. Then resolves the season, reads current ratings (defaulting absent rows to `starting_rating`), computes team means, computes the delta once, writes `matches` + `match_players` + upserts `player_ratings`. All one transaction.
- **`delete_match(p_match_id)`** — deletes, then calls `recalc_season`.
- **`recalc_season(p_season_id)`** — resets that season's `player_ratings` to `starting_rating`, replays every match ordered by `(played_at, id)`, rewriting each `match_players` before/after/delta. This is the single source of truth for correctness — used after any delete or edit, and available as a repair tool.
- **`create_competition(name, season_length, timezone) → competition`** — generates a unique `join_code`, inserts competition + owner's player row.
- **`preview_competition(p_join_code) → (name, owner_name, player_count, unclaimed jsonb)`** — `SECURITY DEFINER`, readable by any authenticated user so the join screen can show what you're about to join and which dummy players are claimable, *without* granting read on the whole competition.
- **`join_competition(p_join_code, p_display_name, p_claim_player_id uuid default null) → player`** — either claims an unclaimed player (sets `user_id`, keeps rating + history) or creates a new one. Allowed for anonymous users.

### RLS

Row Level Security on every table. Reads are membership-scoped; **all writes go through the `SECURITY DEFINER` RPCs above** — the tables themselves grant no direct INSERT/UPDATE/DELETE except `profiles` (own row) and `competitions`/`players` (owner-only admin edits).

The anonymous restriction is one reusable predicate:
```sql
create function is_registered() returns boolean language sql stable as $$
  select auth.uid() is not null
     and coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false) = false;
$$;
```
Anonymous users may `join_competition` and read everything in competitions they've joined. They may not create a competition, add dummy players, or log a match — enforced in both the RPCs (raise) and the policies (belt and braces).

### Views and realtime

- `leaderboard` view: `player_ratings` ⋈ `players`, with `rank() over (partition by season_id order by rating desc)`, `display_name`, `is_claimed`.
- `match_feed` view: match + both teams' players aggregated as JSON, so the match list is one query.
- `alter publication supabase_realtime add table matches, player_ratings;` plus indexes on `matches(competition_id, played_at desc)`, `match_players(player_id)`, `player_ratings(season_id, rating desc)`, `players(competition_id)`, `competitions(join_code)`.

---

## Part 2 — Flutter app design

### Structure

```
lib/
  main.dart                     # bootstrap: dotenv, Supabase.initialize, DI, runApp
  app/
    app.dart                    # adaptive root (CupertinoApp vs MaterialApp), l10n, theme
    router/app_router.dart      # go_router + auth redirect
    di/injector.dart            # get_it registrations
  core/
    config/env.dart
    error/failure.dart          # sealed Failure; supabase PostgrestException → Failure mapper
    theme/                      # tokens (spacing/radius/typography) + material & cupertino themes
    widgets/adaptive/           # AdaptiveScaffold, AdaptiveAppBar, AdaptiveButton,
                                # AdaptiveTextField, AdaptiveDialog, AdaptiveActionSheet,
                                # AdaptiveSegmented, AdaptiveRefresh, AdaptiveLoader
    widgets/                    # shared non-adaptive: RatingDeltaChip, EmptyState, ErrorRetry
  l10n/  app_en.arb  app_nl.arb
  features/
    auth/         data/ domain/ presentation/
    competition/  data/ domain/ presentation/
    player/       data/ domain/ presentation/
    match/        data/ domain/ presentation/
    leaderboard/  data/ domain/ presentation/
    profile/      data/ domain/ presentation/
```

Per feature: `domain/` holds entities + an abstract repository; `data/` holds
the Supabase-backed implementation and DTO mappers; `presentation/` holds
blocs, pages and widgets. **No usecase layer** — blocs talk to repositories
directly. It keeps the boilerplate proportional to the app's size while
preserving the dependency direction (presentation → domain ← data).

### Adaptive layer

A single `AppPlatform.useCupertino` (`!kIsWeb && (iOS || macOS)`) drives every
widget in `core/widgets/adaptive/`. Feature code imports only the adaptive
wrappers, never `CupertinoX`/`MaterialX` directly — that keeps the doubled UI
work confined to one folder. Web and Android get Material 3 with a seeded
colour scheme and light/dark; iOS gets Cupertino with a matching accent.

### Blocs

| Bloc | Responsibility |
|---|---|
| `AuthBloc` | Wraps `onAuthStateChange`; exposes `unauthenticated / anonymous / registered`; handles Apple, Google, OTP request+verify, anonymous sign-in, upgrade, sign-out |
| `CompetitionListBloc` | The user's competitions (home screen) |
| `CreateCompetitionCubit` / `JoinCompetitionCubit` | Form + RPC; join flow includes the preview + dummy-player claim step |
| `CompetitionDetailBloc` | Competition + current season + season switcher |
| `LeaderboardCubit` | Season leaderboard + realtime subscription on `player_ratings` |
| `MatchListCubit` | Paginated `match_feed` + realtime insert/delete |
| `MatchFormCubit` | Team building, score entry, validation, submit; shows a **client-side Elo preview** before submitting |
| `PlayersCubit` | Player list, add dummy player, deactivate, share join code |
| `ProfileCubit` | Display name, avatar, account upgrade entry point |

`EloCalculator` is a pure Dart mirror of `elo_delta`, used for the pre-submit
preview — and unit-tested against the same fixture table as the SQL function
so the two can't drift.

### Auth mechanics

- **iOS/Android**: native `sign_in_with_apple` and `google_sign_in` → `supabase.auth.signInWithIdToken(...)`. `google_sign_in` 7.x needs `GoogleSignIn.instance.initialize(serverClientId: ...)` before `authenticate()`.
- **Web**: `supabase.auth.signInWithOAuth(provider, redirectTo: ...)` for both — avoids the 7.x web SDK's id-token limitations.
- **Email code**: `signInWithOtp(email: ..., shouldCreateUser: true)` → 6-digit `verifyOTP`. Chosen over deep links because it needs no per-platform URL scheme setup and behaves identically on all three targets.
- **Anonymous**: `signInAnonymously()`. Upgrade = `linkIdentity()` for OAuth, or `updateUser(email:)` + verify for email — same `user.id` throughout, so the player row, rating and history carry over untouched.

### Realtime

One channel per open competition, subscribing to `postgres_changes` on
`matches` (filter `competition_id`) and `player_ratings` (filter
`season_id`). Channels are disposed in the cubit's `close()`. See
`CLAUDE.md`'s "Realtime is a tick, never a payload" note for why the payload
itself is dropped in favour of a debounced refetch.

### Localisation

`flutter_localizations` + `gen-l10n` with `app_en.arb` / `app_nl.arb`,
following device locale with an in-app override. Every user-facing string
goes through `AppLocalizations`. Dates/numbers via `intl` with the active
locale.

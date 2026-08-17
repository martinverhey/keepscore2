# KeepScore 2

Create your own competition ladder — create matches, get an Elo leaderboard.

A Flutter (iOS / Android / Web) + Supabase app for tracking 1v1–NvM matches within a competition ("Office Table Tennis", a running D&D group, whatever) and ranking players with Elo, per season.

## Features

- **Competitions** — create one, share a join code, invite players.
- **Players** — a player list per competition, including placeholders for people who haven't claimed an account yet.
- **Matches** — build two teams of any size, get a live Elo preview, submit.
  Edit or delete afterwards; the season is transparently replayed.
- **Leaderboard** — Elo per competition, with a combined track and a separate track per game type (1v1 / 2v2 / 3v3 / 4v4 / mixed).
- **Seasons** — calendar-aligned (monthly / quarterly / yearly), hard reset, with a history view of past seasons, medals, and streaks.
- **Auth** — Apple, Google, or email OTP. Guests (anonymous accounts) can join and read a competition, then upgrade to a real account in place without losing anything.
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

Features: `auth`, `competition`, `player`, `match`, `leaderboard`, `profile`,
`settings`.

## Getting started

### Prerequisites

- Flutter (Dart SDK `^3.10.7`)
- A Supabase project, with the schema in `supabase/migrations` applied

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

## License

No license file yet — all rights reserved by default.

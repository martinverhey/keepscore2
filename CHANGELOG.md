# Changelog

Newest first. Each heading is an annotated `vX.Y.Z` tag; pushing that tag ships
the build to TestFlight and Play internal testing.

## v0.2.1 — 2026-09-03

### Added
- 1v1 / Teams toggle in the new match sheet
- Both sides picked in one sheet, step by step
- A 1v1 is named after its players everywhere it shows
- Matches filter offers only game types played this season
- Scrubbable rating trend chart
- Fourth streak tier at 25 wins
- App version in settings

### Changed
- Sides are numbered, not lettered: Team 1 / Team 2
- Managing players is owner-only
- Shorter profile stat labels

### Fixed
- Sheet content sat under the Android navigation bar
- Joining or creating a competition opened a black screen
- Profile tabs scrolled away with the tab body
- Rating history drawn out of order past ten matches

## v0.2.0 — 2026-09-02

### Added
- Liquid glass bars, buttons and sheets on iOS
- New match as its own action beside the tab bar
- The glass bar names the day you are scrolled to
- Sliding glass switch for dark mode
- Seasons headed by name and date range

### Changed
- Page filters are bar actions, with the value in a heading
- One tab bar above both tabs, so the pill animates

### Fixed
- Hard white glass rim in dark mode
- Tab bar reserved the status bar inset above its icons
- Glass tab bar lagged a tap behind

## v0.1.7 — 2026-08-30

### Added
- Manage players without leaving the team picker
- Day headers pin while their own day is on screen

### Fixed
- Team rating vanished when a team was emptied
- History rows opened a profile
- Profile stat labels too long to fit

## v0.1.6 — 2026-08-30

### Added
- Floating action button for adding competitions and players
- Empty states point at the action that fills them

### Changed
- Joining a competition is a sheet, not a page

### Fixed
- Wide web: app bar ends and the FAB sat in the gutter
- Adaptive buttons sized per platform

## v0.1.5 — 2026-08-29

### Changed
- Sheets and dialogs have their own surface colour
- Your own name is accented instead of tagged
- Drag-to-dismiss springs back when a sheet refuses

### Fixed
- Stray gap above the matches list

## v0.1.4 — 2026-08-29

### Added
- Match detail shows who added it, and both team areas
- Drag any part of a sheet to dismiss it
- Delta row on the match card

### Changed
- Rating deltas point with a triangle, not a sign

## v0.1.3 — 2026-08-29

### Added
- Branded splash screen
- Match detail opens in a sheet

### Fixed
- Page titles threw on every navigation on Android

## v0.1.2 — 2026-08-29

### Added
- Log a match in a sheet
- Sheets have their own surface and drag-to-dismiss

### Changed
- Competition list cached app-wide
- Dark mode is a switch
- Placeholders are called unclaimed players

### Fixed
- Switching competitions left both tabs on the old one
- App bar collapses again on Matches and Leaderboard
- Add-players hint missing when a competition had none

## v0.1.1 — 2026-08-28

### Added
- Language preference
- Every tab and settings page is its own route

### Changed
- Current competition and sidebar are app-wide

## v0.1.0 — 2026-08-28

First release.

- Competitions: create, join by code or QR, invite, leave
- Players: placeholders, claiming, renaming, deactivating
- Matches: any team size, edit and delete, feed by day
- Leaderboard: Elo per season, medals, streaks, realtime
- Profile: overview, head-to-head, season history
- Seasons: calendar-aligned resets, finished ones in History
- Auth: email codes, guests, guest upgrade
- English and Dutch, light and dark, iOS / Android / web

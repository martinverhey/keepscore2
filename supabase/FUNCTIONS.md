# Database functions, explained simply

Every action the app takes — joining a competition, logging a match, editing
a score — is actually a call to one of these functions on the database, not
a raw insert/update. This page explains what each one does in plain
language. For the actual SQL, see `migrations/20260809100000_schema.sql`,
`20260809100100_functions.sql`, `20260809100200_rls.sql`,
`20260809100300_views_realtime.sql`, and `20260809100500_normalize_join_code.sql`.

## Who's allowed to do what

- **is_registered** — Is this a real signed-in user, not a guest? Guests
  (anonymous sign-in) can look around but can't create or change anything.
- **is_member** — Is this person part of this competition?
- **is_owner** — Did this person create this competition?
- **shares_competition** — Are these two people in a competition together?
  Used so members can see each other's names without opening up profiles to
  everyone.

## Signing up

- **handle_new_user** — Runs automatically the moment someone signs up.
  Creates their profile (display name etc.) so the rest of the app has
  something to show for them straight away.

## The rating math (Elo)

- **elo_delta** — Given two teams' ratings and the final score, works out
  how many points the winning team gains and the losing team loses (always
  the same number both ways — one goes up, the other goes down by exactly
  as much). See "How the ratings actually move" below.
- **apply_match_ratings** — Takes one already-logged match, calls
  `elo_delta` to get the point swing, and writes the new ratings for every
  player in it.
- **recalc_season** — Wipes a season's ratings and replays every match in
  it from the start, in order. This is how the app guarantees ratings stay
  correct after a match is edited, deleted, or logged with a back-dated
  timestamp.

## Seasons

- **season_bounds** — Works out when a season starts and ends — e.g. "the
  month of August, in Amsterdam's timezone."
- **ensure_season** — Finds the season a given date falls into, creating it
  first if nobody's played in it yet.
- **season_window** — Tells the app what the *current* season is, even
  before it technically exists (no match played in it yet, so no row for
  it).

## Joining a competition

- **generate_join_code** — Makes a random 6-character code for a brand new
  competition, retrying if it happens to clash with an existing one.
- **create_competition** — Sets up a new competition and makes the creator
  its first player.
- **add_dummy_player** — Lets the owner add a "placeholder" player — someone
  playing who doesn't have an account yet.
- **normalize_join_code** — Cleans up a join code however someone typed or
  pasted it: strips spaces/dashes, fixes the casing.
- **preview_competition** — Shows what a join code leads to *before*
  actually joining: the competition's name, who's already in it, and which
  placeholder players are still up for grabs.
- **join_competition** — Actually joins a competition, or turns one of
  those placeholder players into "you" (keeping their existing rating and
  match history).

## Matches

- **create_match** — Logs a new match: makes sure both teams have players,
  nobody's listed twice, the score is valid, then saves it and updates
  ratings.
- **update_match_score** — Changes a match's score or date after the fact,
  then redoes the ratings for whichever season(s) are affected.
- **delete_match** — Removes a match, then redoes the ratings for that
  season as if it never happened.

## How the ratings actually move

- Everyone starts a season at the same rating (1000 by default).
- After a match, the winning team's rating goes up and the losing team's
  goes down by the *same* number of points — nothing is created or lost,
  it just moves from the losers to the winners.
- How many points depends on how surprising the result was: beating a team
  that was rated much higher earns a lot; beating a team rated much lower
  barely moves the needle, because that was expected anyway.
- If "margin of victory" is turned on for a competition, winning by a
  bigger score counts for a bit more — but only up to a cap, and the bonus
  shrinks the more the winner was already expected to win. That stops a
  strong player who keeps beating weak players by a lot from running away
  with the ladder.
- A draw counts as half a win for both teams.
- Editing or deleting a match, or logging one with an earlier date than
  matches that already exist, doesn't try to patch the numbers — it just
  replays the whole season's matches from scratch in order, so the ratings
  are always exactly what they'd be if that match history had happened for
  real.

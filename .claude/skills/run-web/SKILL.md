---
name: run-web
description: Launch KeepScore2's web build in Chrome and screenshot it, to see a UI change in the real app. Use when asked to run the app, screenshot a screen, check a colour or layout change on screen, or confirm something works outside the test suite. Covers the two traps that make Flutter web screenshots silently wrong — the frozen virtual clock and the stale service worker.
---

# Running KeepScore2 on the web

`flutter run -d chrome` is fine when a human is watching. To *see* the result
yourself, build once and drive a headless Chrome over the DevTools Protocol.

## The two traps

Both of these fail by handing you a screenshot that looks plausible, so neither
announces itself.

1. **`chrome --screenshot --virtual-time-budget=N` never gets past the splash.**
   The virtual clock stalls Flutter's frame loop, so every shot is the centred
   spinner on `/splash`, whatever N is. Drive the browser over CDP and wait on
   the real clock instead — that is what `screenshot.mjs` does.

2. **Flutter's service worker serves the previous bundle.** Rebuild, screenshot
   again, and you can get a byte-identical PNG of the *old* UI. It caches per
   origin, so serve each rebuild **on a new port**. If two consecutive shots
   have the same md5 after a real change, this is why — check before concluding
   the change had no effect.

## Recipe

```bash
flutter build web --no-tree-shake-icons

# a port you have not served from yet this session
PORT=8801
(cd build/web && python3 -m http.server $PORT >/dev/null 2>&1 &)

"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless=new --disable-gpu --hide-scrollbars \
  --remote-debugging-port=9333 \
  --user-data-dir="$TMPDIR/keepscore-chrome" about:blank >/dev/null 2>&1 &
sleep 4

node .claude/skills/run-web/screenshot.mjs http://localhost:$PORT/ shot.png 10000
SCHEME=dark node .claude/skills/run-web/screenshot.mjs http://localhost:$PORT/ shot-dark.png 10000
```

Then **look at the PNG**. Clean up with
`pkill -f "http.server $PORT"; pkill -f remote-debugging-port=9333`.

## What you will actually see

Unauthenticated, the app settles on the sign-in page — heading, "Continue with
email" (filled), "Continue as guest" (plain). That is enough to check the theme,
the accent and any l10n change. It renders in whatever locale Chrome reports, so
the Dutch strings usually show.

Anything behind auth (leaderboard, matches, roster) needs a signed-in session;
there is no seeded local session, so driving to those screens means going
through the email OTP. Verify those in a widget test instead unless the point is
genuinely visual.

A blank body with a small centred dot is `/splash` — the app booted but the auth
state never resolved. Trap 1 is the usual cause.

## Measuring, not eyeballing

For contrast or exact colour questions, sample the PNG rather than trusting your
eye — a peach and a mid-orange are easy to confuse at a glance, and that
mistake sends you off fixing the wrong widget. Decode the PNG (`zlib` +
un-filter the scanlines; CDP writes 8-bit RGB), take the most common colour in a
small rectangle over the element, and compute the ratio. `Color.computeLuminance`
makes the same check cheap from a Dart test, which is the better home for it —
see `test/core/adaptive_colors_test.dart`.

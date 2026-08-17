---
name: run-web
description: Launch KeepScore2's web build in Chrome and screenshot it, to see a UI change in the real app. Use when asked to run the app, screenshot a screen, check a colour or layout change on screen, click through the UI, test an authenticated/guest screen, or confirm something works outside the test suite. Covers the traps that make Flutter web screenshots and scripted clicks silently wrong — the frozen virtual clock, the stale service worker, and CSS-vs-device-pixel click coordinates — plus injecting a session directly to reach authenticated screens without clicking.
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

## Clicking through the UI

`screenshot.mjs` opens a fresh target and **closes it** when done (`Page.close`),
so it can't be chained into a click. Use `click.mjs` instead, which reuses the
already-open page target:

```bash
node .claude/skills/run-web/click.mjs 220 262 after-click.png 5000
```

**The coordinates are CSS pixels — the same width/height you passed to
`Emulation.setDeviceMetricsOverride` (440×900 by default) — not the pixels you
measure off the PNG.** `deviceScaleFactor: 2` means the screenshot comes back
at 2x, e.g. an 880×1800 PNG for a 440×900 viewport. Reading a button's
position straight off the image and passing that to `Input.dispatchMouseEvent`
silently clicks a point twice as far down and right as intended — usually
empty space below the real target — and every symptom of this looks like "the
click did nothing": no navigation, no network request, sometimes a stray
hover/focus highlight where the miss briefly grazed something. Divide both
screenshot-measured coordinates by the scale factor before clicking.

Even at the right coordinates, a single scripted mousePressed+mouseReleased on
a CanvasKit/Skwasm canvas is still less reliable than a real click — treat a
click that produces no visible or network effect as "probably missed," not
"probably broken," and re-measure before concluding the app misbehaved.

## Testing authenticated flows without clicking at all

For anything gated behind sign-in, prefer `inject_session.mjs` over driving
the OTP or guest flow through the UI. It signs in anonymously against the live
project over REST, reshapes the response into the exact JSON shape
`supabase_flutter` persists (gotrue's `Session.toJson()`), and writes it
directly to `localStorage` under the `sb-<project-ref>-auth-token` key the
app reads on boot, then reloads:

```bash
node .claude/skills/run-web/inject_session.mjs authenticated.png 8000
```

This sidesteps the click-reliability problem entirely for the common case
where the click was never the point — reaching an authenticated screen was.
It's also the only deterministic way to test session *persistence*: kill the
Chrome process, relaunch it against the same `--user-data-dir`, and check
whether the app boots straight past sign-in. A scripted click in the loop
would leave you unable to tell a real persistence bug apart from a missed
click on relaunch.

## What you will actually see

Unauthenticated, the app settles on the sign-in page — heading, "Continue with
email" (filled), "Continue as guest" (plain). That is enough to check the theme,
the accent and any l10n change. It renders in whatever locale Chrome reports, so
the Dutch strings usually show.

Anything behind auth (leaderboard, matches, roster) needs a signed-in session.
There's no seeded local session and no way to complete the email OTP flow
headlessly (the code only ever arrives by email), but `inject_session.mjs`
reaches a guest-authenticated screen without either problem. For anything that
specifically needs a *registered* (non-guest) account, verify in a widget test
instead unless the point is genuinely visual.

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

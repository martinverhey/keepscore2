---
name: update-upgrade
description: Upgrade KeepScore2's toolchain and dependencies — run flutter upgrade, flutter pub upgrade --major-versions and dart pub upgrade --major-versions, then bump the pinned Flutter version in the GitHub workflows and the Android Gradle/AGP/Kotlin versions if Flutter changed. Use when asked to upgrade or update Flutter, the SDK, the packages or the dependencies, or to bring the project up to date.
---

# Upgrading Flutter and the dependencies

Run every step from the project root. Don't commit unless the user says so
(see "Git workflow" in `CLAUDE.md`).

## 1. Note where you start

```bash
flutter --version
grep -rn flutter-version .github/workflows
git status --short
```

Write down the current Flutter version and the version pinned in CI. If the
working tree already has changes, tell the user before going on, so the
upgrade doesn't get mixed in with them.

## 2. Upgrade Flutter

```bash
flutter upgrade
flutter --version
```

Read the new version off the `Flutter X.Y.Z • channel …` line. If it is
unchanged, say so and carry on with the packages.

## 3. Upgrade the packages, majors included

```bash
flutter pub upgrade --major-versions
dart pub upgrade --major-versions
```

`--major-versions` rewrites the constraints in `pubspec.yaml` as well as the
lockfile. Before going on, run `git diff pubspec.yaml` and list every
constraint that crossed a major version.

**`liquid_glass_easy` is pinned at `^5` on purpose.** Every widget rename in
its history landed in a major release, and `CLAUDE.md` says to read its
changelog before widening the constraint. If the upgrade moved it to a new
major, read that changelog, check every call site in `core/widgets/adaptive/`
(the only files allowed to import it), and tell the user. If it isn't worth
it right now, put the constraint back to `^5.x` and run `flutter pub get`.
Treat any other major bump the same way: read its changelog before taking it.

## 4. Bump the CI Flutter version (if it changed)

All three workflows, `beta-android.yml`, `beta-ios.yml` and `web.yml`, pin
`flutter-version:` on `subosito/flutter-action`. If step 2 changed the
version, bump all three to the exact new version, in the same change as the
upgrade:

```bash
sed -i '' 's/flutter-version: "OLD"/flutter-version: "NEW"/' .github/workflows/*.yml
grep -rn flutter-version .github/workflows
```

The grep must show the same version as `flutter --version` in all three
files. If CI lags behind, every release job fails: v0.5.0 failed on all three
platforms because of this.

## 5. Bump the Android build tools (if Flutter changed)

A new Flutter release often raises its minimum Gradle, Android Gradle Plugin
(AGP) and Kotlin Gradle Plugin (KGP) versions. Below a minimum, the build
fails outright with `Your project's Gradle version (…) is lower than
Flutter's minimum supported version`. `flutter build web` and `flutter test`
never reach Gradle, so nothing in step 6 catches this unless you build
Android. v0.6.1 failed on Play for exactly this reason after the 3.50 upgrade.

Read the new minimums and template versions off the SDK itself:

```bash
FLUTTER_ROOT="$(dirname "$(dirname "$(which flutter)")")"
grep -nE "(warn|error)(Gradle|AGP|KGP)Version" \
  "$FLUTTER_ROOT/packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt"
grep -nE "^const template(DefaultGradle|AndroidGradlePlugin|KotlinGradlePlugin)Version " \
  "$FLUTTER_ROOT/packages/flutter_tools/lib/src/android/gradle_utils.dart"
```

`error*` is the hard minimum; `warn*` and the `template*` constants are what
Flutter generates for a new project. Compare them with ours:

- Gradle: `distributionUrl` in `android/gradle/wrapper/gradle-wrapper.properties`
- AGP: `com.android.application` in `android/settings.gradle.kts`
- KGP: `org.jetbrains.kotlin.android` in `android/settings.gradle.kts`

If any one of them is below its `warn*` version, move all three to the
`template*` versions together. They are tested as a set, and bumping only the
one that errors tends to trip the next check on the following build.

## 6. Verify

```bash
flutter gen-l10n
flutter analyze
flutter test
flutter build web
flutter build appbundle --release
```

The app bundle is what the Android release job builds. It is the only step
here that runs Gradle and R8, so don't skip it.

`flutter analyze` must be clean. A new Flutter release often deprecates
things, so a pile of new `deprecated_member_use` infos is normal after an
upgrade. Try `dart fix --dry-run`, then `dart fix --apply`. After
`dart fix --apply`, dedupe and re-sort the imports it touched, because it can
leave duplicates behind. Fix by hand whatever it can't.

Fix failing tests at the cause; don't loosen the assertion. Follow the
conventions in `CLAUDE.md` while doing it (no comments, adaptive widgets
only). If a fix teaches something the code can't express, add it to
`CLAUDE.md`. For example, the 3.50 move to `material_ui`/`cupertino_ui` added
the note on `KeepScoreApp.localizationsDelegates`.

## 7. Report

Tell the user:
- the Flutter version before → after, and whether CI was bumped
- Gradle / AGP / KGP before → after, or that they already met the minimums
- each major version bump, with anything it broke or anything that was held
  back
- the analyze, test and build results
- an offer to commit, usually as a single `build(deps): …` commit

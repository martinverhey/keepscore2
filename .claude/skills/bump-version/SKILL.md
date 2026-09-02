---
name: bump-version
description: Cut a new KeepScore2 version — reconcile pubspec.yaml against the git tags, bump patch/minor/major, commit, tag, and push. Use when asked to bump the version, cut or ship a release, tag a new version, push a beta to TestFlight or Play, or when pubspec.yaml and the latest tag disagree.
---

# Bumping the version

The version lives in exactly three places and they must agree:

- `pubspec.yaml`'s `version:` line — bare `X.Y.Z`, no `+build` suffix.
- an annotated git tag `vX.Y.Z` on the commit that set it.
- the top heading of `CHANGELOG.md` — `## vX.Y.Z — YYYY-MM-DD`, newest
  first, listing what that version changed.

**Pushing the tag is the release.** Both `.github/workflows/beta-*.yml` fire on
`v*.*.*` and upload to TestFlight and Play internal testing. There is no
staging step and no undo — a build that reaches either store cannot be
unpublished, only superseded. That is why step 4 below confirms before pushing
and not after.

Never `git tag -f` a tag that is already on `origin`: it re-runs both workflows
and pushes a second build under the same version name.

## 1. Read the current state

```bash
git status --porcelain
git rev-parse --abbrev-ref HEAD
sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | head -1
git tag -l 'v*' --sort=-v:refname | head -3
git ls-remote --tags origin 'v*' | tail -3
sed -n 's/^## \(v[0-9].*\)/\1/p' CHANGELOG.md | head -1
```

A tag that exists locally but not on `origin` never shipped. Say so before
bumping: `git push --follow-tags` will carry it along and run its workflows
against that older commit, which is a second build the user may not want.

Stop and say so if the tree is dirty or HEAD is not `main` — this repo commits
straight to `main`, so a release is always cut from a clean `main`.

## 2. Reconcile pubspec against the latest tag

The invariant is `pubspec.yaml` version == highest `v*` tag, at all times, not
just at release. If they differ, fix that **first**, in its own commit, and
ask before doing it — do not fold the correction into the bump.

- **pubspec behind the latest tag** (tagged without bumping — this is what
  happened with `v0.1.2` against `version: 0.1.1`): the store artifact was
  right, because CI derives fastlane's `BUILD_NAME` from `${GITHUB_REF_NAME#v}`
  and ignores pubspec on a tag build. Only the tree is wrong. Bring pubspec
  forward to the tag's version and commit it as
  `chore(release): sync pubspec to vX.Y.Z`. Leave the published tag where it
  is.
- **pubspec ahead of the latest tag** (bumped without tagging): ask which the
  user meant — tag the current commit at the pubspec version, or roll pubspec
  back to the tag and treat the bump as the release about to be cut.

`CHANGELOG.md` is reconciled the same way: if its top heading is behind the
latest tag, that version shipped without notes. Write them from
`git log --oneline --no-merges <previous tag>..<latest tag>` and commit that
alone, before the bump.

Then continue from the reconciled version.

## 3. Ask for the bump, apply it, write the notes, commit, tag

Ask with `AskUserQuestion`, and put the resulting number in each option label
so the choice is concrete — `Patch → 0.1.3`, `Minor → 0.2.0`,
`Major → 1.0.0` — computed off the reconciled version.

```bash
NEXT=0.1.3
python3 - <<PY
import pathlib
path = pathlib.Path("pubspec.yaml")
lines = path.read_text().splitlines(keepends=True)
for index, line in enumerate(lines):
    if line.startswith("version:"):
        lines[index] = f"version: $NEXT\n"
        break
else:
    raise SystemExit("no version: line in pubspec.yaml")
path.write_text("".join(lines))
PY
```

Then write the entry at the top of `CHANGELOG.md`, above the previous
version:

```bash
git log --oneline --no-merges "v$PREVIOUS..HEAD"
```

Group what that turns up under `### Added` / `### Changed` / `### Fixed` —
`feat` is Added, `fix` is Fixed, `refactor`/`style`/`perf` are Changed when a
user could notice and dropped when they could not. `chore`, `docs`, `test` and
`ci` stay out entirely.

**One short line per bullet, no trailing explanation.** Name what the user gets
or what was broken and stop — "Profile tabs scrolled away with the tab body",
not "the profile sheet's tabs now stay pinned because they moved into the
header slot". The reason lives in the commit; the changelog is scanned, not
read. A version with nothing a user can see still gets a heading, with one line
saying so.

The notes go in the release commit, so the tag points at the version, its
pubspec and its notes together:

```bash
git add pubspec.yaml CHANGELOG.md
git commit -m "chore(release): v$NEXT"
git tag -a "v$NEXT" -m "v$NEXT"
```

**`git tag -a`, not a lightweight tag** — `git push --follow-tags` in step 4
only pushes annotated tags, so a lightweight one silently stays local and the
release never fires.

Everything so far is local and reversible
(`git tag -d v$NEXT && git reset --hard HEAD~1`).

## 4. Confirm, then push

Show what is about to go out and ask for a yes before running anything:

```bash
git log --oneline -1
git tag --points-at HEAD
git show --stat HEAD -- pubspec.yaml
```

State plainly that pushing uploads `vX.Y.Z` to TestFlight and Play internal
testing, then ask. Only on an explicit yes:

```bash
git push --follow-tags origin main
```

If the answer is no, leave the commit and tag in place and say how to undo
them — do not unwind anything unasked.

## After pushing

`gh run list --limit 4` shows both beta workflows. They are independent: iOS
can fail on signing while Android succeeds, and vice versa. A failure there
does not need a new version — re-run the workflow, or use its
`workflow_dispatch` trigger, which falls back to `pubspec.yaml` for
`BUILD_NAME` now that the two agree.

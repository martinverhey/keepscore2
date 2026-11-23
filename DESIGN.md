# KeepScore 2 design guidelines

How the app should look and behave, one section per component. Each section
says the rule, how to build it, and the exceptions. `CLAUDE.md` explains *why*
the code is shaped the way it is; this file is the spec the code is held to.

## Bottom sheets

### Rule

- **The bottom holds at most one primary button, and only for an action that
  commits something** — Save, Create, Join, Log match. A sheet that only shows
  something has no bottom button at all.
- **No Cancel, Done or Close button.** A sheet is closed by tapping outside it,
  dragging it down, or the system back gesture.
- **Every sheet has one defined meaning for being closed that way:**
  - **close** — nothing was pending (an info sheet, a list of things to open).
  - **cancel** — what was typed is discarded. When the sheet holds real
    unsaved input, ask before discarding (`confirmsDismissal: true` plus a
    `PopScope`).
  - **apply** — the selection made so far is kept.
- **Every other action goes in the title row, as an icon** — edit, add, scan,
  manage, delete. Two or more share one capsule.
- **A pick list (choose one of several) picks on tap and closes.** Closing it
  any other way is a cancel.

### How

- Build on `core/widgets/sheet.dart`'s `Sheet`, opened with
  `showAdaptiveSheet`.
- The commit action is `Sheet.primaryButton`, a default-kind `AdaptiveButton`.
- Title-row actions are `AdaptiveBarAction`s in `Sheet.titleTrailing`, with
  `titleTrailingAlignment: CrossAxisAlignment.center`. Two or more go in one
  `AdaptiveBarActionGroup`. Every action carries a `semanticLabel`.
- A pick list is a column of rows in `content`, each popping its own value.

### Exceptions

- **A step-by-step sheet** (the team picker) may put its step navigation —
  Previous / Next — at the bottom, through `primaryButton` /
  `secondaryButton`.
- **A sheet with no commit action but one way out of a dead end** (the
  scanner's "Enter code manually") keeps that way out as its bottom
  `primaryButton`: it has to be visible and labelled when the camera fails.
- **The team picker's Manage** stays a plain text button in the title row
  rather than an icon.

### Accessibility

Without a Cancel button, the barrier is how a screen-reader user leaves a
sheet, so it has to be announced and dismissible on every platform —
`showAdaptiveSheet` makes sure of that, and a new sheet gets it for free.

## Dialogs

### Rule

- **A dialog is only for confirming a step that is destructive or hard to
  undo** — delete, leave, remove, discard unsaved input. Anything else is a
  sheet.
- **The title asks the question.** It names the action and what it acts on,
  and ends in a question mark. Where the thing has a name, the title gives
  its kind followed by the name in single quotes, so a bare name never stands
  alone: `Delete competition '{name}'?` / `Competitie '{name}' verwijderen?`,
  `Remove player '{name}'?` / `Speler '{name}' uit de lijst halen?`. Where it
  has none, a demonstrative does the job: `Discard this match?`.
- **The body only describes the consequence.** What is lost, what stays, what
  happens next — never the question again, and no question mark. "Ratings for
  the season will be recalculated.", not "Delete this match? Ratings…".
- **The confirm button is the title's verb alone** — Delete, Leave, Remove,
  Discard, Sign out — never OK or Yes, and never the verb plus its object:
  the title already names what is acted on, so `Leave competition` under
  `Leave {name}?` says it twice and wraps in Material's button row.
- **The cancel button is Cancel**, unless backing out keeps work in progress,
  in which case it says so (`Keep editing`).
- **The two answers sit side by side, Cancel first.** On
  Material both are text buttons, right-aligned at the dialog's end the way
  Material alerts are — neither answer is the primary one, so
  neither gets a filled style. On iOS they are the
  system alert's own two actions.
- **A destructive action is marked destructive**, so it renders in the
  platform's destructive style: error-coloured text on Material, red on iOS. On iOS the safe answer is then the bold
  default — Cancel, not the destructive action.
- **A step is hard to undo when the user cannot get back to where they
  were**, not only when data is deleted. Signing out of a guest account is
  one: a guest cannot sign back in, so it asks first. A registered user
  signs out without a dialog.

### How

- Open it with `showAdaptiveConfirm`, which returns `true` only on confirm.
- `title` is a `…ConfirmTitle` key ending in `?`; `message` is the matching
  `…ConfirmBody` key; `confirmLabel` is a bare verb (`commonDelete`,
  `commonLeave`, `commonRemove`, or the feature's own verb such as
  `matchDiscard`), never the longer menu-item label that opened the dialog;
  `cancelLabel` is `commonCancel` unless the rule above says otherwise.
- Pass `destructive: true` for anything that deletes, removes, discards or
  cannot be got back. That also makes Cancel the default action on iOS.
- The Material buttons are two plain `TextButton`s in `AlertDialog.actions`,
  which lays them out end-aligned and stacks them only if they cannot fit
  on one line.
- A confirmation that guards one action from several entry points lives in
  one flow function that every entry point calls — `signOut(context)` in
  `auth/presentation/pages/sign_out_flow.dart` decides whether to ask, so the
  profile page, the welcome page and the sidebar cannot drift apart.

### Exceptions

- **A dialog carries a Cancel button, unlike a sheet.** A confirmation is a
  choice between two answers, and both have to be visible.
- **Tapping outside counts as Cancel on Material and does nothing on iOS.**
  That is each platform's own alert behaviour (`showDialog` vs
  `showCupertinoDialog` defaults), and neither can confirm by accident.
- **On wide web a sheet renders as a centred dialog**, because
  `showAdaptiveSheet` swaps the bottom sheet for one there. It is still a
  sheet and follows the sheet rules — no Cancel, one commit button — not
  these.

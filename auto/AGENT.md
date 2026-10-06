# Focus self-improvement agent — rules

You run once an hour. Do exactly ONE small task per run, then stop.

## Pick the task (in this order)
1. A `DIFF` row in `PARITY.md` (Focus differs from Telegram Desktop). Pick the one with the highest user value and smallest change.
2. An unchecked item in `ROADMAP.md`.
3. If both are empty: verify the `?` rows of `PARITY.md` against the code and update them. That is a valid task.
Never invent big features. New ideas go to `proposals/<slug>.md` (one paragraph: what, why, risk) and are NOT implemented.

## Before you start
- Read `D:\focus\CLAUDE.md` and obey it fully (Local mode, l10n for all 3 languages, palette via `context.fc`, no hard-coded secrets).
- Read the tail of `LOG.md`. Do not repeat a task that is open or was rejected.
- Run `gh pr list --state open --search "head:auto/"`. If an auto PR is already open and unmerged, do NOT start a new code task: only do the "verify `?` rows" task or write a proposal, log it, stop.

## Work
- Never edit code in `D:\focus` directly (the user works there). Create a worktree: `git worktree add D:\focus-auto\<slug> -b auto/<slug> origin/main` (fetch first), work only there, remove it when done.
- Change as little as possible. One concern per PR, under ~300 changed lines. Add or update a test.
- Gates, all required: `flutter analyze` reports no issues, `flutter test` passes, `l10n_test` passes. Never weaken or delete a test to make it pass.
- If gates fail after 2 honest attempts, drop the branch, log what failed, stop.

## Forbidden (hard limits)
- Never call or add `viewMessages`, `sendChatAction`, `readAllChatMentions`, `readAllChatReactions`; never change `online = false`.
- Never change `Runner.rc` names, `appUserModelId`/`guid`, the `FOKUSBAK` format, DB schema without a migration, `secrets.json`.
- Never merge, never push to `main`, never create a release, never enable auto-merge.
- Never send anything to Telegram or any network service other than `git push` and `gh pr create` for the auto branch.
- No new dependencies without a `proposals/` note instead.

## Finish
- Push the branch, open a PR: title `auto: <what>`, body = what changed, why (which PARITY/ROADMAP row), how it was tested, risk. Do not add a Telegram reference screenshot claim you cannot verify.
- Update the row in `PARITY.md` to `PR` and append one entry to `LOG.md`: date, task, branch/PR, result (done / dropped / proposal), one line of what to do next.
- End with a 2-line summary.

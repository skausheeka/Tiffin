---
name: push-to-master
description: Use whenever committing changes that will be pushed to origin/master in this repo. Commits must NOT include a "Co-Authored-By: Claude" trailer or otherwise list Claude as a contributor/author — the user does not want Claude attribution on this repo's history.
---

# Push to master — no Claude attribution

This repo's owner does not want Claude credited on commits to `master`, on GitHub or anywhere else.

## Rule

When creating a commit that will land on `origin/master`:

- Do **not** append a `Co-Authored-By: Claude ...` trailer to the commit message, even though the default Claude Code commit workflow normally adds one.
- Do **not** set the commit author to Claude. The author stays the repo's configured git user (`git config user.name` / `user.email`) — this is already correct by default and should not be changed.
- Write the commit message itself exactly as you normally would (clear, focused on the why) — only the trailer is omitted.

## If a commit already has the trailer

If a commit was created with the trailer (e.g. by following the default workflow before this skill was added) and it's about to be pushed to `master`:

1. Amend it: `git commit --amend -m "$(cat <<'EOF'\n<same message, minus the Co-Authored-By line>\nEOF\n)"`
2. If it was already pushed to `origin/master`, force-push the correction: `git push --force-with-lease origin master`. Warn the user before force-pushing, per standard git safety practice, even though this is expected/requested behavior for this specific correction.

## Scope

This applies specifically to `master` in this repository. Other branches, PRs, or other repos follow the normal default (trailer included) unless the user says otherwise.

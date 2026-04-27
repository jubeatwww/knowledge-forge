---
name: sporty-quick-commit
description: >-
  **Sporty-only** one-shot commit — hard-wired to Jira at
  `opennetltd.atlassian.net`, `mvn clean test-compile`, and the
  `pre-release-tw` base branch. Do NOT trigger outside Sporty work repos.
  Verifies build, branches off if needed, stages every change, generates a
  Conventional Commits subject with `Jira: ISSUE_ID` as the first body line,
  and commits. Every commit must carry a Jira ticket. Skips the per-file
  confirmation prompt — use only when you trust every dirty file in the
  working tree. Trigger only when working in a Sporty repo and the user says
  "quick commit", "qc", "一鍵 commit", or similar. For the safer interactive
  variant, use `sporty-commit`.
allowed-tools: Bash(git *), Bash(mvn *)
---

# Sporty Quick Commit

Fast path for trusted, focused changes. Same core rules as `sporty-commit`,
but the staging step is automatic and there is only one confirmation gate
(the commit message). Never pushes.

## Core rules

1. **Every commit carries a ticket.** No ticket → ask the user. Never invent one.
2. **Never commit on a base branch.** If the user is on `master` / `main` /
   `develop` / `pre-release-tw`, branch off first using the ticket from rule 1.
3. **Build must compile.** `mvn clean test-compile` runs before staging.
4. **Never push, amend, rebase, or rewrite history.** Out of scope.

## Workflow

### 1. Build verification

```bash
mvn clean test-compile
```

If compilation fails, stop and report the errors verbatim.

### 2. Resolve `ISSUE_ID` and make sure we are on a working branch

```bash
current=$(git branch --show-current)
```

**Case A — on a base branch (`master`, `main`, `develop`, `pre-release-tw`):**

1. Tell the user: `"You're on <current> — every commit needs a ticket and a feature branch. Let me set that up first."`
2. Ask for the Jira ticket number. Do **not** guess.
3. Default new branch name to `feature/<TICKET>`. Confirm with the user — they
   may swap the prefix to `bug` / `fix` / `hotfix` / `chore`.
4. `git checkout -b feature/<TICKET>` carries dirty changes onto the new
   branch — no stash needed. Do **not** `git pull` first.
5. Set `ISSUE_ID = <TICKET>`. Skip Case B.

**Case B — on a working branch matching `<prefix>/<TICKET>(-N)?`:**

```bash
issue_id=$(echo "$current" | sed -E 's#^(feature|bug|fix|hotfix|chore)/##; s/-[0-9]+$//')
```

Supported prefixes: `feature` / `bug` / `fix` / `hotfix` / `chore`.

**Case C — on a working branch that does *not* match the pattern:**

Ask the user for `ISSUE_ID` directly. Do **not** commit without one.

### 3. Stage everything

Show the user what is about to be staged so they can sanity-check, **then**
stage it without a separate prompt:

```bash
git status --short
git add -A
```

If there are no changes after staging, report `Nothing to commit` and stop.

> **Watch out:** this stages every dirty file, including new files. If the
> user is in the habit of leaving `.env`, log files, or scratch notes in the
> tree, recommend `sporty-commit` instead.

### 4. Read the staged diff

```bash
git diff --cached --stat
git diff --cached
```

### 5. Generate the commit message

Same format as `sporty-commit`:

```
<type>(<scope>): <short description>

Jira: <ISSUE_ID>
- <bullet 1>
- <bullet 2>
```

Rules:
- Subject line is `<type>(<scope>): <short description>`, imperative mood,
  under 72 chars.
- `Jira: <ISSUE_ID>` is **always** the first body line.
- Types: `feat` / `fix` / `refactor` / `chore` / `docs` / `test` / `style` /
  `perf`, lowercase, imperative.
- Skip bullets for trivial one-line fixes (but always keep `Jira:` line).
- English only. No `Co-Authored-By` trailers.

### 6. Confirm and commit

Print the message and ask once: **"Commit with this message? (yes / edit / abort)"**

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <short description>

Jira: <ISSUE_ID>
- <bullet 1>
- <bullet 2>
EOF
)"
```

### 7. Report

```
Committed <short-sha> on <branch>
  <type>(<scope>): <short description>
```

If a new branch was created in Step 2, mention it on the first line:

```
Created branch feature/<TICKET> (off <base-branch>)
Committed <short-sha> on feature/<TICKET>
  <type>(<scope>): <short description>
```

## Constraints

- Never commit without a ticket. If `ISSUE_ID` cannot be resolved, stop and ask.
- Never commit directly on `master` / `main` / `develop` / `pre-release-tw`.
- Never push (use `sporty-create-pr` after).
- Never amend, rebase, or rewrite history.
- Single confirmation gate — only the commit message. Staging is automatic.
- All commit text in English (en_US).
- Never include `Co-Authored-By` trailers.

## Error handling

| Failure                          | Action                                                          |
|----------------------------------|-----------------------------------------------------------------|
| `mvn clean test-compile` fails   | Stop, report errors verbatim, do not stage anything.            |
| User refuses to provide a ticket | Stop. This skill will not produce a ticket-less commit.         |
| `git checkout -b` fails          | Report stderr verbatim. Do not try to commit.                   |
| No changes in working tree       | Report `Nothing to commit` and stop.                            |
| `git commit` fails               | Report stderr verbatim and stop.                                |
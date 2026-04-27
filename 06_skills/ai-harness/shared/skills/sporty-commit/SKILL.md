---
name: sporty-commit
description: >-
  **Sporty-only** commit workflow — hard-wired to Jira at
  `opennetltd.atlassian.net`, `mvn clean test-compile`, and the
  `pre-release-tw` base branch. Do NOT trigger outside Sporty work repos;
  for other repos use a generic commit flow. Every commit must carry a Jira
  ticket. Subject line uses Conventional Commits format; `Jira: ISSUE_ID`
  appears as the first body line. If the user is still on a base branch
  (master / main / etc.), the skill creates a feature branch first. Trigger
  only when working in a Sporty repo and the user asks to "commit",
  "幫我 commit", or similar. For a no-questions-asked Sporty variant, use
  `sporty-quick-commit` instead.
allowed-tools: Bash(git *), Bash(mvn *)
---

# Commit

Create one well-formed commit on the current branch. Every commit **must** be
tied to a Jira ticket — no exceptions. This skill never pushes and never opens
a PR — pair it with `sporty-create-pr` for that.

## Core rules

1. **Every commit carries a ticket.** No ticket → ask the user. Never invent one.
2. **Never commit on a base branch.** If the user is on `master` / `main` /
   `develop` / `pre-release-tw`, branch off first using the ticket from rule 1.
3. **Build must compile.** `mvn clean test-compile` runs before staging.
4. **Never auto-stage blindly.** Show the file list and let the user confirm.
5. **Never push, amend, rebase, or rewrite history.** Out of scope.

## Required inputs

| Input           | How to resolve                                                           |
|-----------------|--------------------------------------------------------------------------|
| `ISSUE_ID`      | Resolved in Step 2 — from branch name, or asked from the user.           |
| `ISSUE_SUMMARY` | Last commit subject or Jira (Step 3). Ask the user if both fail.         |
| Files to stage  | Determined interactively in Step 4 — never blanket `git add -A`.         |

## Workflow

Follow these steps in order. Do not skip or reorder.

### 1. Build verification

```bash
mvn clean test-compile
```

If compilation fails, stop and report errors verbatim. Do **not** proceed.

### 2. Resolve `ISSUE_ID` and make sure we are on a working branch

```bash
current=$(git branch --show-current)
```

Decide based on `current`:

**Case A — on a base branch (`master`, `main`, `develop`, `pre-release-tw`):**

The user forgot to branch off before working. Recover automatically:

1. Tell the user: `"You're on <current> — every commit needs a ticket and a feature branch. Let me set that up first."`
2. Ask for the Jira ticket number (e.g. `SPRTPLTFRM-14009`). Do **not** guess.
3. Default new branch name to `feature/<TICKET>`. Confirm with the user — they
   may swap the prefix to `bug` / `fix` / `hotfix` / `chore` if it fits better.
4. Create the branch. `git checkout -b` carries uncommitted changes onto the
   new branch — no stash needed:
   ```bash
   git checkout -b feature/<TICKET>
   ```
5. Set `ISSUE_ID = <TICKET>`. Skip the parsing in Case B.

> Do **not** `git pull` or `git fetch` first. Pulling onto a dirty working
> tree is messy and the user just wants to get changes off the base branch.

**Case B — on a working branch matching `<prefix>/<TICKET>(-N)?`:**

Parse the ticket from the branch name (`feature` / `bug` / `fix` / `hotfix` /
`chore` prefixes, optional `-N` retry suffix):

| Branch name                  | Extracted `ISSUE_ID` |
|------------------------------|----------------------|
| `feature/SPRTPLTFRM-14009`   | `SPRTPLTFRM-14009`   |
| `feature/SPRTPLTFRM-14009-2` | `SPRTPLTFRM-14009`   |
| `bug/PROJ-123`               | `PROJ-123`           |
| `fix/PROJ-123-3`             | `PROJ-123`           |
| `hotfix/ABC-456`             | `ABC-456`            |
| `chore/ABC-456`              | `ABC-456`            |

```bash
issue_id=$(echo "$current" | sed -E 's#^(feature|bug|fix|hotfix|chore)/##; s/-[0-9]+$//')
```

**Case C — on a working branch that does *not* match the pattern:**

Ask the user for `ISSUE_ID` directly. Do **not** commit without one.

### 3. Show what will be staged and confirm

Survey the working tree:

```bash
git status --short
git diff --stat
git diff --stat --cached
```

Print a single combined list of files that would be included in the commit
(both unstaged and already-staged), then ask:

**"Stage all of these? (yes / pick / abort)"**

- `yes` → stage every listed file with `git add <file>` per file (do **not**
  use `git add -A` or `git add .`).
- `pick` → ask the user which files to include and stage only those.
- `abort` → stop the workflow.

If there are no changed files, report `Nothing to commit` and stop.

### 4. Read the staged diff

```bash
git diff --cached --stat
git diff --cached
```

Use this — not the unstaged diff — as the source of truth for the message.

### 5. Generate the commit message

Format:

```
<type>(<scope>): <short description>

Jira: <ISSUE_ID>
- <bullet 1: what changed and why>
- <bullet 2: ...>
```

Rules:
- Subject line is `<type>(<scope>): <short description>`, imperative mood,
  under 72 chars.
- `Jira: <ISSUE_ID>` is **always** the first body line. No exceptions.
- Types: `feat` / `fix` / `refactor` / `chore` / `docs` / `test` / `style` /
  `perf`, lowercase.
- Body bullets only when the change is non-trivial — one bullet per logical
  change. Skip bullets for one-line fixes (but always keep `Jira:` line).
- English only. Do **not** add `Co-Authored-By` lines.

Example:

```
fix(auth): resolve session timeout issue

Jira: SPRTPLTFRM-14009
- Update session expiration logic
- Add retry mechanism for auth tokens
```

### 6. Show the draft and confirm

Print the full commit message and ask:
**"Commit with this message? (yes / edit / abort)"**

### 7. Commit (only after confirmation)

Use a heredoc so newlines survive:

```bash
git commit -m "$(cat <<'EOF'
<type>(<scope>): <short description>

Jira: <ISSUE_ID>
- <bullet 1>
- <bullet 2>
EOF
)"
```

### 8. Report

Output exactly:

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
- Never push (`git push` is out of scope — use `sporty-create-pr` after).
- Never amend, rebase, or rewrite history.
- Never use `git add -A` / `git add .` blindly. Always show the file list first.
- All commit text in English (en_US).
- Never include `Co-Authored-By` trailers.

## Error handling

| Failure                          | Action                                                          |
|----------------------------------|-----------------------------------------------------------------|
| `mvn clean test-compile` fails   | Stop, report errors verbatim, do not stage anything.            |
| User refuses to provide a ticket | Stop. This skill will not produce a ticket-less commit.         |
| `git checkout -b` fails          | Report stderr verbatim. Do not try to commit.                   |
| No files changed                 | Report `Nothing to commit` and stop.                            |
| `git commit` fails               | Report stderr verbatim and stop. Do not retry blindly.          |

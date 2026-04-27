---
name: commit
description: >-
  Standardized commit workflow with repo-aware guardrails. Detect repo mode
  first: if the repo path or repo name contains `sporty` (case-insensitive),
  use the Sporty flow with Jira ticket requirement, `mvn clean test-compile`,
  and feature-branch enforcement. Otherwise use a generic commit flow with no
  ticket requirement. Trigger when the user asks to "commit", "幫我 commit",
  or similar.
allowed-tools: Bash(git *), Bash(mvn *)
---

# Commit

Create one well-formed commit on the current branch. This skill is
**repo-aware**: Sporty repos use the Jira workflow; everything else uses a
generic git workflow.

## Core rules

1. Detect repo mode before doing anything else.
2. In **Sporty mode**, every commit carries a Jira ticket.
3. In **Generic mode**, do **not** require a ticket or Jira summary.
4. Never auto-stage blindly. Show the file list and let the user confirm.
5. Never push, amend, rebase, or rewrite history.

## Repo guard

Determine the repo mode up front:

```bash
repo_root=$(git rev-parse --show-toplevel)
repo_name=$(basename "$repo_root")
repo_probe=$(printf '%s\n%s\n' "$repo_root" "$repo_name" | tr '[:upper:]' '[:lower:]')

if printf '%s' "$repo_probe" | grep -q 'sporty'; then
  REPO_MODE="sporty"
else
  REPO_MODE="generic"
fi
```

- `sporty` in repo path or repo name → **Sporty mode**
- otherwise → **Generic mode**
- If the user explicitly says the repo should be treated differently, follow the
  user over the heuristic.

## Workflow

### 1. Detect repo mode

Tell the user whether the repo is being handled as **Sporty** or **Generic**.

### 2. Build verification

**Sporty mode**

```bash
mvn clean test-compile
```

If compilation fails, stop and report the errors verbatim.

**Generic mode**

- No mandatory build gate.
- Only run a repo-specific verification command if the user asked for it or if
  the repo has an obvious, low-risk default and you are confident it applies.
- If no such default exists, say so briefly and continue with a git-only commit.

### 3. Resolve branch rules and commit metadata

```bash
current=$(git branch --show-current)
```

#### Sporty mode

Resolve `ISSUE_ID` and enforce a working branch:

- On `master`, `main`, `develop`, or `pre-release-tw`:
  1. Tell the user a ticket and feature branch are required.
  2. Ask for the Jira ticket number. Never invent one.
  3. Default new branch name to `feature/<TICKET>` and let the user override
     the prefix if needed.
  4. Create the branch:
     ```bash
     git checkout -b feature/<TICKET>
     ```
- On a working branch matching `<prefix>/<TICKET>(-N)?`, parse the ticket:
  ```bash
  issue_id=$(echo "$current" | sed -E 's#^(feature|bug|fix|hotfix|chore)/##; s/-[0-9]+$//')
  ```
- On any other branch, ask the user for `ISSUE_ID`.

#### Generic mode

- Do **not** ask for a ticket.
- Do **not** force a feature branch just because the user is on `main` or
  `master`. Only branch if the user explicitly asks.
- Resolve a plain commit title from the staged diff, working tree, or last
  commit context.

### 4. Show what will be staged and confirm

Survey the working tree:

```bash
git status --short
git diff --stat
git diff --stat --cached
```

Print a single combined list of files that would be included in the commit and
ask:

**"Stage all of these? (yes / pick / abort)"**

- `yes` → stage every listed file with `git add <file>` per file
- `pick` → ask which files to include and stage only those
- `abort` → stop

If there are no changed files, report `Nothing to commit` and stop.

### 5. Read the staged diff

```bash
git diff --cached --stat
git diff --cached
```

Use the staged diff as the source of truth for the message.

### 6. Generate the commit message

#### Sporty mode

Format:

```text
<type>(<scope>): <short description>

Jira: <ISSUE_ID>
- <bullet 1: what changed and why>
- <bullet 2: ...>
```

Rules:
- Subject line is `<type>(<scope>): <short description>`, imperative mood, under 72 chars
- `Jira: <ISSUE_ID>` is always the first body line
- Types: `feat` / `fix` / `refactor` / `chore` / `docs` / `test` / `style` / `perf`
- Skip bullets for trivial one-line fixes (but always keep `Jira:` line)

#### Generic mode

Format:

```text
<type>(<scope>): <short description>

- <bullet 1: what changed and why>
- <bullet 2: ...>
```

Rules:
- No ticket header
- `(<scope>)` is optional when it does not add value
- Keep the first line imperative and under 72 chars
- Skip the body for trivial one-line fixes

### 7. Show the draft and confirm

Print the full commit message and ask:

**"Commit with this message? (yes / edit / abort)"**

### 8. Commit

Use a heredoc so newlines survive:

```bash
git commit -m "$(cat <<'EOF'
<final commit message>
EOF
)"
```

### 9. Report

**Sporty mode**

```text
Committed <short-sha> on <branch>
  [<ISSUE_ID>] <ISSUE_SUMMARY>
```

If a new branch was created:

```text
Created branch feature/<TICKET> (off <base-branch>)
Committed <short-sha> on feature/<TICKET>
  [<ISSUE_ID>] <ISSUE_SUMMARY>
```

**Generic mode**

```text
Committed <short-sha> on <branch>
  <type>(<scope>): <short description>
```

## Constraints

- Ticket and Jira are required only in **Sporty mode**
- Never require a ticket in **Generic mode**
- Never push, amend, rebase, or rewrite history
- Never use `git add -A` or `git add .` in this skill
- All commit text in English
- Never include `Co-Authored-By` trailers

## Error handling

| Failure | Action |
|---------|--------|
| Sporty build fails | Stop, report errors verbatim, do not stage anything |
| Sporty ticket cannot be resolved | Stop and ask the user |
| `git checkout -b` fails | Report stderr verbatim, do not continue |
| No files changed | Report `Nothing to commit` and stop |
| `git commit` fails | Report stderr verbatim and stop |

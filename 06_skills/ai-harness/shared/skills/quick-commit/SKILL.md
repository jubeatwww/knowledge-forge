---
name: quick-commit
description: >-
  Fast commit workflow with repo-aware guardrails. Detect repo mode first: if
  the repo path or repo name contains `sporty` (case-insensitive), use the
  Sporty flow with Jira ticket requirement, `mvn clean test-compile`, and
  feature-branch enforcement. Otherwise use a generic quick-commit flow with no
  ticket requirement. Trigger when the user says "quick commit", "qc",
  "一鍵 commit", or similar. For the safer interactive variant, use `commit`.
allowed-tools: Bash(git *), Bash(mvn *)
---

# Quick Commit

Fast path for trusted, focused changes. Same repo-aware split as `commit`, but
the staging step is automatic and there is only one confirmation gate.

## Core rules

1. Detect repo mode before doing anything else.
2. In **Sporty mode**, every commit carries a Jira ticket.
3. In **Generic mode**, do **not** require a ticket.
4. Never push, amend, rebase, or rewrite history.

## Repo guard

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

If the user explicitly overrides the heuristic, follow the user.

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
  there is an obvious, low-risk default and you are confident it applies.
- Otherwise continue with a git-only quick commit.

### 3. Resolve branch rules and commit metadata

```bash
current=$(git branch --show-current)
```

#### Sporty mode

- On `master`, `main`, `develop`, or `pre-release-tw`, ask for the Jira ticket,
  default branch name to `feature/<TICKET>`, and create it with:
  ```bash
  git checkout -b feature/<TICKET>
  ```
- On a matching work branch, parse the ticket:
  ```bash
  issue_id=$(echo "$current" | sed -E 's#^(feature|bug|fix|hotfix|chore)/##; s/-[0-9]+$//')
  ```
- Otherwise ask for `ISSUE_ID`.

Resolve `ISSUE_SUMMARY` the same way as `commit`:

```bash
git rev-list --count HEAD ^origin/master
```

- `count == 0` → Jira or user input
- `count > 0` → last commit subject without `[ISSUE_ID]`

#### Generic mode

- Do **not** ask for a ticket
- Do **not** auto-branch just because the user is on `main` or `master`
- Resolve a plain commit title from the current changes

### 4. Show what will be staged, then stage everything

```bash
git status --short
git diff --stat
git add -A
```

If there are no changes after staging, report `Nothing to commit` and stop.

> Watch out: this stages every dirty file, including new files. If the working
> tree is mixed, recommend `commit` instead.

### 5. Read the staged diff

```bash
git diff --cached --stat
git diff --cached
```

### 6. Generate the commit message

#### Sporty mode

```text
[<ISSUE_ID>] <ISSUE_SUMMARY>

<type>(<scope>): <short description>

- <bullet 1>
- <bullet 2>
```

#### Generic mode

```text
<type>(<scope>): <short description>

- <bullet 1>
- <bullet 2>
```

Rules for both modes:
- types: `feat` / `fix` / `refactor` / `chore` / `docs` / `test` / `style` / `perf`
- keep the first line imperative and concise
- skip the body for trivial one-line fixes
- no `Co-Authored-By` trailers

### 7. Confirm and commit

Print the full message and ask once:

**"Commit with this message? (yes / edit / abort)"**

Then commit:

```bash
git commit -m "$(cat <<'EOF'
<final commit message>
EOF
)"
```

### 8. Report

**Sporty mode**

```text
Committed <short-sha> on <branch>
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
- Single confirmation gate only: the commit message
- Never push, amend, rebase, or rewrite history
- All commit text in English

## Error handling

| Failure | Action |
|---------|--------|
| Sporty build fails | Stop and report errors verbatim |
| Sporty ticket cannot be resolved | Stop and ask the user |
| `git checkout -b` fails | Report stderr verbatim and stop |
| No changes in working tree | Report `Nothing to commit` and stop |
| `git commit` fails | Report stderr verbatim and stop |

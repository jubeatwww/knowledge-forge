---
name: sporty-create-pr
description: >-
  **Sporty-only** PR workflow — hard-wired to Jira at
  `opennetltd.atlassian.net` and the `pre-release-tw` base branch. Do NOT
  trigger outside Sporty work repos; for other repos use a generic PR
  flow. Title format `[ISSUE_ID] ISSUE_SUMMARY`, body links back to the
  Jira ticket, PR opens against `pre-release-tw` by default. Trigger only
  when working in a Sporty repo and the user asks to "open a PR",
  "create a pull request", "幫我開 PR", or similar.
allowed-tools: Bash(git *), Bash(gh *)
---

# Create PR

Open a pull request following the team's conventions. This skill stops at PR
creation — it does **not** post anything back to Jira.

## Required inputs (collect before doing anything destructive)

| Input           | How to resolve                                                                                |
|-----------------|-----------------------------------------------------------------------------------------------|
| `ISSUE_ID`      | Parse from current branch name (see Step 1). Ask the user if parsing fails.                   |
| `ISSUE_SUMMARY` | Pull fｓrom last commit subject or Jira (see Step 2). Ask the user if both fail.               |
| `BASE_BRANCH`   | Defaults to `pre-release-tw`. Override only if the user explicitly asks for a different base. |

## Workflow

Follow these steps in order. Do not skip or reorder.

### 1. Retrieve `ISSUE_ID` from the current branch

```bash
git branch --show-current
```

Supported branch patterns (strip prefix and any trailing `-N` retry suffix):

| Branch name                  | Extracted `ISSUE_ID` |
|------------------------------|----------------------|
| `feature/SPRTPLTFRM-14009`   | `SPRTPLTFRM-14009`   |
| `feature/SPRTPLTFRM-14009-2` | `SPRTPLTFRM-14009`   |
| `bug/PROJ-123`               | `PROJ-123`           |
| `fix/PROJ-123-3`             | `PROJ-123`           |
| `hotfix/ABC-456`             | `ABC-456`            |
| `chore/ABC-456`              | `ABC-456`            |

Example extraction:

```bash
branch=$(git branch --show-current)
issue_id=$(echo "$branch" | sed -E 's#^(feature|bug|fix|hotfix|chore)/##; s/-[0-9]+$//')
```

If the branch does not match any pattern, **ask the user** for `ISSUE_ID` manually.

### 2. Retrieve `ISSUE_SUMMARY`

Determine whether the branch already has commits diverged from `master`
(branches are created off `master`, even though PRs target `pre-release-tw`):

```bash
git rev-list --count HEAD ^origin/master
```

- **count == 0** → branch has no new commits → stop and tell the user there is nothing to PR.
- **count == 1** (first commit) → fetch from Jira:
  - URL: `https://opennetltd.atlassian.net/browse/<ISSUE_ID>`
  - Use Atlassian MCP `getJiraIssue` if available; otherwise ask the user.
- **count > 1** → take the last commit subject and strip the `[ISSUE_ID]` prefix:
  ```bash
  git log -1 --format=%s
  ```
  Example: `[SPRTPLTFRM-14009] Fix login retry` → `Fix login retry`.

If both extraction paths fail, **ask the user** to provide `ISSUE_SUMMARY` manually.

### 3. Resolve `BASE_BRANCH`

Default to `pre-release-tw`. PRs in this repo branch off and merge back into
`pre-release-tw` — do **not** target `master` / `main` / `develop` unless the
user explicitly asks for a different base in their message (e.g. "open a PR
against master").

Validate the resolved base exists on the remote:

```bash
git fetch origin <BASE_BRANCH>
git rev-parse --verify origin/<BASE_BRANCH>
```

If it does not exist, stop and ask the user for a valid base.

### 4. Make sure the branch is pushed and up to date

```bash
git status --short
git fetch origin <BASE_BRANCH>
```

- If there are uncommitted changes, stop and tell the user — do **not** auto-stage or auto-commit.
- If the local branch is ahead of `origin/<current-branch>` (or the upstream is missing), push:
  ```bash
  git push -u origin "$(git branch --show-current)"
  ```

### 5. Generate the PR description

Collect commit subjects between the merge base and `HEAD`:

```bash
merge_base=$(git merge-base HEAD origin/<BASE_BRANCH>)
git log --no-merges --reverse --format='%s' "$merge_base"..HEAD
```

Summarize into 2–5 bullets — present tense, group by behavior not by file.
Do not invent commits, tickets, or test results that did not happen.

### 6. Show the draft PR to the user and confirm

Print the generated title and body, then ask:
**"Create this PR against `<BASE_BRANCH>`? (yes / edit / abort)"**

Title format:
```
[<ISSUE_ID>] <ISSUE_SUMMARY>
```

Body format:
```markdown
## Jira Issue

https://opennetltd.atlassian.net/browse/<ISSUE_ID>

## Changes

- <bullet 1>
- <bullet 2>
- ...
```

### 7. Create the PR (only after confirmation)

Use a heredoc so the body keeps its newlines:

```bash
gh pr create \
  --base "<BASE_BRANCH>" \
  --title "[<ISSUE_ID>] <ISSUE_SUMMARY>" \
  --body "$(cat <<'EOF'
## Jira Issue

https://opennetltd.atlassian.net/browse/<ISSUE_ID>

## Changes

- <bullet 1>
- <bullet 2>
EOF
)"
```

### 8. Report the result

Output exactly:

```
PR created: <pr-url>
Base:       <BASE_BRANCH>
Jira:       https://opennetltd.atlassian.net/browse/<ISSUE_ID>
```

## Constraints

- All PR text in English (en_US).
- Never post to Jira from this skill — PR creation only.
- Never run `git add`, `git commit`, force-push, or branch deletion from this skill.
- If `gh` is not authenticated, stop and tell the user to run `gh auth login` themselves.

## Error handling

| Failure                           | Action                                                                            |
|-----------------------------------|-----------------------------------------------------------------------------------|
| Branch parsing fails              | Ask user for `ISSUE_ID` manually.                                                 |
| Jira lookup fails on first commit | Ask user for `ISSUE_SUMMARY` manually.                                            |
| Base branch missing on remote     | Stop, re-ask for `BASE_BRANCH`.                                                   |
| Uncommitted changes present       | Stop, report status, do not auto-commit.                                          |
| `gh pr create` fails              | Report stderr verbatim, check that the branch is pushed and no PR already exists. |

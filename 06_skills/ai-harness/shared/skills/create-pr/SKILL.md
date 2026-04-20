---
name: create-pr
description: >-
  Standardized pull request workflow with repo-aware guardrails. Detect repo
  mode first: if the repo path or repo name contains `sporty`
  (case-insensitive), use the Sporty flow with Jira-linked title/body and
  `pre-release-tw` as the default base branch. Otherwise use a generic PR flow
  with no Jira requirement and a base branch inferred from the remote. Trigger
  when the user asks to "open a PR", "create a pull request", "幫我開 PR", or
  similar.
allowed-tools: Bash(git *), Bash(gh *)
---

# Create PR

Open a pull request following repo-aware conventions. This skill stops at PR
creation.

## Core rules

1. Detect repo mode before doing anything else.
2. In **Sporty mode**, use Jira-linked title/body and default base
   `pre-release-tw`.
3. In **Generic mode**, do **not** require Jira or ticket formatting.
4. Never auto-commit, amend, force-push, or delete branches from this skill.

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

### 1. Detect repo mode and current branch

```bash
branch=$(git branch --show-current)
```

Tell the user whether the repo is being handled as **Sporty** or **Generic**.

### 2. Resolve title metadata

#### Sporty mode

Parse `ISSUE_ID` from the branch if it matches `<prefix>/<TICKET>(-N)?`:

```bash
issue_id=$(echo "$branch" | sed -E 's#^(feature|bug|fix|hotfix|chore)/##; s/-[0-9]+$//')
```

If parsing fails, ask the user for `ISSUE_ID`.

Resolve `ISSUE_SUMMARY`:

```bash
git rev-list --count HEAD ^origin/master
```

- `count == 0` → stop; there is nothing to PR
- `count == 1` → fetch from Jira if available, otherwise ask the user
- `count > 1` → take the last commit subject and strip `[ISSUE_ID]`

PR title format:

```text
[<ISSUE_ID>] <ISSUE_SUMMARY>
```

#### Generic mode

- Do **not** require `ISSUE_ID`
- Default the PR title to the last commit subject:
  ```bash
  git log -1 --format=%s
  ```
- If that is missing or unsuitable, ask the user for a title

### 3. Resolve base branch

#### Sporty mode

Default to `pre-release-tw`. Override only if the user explicitly asks.

#### Generic mode

Infer from the remote default branch first:

```bash
base_branch=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')
```

Fallback order:
1. inferred `origin/HEAD`
2. `main`
3. `master`

Validate the base exists on the remote:

```bash
git fetch origin <BASE_BRANCH>
git rev-parse --verify origin/<BASE_BRANCH>
```

If it does not exist, ask the user for a valid base.

### 4. Make sure the branch is ready

```bash
git status --short
git fetch origin <BASE_BRANCH>
```

- If there are uncommitted changes, stop and tell the user
- If the local branch is ahead of its upstream or the upstream is missing, push:
  ```bash
  git push -u origin "$(git branch --show-current)"
  ```

### 5. Generate the PR body

Collect commit subjects between the merge base and `HEAD`:

```bash
merge_base=$(git merge-base HEAD origin/<BASE_BRANCH>)
git log --no-merges --reverse --format='%s' "$merge_base"..HEAD
```

Summarize into 2 to 5 bullets.

#### Sporty mode body

```markdown
## Jira Issue

https://opennetltd.atlassian.net/browse/<ISSUE_ID>

## Changes

- <bullet 1>
- <bullet 2>
```

#### Generic mode body

```markdown
## Summary

- <bullet 1>
- <bullet 2>
```

### 6. Show the draft and confirm

Print the generated title and body, then ask:

**"Create this PR against `<BASE_BRANCH>`? (yes / edit / abort)"**

### 7. Create the PR

```bash
gh pr create \
  --base "<BASE_BRANCH>" \
  --title "<FINAL_TITLE>" \
  --body "$(cat <<'EOF'
<final body>
EOF
)"
```

### 8. Report

**Sporty mode**

```text
PR created: <pr-url>
Base:       <BASE_BRANCH>
Jira:       https://opennetltd.atlassian.net/browse/<ISSUE_ID>
```

**Generic mode**

```text
PR created: <pr-url>
Base:       <BASE_BRANCH>
Title:      <FINAL_TITLE>
```

## Constraints

- Jira is required only in **Sporty mode**
- Never require Jira or ticket formatting in **Generic mode**
- Never run `git add`, `git commit`, force-push, or branch deletion here
- If `gh` is not authenticated, stop and tell the user to run `gh auth login`
- All PR text should be in English unless the user explicitly asks otherwise

## Error handling

| Failure | Action |
|---------|--------|
| Sporty branch parsing fails | Ask the user for `ISSUE_ID` |
| Base branch missing on remote | Stop and re-ask for `BASE_BRANCH` |
| Uncommitted changes present | Stop and report status |
| `gh pr create` fails | Report stderr verbatim and stop |

#!/usr/bin/env bash
# Claude Code status line — disciplined two-line layout
# Line 1: repo  branch  model  (thinking)
# Line 2: 5h pct  7d pct  ctx pct  [thin bar]

input=$(cat)

model=$(echo "$input"    | jq -r '.model.display_name // ""')
effort=$(echo "$input"   | jq -r '.output_style.name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
raw_cwd=$(echo "$input"  | jq -r '.cwd // ""')

# ── Color palette ─────────────────────────────────────────────────────────────
reset='\033[0m'
accent='\033[38;5;114m'      # phosphor green — repo name only
gray='\033[38;5;250m'        # primary text
dark_gray='\033[38;5;250m'   # secondary info (model, branch)
dim_label='\033[38;5;244m'   # labels and separators — subtle but readable
bar_fill='\033[38;5;246m'    # normal filled bar segments — above empty trough
amber='\033[38;5;178m'       # warning: medium-high usage
muted_red='\033[38;5;167m'   # critical: >85% usage

# ── Repo / project name ───────────────────────────────────────────────────────
repo_name=""
if [ -n "$raw_cwd" ]; then
  if git -C "$raw_cwd" rev-parse --git-dir >/dev/null 2>&1; then
    toplevel=$(git -C "$raw_cwd" rev-parse --show-toplevel 2>/dev/null)
    repo_name=$(basename "$toplevel")
  else
    repo_name=$(basename "$raw_cwd")
  fi
fi

# ── Git branch ────────────────────────────────────────────────────────────────
git_branch=""
if [ -n "$raw_cwd" ] && git -C "$raw_cwd" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$raw_cwd" symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$raw_cwd" rev-parse --short HEAD 2>/dev/null)
fi

# Render a metric: label, thin bar, percentage
# Usage: metric_segment <label> <pct> <warn_threshold> <crit_threshold>
metric_segment() {
  local label="$1"
  local pct="$2"
  local warn="${3:-70}"
  local crit="${4:-85}"
  local pct_int
  pct_int=$(printf '%.0f' "$pct")

  local num_color="$gray"
  local fill_color="$bar_fill"
  local trough_color="$dim_label"
  if [ "$pct_int" -ge "$crit" ]; then
    num_color="$muted_red"
    fill_color="$muted_red"
    trough_color="$muted_red"
  elif [ "$pct_int" -ge "$warn" ]; then
    num_color="$amber"
    fill_color="$amber"
    trough_color="$amber"
  fi

  # Build bar with filled and empty segments colored separately
  local width=12
  local filled_count
  filled_count=$(awk -v p="$pct" -v w="$width" \
    'BEGIN { v=int(p/100*w+0.5); if(v>w)v=w; if(v<0)v=0; print v }')
  local empty_count=$(( width - filled_count ))
  local filled_str="" empty_str="" i
  for (( i=0; i<filled_count; i++ )); do filled_str="${filled_str}━"; done
  for (( i=0; i<empty_count;  i++ )); do empty_str="${empty_str}─"; done

  printf "${dim_label}%s${reset} ${fill_color}%s${trough_color}%s${reset} ${num_color}%d%%${reset}" \
    "$label" "$filled_str" "$empty_str" "$pct_int"
}

# ── Line 1: repo  branch  model  (thinking) ───────────────────────────────────
line1=""

if [ -n "$repo_name" ]; then
  line1="$(printf "${accent}%s${reset}" "$repo_name")"
fi

if [ -n "$git_branch" ]; then
  line1="${line1}$(printf "   ${dark_gray}%s${reset}" "$git_branch")"
fi

if [ -n "$model" ]; then
  line1="${line1}$(printf "   ${dark_gray}%s${reset}" "$model")"
fi

if [ -n "$effort" ] && [ "$effort" != "default" ] && [ "$effort" != "Default" ]; then
  line1="${line1}$(printf " ${dim_label}(%s)${reset}" "$effort")"
fi

# ── Line 2: usage metrics ─────────────────────────────────────────────────────
parts2=()

if [ -n "$five_pct" ]; then
  parts2+=("$(metric_segment '5h' "$five_pct" 70 85)")
fi

if [ -n "$week_pct" ]; then
  parts2+=("$(metric_segment '7d' "$week_pct" 70 85)")
fi

if [ -n "$used_pct" ]; then
  parts2+=("$(metric_segment 'ctx' "$used_pct" 70 85)")
fi

# ── Assemble output ───────────────────────────────────────────────────────────
if [ -n "$line1" ]; then
  printf '%s' "$line1"
fi

if [ "${#parts2[@]}" -gt 0 ]; then
  [ -n "$line1" ] && printf '\n'
  first=1
  for seg in "${parts2[@]}"; do
    if [ "$first" -eq 1 ]; then
      printf '%s' "$seg"
      first=0
    else
      printf "   %s" "$seg"
    fi
  done
fi

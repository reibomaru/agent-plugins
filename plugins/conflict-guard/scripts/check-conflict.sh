#!/usr/bin/env bash
# conflict-guard: Check for potential merge conflicts with base branch
# Runs as a PreToolUse hook for Write/Edit tools
#
# Input (stdin): JSON with tool_name and tool_input
# Output (stdout): JSON with decision (allow/warn)

set -euo pipefail

INPUT=$(cat)

# Extract file_path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  echo '{"decision":"allow"}'
  exit 0
fi

# Not in a git repo -> skip
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo '{"decision":"allow"}'
  exit 0
fi

# Resolve to relative path from repo root
REPO_ROOT=$(git rev-parse --show-toplevel)
REL_PATH="${FILE_PATH#"$REPO_ROOT"/}"

# Detect base branch: check common names, fallback to default remote HEAD
detect_base_branch() {
  # Check environment variable first (user override)
  if [[ -n "${CONFLICT_GUARD_BASE_BRANCH:-}" ]]; then
    echo "$CONFLICT_GUARD_BASE_BRANCH"
    return
  fi

  # Try to get default branch from remote
  local default_branch
  default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
  if [[ -n "$default_branch" ]]; then
    echo "origin/$default_branch"
    return
  fi

  # Fallback: check common branch names
  for branch in origin/main origin/master origin/develop; do
    if git rev-parse --verify "$branch" &>/dev/null; then
      echo "$branch"
      return
    fi
  done

  # No base branch found
  echo ""
}

BASE_BRANCH=$(detect_base_branch)

if [[ -z "$BASE_BRANCH" ]]; then
  echo '{"decision":"allow"}'
  exit 0
fi

# Find merge base
CURRENT_BRANCH=$(git rev-parse HEAD 2>/dev/null || true)
if [[ -z "$CURRENT_BRANCH" ]]; then
  echo '{"decision":"allow"}'
  exit 0
fi

MERGE_BASE=$(git merge-base "$CURRENT_BRANCH" "$BASE_BRANCH" 2>/dev/null || true)
if [[ -z "$MERGE_BASE" ]]; then
  echo '{"decision":"allow"}'
  exit 0
fi

# Check if the base branch has modified this file since the merge base
BASE_DIFF=$(git diff --name-only "$MERGE_BASE".."$BASE_BRANCH" -- "$REL_PATH" 2>/dev/null || true)

if [[ -z "$BASE_DIFF" ]]; then
  # Base branch hasn't touched this file -> no conflict risk
  echo '{"decision":"allow"}'
  exit 0
fi

# Base branch has changes to this file. Check if current branch also modified it.
LOCAL_DIFF=$(git diff --name-only "$MERGE_BASE"..HEAD -- "$REL_PATH" 2>/dev/null || true)

# Get the changed line ranges on the base branch for context
BASE_CHANGES=$(git diff --stat "$MERGE_BASE".."$BASE_BRANCH" -- "$REL_PATH" 2>/dev/null | head -1)

if [[ -n "$LOCAL_DIFF" ]]; then
  # Both branches modified the same file -> high conflict risk
  MSG="⚠️ CONFLICT RISK (HIGH): '$REL_PATH' has been modified on both the current branch and '$BASE_BRANCH' since their merge-base. Editing this file will likely cause a merge conflict.\n\nBase branch changes: $BASE_CHANGES\n\nConsider: (1) merge/rebase from $BASE_BRANCH first, or (2) proceed carefully and resolve conflicts later."
  # Escape for JSON
  MSG_JSON=$(echo -e "$MSG" | jq -Rs .)
  echo "{\"decision\":\"warn\",\"message\":$MSG_JSON}"
else
  # Only base branch modified it -> moderate conflict risk
  MSG="⚠️ CONFLICT RISK: '$REL_PATH' has been modified on '$BASE_BRANCH' since the merge-base. Editing this file may cause a merge conflict when merging.\n\nBase branch changes: $BASE_CHANGES\n\nConsider merging/rebasing from $BASE_BRANCH first if changes overlap."
  MSG_JSON=$(echo -e "$MSG" | jq -Rs .)
  echo "{\"decision\":\"warn\",\"message\":$MSG_JSON}"
fi

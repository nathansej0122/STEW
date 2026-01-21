---
name: h:status
description: Read-only overview of current coordination state (CLEO focus, git status, AI-OPS)
allowed-tools: Read, Grep, Glob, Bash
---

# Harness Status Check

You are performing a read-only status check for the coordination overlay.

## Required Checks

### 1. CLEO Focus Status

Run the following to get current focused task:

```bash
# Try CLEO_BIN first, then PATH
if [ -n "${CLEO_BIN:-}" ]; then
  "$CLEO_BIN" focus show
elif command -v cleo >/dev/null 2>&1; then
  cleo focus show
else
  echo "CLEO not found. Set CLEO_BIN env var or add cleo to PATH."
  echo "Install: https://github.com/your-org/cleo"
fi
```

### 2. Git Repository Status

```bash
git status --porcelain
```

Report:
- Clean tree vs pending changes
- Current branch name

### 3. AI-OPS Document Presence

Check for these files in the target repo:
- `.planning/AI-OPS.md` - If exists, user MUST read before any action
- `.planning/AI-OPS-KNOWLEDGE.md` - Supplemental knowledge base
- `.planning/LOCKED_BEHAVIOR_CANDIDATES.md` - Authoritative for locked behaviors

### 4. Planning Infrastructure

Check for:
- `.planning/STATE.md`
- `.planning/ROADMAP.md`
- `.planning/PROJECT.md`
- `.planning/config.json`

## Output Format

Provide a summary in this exact structure:

```
=== HARNESS STATUS ===

CLEO Focus: [T### - Task Title] or [None - no focused task]
Git Status: [Clean] or [Uncommitted changes: X files]
Branch: [branch-name]

AI-OPS Documents:
  - AI-OPS.md: [Present - READ REQUIRED] or [Missing]
  - LOCKED_BEHAVIOR_CANDIDATES.md: [Present - authoritative] or [Missing]

Planning Docs: [X of 4 present]

=== RECOMMENDED NEXT COMMAND ===
[Recommendation based on state]
```

## Recommendation Logic

1. If no CLEO focus: recommend `h:focus`
2. If CLEO focus exists but AI-OPS missing: recommend onboarding/reading docs
3. If CLEO focus + AI-OPS present: recommend `h:route`

## Important

- This is READ-ONLY. Do not modify any files.
- Do not execute GSD commands; only check status.
- If AI-OPS.md exists, emphasize it must be read before proceeding.

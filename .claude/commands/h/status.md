---
name: h:status
description: Read-only overview of current coordination state (CLEO focus, git status, AI-OPS)
allowed-tools: Read, Grep, Glob, Bash
---

# Harness Status Check

You are performing a read-only status check for the coordination overlay.

## Required Checks

### 1. CLEO Focus Status

**CLEO project state is EXTERNAL to repos.** CLEO state lives in a directory specified by
`CLEO_PROJECT_DIR`, not in the project repository. Project repos must NOT contain `.cleo/`.

Run the following to get current focused task:

```bash
# CLEO requires CLEO_PROJECT_DIR to be set (external state directory)
if [ -z "${CLEO_PROJECT_DIR:-}" ]; then
  echo "CLEO_NOT_CONFIGURED"
else
  # Resolve CLEO binary
  if [ -n "${CLEO_BIN:-}" ]; then
    CLEO_CMD="$CLEO_BIN"
  elif command -v cleo >/dev/null 2>&1; then
    CLEO_CMD="cleo"
  else
    echo "CLEO_BINARY_NOT_FOUND"
    exit 0
  fi

  # Run CLEO from the external project state directory
  if [ -f "$CLEO_PROJECT_DIR/.cleo/todo.json" ]; then
    (cd "$CLEO_PROJECT_DIR" && "$CLEO_CMD" focus show 2>/dev/null) || echo "CLEO_FOCUS_ERROR"
  else
    echo "CLEO_NOT_INITIALIZED"
  fi
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

CLEO: [Status line - see below]
Git Status: [Clean] or [Uncommitted changes: X files]
Branch: [branch-name]

AI-OPS Documents:
  - AI-OPS.md: [Present - READ REQUIRED] or [Missing]
  - LOCKED_BEHAVIOR_CANDIDATES.md: [Present - authoritative] or [Missing]

Planning Docs: [X of 4 present]

=== RECOMMENDED NEXT COMMAND ===
[Recommendation based on state]
```

### CLEO Status Line Values

Based on the check output, report ONE of these:

| Output | Status Line |
|--------|-------------|
| `CLEO_NOT_CONFIGURED` | Not configured (set CLEO_PROJECT_DIR) |
| `CLEO_BINARY_NOT_FOUND` | Binary not found (add cleo to PATH or set CLEO_BIN) |
| `CLEO_NOT_INITIALIZED` | Project state not initialized in $CLEO_PROJECT_DIR |
| `CLEO_FOCUS_ERROR` | Error reading focus |
| No task focused | None - no focused task |
| Task focused | T### - Task Title |

**IMPORTANT:** Never suggest running `cleo init` inside the project repository.
If CLEO_PROJECT_DIR is not set or not initialized, that is a configuration issue
to be resolved externally, not inside the repo.

## Recommendation Logic

1. If CLEO not configured: recommend setting `CLEO_PROJECT_DIR` (do NOT recommend `cleo init` in repo)
2. If CLEO configured but not initialized: recommend initializing CLEO in `$CLEO_PROJECT_DIR` (external)
3. If no CLEO focus: recommend `h:focus`
4. If CLEO focus exists but AI-OPS missing: recommend onboarding/reading docs
5. If CLEO focus + AI-OPS present: recommend `h:route`

## Important

- This is READ-ONLY. Do not modify any files.
- Do not execute GSD commands; only check status.
- If AI-OPS.md exists, emphasize it must be read before proceeding.
- **NEVER recommend `cleo init` inside the project repository.**

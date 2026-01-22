---
name: h:status
description: Read-only overview of current coordination state (CLEO mandatory, planning contract)
allowed-tools: Read, Grep, Glob, Bash
---

<!-- FENCE CHECK: If output appears garbled, verify this file has balanced markdown fences. -->
<!-- Each "Run:" section must contain exactly ONE fenced bash block. -->

# Harness Status Check

You are performing a read-only status check for the coordination overlay.

**CLEO is MANDATORY. Planning contract (STATE.md) is REQUIRED.**

## Run: Consolidated Status Check

Execute this single Bash block to gather all status information:

```bash
# === CLEO Auto-Discovery (MANDATORY) ===
# Derive PROJECT_KEY: git remote origin basename, else repo directory basename
REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
if [ -n "$REMOTE_URL" ]; then
  PROJECT_KEY=$(basename "$REMOTE_URL" .git)
else
  PROJECT_KEY=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
fi
CLEO_STATE_DIR="$HOME/.cleo/projects/$PROJECT_KEY"
echo "PROJECT_KEY: $PROJECT_KEY"
echo "CLEO_STATE_DIR: $CLEO_STATE_DIR"

# === Gate 0: CLEO Binary ===
if command -v cleo >/dev/null 2>&1; then
  CLEO_CMD="cleo"
elif [ -n "${CLEO_BIN:-}" ] && [ -x "$CLEO_BIN" ]; then
  CLEO_CMD="$CLEO_BIN"
else
  echo "CLEO_BINARY: NOT_FOUND"
  exit 1
fi
echo "CLEO_BINARY: OK"

# === Gate 1: CLEO Initialized ===
if [ ! -f "$CLEO_STATE_DIR/.cleo/todo.json" ]; then
  echo "CLEO_INIT: NOT_INITIALIZED"
  exit 1
fi
echo "CLEO_INIT: OK"

# === Gate 2: CLEO Focus (read directly from todo.json) ===
TODO_FILE="$CLEO_STATE_DIR/.cleo/todo.json"
read -r FOCUS_ID FOCUS_TITLE FOCUS_STATUS < <(python3 - "$TODO_FILE" <<'PYEOF'
import sys, json
todo_file = sys.argv[1]
try:
    with open(todo_file) as f:
        d = json.load(f)
except:
    print("\t\t")
    sys.exit(0)
focus = d.get("focus") or {}
focus_id = focus.get("currentTask") or focus.get("focusedTaskId") or ""
focus_title = ""
focus_status = ""
if focus_id:
    for task in d.get("tasks", []):
        if task.get("id") == focus_id:
            focus_title = task.get("title", "")
            focus_status = task.get("status", "")
            break
print(f"{focus_id}\t{focus_title}\t{focus_status}")
PYEOF
)

if [ -z "$FOCUS_ID" ]; then
  echo "CLEO_FOCUS: NO_FOCUS"
  exit 1
fi
echo "CLEO_FOCUS: $FOCUS_ID - $FOCUS_TITLE ($FOCUS_STATUS)"

# === Gate 3: Planning Contract (STATE.md) ===
if [ ! -f ".planning/STATE.md" ]; then
  echo "STATE_MD: MISSING"
  exit 1
fi
echo "STATE_MD: OK"

# === Gate 4: STATE.md Pointer ===
POINTER_LINE=$(grep -E "^\s*Pointer:" .planning/STATE.md 2>/dev/null | head -1 | sed 's/^[[:space:]]*Pointer:[[:space:]]*//')
if [ -z "$POINTER_LINE" ] || echo "$POINTER_LINE" | grep -q "^<"; then
  echo "STATE_POINTER: MISSING_OR_PLACEHOLDER"
  exit 1
fi
echo "STATE_POINTER: $POINTER_LINE"

# === Git Status ===
echo ""
echo "GIT_BRANCH: $(git branch --show-current 2>/dev/null || echo 'unknown')"
PORCELAIN=$(git status --porcelain 2>/dev/null)
if [ -z "$PORCELAIN" ]; then
  echo "GIT_STATUS: Clean"
else
  echo "GIT_STATUS: $(echo "$PORCELAIN" | wc -l | tr -d ' ') uncommitted changes"
fi

# === AI-OPS Documents (presence only) ===
echo ""
[ -f ".planning/AI-OPS.md" ] && echo "AI_OPS_MD: Present - READ REQUIRED" || echo "AI_OPS_MD: Missing"
[ -f ".planning/AI-OPS-KNOWLEDGE.md" ] && echo "AI_OPS_KNOWLEDGE_MD: Present" || echo "AI_OPS_KNOWLEDGE_MD: Missing"

# === .continue-here.md violation check ===
if [ -f ".planning/.continue-here.md" ]; then
  echo ""
  echo "CONTINUE_HERE_VIOLATION: File exists but is not part of contract"
fi
```

## Interpretation

### If `CLEO_BINARY: NOT_FOUND`

```
=== HARNESS STATUS - BLOCKED ===

CLEO binary not found.

CLEO is mandatory for STEW routing.

Install CLEO: See https://github.com/kryptobaseddev/cleo
```

### If `CLEO_INIT: NOT_INITIALIZED`

```
=== HARNESS STATUS - BLOCKED ===

CLEO not initialized for this project.

Project Key: [PROJECT_KEY]
CLEO State Dir: [CLEO_STATE_DIR]

Run: h:init

This will automatically initialize CLEO, set focus, and normalize STATE.md.
```

### If `CLEO_FOCUS: NO_FOCUS`

```
=== HARNESS STATUS - BLOCKED ===

No CLEO focus set.

CLEO focus is mandatory for STEW routing.

Run: h:init

This will automatically create a task and set focus.
```

### If `STATE_MD: MISSING`

```
=== HARNESS STATUS - BLOCKED ===

Missing .planning/STATE.md

Create it with this minimal template:

Current Work:
  Pointer: <path to current plan doc or phase directory>
  Status: <one-line status>

Next Action:
  <one-line next step>
```

### If `STATE_POINTER: MISSING_OR_PLACEHOLDER`

```
=== HARNESS STATUS - BLOCKED ===

STATE.md Pointer is missing or contains placeholder.

Run: h:init

This will attempt to derive Pointer from legacy STATE.md formats.
If derivation fails, manual edit of .planning/STATE.md is required.
```

### If `CONTINUE_HERE_VIOLATION`

Include this warning in output:

```
WARNING: .planning/.continue-here.md exists but is deprecated.
This file is not part of the STEW contract. Delete it:
  rm .planning/.continue-here.md
```

## Output Format (All Gates Pass)

```
=== HARNESS STATUS ===

CLEO (mandatory):
  Project Key: [PROJECT_KEY]
  State Dir: [CLEO_STATE_DIR]
  Focus: [FOCUS_ID] - [FOCUS_TITLE] ([FOCUS_STATUS])

Planning Contract:
  STATE.md: Present
  Pointer: [extracted path from STATE.md]

Git Status: [Clean] or [Uncommitted changes: X files]
Branch: [branch-name]

AI-OPS Documents:
  - AI-OPS.md: [Present - READ REQUIRED] or [Missing]

=== RECOMMENDED NEXT COMMAND ===
h:focus to see current work pointer, or h:route to proceed
```

## Recommendation Logic

1. If any gate fails: show specific block message (do NOT proceed)
2. If AI-OPS.md present: remind user it must be read before work
3. If all gates pass: recommend `h:focus` or `h:route`

## Important

- This is READ-ONLY. Do not modify any files.
- CLEO is MANDATORY. No routing without CLEO focus.
- STATE.md Pointer is the work location. CLEO focus is the active task.
- If .continue-here.md exists, warn user to delete it (deprecated).

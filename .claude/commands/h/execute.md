---
name: h:execute
description: Dispatch to GSD with explicit approval gate - 2-step handshake required
allowed-tools: Bash, Read, Skill
---

<!-- FENCE CHECK: If output appears garbled, verify this file has balanced markdown fences. -->
<!-- Single bash block rule enforced. -->

# Harness Execute Command

**This is the GSD dispatch entrypoint.** It verifies all gates, proposes an execution, and requires explicit approval before invoking GSD.

**STEW is the only user-facing entrypoint. GSD is an internal executor.**

---

## Two-Step Handshake

This command requires a two-step interaction:

1. **Step 1 (Proposal):** Run `/h:execute` - outputs proposed execution and asks for approval
2. **Step 2 (Execution):** User replies exactly `APPROVE`, then runs `/h:execute` again - executes the GSD skill

This prevents silent execution and ensures explicit user consent.

---

## Run: Preflight Check

Execute this single Bash block to verify all prerequisites:

```bash
# === CLEO Auto-Discovery (MANDATORY) ===
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
TODO_FILE="$CLEO_STATE_DIR/.cleo/todo.json"
if [ ! -f "$TODO_FILE" ]; then
  echo "CLEO_INIT: NOT_INITIALIZED"
  exit 1
fi
echo "CLEO_INIT: OK"

# === Gate 2: CLEO Focus ===
IFS=$'\t' read -r FOCUS_ID FOCUS_TITLE < <(python3 - "$TODO_FILE" <<'PYEOF'
import sys, json
todo_file = sys.argv[1]
try:
    with open(todo_file) as f:
        d = json.load(f)
except:
    print("\t")
    sys.exit(0)
focus = d.get("focus") or {}
focus_id = focus.get("currentTask") or focus.get("focusedTaskId") or ""
focus_title = ""
if focus_id:
    for task in d.get("tasks", []):
        if task.get("id") == focus_id:
            focus_title = task.get("title", "").replace('\t', ' ').replace('\n', ' ')
            break
print(f"{focus_id}\t{focus_title}")
PYEOF
)

if [ -z "$FOCUS_ID" ]; then
  echo "CLEO_FOCUS: NO_FOCUS"
  exit 1
fi
echo "CLEO_FOCUS: $FOCUS_ID - $FOCUS_TITLE"

# === Gate 3: STATE.md ===
if [ ! -f ".planning/STATE.md" ]; then
  echo "STATE_MD: MISSING"
  exit 1
fi
echo "STATE_MD: OK"

# === Gate 4: STATE.md Pointer ===
POINTER=$(grep -E "^\s*Pointer:" .planning/STATE.md 2>/dev/null | head -1 | sed 's/^[[:space:]]*Pointer:[[:space:]]*//')
if [ -z "$POINTER" ] || echo "$POINTER" | grep -q "^<"; then
  echo "STATE_POINTER: MISSING_OR_PLACEHOLDER"
  exit 1
fi
echo "STATE_POINTER: $POINTER"

# === Gate 5: Resolve PLAN_FILE ===
PHASE_DIR=""
PLAN_FILE=""

# If pointer is a directory, that's the phase dir
if [ -d "$POINTER" ]; then
  PHASE_DIR="$POINTER"
elif [ -f "$POINTER" ]; then
  PHASE_DIR=$(dirname "$POINTER")
fi

# Find plan file
if [ -n "$PHASE_DIR" ] && [ -d "$PHASE_DIR" ]; then
  if [ -f "$PHASE_DIR/PLAN.md" ]; then
    PLAN_FILE="$PHASE_DIR/PLAN.md"
  else
    PLAN_FILE=$(ls "$PHASE_DIR"/*-PLAN.md 2>/dev/null | sort | head -1)
  fi
fi

# If pointer is itself a plan file
if [ -z "$PLAN_FILE" ] && [ -f "$POINTER" ] && echo "$POINTER" | grep -qE 'PLAN\.md$'; then
  PLAN_FILE="$POINTER"
fi

if [ -z "$PLAN_FILE" ] || [ ! -f "$PLAN_FILE" ]; then
  echo "PLAN_FILE: NONE"
  exit 1
fi
echo "PLAN_FILE: $PLAN_FILE"

# === Gate 6: Classification (must exist) ===
if [ ! -f ".planning/HARNESS_STATE.json" ]; then
  echo "CLASSIFICATION: MISSING"
  echo "HARNESS_STATE_JSON: NOT_FOUND"
  exit 1
fi

python3 << 'PYEOF'
import json, sys
try:
    with open('.planning/HARNESS_STATE.json', 'r') as f:
        state = json.load(f)
    c = state.get('classification', {})
    if not c:
        print("CLASSIFICATION: NONE")
        sys.exit(1)
    print(f"CLASS_TYPE: {c.get('type', 'unknown')}")
    print(f"CLASS_SCOPE: {c.get('scope', 'unknown')}")
    print(f"CLASS_AUTOMATION: {c.get('automation_fit', 'unknown')}")
except Exception as e:
    print(f"CLASSIFICATION: ERROR - {e}")
    sys.exit(1)
PYEOF

# === Extract Phase Number (if path matches pattern) ===
# Pattern: .planning/phases/<NN-...>/PLAN.md or .planning/phases/<NN-...>/<anything>.md
PHASE_NUM=""
if echo "$PLAN_FILE" | grep -qE '\.planning/phases/[0-9]+-'; then
  PHASE_NUM=$(echo "$PLAN_FILE" | sed -n 's|.*\.planning/phases/\([0-9]\+\)-.*|\1|p')
fi
[ -n "$PHASE_NUM" ] && echo "PHASE_NUM: $PHASE_NUM" || echo "PHASE_NUM: NONE"

# === .continue-here.md violation check ===
if [ -f ".planning/.continue-here.md" ]; then
  echo ""
  echo "CONTINUE_HERE_VIOLATION: YES"
fi

echo ""
echo "=== PREFLIGHT COMPLETE ==="
```

## Interpretation

### If any gate fails

Show the specific block message and stop. Do NOT proceed to proposal.

**If `CLEO_BINARY: NOT_FOUND`:**
```
=== HARNESS EXECUTE - BLOCKED ===

CLEO binary not found.

Install CLEO: See https://github.com/kryptobaseddev/cleo
```

**If `CLEO_INIT: NOT_INITIALIZED`:**
```
=== HARNESS EXECUTE - BLOCKED ===

CLEO not initialized for this project.

Run: h:init
```

**If `CLEO_FOCUS: NO_FOCUS`:**
```
=== HARNESS EXECUTE - BLOCKED ===

No CLEO focus set.

Run: h:init
```

**If `STATE_MD: MISSING` or `STATE_POINTER: MISSING_OR_PLACEHOLDER`:**
```
=== HARNESS EXECUTE - BLOCKED ===

STATE.md missing or Pointer invalid.

Run: h:init
```

**If `PLAN_FILE: NONE`:**
```
=== HARNESS EXECUTE - BLOCKED ===

No plan file found.

Create a plan document first:
- Use gsd:plan-phase to create a plan
- Or manually create PLAN.md in the phase directory

Then run h:route to classify the work.
```

**If `CLASSIFICATION: MISSING` or `CLASSIFICATION: NONE`:**
```
=== HARNESS EXECUTE - BLOCKED ===

No classification found.

Run: h:route

This will classify the work and persist the result.
Then run h:execute again.
```

**If `CONTINUE_HERE_VIOLATION: YES`:**
Include this warning (do not block):
```
WARNING: .planning/.continue-here.md exists but is deprecated.
Delete it: rm .planning/.continue-here.md
```

---

## Step 1: Generate Proposal

If all gates pass, generate the execution proposal.

### If PHASE_NUM exists

```
=== PROPOSED EXECUTION ===

CLEO Focus: [FOCUS_ID] - [FOCUS_TITLE]
Plan File: [PLAN_FILE]
Phase Number: [PHASE_NUM]

Proposed Command: gsd:execute-plan [PHASE_NUM]

This will execute the plan for phase [PHASE_NUM].

=== APPROVAL REQUIRED ===

Reply exactly: APPROVE

Then run h:execute again to proceed.
```

### If PHASE_NUM is NONE (no numeric phase pattern)

```
=== PROPOSED EXECUTION - BLOCKED ===

CLEO Focus: [FOCUS_ID] - [FOCUS_TITLE]
Plan File: [PLAN_FILE]
Phase Number: Not detectable (path does not match .planning/phases/NN-*/...)

The plan file path does not follow the standard phase numbering convention.

STEW cannot automatically dispatch to GSD without a phase number.

=== MANUAL EXECUTION REQUIRED ===

Run the GSD command manually:
  gsd:execute-plan (and specify the plan file location when prompted)

Or restructure the plan directory to follow the convention:
  .planning/phases/01-setup/PLAN.md
  .planning/phases/02-core/PLAN.md
  etc.
```

Stop. Do NOT offer to execute anything.

---

## Step 2: Check for Approval and Execute

After generating a proposal in Step 1, the user must reply with exactly `APPROVE`.

When interpreting this command:

1. Check if the user's immediately previous message is exactly `APPROVE` (case-sensitive, trimmed)
2. If YES and PHASE_NUM exists: Invoke the GSD skill via Skill tool
3. If NO: Show the proposal again (Step 1)

### Execution (only after APPROVE)

If the user's previous message was exactly `APPROVE` and PHASE_NUM exists:

```
=== EXECUTING ===

Invoking: gsd:execute-plan [PHASE_NUM]
```

Then invoke the Skill tool:
```
Skill: gsd:execute-plan
Args: [PHASE_NUM]
```

### If APPROVE received but PHASE_NUM is NONE

```
=== EXECUTION - BLOCKED ===

Cannot execute: No phase number detected.

Manual execution required. See proposal above.
```

Do NOT invoke any skill.

---

## Rules

1. **Never execute GSD without explicit APPROVE** - the 2-step handshake is mandatory
2. **CLEO focus is MANDATORY** - hard-fail without it
3. **STATE.md Pointer is REQUIRED** - hard-fail without it
4. **Classification must exist** - if missing, point to h:route (never auto-classify here)
5. **Phase number required for dispatch** - if path doesn't match pattern, block and explain
6. **Single bash block** - all preflight in one execution
7. **If .continue-here.md exists** - warn but do not block

---

## Summary

```
h:route → h:execute (proposal) → user: APPROVE → h:execute (execution) → GSD
```

STEW is the interface. GSD is the executor. The handshake ensures nothing runs silently.

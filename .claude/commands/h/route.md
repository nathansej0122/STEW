---
name: h:route
description: Coordination router - determine next action based on CLEO focus and STATE.md Pointer
allowed-tools: Bash, Skill
---

<!-- FENCE CHECK: If output appears garbled, verify this file has balanced markdown fences. -->
<!-- Each "Run:" section must contain exactly ONE fenced bash block. -->

# Harness Route Command

Coordination router. Reads state, recommends actions. **Never executes GSD. Never re-reasons. Uses persisted classification only.**

**CLEO focus is MANDATORY. STATE.md Pointer is REQUIRED.**

---

## Run: Consolidated State Check

Execute this single Bash block to gather all routing state:

```bash
# === CLEO Auto-Discovery (MANDATORY) ===
REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
if [ -n "$REMOTE_URL" ]; then
  PROJECT_KEY=$(basename "$REMOTE_URL" .git)
else
  PROJECT_KEY=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
fi
CLEO_STATE_DIR="$HOME/.cleo/projects/$PROJECT_KEY"

# === Gate 0: CLEO Focus (MANDATORY) ===
if command -v cleo >/dev/null 2>&1; then
  CLEO_CMD="cleo"
elif [ -n "${CLEO_BIN:-}" ] && [ -x "$CLEO_BIN" ]; then
  CLEO_CMD="$CLEO_BIN"
else
  echo "CLEO_BINARY: NOT_FOUND"
  exit 1
fi

if [ ! -f "$CLEO_STATE_DIR/.cleo/todo.json" ]; then
  echo "CLEO_INIT: NOT_INITIALIZED"
  echo "CLEO_STATE_DIR: $CLEO_STATE_DIR"
  exit 1
fi

CLEO_FOCUS=$( (cd "$CLEO_STATE_DIR" && "$CLEO_CMD" focus show --format json 2>/dev/null) || echo '{}')
FOCUS_ID=$(echo "$CLEO_FOCUS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('task',{}).get('id',''))" 2>/dev/null || true)
FOCUS_TITLE=$(echo "$CLEO_FOCUS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('task',{}).get('title',''))" 2>/dev/null || true)

if [ -z "$FOCUS_ID" ]; then
  echo "CLEO_FOCUS: NO_FOCUS"
  echo "CLEO_STATE_DIR: $CLEO_STATE_DIR"
  exit 1
fi
echo "CLEO_FOCUS: $FOCUS_ID - $FOCUS_TITLE"

# === Gate 1: STATE.md and Pointer ===
if [ ! -f ".planning/STATE.md" ]; then
  echo "STATE_MD: MISSING"
  exit 1
fi

POINTER=$(grep -E "^\s*Pointer:" .planning/STATE.md 2>/dev/null | head -1 | sed 's/^[[:space:]]*Pointer:[[:space:]]*//')
if [ -z "$POINTER" ] || echo "$POINTER" | grep -q "^<"; then
  echo "STATE_POINTER: MISSING_OR_PLACEHOLDER"
  exit 1
fi
echo "STATE_POINTER: $POINTER"

# === Gate 2: AI-OPS ===
[ -f ".planning/AI-OPS.md" ] && echo "AI_OPS: Present - READ REQUIRED" || echo "AI_OPS: Missing"

# === Gate 3: Phase/Plan Detection ===
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

[ -n "$PHASE_DIR" ] && echo "PHASE_DIR: $PHASE_DIR" || echo "PHASE_DIR: N/A"
[ -n "$PLAN_FILE" ] && echo "PLAN_FILE: $PLAN_FILE" || echo "PLAN_FILE: NONE"

# === Classification (from persisted state) ===
if [ -f ".planning/HARNESS_STATE.json" ]; then
  python3 << 'PYEOF'
import json
try:
    with open('.planning/HARNESS_STATE.json', 'r') as f:
        state = json.load(f)
    c = state.get('classification', {})
    if c:
        print(f"CLASS_TYPE: {c.get('type', 'unknown')}")
        print(f"CLASS_SCOPE: {c.get('scope', 'unknown')}")
        print(f"CLASS_AUTOMATION: {c.get('automation_fit', 'unknown')}")
        print(f"CLASS_ECC: {c.get('ecc', 'unknown')}")
        print(f"CLASS_SOURCE: {c.get('source', 'unknown')}")
    else:
        print("CLASSIFICATION: NONE")
except:
    print("CLASSIFICATION: NONE")
PYEOF
else
  echo "CLASSIFICATION: NONE"
fi

# === .continue-here.md violation check ===
if [ -f ".planning/.continue-here.md" ]; then
  echo ""
  echo "CONTINUE_HERE_VIOLATION: YES"
fi
```

## Interpretation

**If `CLEO_BINARY: NOT_FOUND`** - Show block message and stop:

```
=== HARNESS ROUTE - BLOCKED ===

CLEO binary not found.

CLEO is mandatory for STEW routing.

Install CLEO: See https://github.com/kryptobaseddev/cleo
```

**If `CLEO_INIT: NOT_INITIALIZED`** - Show block message and stop:

```
=== HARNESS ROUTE - BLOCKED ===

CLEO not initialized for this project.

CLEO State Dir: [CLEO_STATE_DIR]

Run: h:cleo-init

This will automatically initialize CLEO and set focus.
```

**If `CLEO_FOCUS: NO_FOCUS`** - Show block message and stop:

```
=== HARNESS ROUTE - BLOCKED ===

No CLEO focus set.

CLEO focus is mandatory for STEW routing.

Run: h:cleo-init

This will automatically create a task and set focus.
```

**If `STATE_MD: MISSING`** - Show block message and stop:

```
=== HARNESS ROUTE - BLOCKED ===

Missing .planning/STATE.md

Create it with this template:

Current Work:
  Pointer: <path to current plan doc or phase directory>
  Status: <one-line status>

Next Action:
  <one-line next step>
```

**If `STATE_POINTER: MISSING_OR_PLACEHOLDER`** - Show block message and stop:

```
=== HARNESS ROUTE - BLOCKED ===

STATE.md Pointer is missing or contains placeholder.

Edit .planning/STATE.md and set the Pointer line to a real path.
```

**If `AI_OPS: Present`** - Remind user it must be read before work (do NOT block).

**If `PLAN_FILE: NONE`** - No plan exists, recommend creating one.

**If `CLASSIFICATION: NONE`** - Call `h:_classify` via Skill tool to populate classification.

**If `CONTINUE_HERE_VIOLATION: YES`** - Warn user to delete deprecated file.

---

## Output Generation

Build output strictly from parsed values. No narrative reasoning.

### Header (always shown)

```
=== HARNESS ROUTE ===

CLEO Focus (mandatory): [FOCUS_ID] - [FOCUS_TITLE]
STATE.md Pointer: [POINTER]
AI-OPS: [Present - READ REQUIRED] or [Not present]
Phase: [PHASE_DIR value or "N/A"]
Plan: [Yes/No] [PLAN_FILE path if yes]
```

### If .continue-here.md exists

```
WARNING: .planning/.continue-here.md exists but is deprecated.
Delete it: rm .planning/.continue-here.md
```

### If no plan

```
=== RECOMMENDATION ===
No plan file found. Create a plan document in the phase directory.
Recommend: Create PLAN.md or use gsd:plan-phase
```

Stop.

### If plan exists (show classification and recommendations)

```
=== WORK CLASSIFICATION ===
Type: [TYPE value]
Scope: [SCOPE value]
Automation: [AUTOMATION_FIT value]
ECC: [ECC value]
Source: [SOURCE value]

=== RECOMMENDATION ===
Recommend: Execute the plan (gsd:execute-phase or manual execution)
```

### Automation Section (conditional on AUTOMATION_FIT)

**If AUTOMATION_FIT = forbidden:**
Do not print automation section. RALPH commands are invisible.

**If AUTOMATION_FIT = discouraged:**
```
=== AUTOMATION ===
RALPH: Available with caution
  h:ralph-init [slug] (if bounded subtask identified)
```

**If AUTOMATION_FIT = allowed:**
```
=== AUTOMATION ===
RALPH: Recommended
  h:ralph-init [slug]
  h:ralph-run (after bundle created)
```

### ECC Section (conditional on ECC)

**If ECC = suggested:**
```
=== ECC ===
Recommend: h:ecc-security-review or h:ecc-code-review
```

**If ECC = optional:**
```
=== ECC ===
Optional: h:ecc-code-review
```

**If ECC = unnecessary:**
Do not print ECC section.

---

## Rules

1. Never execute GSD commands
2. CLEO focus is MANDATORY; STATE.md Pointer is REQUIRED
3. Never classify inline - always call h:_classify and read persisted result
4. Never explain classification logic
5. If automation_fit=forbidden, RALPH commands are invisible (omit automation section entirely)
6. If ecc=unnecessary, omit ECC section entirely
7. Output values only - no narrative interpretation
8. If .continue-here.md exists, warn user to delete it (deprecated)

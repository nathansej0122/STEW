---
name: h:init
description: One-command bootstrap for CLEO + STATE.md coordination stack
allowed-tools: Bash, Read
---

<!-- FENCE CHECK: If output appears garbled, verify this file has balanced markdown fences. -->
<!-- Single bash block rule enforced. -->

# Harness Initialization

**This is the canonical first step.** Run `h:init` when any harness command blocks.

This command:
1. Initializes CLEO for the current repository (if needed)
2. Sets CLEO focus (if needed)
3. Normalizes STATE.md Pointer (if needed)

**No flags required. Fully automatic. Idempotent.**

## Run: Initialize Coordination Stack

Execute this single Bash block:

```bash
# ============================================================
# PHASE 1: CLEO INITIALIZATION (from h:cleo-init)
# ============================================================

# === CLEO Auto-Discovery ===
REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
if [ -n "$REMOTE_URL" ]; then
  PROJECT_KEY=$(basename "$REMOTE_URL" .git)
else
  PROJECT_KEY=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
fi
CLEO_STATE_DIR="$HOME/.cleo/projects/$PROJECT_KEY"
echo "PROJECT_KEY: $PROJECT_KEY"
echo "CLEO_STATE_DIR: $CLEO_STATE_DIR"

# === Resolve CLEO Binary ===
CLEO_CMD=""
if command -v cleo >/dev/null 2>&1; then
  CLEO_CMD="cleo"
elif [ -n "${CLEO_BIN:-}" ] && [ -x "$CLEO_BIN" ]; then
  CLEO_CMD="$CLEO_BIN"
else
  echo ""
  echo "CLEO_BINARY: NOT_FOUND"
  echo ""
  echo "INIT_CLEO: Blocked"
  echo "INIT_FOCUS: Blocked"
  echo "INIT_STATE_POINTER: Blocked"
  echo ""
  echo "CLEO binary not found on PATH and CLEO_BIN not set."
  echo "Install CLEO: See https://github.com/kryptobaseddev/cleo"
  exit 1
fi

# === Ensure CLEO State Directory Exists ===
mkdir -p "$CLEO_STATE_DIR"

# === Initialize CLEO if Needed ===
if [ ! -f "$CLEO_STATE_DIR/.cleo/todo.json" ]; then
  echo ""
  echo "Initializing CLEO in $CLEO_STATE_DIR..."
  (cd "$CLEO_STATE_DIR" && "$CLEO_CMD" init)
  INIT_CLEO="Initialized"
else
  INIT_CLEO="Already initialized"
fi

# === Ensure Focus is Set (read directly from todo.json) ===
TODO_FILE="$CLEO_STATE_DIR/.cleo/todo.json"
FOCUS_ID=$(python3 - "$TODO_FILE" <<'PYEOF'
import sys, json
todo_file = sys.argv[1]
try:
    with open(todo_file) as f:
        d = json.load(f)
except:
    print("")
    sys.exit(0)
focus = d.get("focus") or {}
print(focus.get("currentTask") or focus.get("focusedTaskId") or "")
PYEOF
)

if [ -z "$FOCUS_ID" ]; then
  # Need to create a task and set focus
  TASK_TITLE="Work on $PROJECT_KEY"

  # Try to derive better title from STATE.md pointer if present
  if [ -f ".planning/STATE.md" ]; then
    POINTER=$(grep -E "^\s*Pointer:" .planning/STATE.md 2>/dev/null | head -1 | sed 's/^[[:space:]]*Pointer:[[:space:]]*//')
    if [ -n "$POINTER" ] && ! echo "$POINTER" | grep -q "^<"; then
      POINTER_BASE=$(basename "$POINTER" .md 2>/dev/null || true)
      if [ -n "$POINTER_BASE" ]; then
        TASK_TITLE="Work on $PROJECT_KEY: $POINTER_BASE"
      fi
    fi
  fi

  echo ""
  echo "Creating initial task: $TASK_TITLE"
  ADD_OUTPUT=$( (cd "$CLEO_STATE_DIR" && "$CLEO_CMD" add "$TASK_TITLE" 2>&1) || true)

  # Get the first task ID from the list
  TASK_LIST=$( (cd "$CLEO_STATE_DIR" && "$CLEO_CMD" list --format json 2>/dev/null) || echo '{"tasks":[]}')
  FIRST_TASK_ID=$(echo "$TASK_LIST" | python3 -c "import sys,json; d=json.load(sys.stdin); tasks=d.get('tasks',[]); print(tasks[0].get('id','') if tasks else '')" 2>/dev/null || true)

  if [ -n "$FIRST_TASK_ID" ]; then
    echo "Setting focus to $FIRST_TASK_ID..."
    (cd "$CLEO_STATE_DIR" && "$CLEO_CMD" focus set "$FIRST_TASK_ID")
    INIT_FOCUS="Set"
    FOCUS_ID="$FIRST_TASK_ID"
  else
    echo "WARNING: Could not determine task ID after creation"
    INIT_FOCUS="Not set (manual intervention needed)"
  fi
else
  INIT_FOCUS="Already set"
fi

# Get final focus info (read directly from todo.json)
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

echo ""
echo "INIT_CLEO: $INIT_CLEO"
echo "INIT_FOCUS: $INIT_FOCUS"
echo "CLEO_FOCUS: $FOCUS_ID - $FOCUS_TITLE"

# ============================================================
# PHASE 2: STATE.MD NORMALIZATION (from h:state-normalize)
# ============================================================

echo ""
echo "--- STATE.md Normalization ---"

# === Gate: STATE.md must exist ===
if [ ! -f ".planning/STATE.md" ]; then
  echo "STATE_MD: MISSING"
  echo "INIT_STATE_POINTER: Skipped (no STATE.md)"
  echo ""
  echo "WARNING: .planning/STATE.md does not exist."
  echo "Create it with this template:"
  echo ""
  echo "Current Work:"
  echo "  Pointer: <path to PLAN.md or phase directory>"
  echo "  Status: <one-line status>"
  echo ""
  echo "Then rerun h:init or h:state-normalize."
  echo ""
  echo "=== PARTIAL INIT COMPLETE ==="
  echo "INIT_CLEO: $INIT_CLEO"
  echo "INIT_FOCUS: $INIT_FOCUS"
  echo "INIT_STATE_POINTER: Skipped"
  echo "NEXT: Create .planning/STATE.md, then run h:status"
  exit 0
fi

# === Check for existing valid Pointer ===
EXISTING_POINTER=$(grep -E "^\s*Pointer:" .planning/STATE.md 2>/dev/null | head -1 | sed 's/^[[:space:]]*Pointer:[[:space:]]*//')
EXISTING_POINTER=$(echo "$EXISTING_POINTER" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$EXISTING_POINTER" ] && ! echo "$EXISTING_POINTER" | grep -qE '^<.*>$'; then
  echo "STATE_POINTER: $EXISTING_POINTER (already valid)"
  INIT_STATE_POINTER="Already compliant"
else
  # === Migration: Derive Pointer from legacy formats ===
  DERIVED_POINTER=""
  DERIVATION_SOURCE=""

  # Priority a) Resume file: line
  RESUME_FILE=$(grep -E "^\s*Resume\s+file:" .planning/STATE.md 2>/dev/null | head -1 | sed 's/^[[:space:]]*Resume[[:space:]]*file:[[:space:]]*//')
  RESUME_FILE=$(echo "$RESUME_FILE" | sed 's/`//g; s/"//g; s/'"'"'//g; s/^[[:space:]]*//; s/[[:space:]]*$//')

  if [ -n "$RESUME_FILE" ]; then
    DERIVATION_SOURCE="Resume file"

    if echo "$RESUME_FILE" | grep -qE '\.continue-here\.md$'; then
      DIR=$(dirname "$RESUME_FILE")
    else
      if [ -f "$RESUME_FILE" ] && echo "$RESUME_FILE" | grep -qE 'PLAN\.md$'; then
        DERIVED_POINTER="$RESUME_FILE"
      else
        DIR=$(dirname "$RESUME_FILE")
      fi
    fi

    if [ -z "$DERIVED_POINTER" ] && [ -n "$DIR" ] && [ -d "$DIR" ]; then
      if [ -f "$DIR/PLAN.md" ]; then
        DERIVED_POINTER="$DIR/PLAN.md"
      else
        FIRST_PLAN=$(ls "$DIR"/*-PLAN.md 2>/dev/null | sort | head -1)
        if [ -n "$FIRST_PLAN" ]; then
          DERIVED_POINTER="$FIRST_PLAN"
        fi
      fi
    fi
  fi

  # Priority b) Phase Directory: line
  if [ -z "$DERIVED_POINTER" ]; then
    PHASE_DIR=$(grep -E "^\s*Phase\s+Directory:" .planning/STATE.md 2>/dev/null | head -1 | sed 's/^[[:space:]]*Phase[[:space:]]*Directory:[[:space:]]*//')
    PHASE_DIR=$(echo "$PHASE_DIR" | sed 's/`//g; s/"//g; s/'"'"'//g; s/^[[:space:]]*//; s/[[:space:]]*$//')

    if [ -n "$PHASE_DIR" ] && [ -d "$PHASE_DIR" ]; then
      DERIVATION_SOURCE="Phase Directory"
      if [ -f "$PHASE_DIR/PLAN.md" ]; then
        DERIVED_POINTER="$PHASE_DIR/PLAN.md"
      else
        FIRST_PLAN=$(ls "$PHASE_DIR"/*-PLAN.md 2>/dev/null | sort | head -1)
        if [ -n "$FIRST_PLAN" ]; then
          DERIVED_POINTER="$FIRST_PLAN"
        fi
      fi
    fi
  fi

  # Priority c) Current Phase: line
  if [ -z "$DERIVED_POINTER" ]; then
    CURRENT_PHASE=$(grep -E "^\s*Current\s+Phase:" .planning/STATE.md 2>/dev/null | head -1 | sed 's/^[[:space:]]*Current[[:space:]]*Phase:[[:space:]]*//')
    CURRENT_PHASE=$(echo "$CURRENT_PHASE" | sed 's/`//g; s/"//g; s/'"'"'//g; s/^[[:space:]]*//; s/[[:space:]]*$//')

    if [ -n "$CURRENT_PHASE" ]; then
      DERIVATION_SOURCE="Current Phase"
      for CANDIDATE_DIR in ".planning/phases/$CURRENT_PHASE" ".planning/$CURRENT_PHASE"; do
        if [ -d "$CANDIDATE_DIR" ]; then
          if [ -f "$CANDIDATE_DIR/PLAN.md" ]; then
            DERIVED_POINTER="$CANDIDATE_DIR/PLAN.md"
            break
          else
            FIRST_PLAN=$(ls "$CANDIDATE_DIR"/*-PLAN.md 2>/dev/null | sort | head -1)
            if [ -n "$FIRST_PLAN" ]; then
              DERIVED_POINTER="$FIRST_PLAN"
              break
            fi
          fi
        fi
      done
    fi
  fi

  # === Check if derivation succeeded ===
  if [ -z "$DERIVED_POINTER" ]; then
    echo "DERIVATION_SOURCE: ${DERIVATION_SOURCE:-None found}"
    echo "DERIVED_POINTER: (unable to derive)"
    INIT_STATE_POINTER="Manual fix required"
    echo ""
    echo "WARNING: Could not derive Pointer from STATE.md content."
    echo "Edit .planning/STATE.md and add a Pointer line manually."
  else
    echo "DERIVATION_SOURCE: $DERIVATION_SOURCE"
    echo "DERIVED_POINTER: $DERIVED_POINTER"

    # === Update STATE.md (idempotent) ===
    if grep -qE "^\s*Current\s+Work:" .planning/STATE.md; then
      if grep -qE "^\s*Pointer:" .planning/STATE.md; then
        sed -i "s|^\([[:space:]]*\)Pointer:.*|\1Pointer: $DERIVED_POINTER|" .planning/STATE.md
        INIT_STATE_POINTER="Updated (replaced)"
      else
        sed -i "/^\s*Current\s*Work:/a\\  Pointer: $DERIVED_POINTER" .planning/STATE.md
        INIT_STATE_POINTER="Updated (inserted)"
      fi
    else
      {
        echo "Current Work:"
        echo "  Pointer: $DERIVED_POINTER"
        echo ""
        cat .planning/STATE.md
      } > .planning/STATE.md.tmp && mv .planning/STATE.md.tmp .planning/STATE.md
      INIT_STATE_POINTER="Updated (prepended)"
    fi
  fi
fi

# ============================================================
# FINAL SUMMARY
# ============================================================

echo ""
echo "=== INIT COMPLETE ==="
echo "INIT_CLEO: $INIT_CLEO"
echo "INIT_FOCUS: $INIT_FOCUS"
echo "INIT_STATE_POINTER: $INIT_STATE_POINTER"
echo "NEXT: Run h:status"
```

## Output Format

### Success (All Steps Complete)

```
PROJECT_KEY: my-app
CLEO_STATE_DIR: ~/.cleo/projects/my-app

INIT_CLEO: Already initialized
INIT_FOCUS: Already set
CLEO_FOCUS: T001 - Work on my-app

--- STATE.md Normalization ---
STATE_POINTER: .planning/phases/phase-1/PLAN.md (already valid)

=== INIT COMPLETE ===
INIT_CLEO: Already initialized
INIT_FOCUS: Already set
INIT_STATE_POINTER: Already compliant
NEXT: Run h:status
```

### Success (First-Time Setup)

```
PROJECT_KEY: my-app
CLEO_STATE_DIR: ~/.cleo/projects/my-app

Initializing CLEO in ~/.cleo/projects/my-app...
Creating initial task: Work on my-app
Setting focus to T001...

INIT_CLEO: Initialized
INIT_FOCUS: Set
CLEO_FOCUS: T001 - Work on my-app

--- STATE.md Normalization ---
DERIVATION_SOURCE: Resume file
DERIVED_POINTER: .planning/phases/phase-1/PLAN.md

=== INIT COMPLETE ===
INIT_CLEO: Initialized
INIT_FOCUS: Set
INIT_STATE_POINTER: Updated (inserted)
NEXT: Run h:status
```

### Partial Success (No STATE.md)

```
PROJECT_KEY: my-app
...
INIT_CLEO: Initialized
INIT_FOCUS: Set
...
--- STATE.md Normalization ---
STATE_MD: MISSING
INIT_STATE_POINTER: Skipped (no STATE.md)

WARNING: .planning/STATE.md does not exist.
...
=== PARTIAL INIT COMPLETE ===
INIT_CLEO: Initialized
INIT_FOCUS: Set
INIT_STATE_POINTER: Skipped
NEXT: Create .planning/STATE.md, then run h:status
```

## Interpretation

After successful execution, report to user:

```
=== HARNESS INITIALIZED ===

Project Key: [PROJECT_KEY]
State Directory: [CLEO_STATE_DIR]

CLEO: [Initialized / Already initialized]
Focus: [Set / Already set] - [FOCUS_ID] - [FOCUS_TITLE]
STATE.md Pointer: [Updated / Already compliant / Manual fix required]

=== NEXT STEP ===
Run h:status to verify full coordination state.
```

## If CLEO Binary Not Found

Report to user:

```
=== HARNESS INIT - BLOCKED ===

CLEO binary not found.

Install CLEO: See https://github.com/kryptobaseddev/cleo

After installation, rerun: h:init
```

## Rules

1. **No flags required** - Everything is auto-discovered
2. **Idempotent** - Safe to run multiple times
3. **Single bash block** - All logic in one execution
4. **No .continue-here.md creation** - Only reads legacy references for migration
5. **Graceful degradation** - If STATE.md missing, CLEO still initializes

---
name: h:cleo-init
description: Initialize CLEO state for the current repository (auto-discovery, no flags)
allowed-tools: Bash
---

<!-- FENCE CHECK: If output appears garbled, verify this file has balanced markdown fences. -->
<!-- Single bash block rule enforced. -->

# CLEO Initialization

You are initializing CLEO state for the current repository. This command:
1. Auto-discovers PROJECT_KEY from git remote or repo basename
2. Creates CLEO state directory if needed
3. Initializes CLEO if needed
4. Creates an initial task and sets focus if needed

**No flags required. Fully automatic.**

## Run: Initialize CLEO

Execute this single Bash block:

```bash
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
  RESULT_INIT="Initialized"
else
  RESULT_INIT="Already initialized"
fi
echo "RESULT_INIT: $RESULT_INIT"

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
  # Derive task title from repo name + STATE.md pointer if present
  TASK_TITLE="Work on $PROJECT_KEY"
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

  # Try to add task and get the ID
  ADD_OUTPUT=$( (cd "$CLEO_STATE_DIR" && "$CLEO_CMD" add "$TASK_TITLE" 2>&1) || true)

  # Get the first task ID from the list
  TASK_LIST=$( (cd "$CLEO_STATE_DIR" && "$CLEO_CMD" list --format json 2>/dev/null) || echo '{"tasks":[]}')
  FIRST_TASK_ID=$(echo "$TASK_LIST" | python3 -c "import sys,json; d=json.load(sys.stdin); tasks=d.get('tasks',[]); print(tasks[0].get('id','') if tasks else '')" 2>/dev/null || true)

  if [ -n "$FIRST_TASK_ID" ]; then
    echo "Setting focus to $FIRST_TASK_ID..."
    (cd "$CLEO_STATE_DIR" && "$CLEO_CMD" focus set "$FIRST_TASK_ID")
    RESULT_FOCUS="Focus set"
    FOCUS_ID="$FIRST_TASK_ID"
  else
    echo "WARNING: Could not determine task ID after creation"
    RESULT_FOCUS="Focus not set (manual intervention needed)"
  fi
else
  RESULT_FOCUS="Focus already set"
fi
echo "RESULT_FOCUS: $RESULT_FOCUS"

# === Get Final Focus Info (read directly from todo.json) ===
read -r FOCUS_ID FOCUS_TITLE < <(python3 - "$TODO_FILE" <<'PYEOF'
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
            focus_title = task.get("title", "")
            break
print(f"{focus_id}\t{focus_title}")
PYEOF
)

echo ""
echo "=== CLEO INITIALIZED ==="
echo "FOCUS: $FOCUS_ID - $FOCUS_TITLE"
```

## Output Format (Success)

```
PROJECT_KEY: [derived key]
CLEO_STATE_DIR: [path]

RESULT_INIT: Initialized | Already initialized
RESULT_FOCUS: Focus set | Focus already set

=== CLEO INITIALIZED ===
FOCUS: [id] - [title]
```

## Interpretation

After successful execution, report to user:

```
=== CLEO INITIALIZED ===

Project Key: [PROJECT_KEY]
State Directory: [CLEO_STATE_DIR]

Initialization: [Initialized / Already initialized]
Focus: [Focus set / Focus already set]

Current Focus: [FOCUS_ID] - [FOCUS_TITLE]

=== NEXT STEP ===
Run h:status to verify full coordination state.
```

## If CLEO Binary Not Found

Report to user:

```
=== CLEO INIT - BLOCKED ===

CLEO binary not found.

Install CLEO: See https://github.com/kryptobaseddev/cleo

After installation, rerun: h:cleo-init
```

## Rules

1. **No flags required** - Everything is auto-discovered
2. **Idempotent** - Safe to run multiple times
3. **Single bash block** - All logic in one execution
4. **No .continue-here.md** - This command does not touch planning files

---
name: h:focus
description: Show current planning focus from CLEO and STATE.md Pointer
allowed-tools: Read, Grep, Glob, Bash
---

<!-- FENCE CHECK: If output appears garbled, verify this file has balanced markdown fences. -->
<!-- Each "Run:" section must contain exactly ONE fenced bash block. -->

# Harness Focus Management

You are displaying the **current focus** from CLEO (mandatory) and STATE.md Pointer (location).

**CLEO focus is mandatory. STATE.md Pointer provides the work location.**

## Run: Consolidated Focus Check

Execute this single Bash block to gather all focus information:

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

# === Gate 1: CLEO Initialized ===
if [ ! -f "$CLEO_STATE_DIR/.cleo/todo.json" ]; then
  echo "CLEO_INIT: NOT_INITIALIZED"
  exit 1
fi

# === Gate 2: CLEO Focus ===
CLEO_FOCUS=$( (cd "$CLEO_STATE_DIR" && "$CLEO_CMD" focus show --format json 2>/dev/null) || echo '{}')
FOCUS_ID=$(echo "$CLEO_FOCUS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('task',{}).get('id',''))" 2>/dev/null || true)
FOCUS_TITLE=$(echo "$CLEO_FOCUS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('task',{}).get('title',''))" 2>/dev/null || true)
FOCUS_STATUS=$(echo "$CLEO_FOCUS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('task',{}).get('status',''))" 2>/dev/null || true)
FOCUS_DESC=$(echo "$CLEO_FOCUS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('task',{}).get('description','')[:200] if d.get('task',{}).get('description') else '')" 2>/dev/null || true)

if [ -z "$FOCUS_ID" ]; then
  echo "CLEO_FOCUS: NO_FOCUS"
  exit 1
fi

echo ""
echo "=== CLEO FOCUS (MANDATORY) ==="
echo "Task ID: $FOCUS_ID"
echo "Title: $FOCUS_TITLE"
echo "Status: $FOCUS_STATUS"
[ -n "$FOCUS_DESC" ] && echo "Description: $FOCUS_DESC"

# === Gate 3: STATE.md ===
if [ ! -f ".planning/STATE.md" ]; then
  echo ""
  echo "STATE_MD: MISSING"
  exit 1
fi

# === Gate 4: STATE.md Pointer ===
POINTER_LINE=$(grep -E "^\s*Pointer:" .planning/STATE.md 2>/dev/null | head -1 | sed 's/^[[:space:]]*Pointer:[[:space:]]*//')
if [ -z "$POINTER_LINE" ] || echo "$POINTER_LINE" | grep -q "^<"; then
  echo ""
  echo "STATE_POINTER: MISSING_OR_PLACEHOLDER"
  exit 1
fi

echo ""
echo "=== STATE.MD POINTER (LOCATION) ==="
echo "Pointer: $POINTER_LINE"

# Check if pointer file/dir exists
if [ -f "$POINTER_LINE" ]; then
  echo "Pointer exists: YES (file)"
elif [ -d "$POINTER_LINE" ]; then
  echo "Pointer exists: YES (directory)"
else
  echo "Pointer exists: NO - file/directory not found"
fi

# === .continue-here.md violation check ===
if [ -f ".planning/.continue-here.md" ]; then
  echo ""
  echo "CONTINUE_HERE_VIOLATION: File exists but is deprecated"
fi
```

## Interpretation

### If `CLEO_BINARY: NOT_FOUND`

```
=== HARNESS FOCUS - BLOCKED ===

CLEO binary not found.

CLEO is mandatory for STEW routing.

Install CLEO: See https://github.com/kryptobaseddev/cleo
```

### If `CLEO_INIT: NOT_INITIALIZED`

```
=== HARNESS FOCUS - BLOCKED ===

CLEO not initialized for this project.

Project Key: [PROJECT_KEY]
CLEO State Dir: [CLEO_STATE_DIR]

Run: h:init

This will automatically initialize CLEO, set focus, and normalize STATE.md.
```

### If `CLEO_FOCUS: NO_FOCUS`

```
=== HARNESS FOCUS - BLOCKED ===

No CLEO focus set.

CLEO focus is mandatory for STEW routing.

Run: h:init

This will automatically create a task and set focus.
```

### If `STATE_MD: MISSING`

```
=== HARNESS FOCUS - BLOCKED ===

Missing .planning/STATE.md

Create it with this template:

Current Work:
  Pointer: <path to current plan doc or phase directory>
  Status: <one-line status>

Next Action:
  <one-line next step>
```

### If `STATE_POINTER: MISSING_OR_PLACEHOLDER`

```
=== HARNESS FOCUS - BLOCKED ===

STATE.md Pointer is missing or contains placeholder.

Run: h:init

This will attempt to derive Pointer from legacy STATE.md formats.
If derivation fails, manual edit of .planning/STATE.md is required.
```

### If Pointer File Missing (Warning Only)

If the pointer references a file that doesn't exist, include this warning:

```
WARNING: Pointer file does not exist: [path]

Either:
1. Create the referenced file/directory
2. Update STATE.md Pointer to an existing location
```

## Output Format (All Gates Pass)

```
=== HARNESS FOCUS ===

CLEO Focus (mandatory):
  Task: [FOCUS_ID] - [FOCUS_TITLE]
  Status: [FOCUS_STATUS]
  Description: [truncated description if present]

Work Location (from STATE.md):
  Pointer: [extracted path]
  Exists: [YES/NO]

=== RECOMMENDED FILE TO OPEN ===
[The path from Pointer - this is where work should resume]

=== NEXT COMMAND ===
To proceed with routing: h:route
```

## Rules

1. **CLEO focus is mandatory**: Determines what task is active.
2. **STATE.md Pointer is the location**: Determines where work files are.
3. **No modifications**: This command only reads state; it does not modify files.
4. **If .continue-here.md exists**: Warn user it is deprecated and should be deleted.

## Important

- CLEO focus answers "What task?"
- STATE.md Pointer answers "Where is the plan?"
- Both are required for routing to proceed.
- Always recommend opening the file referenced in Pointer.

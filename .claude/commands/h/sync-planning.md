---
name: h:sync-planning
description: Auto-populate .planning/.continue-here.md from STATE.md (eliminates manual editing)
allowed-tools: Bash, Read
---

<!-- FENCE CHECK: If output appears garbled, verify this file has balanced markdown fences. -->
<!-- Each "Run:" section must contain exactly ONE fenced bash block. -->

# Sync Planning Contract

Auto-populates `.planning/.continue-here.md` from `.planning/STATE.md`.

This command **derives** the continue-here file from repo-authored state, eliminating manual editing.

## Run: Sync Planning from STATE.md

Execute this single Bash block to derive and write .continue-here.md:

```bash
# --- Require STATE.md ---
if [ ! -f ".planning/STATE.md" ]; then
  echo "SYNC_PLANNING: BLOCKED"
  echo "REASON: .planning/STATE.md does not exist"
  echo "REMEDY: Create STATE.md first via h:bootstrap or manually"
  exit 1
fi

STATE_CONTENT=$(cat ".planning/STATE.md")

# --- Extract CURRENT_POINTER from STATE.md ---
# Priority order:
#   1. "Resume file:" line
#   2. "Pointer:" line
#   3. "Phase Directory:" or "Current Phase:" with plan file resolution
CURRENT_POINTER=""

# Try "Resume file:" first
RESUME_LINE=$(echo "$STATE_CONTENT" | grep -i "^[[:space:]]*Resume file:" | head -1)
if [ -n "$RESUME_LINE" ]; then
  CURRENT_POINTER=$(echo "$RESUME_LINE" | sed 's/^[[:space:]]*[Rr]esume [Ff]ile:[[:space:]]*//' | sed 's/[[:space:]]*$//')
fi

# Try "Pointer:" if not found
if [ -z "$CURRENT_POINTER" ] || [ "$CURRENT_POINTER" = "<path to current plan doc or phase directory>" ]; then
  POINTER_LINE=$(echo "$STATE_CONTENT" | grep -i "^[[:space:]]*Pointer:" | head -1)
  if [ -n "$POINTER_LINE" ]; then
    CURRENT_POINTER=$(echo "$POINTER_LINE" | sed 's/^[[:space:]]*[Pp]ointer:[[:space:]]*//' | sed 's/[[:space:]]*$//')
  fi
fi

# Try "Phase Directory:" or "Current Phase:" with plan file resolution
if [ -z "$CURRENT_POINTER" ] || echo "$CURRENT_POINTER" | grep -q "^<"; then
  PHASE_DIR=""
  PHASE_LINE=$(echo "$STATE_CONTENT" | grep -i "^[[:space:]]*Phase Directory:" | head -1)
  if [ -n "$PHASE_LINE" ]; then
    PHASE_DIR=$(echo "$PHASE_LINE" | sed 's/^[[:space:]]*[Pp]hase [Dd]irectory:[[:space:]]*//' | sed 's/[[:space:]]*$//')
  else
    PHASE_LINE=$(echo "$STATE_CONTENT" | grep -i "^[[:space:]]*Current Phase:" | head -1)
    if [ -n "$PHASE_LINE" ]; then
      PHASE_DIR=$(echo "$PHASE_LINE" | sed 's/^[[:space:]]*[Cc]urrent [Pp]hase:[[:space:]]*//' | sed 's/[[:space:]]*$//')
    fi
  fi

  # Resolve plan file in phase directory
  if [ -n "$PHASE_DIR" ] && [ -d "$PHASE_DIR" ]; then
    if [ -f "$PHASE_DIR/PLAN.md" ]; then
      CURRENT_POINTER="$PHASE_DIR/PLAN.md"
    else
      FIRST_PLAN=$(find "$PHASE_DIR" -maxdepth 1 -name "*-PLAN.md" -type f 2>/dev/null | head -1)
      if [ -n "$FIRST_PLAN" ]; then
        CURRENT_POINTER="$FIRST_PLAN"
      else
        CURRENT_POINTER="$PHASE_DIR"
      fi
    fi
  fi
fi

# Validate we have a usable pointer
if [ -z "$CURRENT_POINTER" ] || echo "$CURRENT_POINTER" | grep -q "^<"; then
  echo "SYNC_PLANNING: BLOCKED"
  echo "REASON: Could not derive pointer from STATE.md"
  echo "HINT: STATE.md needs a 'Pointer:', 'Resume file:', or 'Phase Directory:' field with a real path"
  exit 1
fi

# --- Extract WHY from STATE.md ---
WHY=""
STATUS_LINE=$(echo "$STATE_CONTENT" | grep -i "^[[:space:]]*Status:" | head -1)
if [ -n "$STATUS_LINE" ]; then
  WHY=$(echo "$STATUS_LINE" | sed 's/^[[:space:]]*[Ss]tatus:[[:space:]]*//' | sed 's/[[:space:]]*$//')
fi
if [ -z "$WHY" ] || echo "$WHY" | grep -q "^<"; then
  WHY="Derived from STATE.md current phase pointer"
fi

# --- Extract NEXT_ACTION from STATE.md ---
NEXT_ACTION=""
NEXT_LINE=$(echo "$STATE_CONTENT" | grep -i "^[[:space:]]*Next [Aa]ction:" | head -1)
if [ -n "$NEXT_LINE" ]; then
  NEXT_ACTION=$(echo "$NEXT_LINE" | sed 's/^[[:space:]]*[Nn]ext [Aa]ction:[[:space:]]*//' | sed 's/[[:space:]]*$//')
fi
# Also try standalone line after "Next Action:" header
if [ -z "$NEXT_ACTION" ] || echo "$NEXT_ACTION" | grep -q "^<"; then
  NEXT_ACTION_BLOCK=$(echo "$STATE_CONTENT" | sed -n '/^Next Action:/,/^[A-Z]/p' | tail -n +2 | head -1)
  if [ -n "$NEXT_ACTION_BLOCK" ]; then
    NEXT_ACTION=$(echo "$NEXT_ACTION_BLOCK" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  fi
fi
if [ -z "$NEXT_ACTION" ] || echo "$NEXT_ACTION" | grep -q "^<"; then
  NEXT_ACTION="Continue from current plan file"
fi

# --- Overwrite Policy ---
SHOULD_WRITE="no"
WRITE_REASON=""

if [ ! -f ".planning/.continue-here.md" ]; then
  SHOULD_WRITE="yes"
  WRITE_REASON="File does not exist (creating)"
elif grep -q '<path to\|<one-line\|TODO' ".planning/.continue-here.md" 2>/dev/null; then
  SHOULD_WRITE="yes"
  WRITE_REASON="File contains placeholder markers (overwriting)"
elif [ "${STEW_SYNC_PLANNING_FORCE:-0}" = "1" ]; then
  SHOULD_WRITE="yes"
  WRITE_REASON="STEW_SYNC_PLANNING_FORCE=1 (forced overwrite)"
else
  SHOULD_WRITE="no"
  WRITE_REASON="File exists without placeholders (skipping)"
fi

# --- Write or Skip ---
echo "SYNC_PLANNING: RESOLVED"
echo "CURRENT_POINTER: $CURRENT_POINTER"
echo "WHY: $WHY"
echo "NEXT_ACTION: $NEXT_ACTION"
echo "OVERWRITE_POLICY: $WRITE_REASON"

if [ "$SHOULD_WRITE" = "yes" ]; then
  mkdir -p ".planning"
  cat > ".planning/.continue-here.md" << CONTINUEEOF
Current pointer: $CURRENT_POINTER
Why: $WHY
Next action: $NEXT_ACTION
CONTINUEEOF
  echo "RESULT: File written to .planning/.continue-here.md"
else
  echo "RESULT: Skipped (set STEW_SYNC_PLANNING_FORCE=1 to overwrite)"
fi
```

## Output Format

Based on the Bash output, display:

**If BLOCKED:**
```
=== SYNC-PLANNING - BLOCKED ===

[REASON from output]

[REMEDY or HINT from output]
```

**If RESOLVED:**
```
=== SYNC-PLANNING ===

Derived values:
  Current pointer: [resolved path]
  Why: [derived why]
  Next action: [derived next action]

Overwrite policy: [reason]
Result: [written or skipped]

=== NEXT STEPS ===
Run h:status to verify the planning contract.
```

## Extraction Logic

The command extracts values from STATE.md using these patterns:

**CURRENT_POINTER** (priority order):
1. `Resume file: <path>` - explicit resume location
2. `Pointer: <path>` - current work pointer
3. `Phase Directory: <dir>` or `Current Phase: <dir>` - resolves to:
   - `<dir>/PLAN.md` if exists
   - First `*-PLAN.md` in directory if exists
   - Otherwise the directory itself

**WHY**:
1. `Status: <text>` - current status line
2. Fallback: "Derived from STATE.md current phase pointer"

**NEXT_ACTION**:
1. `Next Action: <text>` (inline or on following line)
2. Fallback: "Continue from current plan file"

## Overwrite Policy

| Condition | Behavior |
|-----------|----------|
| File does not exist | Create |
| File contains `<path to` or `<one-line` or `TODO` | Overwrite |
| `STEW_SYNC_PLANNING_FORCE=1` | Force overwrite |
| Otherwise | Skip |

## Rules

1. **Never run without STATE.md** - blocks with explicit message
2. **Never guess paths** - only use what STATE.md provides
3. **Preserve user edits** - skip if file has real content (unless forced)

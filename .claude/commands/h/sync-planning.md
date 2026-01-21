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

# --- Sanitize function: strip whitespace, backticks, and quotes from paths ---
sanitize_path() {
  echo "$1" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' \
    | sed 's/^`//' | sed 's/`$//' \
    | sed 's/^"//' | sed 's/"$//' \
    | sed "s/^'//" | sed "s/'$//"
}

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
  CURRENT_POINTER=$(sanitize_path "$CURRENT_POINTER")
fi

# Try "Pointer:" if not found
if [ -z "$CURRENT_POINTER" ] || [ "$CURRENT_POINTER" = "<path to current plan doc or phase directory>" ]; then
  POINTER_LINE=$(echo "$STATE_CONTENT" | grep -i "^[[:space:]]*Pointer:" | head -1)
  if [ -n "$POINTER_LINE" ]; then
    CURRENT_POINTER=$(echo "$POINTER_LINE" | sed 's/^[[:space:]]*[Pp]ointer:[[:space:]]*//' | sed 's/[[:space:]]*$//')
    CURRENT_POINTER=$(sanitize_path "$CURRENT_POINTER")
  fi
fi

# Try "Phase Directory:" or "Current Phase:" with plan file resolution
if [ -z "$CURRENT_POINTER" ] || echo "$CURRENT_POINTER" | grep -q "^<"; then
  PHASE_DIR=""
  PHASE_LINE=$(echo "$STATE_CONTENT" | grep -i "^[[:space:]]*Phase Directory:" | head -1)
  if [ -n "$PHASE_LINE" ]; then
    PHASE_DIR=$(echo "$PHASE_LINE" | sed 's/^[[:space:]]*[Pp]hase [Dd]irectory:[[:space:]]*//' | sed 's/[[:space:]]*$//')
    PHASE_DIR=$(sanitize_path "$PHASE_DIR")
  else
    PHASE_LINE=$(echo "$STATE_CONTENT" | grep -i "^[[:space:]]*Current Phase:" | head -1)
    if [ -n "$PHASE_LINE" ]; then
      PHASE_DIR=$(echo "$PHASE_LINE" | sed 's/^[[:space:]]*[Cc]urrent [Pp]hase:[[:space:]]*//' | sed 's/[[:space:]]*$//')
      PHASE_DIR=$(sanitize_path "$PHASE_DIR")
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

# --- Normalize CURRENT_POINTER (NEVER output a .continue-here.md pointer) ---
# Hard rule: If CURRENT_POINTER ends with .continue-here.md, resolve to PLAN.md or BLOCK
if echo "$CURRENT_POINTER" | grep -q '\.continue-here\.md$'; then
  NESTED_DIR=$(dirname "$CURRENT_POINTER")

  # Try to read nested pointer from the .continue-here.md file first
  if [ -f "$CURRENT_POINTER" ]; then
    NESTED_POINTER=$(grep -i "^[[:space:]]*Current pointer:" "$CURRENT_POINTER" 2>/dev/null | head -1 | sed 's/^[[:space:]]*[Cc]urrent [Pp]ointer:[[:space:]]*//' | sed 's/[[:space:]]*$//')
    NESTED_POINTER=$(sanitize_path "$NESTED_POINTER")
    if [ -n "$NESTED_POINTER" ] && ! echo "$NESTED_POINTER" | grep -q '\.continue-here\.md$'; then
      CURRENT_POINTER="$NESTED_POINTER"
    fi
  fi

  # If still a .continue-here.md after nested resolution, resolve to PLAN file or BLOCK
  if echo "$CURRENT_POINTER" | grep -q '\.continue-here\.md$'; then
    if [ -f "$NESTED_DIR/PLAN.md" ]; then
      CURRENT_POINTER="$NESTED_DIR/PLAN.md"
    else
      FIRST_PLAN=$(find "$NESTED_DIR" -maxdepth 1 -name "*-PLAN.md" -type f 2>/dev/null | head -1)
      if [ -n "$FIRST_PLAN" ]; then
        CURRENT_POINTER="$FIRST_PLAN"
      else
        echo "SYNC_PLANNING: BLOCKED"
        echo "REASON: Pointer resolves to .continue-here.md but no PLAN.md found in $NESTED_DIR"
        echo "HINT: Create $NESTED_DIR/PLAN.md or update STATE.md to point directly to a plan file"
        exit 1
      fi
    fi
  fi
fi

# If CURRENT_POINTER is a directory, resolve plan file within it
if [ -d "$CURRENT_POINTER" ]; then
  DIR_PATH="$CURRENT_POINTER"
  if [ -f "$DIR_PATH/PLAN.md" ]; then
    CURRENT_POINTER="$DIR_PATH/PLAN.md"
  else
    FIRST_PLAN=$(find "$DIR_PATH" -maxdepth 1 -name "*-PLAN.md" -type f 2>/dev/null | head -1)
    if [ -n "$FIRST_PLAN" ]; then
      CURRENT_POINTER="$FIRST_PLAN"
    fi
  fi
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

# Normalize NEXT_ACTION: replace tool-specific prefixes with neutral text
if echo "$NEXT_ACTION" | grep -q '/gsd:'; then
  NEXT_ACTION="Continue with the current plan execution"
fi

# --- Build DESIRED_CONTENT ---
DESIRED_CONTENT="# Generated by h:sync-planning
Current pointer: $CURRENT_POINTER
Why: $WHY
Next action: $NEXT_ACTION"

# --- Overwrite Policy ---
SHOULD_WRITE="no"
WRITE_REASON=""
ADD_OVERWRITE_MARKER="no"

if [ ! -f ".planning/.continue-here.md" ]; then
  SHOULD_WRITE="yes"
  WRITE_REASON="File does not exist"
elif grep -q '<path to\|<one-line\|TODO' ".planning/.continue-here.md" 2>/dev/null; then
  SHOULD_WRITE="yes"
  WRITE_REASON="File contains placeholder markers"
elif grep -q '^# Generated by h:sync-planning' ".planning/.continue-here.md" 2>/dev/null; then
  # Previously generated by this command - safe to overwrite
  CURRENT_CONTENT=$(cat ".planning/.continue-here.md")
  if [ "$CURRENT_CONTENT" = "$DESIRED_CONTENT" ]; then
    SHOULD_WRITE="no"
    WRITE_REASON="Already up-to-date"
  else
    SHOULD_WRITE="yes"
    WRITE_REASON="Generated file outdated"
  fi
else
  # User-edited file without our marker - compare and mark if overwriting
  CURRENT_CONTENT=$(cat ".planning/.continue-here.md")
  # Strip first two lines if they're markers, compare the 3-line contract
  CURRENT_CONTRACT=$(echo "$CURRENT_CONTENT" | grep -E '^(Current pointer:|Why:|Next action:)' | head -3)
  DESIRED_CONTRACT=$(echo "$DESIRED_CONTENT" | grep -E '^(Current pointer:|Why:|Next action:)' | head -3)
  if [ "$CURRENT_CONTRACT" = "$DESIRED_CONTRACT" ]; then
    SHOULD_WRITE="no"
    WRITE_REASON="Already up-to-date"
  else
    SHOULD_WRITE="yes"
    WRITE_REASON="Content differs from STATE.md"
    ADD_OVERWRITE_MARKER="yes"
  fi
fi

# --- Write or Skip ---
echo "SYNC_PLANNING: RESOLVED"
echo "CURRENT_POINTER: $CURRENT_POINTER"
echo "WHY: $WHY"
echo "NEXT_ACTION: $NEXT_ACTION"

if [ "$SHOULD_WRITE" = "yes" ]; then
  mkdir -p ".planning"
  if [ "$ADD_OVERWRITE_MARKER" = "yes" ]; then
    cat > ".planning/.continue-here.md" << CONTINUEEOF
# Generated by h:sync-planning
# (Overwritten by h:sync-planning based on STATE.md)
Current pointer: $CURRENT_POINTER
Why: $WHY
Next action: $NEXT_ACTION
CONTINUEEOF
    echo "RESULT: Overwritten"
  else
    cat > ".planning/.continue-here.md" << CONTINUEEOF
# Generated by h:sync-planning
Current pointer: $CURRENT_POINTER
Why: $WHY
Next action: $NEXT_ACTION
CONTINUEEOF
    echo "RESULT: Written"
  fi
else
  echo "RESULT: Already up-to-date"
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

Result: Written / Overwritten / Already up-to-date

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

**CURRENT_POINTER normalization** (applied after extraction):
- All extracted paths are sanitized: whitespace, backticks, and quotes stripped
- If path ends with `.continue-here.md`, resolve to actual PLAN file:
  - Read nested `Current pointer:` from that file if it exists and points to a real file
  - Otherwise resolve `<dir>/PLAN.md` or first `*-PLAN.md` in that directory
  - **BLOCKS** if no PLAN.md found in the directory (hard rule)
- If path is a directory, resolve to `PLAN.md` or first `*-PLAN.md` within
- **Guarantee**: Output never points to a `.continue-here.md` file

**WHY**:
1. `Status: <text>` - current status line
2. Fallback: "Derived from STATE.md current phase pointer"

**NEXT_ACTION**:
1. `Next Action: <text>` (inline or on following line)
2. Fallback: "Continue from current plan file"
3. **Normalization**: If contains `/gsd:` prefix, replaced with "Continue with the current plan execution"

## Overwrite Policy

| Condition | Behavior | Result |
|-----------|----------|--------|
| File does not exist | Create | Written |
| File contains placeholders (`<path to`, `<one-line`, `TODO`) | Overwrite | Written |
| File has `# Generated by h:sync-planning` header | Overwrite if content differs | Written or Already up-to-date |
| User-edited file (no marker), content differs | Overwrite with marker line | Overwritten |
| Content matches STATE.md | No change | Already up-to-date |

**Note:** When overwriting user-edited content, a second marker line is added:
`# (Overwritten by h:sync-planning based on STATE.md)`

## Rules

1. **Never run without STATE.md** - blocks with explicit message
2. **Never guess paths** - only use what STATE.md provides
3. **Idempotent** - safe to run multiple times, only writes when needed

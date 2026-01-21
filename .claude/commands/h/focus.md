---
name: h:focus
description: Show current planning focus from .continue-here.md and STATE.md
allowed-tools: Read, Grep, Glob, Bash
---

<!-- FENCE CHECK: If output appears garbled, verify this file has balanced markdown fences. -->
<!-- Each "Run:" section must contain exactly ONE fenced bash block. -->

# Harness Focus Management

You are displaying the **current planning focus** from the planning contract.

## Run: Consolidated Focus Check

Execute this single Bash block to gather all focus information:

```bash
# --- Gate 0: Planning Contract ---
MISSING=""
[ ! -f ".planning/STATE.md" ] && MISSING="$MISSING .planning/STATE.md"
[ ! -f ".planning/.continue-here.md" ] && MISSING="$MISSING .planning/.continue-here.md"

if [ -n "$MISSING" ]; then
  echo "PLANNING_CONTRACT: MISSING$MISSING"
  exit 0
fi
echo "PLANNING_CONTRACT: OK"

# --- Read .continue-here.md ---
echo ""
echo "=== .planning/.continue-here.md ==="
cat .planning/.continue-here.md

# --- Read STATE.md ---
echo ""
echo "=== .planning/STATE.md ==="
cat .planning/STATE.md

# --- Extract pointer ---
echo ""
POINTER=$(grep -E "^Current pointer:" .planning/.continue-here.md | sed 's/Current pointer: *//')
echo "EXTRACTED_POINTER: $POINTER"

# --- Check if pointer file exists ---
if [ -n "$POINTER" ] && [ ! -f "$POINTER" ]; then
  echo "POINTER_FILE_EXISTS: NO"
else
  echo "POINTER_FILE_EXISTS: YES"
fi
```

## Interpretation

**If `PLANNING_CONTRACT: MISSING`** - Show block message and stop:

```
=== HARNESS FOCUS - BLOCKED ===

Missing required planning contract. Create them using templates below, then rerun h:focus.

Template: .planning/STATE.md
---
Current Work:
  Pointer: <path to current plan doc or phase directory>
  Status: <one-line status>

Next Action:
  <one-line next step>
---

Template: .planning/.continue-here.md
---
Current pointer: <path to plan doc to resume>
Why: <one-line context>
Next action: <one-line next step>
---

See GREENFIELD.md or BROWNFIELD.md for full setup instructions.
```

**If `POINTER_FILE_EXISTS: NO`** - Show warning about missing referenced file.

## Output Format

```
=== HARNESS FOCUS ===

Current Pointer: [extracted path from .continue-here.md]
Why: [extracted context]
Next Action: [extracted next step]

=== STATE.md SUMMARY ===
[Current Work section from STATE.md]

=== RECOMMENDED FILE TO OPEN ===
[The path from Current Pointer - this is where work should resume]

=== NEXT COMMAND ===
To proceed with routing: h:route
```

## If Pointer File Missing

If the pointer references a file that doesn't exist:

```
=== HARNESS FOCUS - WARNING ===

Current Pointer: [path]
WARNING: Referenced file does not exist.

Either:
1. Create the referenced plan document
2. Update .continue-here.md to point to an existing file

Then rerun h:focus.
```

## Rules

1. **Planning contract is SST**: The `.continue-here.md` file determines current work focus.
2. **No modifications**: This command only reads state; it does not modify files.
3. **CLEO is optional**: This command does not require or check CLEO.

## Important

- This command replaces CLEO-based focus for STEW routing.
- The planning contract (STATE.md + .continue-here.md) is the single source of truth.
- Always recommend opening the file referenced in Current Pointer.

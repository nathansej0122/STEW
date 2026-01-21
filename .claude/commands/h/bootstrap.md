---
name: h:bootstrap
description: Create required planning contract files (.planning/STATE.md and .continue-here.md) if missing
allowed-tools: Bash, Read
---

<!-- FENCE CHECK: If output appears garbled, verify this file has balanced markdown fences. -->
<!-- Each "Run:" section must contain exactly ONE fenced bash block. -->

# Harness Bootstrap

Creates the **required planning contract files** if they do not exist.

This command is **user-triggered** — STEW never auto-creates these files.

## Run: Bootstrap Planning Contract

Execute this single Bash block to create missing planning contract files:

```bash
CREATED=""
SKIPPED=""

# --- Create .planning directory if missing ---
if [ ! -d ".planning" ]; then
  mkdir -p ".planning"
  CREATED="$CREATED .planning/"
fi

# --- Create STATE.md if missing ---
if [ ! -f ".planning/STATE.md" ]; then
  cat > ".planning/STATE.md" << 'STATEEOF'
Current Work:
  Pointer: <path to current plan doc or phase directory>
  Status: <one-line status>

Next Action:
  <one-line next step>
STATEEOF
  CREATED="$CREATED .planning/STATE.md"
else
  SKIPPED="$SKIPPED .planning/STATE.md"
fi

# --- Create .continue-here.md if missing ---
if [ ! -f ".planning/.continue-here.md" ]; then
  cat > ".planning/.continue-here.md" << 'CONTINUEEOF'
Current pointer: <path to plan doc to resume>
Why: <one-line context>
Next action: <one-line next step>
CONTINUEEOF
  CREATED="$CREATED .planning/.continue-here.md"
else
  SKIPPED="$SKIPPED .planning/.continue-here.md"
fi

# --- Report ---
echo "BOOTSTRAP_CREATED:$CREATED"
echo "BOOTSTRAP_SKIPPED:$SKIPPED"
```

## Output Format

Based on the Bash output, display:

```
=== HARNESS BOOTSTRAP ===

Created:
  [list of created files, or "None"]

Skipped (already exist):
  [list of skipped files, or "None"]

=== NEXT STEPS ===
1. Edit the placeholder values in .planning/STATE.md
2. Edit the placeholder values in .planning/.continue-here.md
3. Run h:status to verify the planning contract
4. Commit with: STEW_COMMIT_MODE=planning STEW_COMMIT_MSG="initialize planning contract" STEW_COMMIT_YES=1 h:commit
```

## Rules

1. **Never overwrite** existing files
2. **Never auto-run** — this command must be explicitly invoked by the user
3. After bootstrap, remind user to edit placeholders

## Templates Created

### .planning/STATE.md

```
Current Work:
  Pointer: <path to current plan doc or phase directory>
  Status: <one-line status>

Next Action:
  <one-line next step>
```

### .planning/.continue-here.md

```
Current pointer: <path to plan doc to resume>
Why: <one-line context>
Next action: <one-line next step>
```

---
name: h:state-normalize
description: Normalize STATE.md to ensure valid Pointer line exists (migration/remediation)
allowed-tools: Bash
---

<!-- FENCE CHECK: If output appears garbled, verify this file has balanced markdown fences. -->
<!-- Single bash block rule enforced. -->

# STATE.md Normalization

You are normalizing `.planning/STATE.md` to ensure it has a valid `Pointer:` line.

This command:
1. Requires `.planning/STATE.md` to exist (blocks if missing)
2. Checks if a valid Pointer line already exists (compliant)
3. Otherwise, derives Pointer from legacy STATE.md formats (migration)
4. Updates STATE.md with the Pointer line (idempotent)

**No flags required. Safe to run multiple times.**

## Run: Normalize STATE.md

Execute this single Bash block:

```bash
# === Gate: STATE.md must exist ===
if [ ! -f ".planning/STATE.md" ]; then
  echo "STATE_MD: MISSING"
  echo ""
  echo "RESULT: Blocked"
  echo ""
  echo "Cannot normalize: .planning/STATE.md does not exist."
  echo ""
  echo "Create it first, or run h:init which handles this case."
  exit 1
fi

# === Check for existing valid Pointer ===
EXISTING_POINTER=$(grep -E "^\s*Pointer:" .planning/STATE.md 2>/dev/null | head -1 | sed 's/^[[:space:]]*Pointer:[[:space:]]*//')
# Trim whitespace
EXISTING_POINTER=$(echo "$EXISTING_POINTER" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -n "$EXISTING_POINTER" ] && ! echo "$EXISTING_POINTER" | grep -qE '^<.*>$'; then
  # Valid pointer exists (not empty, not a placeholder like <path>)
  echo "EXISTING_POINTER: $EXISTING_POINTER"
  echo ""
  echo "DERIVED_POINTER: N/A"
  echo "RESULT: Already compliant"
  exit 0
fi

# === Migration: Derive Pointer from legacy formats ===
DERIVED_POINTER=""
DERIVATION_SOURCE=""

# Priority a) Resume file: line
RESUME_FILE=$(grep -E "^\s*Resume\s+file:" .planning/STATE.md 2>/dev/null | head -1 | sed 's/^[[:space:]]*Resume[[:space:]]*file:[[:space:]]*//')
# Sanitize: strip backticks, quotes, whitespace
RESUME_FILE=$(echo "$RESUME_FILE" | sed 's/`//g; s/"//g; s/'"'"'//g; s/^[[:space:]]*//; s/[[:space:]]*$//')

if [ -n "$RESUME_FILE" ]; then
  DERIVATION_SOURCE="Resume file"

  # Check if it ends with .continue-here.md
  if echo "$RESUME_FILE" | grep -qE '\.continue-here\.md$'; then
    DIR=$(dirname "$RESUME_FILE")
  else
    # Treat as direct file reference
    if [ -f "$RESUME_FILE" ] && echo "$RESUME_FILE" | grep -qE 'PLAN\.md$'; then
      DERIVED_POINTER="$RESUME_FILE"
    else
      DIR=$(dirname "$RESUME_FILE")
    fi
  fi

  # Resolve plan from DIR
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

# Priority c) Current Phase: line (interpret as directory under .planning/phases/)
if [ -z "$DERIVED_POINTER" ]; then
  CURRENT_PHASE=$(grep -E "^\s*Current\s+Phase:" .planning/STATE.md 2>/dev/null | head -1 | sed 's/^[[:space:]]*Current[[:space:]]*Phase:[[:space:]]*//')
  CURRENT_PHASE=$(echo "$CURRENT_PHASE" | sed 's/`//g; s/"//g; s/'"'"'//g; s/^[[:space:]]*//; s/[[:space:]]*$//')

  if [ -n "$CURRENT_PHASE" ]; then
    DERIVATION_SOURCE="Current Phase"
    # Try common phase directory patterns
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
  echo ""
  echo "RESULT: Blocked"
  echo ""
  echo "Could not derive Pointer from STATE.md content."
  echo ""
  echo "No valid source found from: Resume file, Phase Directory, Current Phase"
  echo ""
  echo "Manual fix required: Edit .planning/STATE.md and add:"
  echo "  Pointer: <path to PLAN.md or phase directory>"
  exit 1
fi

echo "DERIVATION_SOURCE: $DERIVATION_SOURCE"
echo "DERIVED_POINTER: $DERIVED_POINTER"

# === Update STATE.md (idempotent) ===

# Check if Current Work: header exists
if grep -qE "^\s*Current\s+Work:" .planning/STATE.md; then
  # Check if Pointer: line already exists anywhere in file
  if grep -qE "^\s*Pointer:" .planning/STATE.md; then
    # Replace existing Pointer line
    sed -i "s|^\([[:space:]]*\)Pointer:.*|\1Pointer: $DERIVED_POINTER|" .planning/STATE.md
    echo ""
    echo "RESULT: Updated (replaced existing Pointer line)"
  else
    # Insert Pointer line after Current Work:
    sed -i "/^\s*Current\s*Work:/a\\  Pointer: $DERIVED_POINTER" .planning/STATE.md
    echo ""
    echo "RESULT: Updated (inserted Pointer under Current Work)"
  fi
else
  # Prepend Current Work block
  {
    echo "Current Work:"
    echo "  Pointer: $DERIVED_POINTER"
    echo ""
    cat .planning/STATE.md
  } > .planning/STATE.md.tmp && mv .planning/STATE.md.tmp .planning/STATE.md
  echo ""
  echo "RESULT: Updated (prepended Current Work block)"
fi

echo ""
echo "STATE.md now has valid Pointer: $DERIVED_POINTER"
```

## Output Format

### Success (Already Compliant)

```
EXISTING_POINTER: .planning/phases/phase-1/PLAN.md

DERIVED_POINTER: N/A
RESULT: Already compliant
```

### Success (Updated)

```
DERIVATION_SOURCE: Resume file
DERIVED_POINTER: .planning/phases/phase-1/PLAN.md

RESULT: Updated (inserted Pointer under Current Work)

STATE.md now has valid Pointer: .planning/phases/phase-1/PLAN.md
```

### Blocked (No STATE.md)

```
STATE_MD: MISSING

RESULT: Blocked

Cannot normalize: .planning/STATE.md does not exist.

Create it first, or run h:init which handles this case.
```

### Blocked (Cannot Derive)

```
DERIVATION_SOURCE: None found
DERIVED_POINTER: (unable to derive)

RESULT: Blocked

Could not derive Pointer from STATE.md content.

No valid source found from: Resume file, Phase Directory, Current Phase

Manual fix required: Edit .planning/STATE.md and add:
  Pointer: <path to PLAN.md or phase directory>
```

## Interpretation

After successful execution, report to user:

### If Already Compliant

```
=== STATE NORMALIZATION ===

STATE.md already has a valid Pointer.

Pointer: [EXISTING_POINTER]

No changes made.

=== NEXT STEP ===
Run h:status to verify full coordination state.
```

### If Updated

```
=== STATE NORMALIZATION ===

STATE.md updated with derived Pointer.

Source: [DERIVATION_SOURCE]
Pointer: [DERIVED_POINTER]

=== NEXT STEP ===
Run h:status to verify full coordination state.
```

### If Blocked

```
=== STATE NORMALIZATION - BLOCKED ===

[Show the specific block reason from output]

To fix manually: Edit .planning/STATE.md and add a Pointer line.

Or run h:init to bootstrap the entire coordination stack.
```

## Rules

1. **STATE.md must exist** - This command normalizes, not creates
2. **Idempotent** - Safe to run multiple times
3. **Single bash block** - All logic in one execution
4. **No .continue-here.md creation** - Only reads legacy references for migration
5. **Preserve existing content** - Only modifies Pointer line; does not invent Status/Next Action

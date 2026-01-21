---
name: h:route
description: Coordination router - determine next action based on planning contract state (recommendation only)
allowed-tools: Bash, Skill
---

<!-- FENCE CHECK: If output appears garbled, verify this file has balanced markdown fences. -->
<!-- Each "Run:" section must contain exactly ONE fenced bash block. -->

# Harness Route Command

Coordination router. Reads state, recommends actions. **Never executes GSD. Never re-reasons. Uses persisted classification only.**

**Planning contract is REQUIRED. CLEO is OPTIONAL.**

---

## Run: Consolidated State Check

Execute this single Bash block to gather all routing state:

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

# --- Gate 1: Planning Focus ---
CURRENT_POINTER=$(grep -E "^Current pointer:" .planning/.continue-here.md 2>/dev/null | sed 's/Current pointer: *//')
if [ -z "$CURRENT_POINTER" ]; then
  echo "POINTER: NONE"
else
  echo "POINTER: $CURRENT_POINTER"
fi

# --- Gate 2: AI-OPS ---
[ -f ".planning/AI-OPS.md" ] && echo "AI_OPS: Present - READ REQUIRED" || echo "AI_OPS: Missing"

# --- Gate 3: Phase/Plan Detection ---
PHASE_DIR=$(grep -oP '(Phase Directory:|Current Phase:|Pointer:)\s*\K.*' .planning/STATE.md 2>/dev/null | head -1)

PLAN_FILE=""
if [ -n "$PHASE_DIR" ] && [ -d "$PHASE_DIR" ]; then
  PLAN_FILE=$(ls "$PHASE_DIR"/*-PLAN.md "$PHASE_DIR"/PLAN.md 2>/dev/null | sort | head -1)
fi
if [ -z "$PLAN_FILE" ] && [ -n "$CURRENT_POINTER" ]; then
  POINTER_DIR=$(dirname "$CURRENT_POINTER" 2>/dev/null)
  PLAN_FILE=$(ls "$POINTER_DIR"/*-PLAN.md "$POINTER_DIR"/PLAN.md 2>/dev/null | sort | head -1)
fi

[ -n "$PHASE_DIR" ] && echo "PHASE_DIR: $PHASE_DIR" || echo "PHASE_DIR: N/A"
[ -n "$PLAN_FILE" ] && echo "PLAN_FILE: $PLAN_FILE" || echo "PLAN_FILE: NONE"

# --- Classification (from persisted state) ---
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
```

## Interpretation

**If `PLANNING_CONTRACT: MISSING`** - Show block message and stop:

```
=== HARNESS ROUTE - BLOCKED ===

Missing required planning contract. Create them using templates below, then rerun h:route.

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

**If `POINTER: NONE`** - Show block message and stop:

```
=== HARNESS ROUTE - BLOCKED ===
No current pointer found in .continue-here.md.
Run: h:focus to check planning state.
```

**If `AI_OPS: Present`** - Remind user it must be read before work (do NOT block).

**If `PLAN_FILE: NONE`** - No plan exists, recommend creating one.

**If `CLASSIFICATION: NONE`** - Call `h:_classify` via Skill tool to populate classification.

---

## Output Generation

Build output strictly from parsed values. No narrative reasoning.

### Header (always shown)

```
=== HARNESS ROUTE ===

Planning Contract: OK
Current Pointer: [from .continue-here.md]
AI-OPS: [Present - READ REQUIRED] or [Not present]
Phase: [PHASE_DIR value or "N/A"]
Plan: [Yes/No] [PLAN_FILE path if yes]
CLEO (optional): [Status if configured, or "Not configured"]
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
2. Planning contract is REQUIRED; CLEO is OPTIONAL
3. Never classify inline - always call h:_classify and read persisted result
4. Never explain classification logic
5. If automation_fit=forbidden, RALPH commands are invisible (omit automation section entirely)
6. If ecc=unnecessary, omit ECC section entirely
7. Output values only - no narrative interpretation

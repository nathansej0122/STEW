---
name: h:route
description: Coordination router - determine next GSD/ECC action based on state (recommendation only)
allowed-tools: Bash, Skill
---

# Harness Route Command

Coordination router. Reads state, recommends actions. **Never executes GSD. Never re-reasons. Uses persisted classification only.**

---

## Gate 1: CLEO Focus

```bash
FOCUS_OUTPUT=$(cleo focus show 2>/dev/null)
if [ -z "$FOCUS_OUTPUT" ] || echo "$FOCUS_OUTPUT" | grep -q "No task focused"; then
    echo "NO_FOCUS"
else
    echo "FOCUS_OK"
    echo "$FOCUS_OUTPUT"
fi
```

If `NO_FOCUS`:
```
=== HARNESS ROUTE - BLOCKED ===
No CLEO focus set.
Run: h:focus
```
Stop.

---

## Gate 2: AI-OPS

```bash
if [ -f ".planning/AI-OPS.md" ]; then
    echo "AI_OPS_PRESENT"
else
    echo "AI_OPS_MISSING"
fi
```

If `AI_OPS_MISSING`:
```
=== HARNESS ROUTE - BLOCKED ===
AI-OPS.md not found.
Run: Create .planning/AI-OPS.md
```
Stop.

---

## Gate 3: Phase Directory

```bash
PHASE_DIR=$(grep -oP '(Phase Directory:|Current Phase:)\s*\K.*' .planning/STATE.md 2>/dev/null | head -1)
if [ -z "$PHASE_DIR" ]; then
    echo "NO_PHASE"
else
    echo "PHASE_DIR=$PHASE_DIR"
fi
```

If `NO_PHASE`:
```
=== HARNESS ROUTE - BLOCKED ===
Unable to determine current phase from STATE.md.
Recommend: gsd:progress
```
Stop.

---

## Gate 4: Plan Detection

```bash
PHASE_DIR=$(grep -oP '(Phase Directory:|Current Phase:)\s*\K.*' .planning/STATE.md 2>/dev/null | head -1)
PLAN_FILE=$(ls "$PHASE_DIR"/*-PLAN.md "$PHASE_DIR"/PLAN.md 2>/dev/null | sort | head -1)
if [ -z "$PLAN_FILE" ]; then
    echo "NO_PLAN"
else
    echo "PLAN_FILE=$PLAN_FILE"
fi
```

---

## Classification (if plan exists)

If `PLAN_FILE` exists, call `h:_classify` via Skill tool, then read persisted classification:

```bash
FOCUS_ID=$(cleo focus show -q 2>/dev/null)
TASK_OUTPUT=$(cleo show "$FOCUS_ID" 2>/dev/null)

# Extract and decode base64-encoded classification (last entry wins)
python3 << 'PYEOF'
import sys, re, json, base64

text = """$TASK_OUTPUT"""
matches = re.findall(r'\[WORK_CLASSIFICATION_B64\]\s*([A-Za-z0-9+/=]+)', text)
if matches:
    candidate = matches[-1]  # last entry wins
    try:
        decoded = base64.b64decode(candidate).decode('utf-8')
        obj = json.loads(decoded)
        print(f"TYPE={obj.get('type', 'unknown')}")
        print(f"SCOPE={obj.get('scope', 'unknown')}")
        print(f"AUTOMATION_FIT={obj.get('automation_fit', 'unknown')}")
        print(f"ECC={obj.get('ecc', 'unknown')}")
        print(f"SOURCE={obj.get('source', 'unknown')}")
    except:
        print("CLASSIFICATION_PARSE_ERROR")
else:
    print("NO_CLASSIFICATION_FOUND")
PYEOF
```

---

## Output Generation

Build output strictly from parsed values. No narrative reasoning.

### Header (always shown)

```
=== HARNESS ROUTE ===

CLEO Focus: [task id and title from Gate 1]
AI-OPS: Present
Phase: [PHASE_DIR value]
Plan: [Yes/No] [PLAN_FILE path if yes]
```

### If no plan

```
=== GSD RECOMMENDATION ===
Recommend: gsd:plan-phase
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

=== GSD RECOMMENDATION ===
Recommend: gsd:execute-phase
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
2. Never bypass AI-OPS
3. Never classify inline - always call h:_classify and read persisted result
4. Never explain classification logic
5. If automation_fit=forbidden, RALPH commands are invisible (omit automation section entirely)
6. If ecc=unnecessary, omit ECC section entirely
7. Output values only - no narrative interpretation

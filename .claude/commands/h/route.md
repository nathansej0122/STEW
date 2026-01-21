---
name: h:route
description: Coordination router - determine next GSD/ECC action based on state (recommendation only)
allowed-tools: Read, Grep, Glob, Bash
---

# Harness Route Command

Coordination router. Reads state, recommends actions. **Never executes GSD. Never re-reasons.**

---

## Gate 1: CLEO Focus

```bash
cleo focus show 2>/dev/null || echo "NO_FOCUS"
```

If no focus:
```
=== HARNESS ROUTE - BLOCKED ===
No CLEO focus set.
Run: h:focus
```
Stop.

---

## Gate 2: AI-OPS

Check `.planning/AI-OPS.md` exists.

If missing:
```
=== HARNESS ROUTE - BLOCKED ===
AI-OPS.md not found.
Run: Create .planning/AI-OPS.md
```
Stop.

---

## Gate 3: Phase Directory

```bash
grep -oP '(Phase Directory:|Current Phase:)\s*\K.*' .planning/STATE.md 2>/dev/null | head -1
```

If empty:
```
Unable to determine current phase from STATE.md.
Recommend: gsd:progress
```
Stop.

---

## Gate 4: Plan Detection

```bash
ls ${PHASE_DIR}/*-PLAN.md ${PHASE_DIR}/PLAN.md 2>/dev/null | head -1
```

Store result as `PLAN_FILE`. May be empty.

---

## Classification (delegated)

If `PLAN_FILE` exists:

1. Call `h:_classify` internally (ensures classification is stored)
2. Read classification from CLEO:

```bash
FOCUS_ID=$(cleo focus show -q)
cleo show "$FOCUS_ID" 2>/dev/null | grep -oP '\[WORK_CLASSIFICATION\] \K{[^}]*}'
```

Parse JSON fields: `automation_fit`, `ecc`, `type`, `scope`

---

## Output

### Header

```
=== HARNESS ROUTE ===

CLEO Focus: [task id and title]
AI-OPS: Present
Phase: [phase name]
Plan: [Yes/No] [path if yes]
```

### If no plan

```
=== GSD RECOMMENDATION ===
Recommend: gsd:plan-phase
```

### If plan exists

```
=== WORK CLASSIFICATION ===
Type: [type]
Scope: [scope]
Automation: [automation_fit]
ECC: [ecc]

=== GSD RECOMMENDATION ===
Recommend: gsd:execute-phase
```

Then branch on `automation_fit`:

#### automation_fit = forbidden

```
=== AUTOMATION ===
RALPH: Not available for this work type
```

Do not mention h:ralph-init or h:ralph-run.

#### automation_fit = discouraged

```
=== AUTOMATION ===
RALPH: Available with caution
  h:ralph-init [slug] (if bounded subtask identified)
```

#### automation_fit = allowed

```
=== AUTOMATION ===
RALPH: Recommended
  h:ralph-init [slug]
  h:ralph-run (after bundle created)
```

Then branch on `ecc`:

#### ecc = suggested

```
=== ECC ===
Recommend: h:ecc-security-review or h:ecc-code-review
```

#### ecc = optional

```
=== ECC ===
Optional: h:ecc-code-review
```

#### ecc = unnecessary

Do not print ECC section.

---

## Rules

1. Never execute GSD commands
2. Never bypass AI-OPS
3. Never re-classify if classification exists
4. Never explain classification logic
5. If automation_fit=forbidden, RALPH commands are invisible

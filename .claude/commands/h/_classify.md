---
name: h:_classify
description: "Internal: One-time work classification for governed orchestration"
allowed-tools: Read, Grep, Glob, Bash
---

# Internal Classifier

**Not user-callable. Called by h:route only.**

## Execution

### 1. Get phase and plan

```bash
PHASE_DIR=$(grep -oP '(Phase Directory:|Current Phase:)\s*\K.*' .planning/STATE.md 2>/dev/null | head -1)
PLAN_FILE=$(ls ${PHASE_DIR}/*-PLAN.md ${PHASE_DIR}/PLAN.md 2>/dev/null | head -1)
```

If no phase → `NO_PHASE`, exit.
If no plan → `NO_PLAN`, exit.

### 2. Check existing classification

```bash
FOCUS_ID=$(cleo focus show -q 2>/dev/null)
EXISTING=$(cleo show "$FOCUS_ID" 2>/dev/null | grep -oP '\[WORK_CLASSIFICATION\] \K{[^}]*}')
```

If found, extract `plan_hash`. Compute current hash:

```bash
CURRENT_HASH=$(sha256sum "$PLAN_FILE" | cut -d' ' -f1)
```

If hashes match → `CLASSIFICATION_CACHED`, exit.

### 3. Parse explicit automation block (preferred)

Look for YAML block in plan:

```yaml
automation:
  type: conceptual | mechanical | mixed
  scope: bounded | unbounded
  ralph: allowed | discouraged | forbidden
  ecc: suggested | optional | unnecessary
```

```bash
grep -A4 '^automation:' "$PLAN_FILE" 2>/dev/null
```

If block exists and all four fields present:
- `type` = value of `type:`
- `scope` = value of `scope:`
- `automation_fit` = value of `ralph:`
- `ecc` = value of `ecc:`
- `source` = `explicit`

Proceed to step 5.

### 4. Fallback heuristics (only if no explicit block)

Apply gates in order:

**Gate 1: Conceptual → forbidden**
- Pattern: `design|architect|research|evaluate|compare|decide|assess`
- AND no file paths
- Result: `type=conceptual, scope=unbounded, automation_fit=forbidden`

**Gate 2: Unbounded → forbidden**
- Pattern: `as needed|where appropriate|throughout the codebase`
- Result: `type=mixed, scope=unbounded, automation_fit=forbidden`

**Gate 3: Mechanical → allowed**
- Has "Allowed Paths" + "Excluded Paths" sections
- Result: `type=mechanical, scope=bounded, automation_fit=allowed`

**Gate 4: Default → discouraged**
- Result: `type=mixed, scope=bounded, automation_fit=discouraged`

Determine `ecc`:
- Security/auth keywords → `suggested`
- Mechanical + allowed → `unnecessary`
- Else → `optional`

Set `source` = `inferred`

### 5. Persist

```bash
CLASSIFICATION='{"type":"...","scope":"...","automation_fit":"...","ecc":"...","plan_hash":"...","source":"...","decided_at":"..."}'
cleo update "$FOCUS_ID" --notes "[WORK_CLASSIFICATION] $CLASSIFICATION"
```

### 6. Update STATE.md breadcrumb

One line under current phase:

```
- Classification: RALPH [automation_fit] ([type]); ECC [ecc]
```

### 7. Output

```
CLASSIFICATION_STORED
```

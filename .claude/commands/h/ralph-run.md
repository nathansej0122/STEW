---
name: h:ralph-run
description: Output RALPH execution command with preflight checks (does NOT run RALPH inline)
allowed-tools: Read, Grep, Glob, Bash
---

# Harness RALPH Run

You are preparing a RALPH execution. **You do NOT run RALPH inline via Claude tools.** You output the exact command for the user to run in their terminal.

**Planning contract is REQUIRED. CLEO is OPTIONAL.**

## Arguments

Expected arguments via `$ARGUMENTS`:
- `<max_iters>` - Maximum iterations (required)
- `<task-slug>` - Task bundle identifier (required)
- `[--tool claude]` - Optional tool override (default: claude)

Example: `h:ralph-run 5 add-priority-field`

## Gate 0: Planning Contract (REQUIRED)

```bash
MISSING=""
if [ ! -f ".planning/STATE.md" ]; then
  MISSING="$MISSING .planning/STATE.md"
fi
if [ ! -f ".planning/.continue-here.md" ]; then
  MISSING="$MISSING .planning/.continue-here.md"
fi

if [ -n "$MISSING" ]; then
  echo "PLANNING_CONTRACT_MISSING:$MISSING"
else
  echo "PLANNING_CONTRACT_OK"
fi
```

If `PLANNING_CONTRACT_MISSING`:
```
=== RALPH RUN - BLOCKED ===

Missing required planning contract:
$MISSING

Create them using the templates in GREENFIELD.md or BROWNFIELD.md, then rerun.
```
Stop.

## Preflight Validation

Before providing the command, verify:

### 1. Bundle Exists

```bash
ls -la .planning/ralph/[task-slug]/ 2>/dev/null
```

If missing, STOP:
```
=== RALPH RUN - BLOCKED ===

Bundle not found: .planning/ralph/[task-slug]/

Create it first: h:ralph-init [task-slug]
```

### 2. CLEO Status (Optional - informational only)

CLEO is optional. If configured, show status. Do NOT block if not configured.

```bash
if [ -n "${CLEO_PROJECT_DIR:-}" ]; then
  if [ -n "${CLEO_BIN:-}" ]; then
    CLEO_CMD="$CLEO_BIN"
  elif command -v cleo >/dev/null 2>&1; then
    CLEO_CMD="cleo"
  else
    echo "CLEO: Binary not found"
    exit 0
  fi
  if [ -f "$CLEO_PROJECT_DIR/.cleo/todo.json" ]; then
    (cd "$CLEO_PROJECT_DIR" && "$CLEO_CMD" focus show 2>/dev/null) || echo "CLEO: Error"
  else
    echo "CLEO: Not initialized"
  fi
else
  echo "CLEO: Not configured"
fi
```

Report CLEO status but do NOT block execution.

### 3. Clean Git Tree

```bash
git status --porcelain
```

The shim will enforce this, but warn if dirty:
```
WARNING: Uncommitted changes detected. The shim requires a clean tree.
(Untracked files in .planning/ralph/[slug]/ are allowed)
```

### 4. AI-OPS Present

Check for `.planning/AI-OPS.md`. If present, remind user it should be read.

### 5. prd.json Valid

```bash
cat .planning/ralph/[task-slug]/prd.json | head -20
```

Verify it's valid JSON and has required fields.

## Output Format

```
=== RALPH RUN PREFLIGHT ===

Planning Contract: OK
Bundle: .planning/ralph/[task-slug]/
CLEO (optional): [Status or "Not configured"]
Git Status: [Clean or WARNING: dirty]
AI-OPS: [Present or Not found]
prd.json: [Valid or ERROR: invalid]

=== SHIM BEHAVIOR ===

The ralph.sh shim will perform these safety checks:
1. Verify clean working tree (only untracked bundle files allowed)
2. Copy prd.json to repo root for RALPH
3. Restore progress.txt if exists from previous run
4. Execute RALPH with iteration limit
5. After run: copy prd.json and progress.txt back to bundle
6. Write run.log capturing stdout/stderr
7. Show git diff for review

=== EXECUTION COMMAND ===

Run this in your terminal:

./scripts/h/ralph.sh [max_iters] [task-slug] --tool claude

Example with your arguments:

./scripts/h/ralph.sh $MAX_ITERS $TASK_SLUG --tool claude

=== MONITORING ===

Watch progress in another terminal:
  tail -f .planning/ralph/[task-slug]/run.log

Or check RALPH's progress.txt:
  cat ./progress.txt
```

## Safety Reminders

Include in output:
```
=== SAFETY REMINDERS ===

- RALPH will execute code changes autonomously
- Review git diff after each run
- If scope violations occur, stop and review
- NEVER-AUTOMATE paths from AI-OPS are excluded by convention
- The shim limits iterations to prevent runaway execution

To abort mid-run: Ctrl+C
To rollback: git checkout main -- [files] or git reset --hard HEAD~N
```

## Rules

1. **Never run RALPH inline** - Only output the command
2. **Validate bundle exists** - Don't provide command for missing bundle
3. **Show full preflight** - User should see all checks before running
4. **Explain shim behavior** - User should understand what will happen
5. **Include safety info** - How to monitor, abort, rollback

## Important

This command prepares for RALPH execution. The user runs the actual command in their terminal, which invokes the ralph.sh shim script.

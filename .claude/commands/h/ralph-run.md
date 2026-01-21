---
name: h:ralph-run
description: Output RALPH execution command with preflight checks (does NOT run RALPH inline)
allowed-tools: Read, Grep, Glob, Bash
---

# Harness RALPH Run

You are preparing a RALPH execution. **You do NOT run RALPH inline via Claude tools.** You output the exact command for the user to run in their terminal.

**CLEO focus is MANDATORY. STATE.md Pointer is REQUIRED.**

## Arguments

Expected arguments via `$ARGUMENTS`:
- `<max_iters>` - Maximum iterations (required)
- `<task-slug>` - Task bundle identifier (required)
- `[--tool claude]` - Optional tool override (default: claude)

Example: `h:ralph-run 5 add-priority-field`

## Gate 0: CLEO Focus and STATE.md (REQUIRED)

```bash
# === CLEO Auto-Discovery ===
REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
if [ -n "$REMOTE_URL" ]; then
  PROJECT_KEY=$(basename "$REMOTE_URL" .git)
else
  PROJECT_KEY=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
fi
CLEO_STATE_DIR="$HOME/.cleo/projects/$PROJECT_KEY"

# Check CLEO
if command -v cleo >/dev/null 2>&1; then
  CLEO_CMD="cleo"
elif [ -n "${CLEO_BIN:-}" ] && [ -x "$CLEO_BIN" ]; then
  CLEO_CMD="$CLEO_BIN"
else
  echo "CLEO_BINARY: NOT_FOUND"
  exit 1
fi

if [ ! -f "$CLEO_STATE_DIR/.cleo/todo.json" ]; then
  echo "CLEO_INIT: NOT_INITIALIZED"
  exit 1
fi

CLEO_FOCUS=$( (cd "$CLEO_STATE_DIR" && "$CLEO_CMD" focus show --format json 2>/dev/null) || echo '{}')
FOCUS_ID=$(echo "$CLEO_FOCUS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('task',{}).get('id',''))" 2>/dev/null || true)

if [ -z "$FOCUS_ID" ]; then
  echo "CLEO_FOCUS: NO_FOCUS"
  exit 1
fi
echo "CLEO_FOCUS: OK ($FOCUS_ID)"

# Check STATE.md
if [ ! -f ".planning/STATE.md" ]; then
  echo "STATE_MD: MISSING"
  exit 1
fi

POINTER=$(grep -E "^\s*Pointer:" .planning/STATE.md 2>/dev/null | head -1 | sed 's/^[[:space:]]*Pointer:[[:space:]]*//')
if [ -z "$POINTER" ] || echo "$POINTER" | grep -q "^<"; then
  echo "STATE_POINTER: MISSING_OR_PLACEHOLDER"
  exit 1
fi
echo "STATE_POINTER: OK"
```

If any gate fails:
```
=== RALPH RUN - BLOCKED ===

[Specific failure reason]

See h:status for remediation steps.
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

### 2. Clean Git Tree

```bash
git status --porcelain
```

The shim will enforce this, but warn if dirty:
```
WARNING: Uncommitted changes detected. The shim requires a clean tree.
(Untracked files in .planning/ralph/[slug]/ are allowed)
```

### 3. AI-OPS Present

Check for `.planning/AI-OPS.md`. If present, remind user it should be read.

### 4. prd.json Valid

```bash
cat .planning/ralph/[task-slug]/prd.json | head -20
```

Verify it's valid JSON and has required fields.

## Output Format

```
=== RALPH RUN PREFLIGHT ===

CLEO Focus (mandatory): [FOCUS_ID]
STATE.md Pointer: OK
Bundle: .planning/ralph/[task-slug]/
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

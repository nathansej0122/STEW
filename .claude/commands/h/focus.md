---
name: h:focus
description: Enforce CLEO as SST for active task; guide user to set focus if missing
allowed-tools: Read, Grep, Glob, Bash
---

# Harness Focus Management

You are enforcing the rule: **CLEO is the Single Source of Truth (SST) for the active task.**

**CLEO project state is EXTERNAL to repos.** CLEO state lives in a directory specified by
`CLEO_PROJECT_DIR`, not in the project repository. Project repos must NOT contain `.cleo/`.

## Check Current Focus

Run:
```bash
# CLEO requires CLEO_PROJECT_DIR to be set (external state directory)
if [ -z "${CLEO_PROJECT_DIR:-}" ]; then
  echo "CLEO_NOT_CONFIGURED"
else
  # Resolve CLEO binary
  if [ -n "${CLEO_BIN:-}" ]; then
    CLEO_CMD="$CLEO_BIN"
  elif command -v cleo >/dev/null 2>&1; then
    CLEO_CMD="cleo"
  else
    echo "CLEO_BINARY_NOT_FOUND"
    exit 0
  fi

  # Run CLEO from the external project state directory
  if [ -f "$CLEO_PROJECT_DIR/.cleo/todo.json" ]; then
    (cd "$CLEO_PROJECT_DIR" && "$CLEO_CMD" focus show 2>/dev/null) || echo "CLEO_FOCUS_ERROR"
  else
    echo "CLEO_NOT_INITIALIZED"
  fi
fi
```

## If CLEO Not Configured

Output:
```
=== HARNESS FOCUS ===

CLEO not configured.

CLEO project state is EXTERNAL to project repositories.
To configure CLEO for this project:

  export CLEO_PROJECT_DIR=~/tooling/native/cleo/projects/<your-project>

The directory must contain initialized CLEO state (.cleo/todo.json).

NOTE: Do NOT run `cleo init` inside the project repository.
```

## If CLEO Binary Not Found

Output:
```
=== HARNESS FOCUS ===

ERROR: CLEO binary not available.

To configure CLEO binary:
  - Add cleo to your PATH
  - Or set CLEO_BIN to point to the cleo binary

CLEO is required for task coordination.
```

## If CLEO Not Initialized

Output:
```
=== HARNESS FOCUS ===

CLEO project state not initialized.

The directory $CLEO_PROJECT_DIR does not contain CLEO state.

To initialize (run from the EXTERNAL state directory, NOT the project repo):
  cd $CLEO_PROJECT_DIR
  cleo init

NOTE: Do NOT run `cleo init` inside the project repository.
```

## If No Focused Task

Output:
```
=== HARNESS FOCUS ===

No task currently focused.

To set a focused task (from CLEO_PROJECT_DIR):
  1. (Optional) List available tasks:
     (cd $CLEO_PROJECT_DIR && cleo list)

  2. Set focus on a task:
     (cd $CLEO_PROJECT_DIR && cleo focus set T###)

The harness requires a focused CLEO task before routing to GSD execution.
```

## If Focused Task Exists

Output:
```
=== HARNESS FOCUS ===

Active Task: T### - [Task Title]
Status: [Task Status from CLEO]

You are focused. The harness recognizes this as the current work item.

=== OPTIONAL GUIDANCE ===

For next-step suggestions from CLEO (run from CLEO_PROJECT_DIR):
  (cd $CLEO_PROJECT_DIR && cleo next --explain)

To proceed with GSD coordination:
  h:route

To change focus (run from CLEO_PROJECT_DIR):
  (cd $CLEO_PROJECT_DIR && cleo focus set T###)
```

## Rules

1. **CLEO is SST**: The focused task in CLEO determines what work is being done.
2. **No overrides**: The harness does not set focus itself; it guides the user.
3. **Read-only**: This command only reads state; it does not modify CLEO.
4. **External state**: CLEO project state lives in `$CLEO_PROJECT_DIR`, not in the project repo.

## Important

- Never run `cleo focus set` automatically
- Never run GSD commands
- Only provide recommendations for the user to execute
- **NEVER recommend `cleo init` inside the project repository**

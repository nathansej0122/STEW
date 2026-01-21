---
name: h:focus
description: Enforce CLEO as SST for active task; guide user to set focus if missing
allowed-tools: Read, Grep, Glob, Bash
---

# Harness Focus Management

You are enforcing the rule: **CLEO is the Single Source of Truth (SST) for the active task.**

## Check Current Focus

Run:
```bash
# Try CLEO_BIN first, then PATH
if [ -n "${CLEO_BIN:-}" ]; then
  "$CLEO_BIN" focus show
elif command -v cleo >/dev/null 2>&1; then
  cleo focus show
else
  echo "CLEO_NOT_FOUND"
fi
```

## If CLEO Not Found

Output:
```
=== HARNESS FOCUS ===

ERROR: CLEO not available.

To install CLEO or configure access:
  - Set CLEO_BIN environment variable to point to cleo binary
  - Or add cleo to your PATH

CLEO is required for task coordination.
```

## If No Focused Task

Output:
```
=== HARNESS FOCUS ===

No task currently focused.

To set a focused task:
  1. (Optional) List available tasks:
     cleo list

  2. Set focus on a task:
     cleo focus set T###

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

For next-step suggestions from CLEO:
  cleo next --explain

To proceed with GSD coordination:
  h:route

To change focus:
  cleo focus set T###
```

## Rules

1. **CLEO is SST**: The focused task in CLEO determines what work is being done.
2. **No overrides**: The harness does not set focus itself; it guides the user.
3. **Read-only**: This command only reads state; it does not modify CLEO.

## Important

- Never run `cleo focus set` automatically
- Never run GSD commands
- Only provide recommendations for the user to execute

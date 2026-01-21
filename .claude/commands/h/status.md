---
name: h:status
description: Read-only overview of current coordination state (planning contract, git status, optional CLEO)
allowed-tools: Read, Grep, Glob, Bash
---

<!-- FENCE CHECK: If output appears garbled, verify this file has balanced markdown fences. -->
<!-- Each "Run:" section must contain exactly ONE fenced bash block. -->

# Harness Status Check

You are performing a read-only status check for the coordination overlay.

## Run: Consolidated Status Check

Execute this single Bash block to gather all status information:

```bash
# --- Planning Contract Check ---
MISSING=""
[ ! -f ".planning/STATE.md" ] && MISSING="$MISSING .planning/STATE.md"
[ ! -f ".planning/.continue-here.md" ] && MISSING="$MISSING .planning/.continue-here.md"

if [ -n "$MISSING" ]; then
  echo "PLANNING_CONTRACT: MISSING$MISSING"
else
  echo "PLANNING_CONTRACT: OK"
fi

# --- Planning Focus ---
echo ""
echo "CONTINUE_HERE_CONTENTS:"
if [ -f ".planning/.continue-here.md" ]; then
  cat ".planning/.continue-here.md"
else
  echo "(file missing)"
fi

# --- Git Status ---
echo ""
echo "GIT_BRANCH: $(git branch --show-current 2>/dev/null || echo 'unknown')"
PORCELAIN=$(git status --porcelain 2>/dev/null)
if [ -z "$PORCELAIN" ]; then
  echo "GIT_STATUS: Clean"
else
  echo "GIT_STATUS: $(echo "$PORCELAIN" | wc -l | tr -d ' ') uncommitted changes"
fi

# --- AI-OPS Documents ---
echo ""
[ -f ".planning/AI-OPS.md" ] && echo "AI_OPS_MD: Present - READ REQUIRED" || echo "AI_OPS_MD: Missing"
[ -f ".planning/AI-OPS-KNOWLEDGE.md" ] && echo "AI_OPS_KNOWLEDGE_MD: Present" || echo "AI_OPS_KNOWLEDGE_MD: Missing"
[ -f ".planning/LOCKED_BEHAVIOR_CANDIDATES.md" ] && echo "LOCKED_BEHAVIOR_MD: Present" || echo "LOCKED_BEHAVIOR_MD: Missing"

# --- Planning Infrastructure ---
echo ""
[ -f ".planning/STATE.md" ] && echo "STATE_MD: Present" || echo "STATE_MD: Missing"
[ -f ".planning/.continue-here.md" ] && echo "CONTINUE_HERE_MD: Present" || echo "CONTINUE_HERE_MD: Missing"
[ -f ".planning/ROADMAP.md" ] && echo "ROADMAP_MD: Present" || echo "ROADMAP_MD: Missing"
[ -f ".planning/PROJECT.md" ] && echo "PROJECT_MD: Present" || echo "PROJECT_MD: Missing"

# --- CLEO Status (Optional) ---
echo ""
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
    CLEO_OUT=$( (cd "$CLEO_PROJECT_DIR" && "$CLEO_CMD" focus show 2>/dev/null) || echo "FOCUS_ERROR")
    echo "CLEO: $CLEO_OUT"
  else
    echo "CLEO: Not initialized"
  fi
else
  echo "CLEO: Not configured"
fi
```

## Interpretation

If `PLANNING_CONTRACT: MISSING` appears in output, show this block message and stop:

```
=== HARNESS STATUS - BLOCKED ===

Missing required planning contract.

To create the missing files now, run: h:bootstrap

Or create them manually using templates below, then rerun h:status.

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

## Output Format

Provide a summary in this exact structure:

```
=== HARNESS STATUS ===

Planning Contract: [OK] or [MISSING - see above]
Planning Focus: [pointer from .continue-here.md]
Git Status: [Clean] or [Uncommitted changes: X files]
Branch: [branch-name]

AI-OPS Documents (optional):
  - AI-OPS.md: [Present - READ REQUIRED] or [Missing]
  - LOCKED_BEHAVIOR_CANDIDATES.md: [Present] or [Missing]

CLEO (optional): [Status or "Not configured"]

=== RECOMMENDED NEXT COMMAND ===
[Recommendation based on state]
```

## Recommendation Logic

1. If planning contract missing: show block message with templates (do NOT proceed)
2. If planning contract OK: recommend `h:focus` to see current work pointer
3. If AI-OPS.md present: remind user it must be read before work
4. If ready to work: recommend `h:route`

## Important

- This is READ-ONLY. Do not modify any files.
- Do not execute GSD commands; only check status.
- Planning contract is REQUIRED; CLEO is OPTIONAL.
- If AI-OPS.md exists, emphasize it must be read before proceeding.

---
name: h:ralph-init
description: Initialize a bounded RALPH task bundle in the target repo
allowed-tools: Read, Grep, Glob, Bash, Write
---

# Harness RALPH Init

You are creating a bounded task bundle for RALPH execution in the **target repo** (not this overlay repo).

## Arguments

The user should provide:
- `$ARGUMENTS` - The task slug (e.g., "add-priority-field")

If no slug provided, ask for one.

## Bundle Structure

Create the following in the TARGET repo:
```
.planning/ralph/<task-slug>/
  PRD.md
  prd.json
  RUNBOOK.md
```

## PRD.md Template

```markdown
# RALPH Task: [Task Title]

CLEO focus expected: T### (set via `cleo focus set T###`)

## Overview

[Brief description of what this bounded task will accomplish]

## Scope

### Allowed Paths
- [path/to/modify/]
- [another/path/]

### Excluded Paths (NEVER modify)
- [sensitive/path/]
- [config/that/shouldnt/change/]

## Success Criteria

- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Verification Commands

```bash
[command to verify success]
```

## Notes

[Any additional context for RALPH execution]
```

## prd.json Template

Reference format from: `~/tooling/native/ralph/prd.json.example`

Create a valid prd.json:
```json
{
  "project": "[Project Name]",
  "branchName": "ralph/[task-slug]",
  "description": "[Task description]",
  "userStories": [
    {
      "id": "US-001",
      "title": "[First user story title]",
      "description": "[As a..., I want..., so that...]",
      "acceptanceCriteria": [
        "[Criterion 1]",
        "[Criterion 2]",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

## RUNBOOK.md Template

```markdown
# RALPH Runbook: [task-slug]

## Pre-flight Checklist

- [ ] CLEO focus set: `cleo focus set T###`
- [ ] Clean git tree (run `git status`)
- [ ] AI-OPS.md read and understood
- [ ] Branch created: `git checkout -b ralph/[task-slug]`

## Scope Boundaries

### Allowed
- [List specific files/directories RALPH may modify]

### Excluded (NEVER-AUTOMATE)
- [List files/directories RALPH must not touch]

## Verification Commands

After each iteration, verify:
```bash
[typecheck command]
[lint command]
[test command]
```

## Rollback

If something goes wrong:
```bash
git checkout main -- [affected files]
# or
git reset --hard HEAD~1
```

## Execution

Run via harness:
```bash
h:ralph-run [max_iters] [task-slug]
```

Or manually:
```bash
./scripts/h/ralph.sh [max_iters] [task-slug] --tool claude
```
```

## Interaction Flow

1. Ask user for task details:
   - Task slug (identifier)
   - Task description
   - Allowed paths
   - Excluded paths
   - User stories / acceptance criteria
   - Verification commands

2. Check if bundle already exists:
   ```bash
   ls -la .planning/ralph/[task-slug]/ 2>/dev/null
   ```

3. Create the bundle directory and files

4. Confirm creation with next steps

## Output Format

```
=== RALPH BUNDLE CREATED ===

Location: .planning/ralph/[task-slug]/

Files created:
  - PRD.md (human-readable spec)
  - prd.json (RALPH-parseable spec)
  - RUNBOOK.md (execution checklist)

=== NEXT STEPS ===

1. Review and edit the bundle files as needed
2. Set CLEO focus: cleo focus set T###
3. Create branch: git checkout -b ralph/[task-slug]
4. Run: h:ralph-run [max_iters] [task-slug]
```

## Rules

1. **Require scope boundaries** - Must define allowed AND excluded paths
2. **Include verification** - Must have commands to verify success
3. **CLEO pointer** - Include CLEO focus expectation (not as SST, just reference)
4. **Valid JSON** - prd.json must be valid and match RALPH format
5. **Target repo only** - Create bundle in user's repo, not this overlay

## Important

This creates the task definition. Execution happens via h:ralph-run.

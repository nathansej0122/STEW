# Architecture

This document describes the coordination overlay kit architecture, authority boundaries, and how it differs from previous approaches.

## Overview

The Coordination Overlay Kit ("harness") is a clean-break coordination layer that sits **on top of** native tools without overriding or duplicating them.

```
┌─────────────────────────────────────────────────────────────┐
│                    USER INTERFACE                            │
│                  (Claude Code CLI)                           │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              PLANNING CONTRACT (REQUIRED)                    │
│                                                              │
│  .planning/STATE.md         Current work pointer + status    │
│  .planning/.continue-here.md  Resume pointer for sessions    │
│                                                              │
│  This is Gate 0. ALL harness commands require it.            │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              HARNESS COORDINATION LAYER                      │
│                                                              │
│  h:status   h:focus   h:route   h:ecc-*   h:ralph-*         │
│                                                              │
│  • Read-only state analysis                                  │
│  • Recommendations (no execution)                            │
│  • RALPH shim (only executable automation)                   │
└─────────────────────────────────────────────────────────────┘
                           │
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
┌─────────────────┐ ┌─────────────┐ ┌─────────────────┐
│     GSD         │ │     ECC     │ │  CLEO (Optional)│
│  (Execution)    │ │ (Review)    │ │  (Task Tracking)│
└─────────────────┘ └─────────────┘ └─────────────────┘
           │
           ▼
┌─────────────────┐
│     RALPH       │
│ (Autonomous)    │
└─────────────────┘
```

## Authority Split

### Planning Contract: Gate 0 (REQUIRED)

- **Authority**: Work pointer and session continuity
- **Files**: `.planning/STATE.md` + `.planning/.continue-here.md`
- **Harness role**: Gate 0 check; all commands block without it
- **Rule**: Planning contract determines where work resumes

The planning contract is the **only hard gate** for routing. Without it, harness commands fail with explicit instructions.

### CLEO: Task Tracking (OPTIONAL)

- **Authority**: Task identity, status, focus (when configured)
- **Harness role**: Query only; informational status
- **Commands**: `cleo focus show`, `cleo list`, `cleo next`
- **Location**: External to project repo (via `CLEO_PROJECT_DIR`)
- **Rule**: CLEO is informational; planning contract gates routing

CLEO is optional. If `CLEO_PROJECT_DIR` is not set, harness reports "Not configured" and continues without blocking.

### GSD: Execution Governance

- **Authority**: Planning and execution phases, validation
- **Harness role**: Recommend GSD commands; never executes them
- **Commands recommended**: `gsd:plan-phase`, `gsd:execute-phase`, `gsd:verify-work`
- **Rule**: User runs GSD commands manually after h:route recommendation

### ECC: Code Review Agents

- **Authority**: Review criteria, agent specifications
- **Harness role**: Load ECC agent specs and apply them (read-only analysis)
- **Agents**: code-reviewer, security-reviewer, doc-updater, refactor-cleaner
- **Rule**: Harness provides findings; user implements fixes

### RALPH: Bounded Autonomous Execution

- **Authority**: Autonomous iteration on defined PRD
- **Harness role**: Create bundles, provide shim with safety gates
- **Rule**: RALPH only runs via shim script with explicit user action

## Non-Collision Rules

The harness guarantees no collision with native tools:

| Rule | Implementation |
|------|----------------|
| No `gsd:*` commands | Harness uses `h:*` namespace exclusively |
| No `ct:*` commands | Harness uses `h:*` namespace exclusively |
| No `set-profile` | Not created in harness |
| No native file copying | Native tools referenced by path, not vendored |
| No execution of GSD | Harness only recommends; user executes |

### Namespace

All harness commands use the `h:` prefix:

- `h:status` - Status overview
- `h:focus` - Focus management
- `h:route` - Coordination routing
- `h:ecc-*` - ECC agent wrappers
- `h:ralph-*` - RALPH bundle management

## Data Flow

### Read-Only Commands

Most harness commands are read-only:

```
h:status
    │
    ├─► Gate 0: Check .planning/STATE.md + .continue-here.md (REQUIRED)
    │       └─► If missing: BLOCK with explicit instructions
    │
    ├─► Read planning focus from .continue-here.md
    ├─► git status --porcelain (read)
    ├─► check .planning/*.md (read)
    └─► cleo focus show (OPTIONAL, if CLEO_PROJECT_DIR set)
    │
    ▼
    Formatted output + recommendation
```

### RALPH Flow (Write Path)

RALPH is the only automated write path, gated by the shim:

```
h:ralph-init
    │
    └─► Creates .planning/ralph/<slug>/ bundle
        (PRD.md, prd.json, RUNBOOK.md)

h:ralph-run
    │
    └─► Outputs command for user to run

scripts/h/ralph.sh (user executes)
    │
    ├─► Verify clean tree
    ├─► Copy bundle to RALPH locations
    ├─► Execute native RALPH
    ├─► Copy results back to bundle
    └─► Show diff for review
```

## File Structure

### Harness Files (this overlay)

```
coordination-overlay-kit/
├── .claude/commands/h/
│   ├── status.md
│   ├── focus.md
│   ├── route.md
│   ├── _classify.md          # Internal: work classification helper
│   ├── ecc-code-review.md
│   ├── ecc-security-review.md
│   ├── ecc-doc-update.md
│   ├── ecc-refactor-clean.md
│   ├── ralph-init.md
│   └── ralph-run.md
├── scripts/h/
│   └── ralph.sh
├── docs/
│   ├── INSTALL.md
│   └── ARCHITECTURE.md
└── install.sh
```

### Target Repo (after install)

```
your-repo/
├── .claude/commands/h/     # Installed by harness
│   └── *.md
├── scripts/h/              # Installed by harness
│   └── ralph.sh
├── scripts/ralph/          # Created by shim on first RALPH run
│   ├── ralph.sh           # Copied from native
│   └── CLAUDE.md          # Copied from native
├── .planning/
│   ├── STATE.md           # REQUIRED - Current work pointer
│   ├── .continue-here.md  # REQUIRED - Resume pointer for sessions
│   ├── HARNESS_STATE.json # Classification cache (auto-created)
│   ├── AI-OPS.md          # Optional - Operational constraints
│   ├── ROADMAP.md         # Optional - Project roadmap
│   ├── phases/            # GSD-managed
│   │   └── phase-N/
│   │       └── PLAN.md
│   └── ralph/             # Created by h:ralph-init
│       └── <task-slug>/
│           ├── PRD.md
│           ├── prd.json
│           ├── RUNBOOK.md
│           ├── progress.txt  # After runs
│           └── run.log       # After runs
└── prd.json               # Temp file during RALPH run
```

**Note**: CLEO state is stored externally (via `CLEO_PROJECT_DIR`), NOT in the project repo.

## Comparison with Previous Approaches

### What Changed

| Aspect | Old Approach | Harness V1 |
|--------|--------------|------------|
| Command namespace | Mixed gsd/ct/custom | Unified h:* |
| GSD integration | Executed GSD inline | Recommend only |
| Tool vendoring | Copied native code | Reference by path |
| RALPH safety | Ad-hoc | Shim with gates |
| State authority | Ambiguous | Planning contract is required gate; CLEO optional |
| Classification storage | Various | HARNESS_STATE.json |

### Why Clean Break

1. **No namespace collision** - `h:*` won't conflict with future GSD/CLEO updates
2. **Clear boundaries** - Harness coordinates, natives execute
3. **Safer RALPH** - Explicit shim with preflight checks
4. **Maintainable** - Native tools update independently

## Safety Model

### Read-Only by Default

Commands marked with `allowed-tools: Read, Grep, Glob, Bash` can only:
- Read files
- Search files
- Run read-only shell commands (git status, cleo show, etc.)

### Write Gates

Only two write paths exist:

1. **h:ralph-init** - Creates bundle files (explicit user request)
2. **scripts/h/ralph.sh** - Runs RALPH (explicit user execution)

### RALPH Safety Gates

The shim enforces:
1. Clean working tree (no uncommitted changes outside bundle)
2. Bundle must exist with valid prd.json
3. Iteration limit
4. Results copied back for review
5. Diff shown after completion

## Governed Orchestration

Classification-first layer determining ECC/RALPH availability.

### Automation Intent is Declared in Plans

Each phase plan includes an explicit governance block:

```yaml
automation:
  type: conceptual | mechanical | mixed
  scope: bounded | unbounded
  ralph: allowed | discouraged | forbidden
  ecc: suggested | optional | unnecessary
```

This is governance metadata, not prose. When present, no heuristics are used.

Plans without this block are classified once automatically using fallback heuristics, then persisted. The harness never guesses twice.

### How It Works

1. **Gate 0 always first** - All commands check planning contract before proceeding
2. **Classification runs once** - `h:_classify` parses explicit block or infers once
3. **HARNESS_STATE.json stores decisions** - Classification persisted in `.planning/HARNESS_STATE.json`
4. **Routing reads only** - `h:route` branches on persisted values, never re-reasons

### Persisted Object

```json
{"type":"...","scope":"...","automation_fit":"...","ecc":"...","plan_hash":"...","source":"explicit|inferred","decided_at":"..."}
```

### Routing Behavior

| automation_fit | RALPH |
|----------------|-------|
| forbidden | Not shown |
| discouraged | Available with caution |
| allowed | Recommended |

| ecc | ECC |
|-----|-----|
| suggested | Recommend |
| optional | Mention |
| unnecessary | Silent |

## Extension Points

### Adding New ECC Agents

1. Create new agent spec in ECC repository
2. Add corresponding `h:ecc-<agent>.md` in harness
3. Reference native spec path

### Adding New Coordination Commands

1. Create `.claude/commands/h/<command>.md`
2. Use `h:` prefix in name
3. Mark appropriate allowed-tools
4. Follow read-only-first principle

### Integrating New Tools

1. Add tool as external dependency (not vendored)
2. Create harness command that references it
3. Document in INSTALL.md

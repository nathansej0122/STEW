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
│      CLEO       │ │     GSD     │ │      ECC        │
│  (Task SST)     │ │ (Execution) │ │ (Review Agents) │
└─────────────────┘ └─────────────┘ └─────────────────┘
           │
           ▼
┌─────────────────┐
│     RALPH       │
│ (Autonomous)    │
└─────────────────┘
```

## Authority Split

### CLEO: Single Source of Truth for Tasks

- **Authority**: Task identity, status, focus
- **Harness role**: Query only; never modifies CLEO state
- **Commands**: `cleo focus show`, `cleo list`, `cleo next`
- **Rule**: Focused CLEO task determines what work is being done

### GSD: Execution Governance

- **Authority**: Planning and execution phases, validation
- **Harness role**: Recommend GSD commands; never executes them
- **Commands recommended**: `gsd:plan-phase`, `gsd:execute-phase`, `gsd:validate-phase`
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
    ├─► cleo focus show (read)
    ├─► git status --porcelain (read)
    └─► check .planning/*.md (read)
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
│   ├── AI-OPS.md          # User-created (recommended)
│   ├── STATE.md           # GSD-managed
│   ├── ROADMAP.md         # GSD-managed
│   └── ralph/             # Created by h:ralph-init
│       └── <task-slug>/
│           ├── PRD.md
│           ├── prd.json
│           ├── RUNBOOK.md
│           ├── progress.txt  # After runs
│           └── run.log       # After runs
└── prd.json               # Temp file during RALPH run
```

## Comparison with Previous Approaches

### What Changed

| Aspect | Old Approach | Harness V1 |
|--------|--------------|------------|
| Command namespace | Mixed gsd/ct/custom | Unified h:* |
| GSD integration | Executed GSD inline | Recommend only |
| Tool vendoring | Copied native code | Reference by path |
| RALPH safety | Ad-hoc | Shim with gates |
| State authority | Ambiguous | CLEO is SST |

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

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
│                 CLEO FOCUS (MANDATORY)                       │
│                                                              │
│  External state: ~/.cleo/projects/$PROJECT_KEY/              │
│  Auto-discovered from git remote or repo basename            │
│                                                              │
│  This is Gate 0. ALL harness commands require it.            │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              PLANNING CONTRACT (REQUIRED)                    │
│                                                              │
│  .planning/STATE.md         Pointer line = work location     │
│                                                              │
│  This is Gate 1. Commands need valid Pointer to proceed.     │
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
│     GSD         │ │     ECC     │ │     RALPH       │
│  (Execution)    │ │ (Review)    │ │  (Autonomous)   │
└─────────────────┘ └─────────────┘ └─────────────────┘
```

## Authority Split

### CLEO: Task Identity (MANDATORY)

- **Authority**: Task identity, status, focus
- **Harness role**: Gate 0 check; all commands block without it
- **Commands**: `cleo focus show`, `cleo list`, `cleo next`
- **Location**: External to project repo (`~/.cleo/projects/$PROJECT_KEY/`)
- **Rule**: CLEO focus is the single source of truth for "what is active"

CLEO is mandatory. If CLEO is not initialized or no focus is set, harness commands hard-fail with explicit instructions.

**Auto-Discovery**: PROJECT_KEY is derived from git remote origin basename (without .git) or repo directory basename. No environment variables required.

### Planning Contract: Gate 1 (REQUIRED)

- **Authority**: Work location (where is the plan)
- **File**: `.planning/STATE.md` with Pointer line
- **Harness role**: Gate 1 check; commands block without valid Pointer
- **Rule**: STATE.md Pointer determines where work files are located

The Pointer line in STATE.md is the single source of truth for "where is the plan."

**Note**: `.planning/.continue-here.md` is deprecated and not part of the contract.

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
    ├─► Gate 0: Check CLEO focus (MANDATORY)
    │       └─► If missing: BLOCK with explicit instructions
    │
    ├─► Gate 1: Check STATE.md Pointer (REQUIRED)
    │       └─► If missing/placeholder: BLOCK with explicit instructions
    │
    ├─► Read git status (read)
    ├─► Check .planning/*.md (presence only)
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
│   ├── STATE.md           # REQUIRED - Pointer line = work location
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

**Note**: CLEO state is stored externally (`~/.cleo/projects/$PROJECT_KEY/`), NOT in the project repo.

**Note**: `.continue-here.md` is deprecated. If present in a repo, commands will warn to delete it.

## Comparison with Previous Approaches

### What Changed

| Aspect | Old Approach | Harness V2 |
|--------|--------------|------------|
| Command namespace | Mixed gsd/ct/custom | Unified h:* |
| GSD integration | Executed GSD inline | Recommend only |
| Tool vendoring | Copied native code | Reference by path |
| RALPH safety | Ad-hoc | Shim with gates |
| CLEO | Optional | **Mandatory** |
| State authority | .continue-here.md | CLEO focus + STATE.md Pointer |
| Classification storage | Various | HARNESS_STATE.json |
| Env vars | CLEO_PROJECT_DIR required | Auto-discovery, no vars needed |

### Why Clean Break

1. **No namespace collision** - `h:*` won't conflict with future GSD/CLEO updates
2. **Clear boundaries** - Harness coordinates, natives execute
3. **Safer RALPH** - Explicit shim with preflight checks
4. **Maintainable** - Native tools update independently
5. **Deterministic** - CLEO state location auto-discovered, not configured

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

1. **Gate 0 always first** - All commands check CLEO focus before proceeding
2. **Gate 1 second** - All commands check STATE.md Pointer
3. **Classification runs once** - `h:_classify` parses explicit block or infers once
4. **HARNESS_STATE.json stores decisions** - Classification persisted in `.planning/HARNESS_STATE.json`
5. **Routing reads only** - `h:route` branches on persisted values, never re-reasons

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

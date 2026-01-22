# COMMANDS — STEW Command Reference

This document is a **reference**, not a tutorial.

It explains every `h:*` command provided by **STEW**, what it does, and when you should (and should not) use it.

If you are new, read **CONCEPTS.md** and **GREENFIELD.md** first.

---

## Command Namespace Rules

All STEW commands:
- use the `h:` prefix
- live in `.claude/commands/h/`
- are **read-only by default**

STEW commands never:
- execute GSD automatically
- modify project code
- override governance

If a command would cause side effects, it will say so explicitly.

---

## Single Source of Truth

| Question | Answer Source |
|----------|---------------|
| What is active? | CLEO focus (mandatory) |
| Where is work located? | STATE.md Pointer |
| What should happen? | GSD plans |
| What is allowed? | Governance rules |

CLEO focus is **mandatory**. STATE.md Pointer is **required**.

---

## CLEO State Auto-Discovery

CLEO project state is stored externally in `$HOME/.cleo/projects/$PROJECT_KEY/`.

**PROJECT_KEY** is derived automatically:
1. If git remote origin exists: basename of remote URL without `.git`
2. Otherwise: basename of repository directory

**No environment variables required.** CLEO state location is deterministic.

### Example

```
Repository: ~/projects/my-app
Git remote: git@github.com:user/my-app.git
PROJECT_KEY: my-app
CLEO_STATE_DIR: ~/.cleo/projects/my-app
```

---

## h:init

### Purpose

**The canonical first step.** One-command bootstrap for the entire coordination stack.

Run `h:init` when any harness command blocks. It handles everything.

### What it does

1. Derives PROJECT_KEY from git remote or repo basename
2. Creates CLEO state directory (`~/.cleo/projects/$PROJECT_KEY/`)
3. Runs `cleo init` if not already initialized
4. Creates an initial task and sets focus (if needed)
5. Normalizes STATE.md Pointer (if STATE.md exists)

### What it requires

- CLEO binary on PATH (or `CLEO_BIN` set)

### What it does *not* require

- No flags
- No environment variables
- No manual directory creation
- No separate commands for different fixes

### When to use

Run `h:init` when any harness command blocks with:
- `CLEO_INIT: NOT_INITIALIZED`
- `CLEO_FOCUS: NO_FOCUS`
- `STATE_POINTER: MISSING_OR_PLACEHOLDER`

### Idempotent

Safe to run multiple times. Reports current state without changes if already configured.

### Output

```
PROJECT_KEY: my-app
CLEO_STATE_DIR: ~/.cleo/projects/my-app

INIT_CLEO: Initialized | Already initialized
INIT_FOCUS: Set | Already set
INIT_STATE_POINTER: Updated | Already compliant | Manual fix required

NEXT: Run h:status
```

### Graceful Degradation

If STATE.md does not exist, CLEO still initializes and focus is still set. The command will warn about missing STATE.md and recommend creating it.

---

## h:cleo-init

### Purpose

**CLEO-only bootstrap command.** Initializes CLEO for the current repository.

**Prefer `h:init` instead** - it does everything `h:cleo-init` does plus STATE.md normalization.

### What it does

1. Derives PROJECT_KEY from git remote or repo basename
2. Creates CLEO state directory (`~/.cleo/projects/$PROJECT_KEY/`)
3. Runs `cleo init` if not already initialized
4. Creates an initial task (title derived from repo name + STATE.md pointer if present)
5. Sets focus to the created task

### What it requires

- CLEO binary on PATH (or `CLEO_BIN` set)

### What it does *not* require

- No flags
- No environment variables
- No manual directory creation

### When to use

**Prefer `h:init` instead.** Use `h:cleo-init` only if you want CLEO initialization without STATE.md normalization.

### Idempotent

Safe to run multiple times. If CLEO is already initialized and focused, reports current state without changes.

### Output

```
PROJECT_KEY: my-app
CLEO_STATE_DIR: ~/.cleo/projects/my-app

RESULT_INIT: Initialized | Already initialized
RESULT_FOCUS: Focus set | Focus already set

=== CLEO INITIALIZED ===
FOCUS: T001 - Work on my-app
```

---

## h:state-normalize

### Purpose

**STATE.md normalization command.** Ensures STATE.md has a valid `Pointer:` line.

**Prefer `h:init` instead** - it does everything `h:state-normalize` does plus CLEO initialization.

### What it does

1. Checks if `.planning/STATE.md` exists (blocks if missing)
2. Checks if a valid `Pointer:` line already exists (compliant)
3. If not, derives Pointer from legacy STATE.md formats:
   - `Resume file:` line (handles `.continue-here.md` references)
   - `Phase Directory:` line
   - `Current Phase:` line
4. Updates STATE.md with the derived Pointer

### What it requires

- `.planning/STATE.md` must exist

### When to use

**Prefer `h:init` instead.** Use `h:state-normalize` only if you want STATE.md normalization without CLEO initialization.

### Idempotent

Safe to run multiple times. If Pointer already valid, reports "Already compliant" without changes.

### Output

```
DERIVATION_SOURCE: Resume file | Phase Directory | Current Phase
DERIVED_POINTER: .planning/phases/phase-1/PLAN.md

RESULT: Updated | Already compliant | Blocked
```

---

## h:status

### Purpose

Displays the **current coordination state** across all tools.

### Gates (all required)

1. **CLEO binary** - Must be available
2. **CLEO initialized** - `~/.cleo/projects/$PROJECT_KEY/.cleo/todo.json` must exist
3. **CLEO focus** - A task must be focused
4. **STATE.md** - `.planning/STATE.md` must exist
5. **STATE.md Pointer** - Must contain a valid `Pointer:` line

### What it reads
- CLEO focus (mandatory)
- STATE.md Pointer line (work location)
- git working tree status
- AI-OPS documents (presence check only)

### What it never does
- modify files
- change focus
- execute tools

### Blocked Outputs

If CLEO not initialized or no focus set:
```
=== HARNESS STATUS - BLOCKED ===

CLEO not initialized for this project.

Run: h:init

This will automatically initialize CLEO, set focus, and normalize STATE.md.
```

If STATE.md Pointer missing:
```
=== HARNESS STATUS - BLOCKED ===

STATE.md Pointer is missing or contains placeholder.

Run: h:init

This will attempt to derive Pointer from legacy STATE.md formats.
```

---

## h:focus

### Purpose

Displays the **current focus** from CLEO and STATE.md Pointer.

### What it does
- Shows CLEO focus task (id, title, status, description)
- Shows STATE.md Pointer (work location)
- Indicates whether pointer file/directory exists

### Gates (all required)
- CLEO binary available
- CLEO initialized
- CLEO focus set
- STATE.md exists
- STATE.md Pointer valid

### What it does *not* do
- Create or modify planning files

### Why it exists

CLEO focus answers "What task?" and STATE.md Pointer answers "Where is the plan?"

---

## h:route

### Purpose

This is the **core STEW command**.

It determines the **single next allowed action** based on current state.

### What it does
1. Verifies CLEO focus (mandatory)
2. Reads STATE.md Pointer (work location)
3. Checks AI-OPS (optional)
4. Determines current phase
5. Detects plans
6. Ensures classification is persisted (to HARNESS_STATE.json)
7. Recommends exactly one next command

### What it never does
- execute GSD
- run ECC
- invoke RALPH

### Output guarantees
- deterministic
- repeatable
- inspectable

If `h:route` output changes, state has changed.

---

## h:_classify (Internal)

### Purpose

Performs **one-time work classification** for a plan.

### Visibility

- **Not user-callable**
- Invoked only by `h:route`

### What it does
- determines work type and scope
- decides whether automation is allowed
- decides whether review is useful
- persists the result to HARNESS_STATE.json

### Why it matters

This is the mechanism that prevents repeated AI reasoning and token waste.

---

## h:ecc-code-review

### Purpose

Runs a **read-only code review** using ECC agent specifications.

### Preconditions
- recent code changes exist
- STEW recommends or allows review

### What it reads
- ECC agent spec from native tool directory
- git diffs
- AI-OPS constraints

### What it never does
- modify code
- apply fixes

---

## h:ecc-security-review

### Purpose

Runs a **security-focused** review using ECC.

### When it appears
- security-sensitive changes
- high-risk zones defined in AI-OPS

This command may not always be suggested.

---

## h:ecc-doc-update

### Purpose

Identifies documentation gaps or drift caused by recent changes.

### Typical use
- after refactors
- after structural changes

---

## h:ecc-refactor-clean

### Purpose

Identifies refactoring opportunities **without executing them**.

### Important

This command **suggests** refactors. It never performs them.

---

## h:ralph-init

### Purpose

Creates a **RALPH bundle** for a specific task.

### What it does
- creates `.planning/ralph/<slug>/`
- writes PRD and run metadata

### Preconditions
- STEW explicitly allows automation

If automation is forbidden, this command should not be used.

---

## h:ralph-run

### Purpose

Prepares and validates a RALPH execution.

### What it does
- validates CLEO focus and STATE.md
- validates clean working tree
- validates bundle integrity
- prints the exact command to run

### What it does *not* do
- directly run RALPH inline

Execution always requires explicit user confirmation.

---

## h:commit

### Purpose

Commits changes using **explicit per-file staging** with mode-based allowlists.

This is the GSD-style commit strategy: frequent commits are OK, but only for verified outcomes.

### What it does

- Validates branch (refuses main/master by default)
- Detects changed files via `git status --porcelain`
- Validates files against mode-specific allowlist
- Detects placeholder text in planning files
- Stages files individually (NEVER `git add .` or `-A`)
- Commits with conventional commit message format

### What it never does

- Use `git add .` or `git add -A`
- Commit `.gitignore`
- Commit to main/master without explicit override
- Commit placeholder scaffolding without explicit override
- Auto-commit (dry-run by default)

### Modes

| Mode | Allowed Files |
|------|---------------|
| `planning` | `.planning/**` (with placeholder check) |
| `harness` | `.claude/commands/h/**`, `scripts/h/**` |
| `docs` | `README.md`, `COMMANDS.md`, `INSTALL.md`, `BROWNFIELD.md`, `GREENFIELD.md`, `ARCHITECTURE.md`, `CONCEPTS.md`, `GOVERNANCE.md` |
| `auto` | Infers from changed files; refuses if mixed |

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `STEW_COMMIT_MSG` | (required) | Commit message |
| `STEW_COMMIT_TYPE` | `chore` | Conventional type (feat, fix, chore, docs) |
| `STEW_COMMIT_SCOPE` | `harness` | Scope for commit message |
| `STEW_COMMIT_MODE` | `auto` | One of: planning, harness, docs, auto |
| `STEW_COMMIT_YES` | `0` | If 1, actually commit; if 0, dry-run |
| `STEW_COMMIT_ALLOW_PLACEHOLDERS` | `0` | If 1, allow placeholder text |
| `STEW_COMMIT_ALLOW_MAIN` | `0` | If 1, allow commits to main/master |

### Examples

**Planning mode:**
```bash
STEW_COMMIT_MODE=planning \
STEW_COMMIT_MSG="update STATE.md pointer" \
STEW_COMMIT_YES=1 \
h:commit
```

**Harness mode:**
```bash
STEW_COMMIT_MODE=harness \
STEW_COMMIT_TYPE=feat \
STEW_COMMIT_MSG="add new ECC wrapper" \
STEW_COMMIT_YES=1 \
h:commit
```

### When to use

- After editing planning files (`.planning/*`)
- After updating harness commands (`.claude/commands/h/*`)
- After updating documentation
- When you want explicit control over what gets committed

---

## Design Guarantees

Across all commands:
- one command → one responsibility
- no hidden side effects
- no implicit execution

If behavior feels surprising, state is inconsistent.

---

## Next Document

- **GOVERNANCE.md** — how classification and gating decisions are made


---

## Plans, Summaries, and Task Memory (Why This Is Not Redundant)

At first glance, STEW + GSD + CLEO can look like overlapping systems:
- plans and summaries
- state files and task notes
- routing and execution

This is intentional separation, not duplication.

The system works because **each artifact answers a different question at a different time**.

---

### PLAN.md — Intent ("What should happen?")

Created by the user via GSD planning commands.

Used by:
- GSD to know what to execute
- STEW to classify and govern
- humans to inspect intent *before* execution

Plans are explicit, forward-looking, and contractual.

They exist so intent is written once instead of inferred repeatedly.

---

### SUMMARY.md — Outcome ("What actually happened?")

Created by GSD during or after execution.

Used for:
- audit and review
- progress reporting
- historical accountability

Summaries are descriptive and backward-looking.

They are **not** used for routing or governance.

Routing based on narrative history would require repeated interpretation, which this system avoids by design.

---

### STATE.md — Position ("Where are we right now?")

Maintained by GSD.

Contains exactly one Pointer line indicating the current work location.

Used by:
- GSD for phase progression
- STEW for routing eligibility

STATE.md encodes position, not meaning.

---

### CLEO Task Focus — Identity ("What task is active?")

Stored in CLEO project state (external to repo).

Used by:
- STEW to gate routing (mandatory)
- humans to retain task identity across sessions

CLEO focus is the single source of truth for "what is active."

---

### Why These Are Separate

If these concerns were collapsed:
- plans would need to include history
- summaries would need to include intent
- routing would depend on prose

That would force continuous reinterpretation.

Instead:
- intent is written once
- judgment is cached once
- history is recorded once

Each artifact may be read many times, but **reasoned about only once**.

---

### Efficiency and Scale

What looks like redundancy is **load-bearing separation**.

This structure eliminates:
- repeated safety analysis
- repeated scope inference
- repeated intent reconstruction

As projects grow, this separation is what keeps token usage predictable and behavior stable.

---

### Analogy

- PLAN.md is a contract
- SUMMARY.md is a receipt
- STATE.md is your current location
- CLEO focus is your active work item
- STEW enforces the rules of the contract
- GSD builds what the contract specifies

You do not drive using receipts.

---

## Regression Tests

### Scenario 1: CLEO not initialized

```bash
# Ensure CLEO state dir doesn't exist
rm -rf ~/.cleo/projects/test-project
cd /path/to/test-project
h:status
```

**Expected output:**
```
=== HARNESS STATUS - BLOCKED ===

CLEO not initialized for this project.

Project Key: test-project
CLEO State Dir: ~/.cleo/projects/test-project

Run: h:init

This will automatically initialize CLEO, set focus, and normalize STATE.md.
```

### Scenario 2: No CLEO focus

```bash
# Initialize but don't set focus
mkdir -p ~/.cleo/projects/test-project
(cd ~/.cleo/projects/test-project && cleo init)
h:status
```

**Expected output:**
```
=== HARNESS STATUS - BLOCKED ===

No CLEO focus set.

CLEO focus is mandatory for STEW routing.

Run: h:init

This will automatically create a task and set focus.
```

### Scenario 3: STATE.md Pointer missing

```bash
# CLEO configured but STATE.md has placeholder
h:status
```

**Expected output:**
```
=== HARNESS STATUS - BLOCKED ===

STATE.md Pointer is missing or contains placeholder.

Run: h:init

This will attempt to derive Pointer from legacy STATE.md formats.
If derivation fails, manual edit of .planning/STATE.md is required.
```

### Scenario 4: .continue-here.md exists (deprecated)

If `.planning/.continue-here.md` exists, commands should warn:

```
WARNING: .planning/.continue-here.md exists but is deprecated.
This file is not part of the STEW contract. Delete it:
  rm .planning/.continue-here.md
```

### Verification Checklist

- [ ] `h:status` hard-fails if CLEO not initialized
- [ ] `h:status` hard-fails if no CLEO focus
- [ ] `h:status` hard-fails if STATE.md Pointer missing
- [ ] `h:focus` has same hard-fail behavior
- [ ] `h:route` has same hard-fail behavior
- [ ] All commands warn if .continue-here.md exists

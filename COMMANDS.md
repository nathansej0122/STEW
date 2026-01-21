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

## h:status

### Purpose

Displays the **current coordination state** across all tools.

### CLEO External State

**CLEO project state is EXTERNAL to repos.** The harness reads CLEO state from
`$CLEO_PROJECT_DIR`, not from the project repository.

If `CLEO_PROJECT_DIR` is not set, `h:status` reports "CLEO: Not configured" — this is
a clean, non-fatal status, not an error. The harness will never recommend running
`cleo init` inside the project repository.

### What it reads
- CLEO focus (from `$CLEO_PROJECT_DIR`)
- git working tree status
- presence of required planning files
- governance readiness

### What it never does
- modify files
- change focus
- execute tools
- recommend `cleo init` in the project repo

### When to use
- at the start of a session
- when routing blocks
- to sanity-check state

---

## h:focus

### Purpose

Ensures a CLEO task is focused before any routing occurs.

### What it does
- reads CLEO focus
- explains how to fix missing focus

### What it does *not* do
- create tasks
- change focus automatically

### Why it exists

STEW treats task focus as non-negotiable. If focus is wrong, everything else is unsafe.

---

## h:route

### Purpose

This is the **core STEW command**.

It determines the **single next allowed action** based on current state.

### What it does
1. Verifies CLEO focus
2. Verifies governance files
3. Determines current phase
4. Detects plans
5. Ensures classification is persisted
6. Recommends exactly one next command

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
- persists the result

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
- validates clean working tree
- validates bundle integrity
- prints the exact command to run

### What it does *not* do
- directly run RALPH inline

Execution always requires explicit user confirmation.

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

Used by:
- GSD for phase progression
- STEW for routing eligibility

STATE.md encodes position, not meaning.

---

### CLEO Task Notes — Decisions ("What has already been decided?")

Stored in CLEO task metadata.

Used by:
- STEW to cache classification and governance decisions
- humans to retain rationale across sessions

These notes prevent the system from re-evaluating safety, scope, and automation decisions.

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
- CLEO notes are margin annotations
- STEW enforces the rules of the contract
- GSD builds what the contract specifies

You do not drive using receipts.

---

## Regression Test: CLEO External State Handling

To verify that the harness correctly handles CLEO external state, test these scenarios:

### Scenario 1: No CLEO_PROJECT_DIR set

```bash
unset CLEO_PROJECT_DIR
h:status
```

**Expected output:**
- CLEO status line shows: `Not configured (set CLEO_PROJECT_DIR)`
- No JSON error blobs (e.g., `E_NOT_INITIALIZED`)
- No recommendation to run `cleo init` in the project repo

### Scenario 2: CLEO_PROJECT_DIR set but uninitialized

```bash
export CLEO_PROJECT_DIR=/tmp/test-cleo-uninitialized
mkdir -p "$CLEO_PROJECT_DIR"
h:status
```

**Expected output:**
- CLEO status line shows: `Project state not initialized in $CLEO_PROJECT_DIR`
- No JSON error blobs
- May recommend initializing CLEO *in the external directory*, NOT in the project repo

### Scenario 3: CLEO_PROJECT_DIR set and initialized

```bash
export CLEO_PROJECT_DIR=/tmp/test-cleo-initialized
mkdir -p "$CLEO_PROJECT_DIR"
(cd "$CLEO_PROJECT_DIR" && cleo init)
(cd "$CLEO_PROJECT_DIR" && cleo add "Test task" && cleo focus set T001)
h:status
```

**Expected output:**
- CLEO status line shows: `T001 - Test task`
- Recommendations proceed normally (e.g., `h:route`)

### Verification Checklist

- [ ] `h:status` never emits raw JSON error objects
- [ ] `h:status` never recommends `cleo init` inside the project repo
- [ ] `h:focus` handles all three scenarios cleanly
- [ ] `h:route` blocks with clear messages when CLEO is not configured


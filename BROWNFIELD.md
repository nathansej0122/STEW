# BROWNFIELD — Integrating STEW into an Existing Project

This guide explains how to introduce **STEW** into an **existing repository** without breaking workflows, history, or trust.

This is the most common and most dangerous use case. Follow the steps exactly.

---

## What "Brownfield" Means Here

A brownfield project is one where:
- code already exists
- commits already exist
- habits already exist
- possibly *bad* AI habits already exist

STEW is designed to **stabilize** these projects, not disrupt them.

---

## Non‑Negotiable Rule

**Do not start by running automation.**

In a brownfield project, the first job of STEW is to:
- observe
- classify
- constrain

Not to act.

---

## Step 0: Initialize CLEO (MANDATORY)

CLEO is **mandatory** for STEW routing.

### Determine PROJECT_KEY

PROJECT_KEY is derived automatically:
1. If git remote origin exists: basename of remote URL without `.git`
2. Otherwise: basename of repository directory

For a repo at `~/projects/existing-app` with remote `git@github.com:user/existing-app.git`, PROJECT_KEY is `existing-app`.

### Initialize CLEO

```bash
# Create and initialize CLEO state directory
mkdir -p ~/.cleo/projects/existing-app
(cd ~/.cleo/projects/existing-app && cleo init)

# Add initial task and set focus
(cd ~/.cleo/projects/existing-app && cleo add "Stabilize existing codebase" && cleo focus set T001)
```

Verify:

```bash
(cd ~/.cleo/projects/existing-app && cleo focus show)
```

**IMPORTANT:** Never run `cleo init` inside the project repository.

---

## Step 1: Create Planning Contract (STATE.md)

Before creating the contract:
- The project must be in a clean git state
- Native tools must already be installed (see INSTALL.md)

From the project root:

```bash
mkdir -p .planning
```

### Create .planning/STATE.md

For brownfield projects, extract the current work pointer:

```bash
cat > .planning/STATE.md << 'EOF'
Current Work:
  Pointer: .planning/phases/phase-1/PLAN.md
  Status: Stabilizing existing codebase

Next Action:
  Review existing code structure
EOF
```

**This file is REQUIRED.** STEW will block until it exists with a valid Pointer.

---

## Step 2: Expose GSD Commands

If GSD is not already exposed:

```bash
mkdir -p .claude/commands
ln -s ~/tooling/native/get-shit-done/commands/gsd .claude/commands/gsd
```

Verify:

```bash
/gsd:help
```

---

## Step 3: Install STEW Into the Project

From the STEW repo:

```bash
cd ~/tooling/stew
./install.sh /path/to/existing/project
```

This:
- adds `h:*` commands
- adds the RALPH shim
- does **not** touch code

---

## Step 4: Create Minimal Governance Files

Create (if missing):

```bash
mkdir -p .planning/phases/phase-1
touch .planning/AI-OPS.md
```

At this stage, AI-OPS.md can be empty.

Its existence alone enables routing.

---

## Step 5: Establish State Without Acting

Run:

```bash
h:status
```

Then:

```bash
h:route
```

Expected behavior:
- STEW reports missing planning structure
- STEW recommends **planning**, not execution

This is correct.

---

## Step 6: Decide How to Treat the Existing Codebase

You now choose one of two paths.

### Option A: Treat as Unknown (Safer)

Run:

```bash
/gsd:map-codebase
```

This creates:
- `.planning/codebase/`
- structural documentation

No code changes occur.

### Option B: Treat as Known (Faster)

Skip mapping and proceed directly to planning.

Only do this if:
- you understand the codebase
- you trust existing structure

---

## Step 7: Initialize GSD Planning

If no planning exists yet:

```bash
/gsd:new-project
```

For brownfield projects:
- keep phases small
- prefer inspection over modification

This creates planning files without touching code.

---

## Step 8: Route, Then Plan

Run:

```bash
h:route
```

STEW will now recommend:

```
gsd:plan-phase
```

Run exactly that:

```bash
/gsd:plan-phase 1
```

Review the plan carefully.

---

## Step 9: Classification Happens Automatically

On the next:

```bash
h:route
```

STEW will:
- classify the plan
- persist classification
- hide unsafe tools

This is where brownfield safety comes from.

---

## Step 10: Only Then Consider Execution

If STEW recommends execution:

```bash
/gsd:execute-phase 1
```

If STEW suggests ECC:
- run the review first

If STEW hides RALPH:
- do **not** force it

---

## Common Brownfield Failure Modes

- Skipping CLEO initialization
- Not setting CLEO focus
- Missing STATE.md or leaving Pointer as placeholder
- Running `cleo init` inside the project repo (use external state directory)
- Running RALPH "just to try it"
- Treating verification plans as mechanical work
- Editing code before classification

STEW is explicitly designed to prevent these.

---

## Recovery If Something Goes Wrong

If STEW blocks:
- read the message
- inspect `.planning/STATE.md`
- check CLEO focus: `(cd ~/.cleo/projects/$PROJECT_KEY && cleo focus show)`

Do **not** delete state unless you understand why.

---

## When Brownfield Becomes Greenfield

Once:
- plans exist
- governance is in place
- unsafe paths are blocked

The project behaves like greenfield under STEW.

From that point forward, use the GREENFIELD loop.

---

## Next Documents

- **COMMANDS.md** — every `h:*` command explained
- **GOVERNANCE.md** — how classification and gating work

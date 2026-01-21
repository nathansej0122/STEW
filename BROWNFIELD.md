# BROWNFIELD — Integrating STEW into an Existing Project

This guide explains how to introduce **STEW** into an **existing repository** without breaking workflows, history, or trust.

This is the most common and most dangerous use case. Follow the steps exactly.

---

## What “Brownfield” Means Here

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

## Step 0: Preconditions (Do Not Skip)

Before touching STEW:

- The project must be in a clean git state
- Native tools must already be installed (see INSTALL.md)
- You must be willing to let STEW block unsafe actions

If any of these are false, stop.

---

## Step 1: Configure CLEO External State

**CLEO project state is EXTERNAL to repos.** Project repos must NOT contain `.cleo/`.

If CLEO external state does not exist yet:

```bash
# Create external state directory (NOT in the project repo)
mkdir -p ~/tooling/native/cleo/projects/your-project

# Initialize CLEO in that directory
cd ~/tooling/native/cleo/projects/your-project
cleo init

# Set the environment variable
export CLEO_PROJECT_DIR=~/tooling/native/cleo/projects/your-project
```

Add the export to your `.bashrc` or `.zshrc` for persistence.

If tasks already exist, pick one and focus it:

```bash
(cd $CLEO_PROJECT_DIR && cleo list)
(cd $CLEO_PROJECT_DIR && cleo focus set T###)
```

**IMPORTANT:** Never run `cleo init` inside the project repository.

STEW refuses to route without focus.

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
mkdir -p .planning/phases
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

- Running `cleo init` inside the project repo (use external state directory)
- Skipping CLEO focus
- Running RALPH "just to try it"
- Treating verification plans as mechanical work
- Editing code before classification

STEW is explicitly designed to prevent these.

---

## Recovery If Something Goes Wrong

If STEW blocks:
- read the message
- inspect `.planning/STATE.md`
- inspect CLEO task notes

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


# GREENFIELD — Using STEW From Zero

This guide walks you through **using STEW in a brand-new project**, end to end.

Follow the steps in order. Do not skip ahead.

---

## What “Greenfield” Means Here

A greenfield project is one where:
- no planning structure exists
- no STEW files exist
- you are starting from an idea or rough goal

This guide assumes:
- native tools are already installed (see INSTALL.md)
- STEW is already installed into the project

---

## Step 0: Create or Enter the Project Repo

```bash
mkdir my-project
cd my-project
git init
```

Nothing else should exist yet.

---

## Step 1: Configure CLEO External State

**CLEO project state is EXTERNAL to repos.** Project repos must NOT contain `.cleo/`.

CLEO must be configured **before anything else**.

```bash
# Create external state directory (NOT in the project repo)
mkdir -p ~/tooling/native/cleo/projects/my-project

# Initialize CLEO in that directory
cd ~/tooling/native/cleo/projects/my-project
cleo init

# Set the environment variable
export CLEO_PROJECT_DIR=~/tooling/native/cleo/projects/my-project
```

Add the export to your `.bashrc` or `.zshrc` for persistence.

Then create at least one task and focus it (from CLEO_PROJECT_DIR):

```bash
(cd $CLEO_PROJECT_DIR && cleo add "Initial task" --type task)
(cd $CLEO_PROJECT_DIR && cleo focus set T001)
```

**IMPORTANT:** Never run `cleo init` inside the project repository.

If no task is focused, STEW will refuse to route.

---

## Step 2: Expose GSD Commands

GSD is not copied into projects. You must expose it.

From the project root:

```bash
mkdir -p .claude/commands
ln -s ~/tooling/native/get-shit-done/commands/gsd .claude/commands/gsd
```

Verify:

```bash
/gsd:help
```

If this fails, stop and fix it.

---

## Step 3: Create Planning Skeleton

Create the minimum required planning files:

```bash
mkdir -p .planning/phases

touch .planning/AI-OPS.md
```

At minimum, AI-OPS.md must exist.

---

## Step 4: Initialize GSD Project

Run:

```bash
/gsd:new-project
```

Follow the prompts.

For greenfield projects:
- research is optional
- minimal scope is fine

This will create:
- PROJECT.md
- ROADMAP.md
- STATE.md
- config.json

---

## Step 5: Let STEW Route

Now run:

```bash
h:route
```

At this stage, STEW will:
- confirm CLEO focus
- confirm planning files
- detect that no plan exists
- recommend exactly one action

Expected output:

```
=== GSD RECOMMENDATION ===
Recommend: gsd:plan-phase
```

Do not run anything else.

---

## Step 6: Plan the Phase

Run the recommended command:

```bash
/gsd:plan-phase 1
```

This creates one or more `*-PLAN.md` files.

Review them before continuing.

---

## Step 7: Route Again

```bash
h:route
```

Now STEW will:
- detect the plan
- classify the work (once)
- persist the classification
- recommend the next action

You will see:
- whether automation is allowed
- whether review is suggested

---

## Step 8: Execute (Manually)

If STEW recommends execution:

```bash
/gsd:execute-phase 1
```

If STEW suggests ECC or RALPH, read the output carefully.

You are always in control.

---

## Step 9: Repeat the Loop

The loop is always:

```
plan → route → act → route
```

Never skip routing.

---

## Common Greenfield Mistakes

- Running `cleo init` inside the project repo (use external state directory)
- Running GSD without CLEO focus
- Skipping AI-OPS.md
- Forcing automation early
- Rerunning commands instead of fixing state

STEW blocks these on purpose.

---

## When to Stop

If STEW blocks:
- read the message
- fix the missing file or state
- rerun `h:route`

Do not bypass the harness.

---

## Next Document

- **BROWNFIELD.md** — integrating STEW into an existing project


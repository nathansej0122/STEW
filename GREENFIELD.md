# GREENFIELD — Using STEW From Zero

This guide walks you through **using STEW in a brand-new project**, end to end.

Follow the steps in order. Do not skip ahead.

---

## What "Greenfield" Means Here

A greenfield project is one where:
- no planning structure exists
- no STEW files exist
- you are starting from an idea or rough goal

This guide assumes:
- native tools are already installed (see INSTALL.md)
- STEW is already installed into the project

---

## Step 0: Initialize CLEO (MANDATORY)

CLEO is **mandatory** for STEW routing.

CLEO state is stored externally, auto-discovered based on PROJECT_KEY.

### Determine PROJECT_KEY

PROJECT_KEY is derived automatically:
1. If git remote origin exists: basename of remote URL without `.git`
2. Otherwise: basename of repository directory

Example: If your repo is at `~/projects/my-app` with remote `git@github.com:user/my-app.git`, PROJECT_KEY is `my-app`.

### Initialize CLEO

```bash
# Create and initialize CLEO state directory
mkdir -p ~/.cleo/projects/my-app
(cd ~/.cleo/projects/my-app && cleo init)

# Add initial task and set focus
(cd ~/.cleo/projects/my-app && cleo add "Initial project setup" && cleo focus set T001)
```

Verify:

```bash
(cd ~/.cleo/projects/my-app && cleo focus show)
```

---

## Step 1: Create or Enter the Project Repo

```bash
mkdir my-project
cd my-project
git init
```

If using a remote:

```bash
git remote add origin git@github.com:user/my-project.git
```

---

## Step 2: Create Planning Contract (STATE.md)

Create the planning directory and STATE.md:

```bash
mkdir -p .planning
```

### Create .planning/STATE.md

```bash
cat > .planning/STATE.md << 'EOF'
Current Work:
  Pointer: .planning/phases/phase-1/PLAN.md
  Status: Not started

Next Action:
  Create phase-1 plan document
EOF
```

**This file is REQUIRED.** STEW will block until it exists with a valid Pointer.

---

## Step 3: Expose GSD Commands

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

## Step 4: Create Planning Skeleton (Optional)

Create additional planning files if desired:

```bash
mkdir -p .planning/phases/phase-1

touch .planning/AI-OPS.md  # Optional but recommended
```

---

## Step 5: Let STEW Route

Now run:

```bash
h:route
```

At this stage, STEW will:
- verify CLEO focus exists
- verify STATE.md has a valid Pointer
- detect that no plan exists
- recommend exactly one action

Expected output:

```
=== RECOMMENDATION ===
No plan file found. Create a plan document in the phase directory.
Recommend: Create PLAN.md or use gsd:plan-phase
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
- persist the classification to HARNESS_STATE.json
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

- Skipping CLEO initialization
- Not setting CLEO focus
- Missing STATE.md or leaving Pointer as placeholder
- Running `cleo init` inside the project repo (use external state directory)
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

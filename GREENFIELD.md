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

## Step 0: Create Planning Contract (REQUIRED)

The planning contract is **mandatory** for STEW routing. Create these files first.

From the project root:

```bash
mkdir -p .planning
```

### Create .planning/STATE.md

```bash
cat > .planning/STATE.md << 'EOF'
Current Work:
  Pointer: .planning/phases/phase-1
  Status: Not started

Next Action:
  Create phase-1 plan document
EOF
```

### Create .planning/.continue-here.md

```bash
cat > .planning/.continue-here.md << 'EOF'
Current pointer: .planning/phases/phase-1/PLAN.md
Why: Starting new project
Next action: Create the phase-1 plan document
EOF
```

**These two files are REQUIRED.** STEW will block until they exist.

---

## Step 1: Create or Enter the Project Repo

```bash
mkdir my-project
cd my-project
git init
```

Then create the planning contract (Step 0).

---

## Step 2: Configure CLEO External State (OPTIONAL)

CLEO is **optional** for STEW routing. If you want task tracking:

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

**IMPORTANT:** Never run `cleo init` inside the project repository.

If you skip CLEO, STEW will still route based on the planning contract.

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
- verify planning contract exists
- read current pointer from .continue-here.md
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

- Skipping the planning contract (STATE.md + .continue-here.md)
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


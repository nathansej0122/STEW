# INSTALL — STEW (Structured Toolchain Execution Wrapper)

> **READ THIS DOCUMENT FIRST.**
>
> STEW will not work unless the requirements in this file are met exactly. This is intentional.

---

## What You Are Installing

STEW is **not** an application and **not** a framework.

You are installing a **coordination harness** that:
- reads state from multiple tools
- applies governance rules
- recommends *one* next action

STEW does **not**:
- install CLEO, GSD, ECC, or RALPH
- copy those tools into your project
- execute work on your behalf

Those tools must already exist.

---

## Critical: Required Native Tool Layout

STEW assumes a **single shared location** on your machine where native tools live.

This is a **hard requirement**.

### Required directories

You must have **all** of the following:

```
~/tooling/native/get-shit-done
~/tooling/native/everything-claude-code
~/tooling/native/ralph
~/tooling/native/cleo
```

If this layout does not exist, **STOP HERE**.

Do not install STEW into a project yet.

---

## Why Tools Live Outside Projects

STEW is designed around these principles:

- Native tools are **shared infrastructure**
- Projects should not vendor or duplicate them
- Multiple projects must reference the *same* tool versions
- Governance only works if behavior is predictable

Keeping tools outside projects prevents:
- silent version drift
- accidental modification of upstream tools
- inconsistent AI behavior across repos
- broken symlinks when copying projects

This design is intentional and non-negotiable.

---

## Tool Responsibilities (Quick Reference)

| Tool | Status | When it is used |
|----|----|----|
| **CLEO** | **MANDATORY** | Task identity (focus) - required for routing |
| **GSD** | Required | Planning & execution |
| **ECC** | Optional | Review agents (when suggested) |
| **RALPH** | Optional | Automation (only when allowed) |
| **STEW** | Required | Routing & governance |

**CLEO is mandatory.** Commands hard-fail without CLEO focus.

---

## Verify Native Tool Installation

Run **all** of the following commands:

```bash
ls -la ~/tooling/native/get-shit-done/commands/gsd
ls -la ~/tooling/native/everything-claude-code/agents
ls -la ~/tooling/native/ralph/ralph.sh
command -v cleo && cleo --version
```

Expected results:
- All paths exist
- `cleo` runs successfully

If any command fails, fix that **before continuing**.

---

## CLEO State: Auto-Discovery (No Configuration Needed)

CLEO project state is stored externally in `~/.cleo/projects/$PROJECT_KEY/`.

**PROJECT_KEY** is derived automatically:
1. If git remote origin exists: basename of remote URL without `.git`
2. Otherwise: basename of repository directory

**No environment variables required.** The location is deterministic.

### Example

```
Repository: ~/projects/my-app
Git remote: git@github.com:user/my-app.git
PROJECT_KEY: my-app
CLEO_STATE_DIR: ~/.cleo/projects/my-app
```

### Initializing CLEO for a Project

```bash
# Create directory
mkdir -p ~/.cleo/projects/my-app

# Initialize CLEO
(cd ~/.cleo/projects/my-app && cleo init)

# Add a task and set focus
(cd ~/.cleo/projects/my-app && cleo add "Initial task" && cleo focus set T001)
```

### Important

- **NEVER** run `cleo init` inside a project repository
- Project repos should NOT contain a `.cleo/` directory
- If you see `.cleo/` in a project repo, it is misconfigured

---

## How Projects See Native Tools

### CLEO
- Must be runnable as `cleo` on your PATH (or set `CLEO_BIN`)
- CLEO project state is stored externally (`~/.cleo/projects/$PROJECT_KEY/`)
- State location is auto-discovered, no configuration needed

### GSD (Get Shit Done)
- GSD commands are **not** installed into projects
- Each project must expose them via a symlink

From the project root:

```bash
mkdir -p .claude/commands
ln -s ~/tooling/native/get-shit-done/commands/gsd .claude/commands/gsd
```

This is why `/gsd:*` commands work inside the project.

### ECC (Everything Claude Code)
- ECC is **content**, not a binary
- STEW reads ECC agent specs directly from:

```
~/tooling/native/everything-claude-code/agents
```

If this folder does not exist, all `h:ecc-*` commands will fail.

### RALPH
- RALPH is executed only through the STEW shim
- The shim expects the native RALPH script at:

```
~/tooling/native/ralph/ralph.sh
```

Projects never run RALPH directly.

---

## Planning Contract (REQUIRED)

Every STEW-governed project **must** have a planning contract.

### Required File

- `.planning/STATE.md` - Contains Pointer line (work location)

### Minimal Template

**Template: .planning/STATE.md**
```
Current Work:
  Pointer: <path to current plan doc or phase directory>
  Status: <one-line status>

Next Action:
  <one-line next step>
```

The Pointer line must contain an actual path, not a placeholder.

### Optional Files

These files enhance governance but are not required for routing:
- `.planning/AI-OPS.md` - Operational constraints
- `.planning/ROADMAP.md` - Project roadmap
- `.planning/HARNESS_STATE.json` - Classification cache

See GREENFIELD.md or BROWNFIELD.md for setup instructions.

### Deprecated

`.planning/.continue-here.md` is **deprecated** and not part of the contract. If present, commands will warn to delete it.

---

## Installing STEW Into a Project

Once native tools are verified, install STEW into a project.

From inside the **STEW repo**:

```bash
cd ~/tooling/stew
./install.sh /path/to/your/project
```

This copies:
- `h:*` commands into `.claude/commands/h/`
- RALPH shim into `scripts/h/ralph.sh`

It does **not** modify any project code.

---

## Verify Installation in the Project

From the project root, run:

```bash
h:status
```

A successful install shows:
- CLEO Focus: [task id and title]
- STATE.md Pointer: [path]
- Missing prerequisites clearly reported

**If CLEO not initialized:**

```
=== HARNESS STATUS - BLOCKED ===

CLEO not initialized for this project.

Project Key: my-app
CLEO State Dir: ~/.cleo/projects/my-app

To initialize:
  mkdir -p "~/.cleo/projects/my-app"
  (cd "~/.cleo/projects/my-app" && cleo init)

Then set focus:
  (cd "~/.cleo/projects/my-app" && cleo add "Initial task" && cleo focus set T001)
```

**If no CLEO focus:**

```
=== HARNESS STATUS - BLOCKED ===

No CLEO focus set.

CLEO focus is mandatory for STEW routing.

Set focus:
  (cd "~/.cleo/projects/my-app" && cleo focus set <task-id>)
```

**If STATE.md Pointer missing:**

```
=== HARNESS STATUS - BLOCKED ===

STATE.md Pointer is missing or contains placeholder.

Edit .planning/STATE.md and set the Pointer line to a real path.
```

---

## Greenfield vs Brownfield: Where to Go Next

### New project (greenfield)
Proceed to:
- **GREENFIELD.md**

### Existing project (brownfield)
Proceed to:
- **BROWNFIELD.md**

Do **not** skip directly to running commands.

---

## If You Cannot Use the Default Layout

If you cannot use `~/tooling/native/...`:

- Do not proceed blindly
- Read GOVERNANCE.md before making changes

STEW assumes this layout to guarantee determinism and safety.

---

## Final Warning

If STEW feels strict, that is intentional.

The harness exists to prevent:
- accidental automation
- unsafe refactors
- invisible AI behavior

Follow the steps exactly. If something blocks, fix the root cause instead of bypassing it.

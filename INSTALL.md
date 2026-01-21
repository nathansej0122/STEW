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

| Tool | Why it is required | When it is used |
|----|----|----|
| **CLEO** | Task focus & continuity | Always |
| **GSD** | Planning & execution | Always |
| **ECC** | Review agents | When suggested |
| **RALPH** | Automation | Only when allowed |
| **STEW** | Routing & governance | Always |

If any tool is missing, STEW will block routing.

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

## How Projects See Native Tools

This is the most common point of confusion.

### CLEO
- Must be runnable as `cleo` on your PATH
- In your setup, this is provided via a dev-mode symlink to the native clone

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
- STEW commands available
- CLEO focus detected (or instructs you to set one)
- Missing prerequisites clearly reported

If `h:status` blocks, read the error message carefully. It is explicit by design.

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


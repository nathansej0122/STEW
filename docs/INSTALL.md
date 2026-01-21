# Installation Guide

This document explains how to install the Coordination Overlay Kit into your repository.

## Prerequisites

The harness coordinates with these native tools (external git clones):

| Tool  | Purpose | Required? |
|-------|---------|-----------|
| CLEO  | Task tracking SST | Yes |
| GSD   | Execution governance | Recommended |
| ECC   | Code review agents | Recommended |
| RALPH | Autonomous execution | Optional |

These tools should be installed separately. The harness references them but does not vendor their code.

## Quick Install

From the coordination-overlay-kit directory:

```bash
# Install to current directory
./install.sh

# Or install to a specific repo
./install.sh /path/to/your/repo
```

## What Gets Installed

### Harness Commands (`.claude/commands/h/`)

| Command | Purpose |
|---------|---------|
| `h:status` | Read-only overview of coordination state |
| `h:focus` | Enforce CLEO as SST for active task |
| `h:route` | Coordination router - recommend next GSD/ECC action |
| `h:ecc-code-review` | Code review suggestions (read-only) |
| `h:ecc-security-review` | Security review suggestions (read-only) |
| `h:ecc-doc-update` | Documentation update suggestions |
| `h:ecc-refactor-clean` | Refactoring suggestions (read-only) |
| `h:ralph-init` | Create bounded RALPH task bundle |
| `h:ralph-run` | Prepare RALPH execution command |

### Scripts (`scripts/h/`)

| Script | Purpose |
|--------|---------|
| `ralph.sh` | RALPH execution shim with safety gates |

## Environment Variables

### Optional Variables

```bash
# Path to CLEO binary (if not in PATH)
export CLEO_BIN=/path/to/cleo

# Path to RALPH script (default: ~/tooling/native/ralph/ralph.sh)
export RALPH_BIN=/path/to/ralph.sh

# Path to RALPH directory (default: ~/tooling/native/ralph)
export RALPH_DIR=/path/to/ralph
```

### Default Paths

If not set, the harness uses these defaults:

- `CLEO`: Assumes `cleo` is in PATH
- `RALPH_BIN`: `~/tooling/native/ralph/ralph.sh`
- `RALPH_DIR`: `~/tooling/native/ralph`
- `ECC agents`: `~/tooling/native/everything-claude-code/agents/`

## Manual Installation

If you prefer to install manually:

```bash
# Create directories
mkdir -p .claude/commands/h
mkdir -p scripts/h

# Copy commands
cp /path/to/coordination-overlay-kit/.claude/commands/h/*.md .claude/commands/h/

# Copy scripts
cp /path/to/coordination-overlay-kit/scripts/h/ralph.sh scripts/h/
chmod +x scripts/h/ralph.sh
```

## Post-Installation Setup

### 1. Verify Installation

```bash
# Run status check
h:status
```

### 2. Set Up CLEO Focus

```bash
# List available tasks
cleo list

# Focus on a task
cleo focus set T###
```

### 3. Create AI-OPS (Recommended)

Create `.planning/AI-OPS.md` in your repo with:
- Operational constraints
- NEVER-AUTOMATE zones
- High-risk areas
- Security requirements

### 4. Start Coordinating

```bash
# Check status
h:status

# Verify focus
h:focus

# Get routing recommendation
h:route
```

## Upgrading

To upgrade to a new version of the overlay:

1. Pull the latest coordination-overlay-kit
2. Re-run `./install.sh /path/to/your/repo`

Existing files are backed up with timestamps before overwriting.

## Uninstalling

To remove the harness:

```bash
# Remove commands
rm -rf .claude/commands/h/

# Remove scripts
rm -rf scripts/h/

# Optionally remove any RALPH bundles
rm -rf .planning/ralph/
```

## Troubleshooting

### CLEO not found

```
ERROR: CLEO not available.
```

Solution: Set `CLEO_BIN` environment variable or add `cleo` to your PATH.

### RALPH not found

```
ERROR: RALPH binary not found
```

Solution: Set `RALPH_BIN` environment variable or install RALPH to `~/tooling/native/ralph/`.

### Commands not recognized

Ensure your Claude Code environment recognizes `.claude/commands/`. Commands should appear as `h:status`, `h:focus`, etc.

## Security Considerations

- The harness commands are read-only except for `h:ralph-init` (creates files)
- RALPH execution requires explicit user action (running the shim script)
- The shim enforces clean working tree before RALPH runs
- AI-OPS NEVER-AUTOMATE zones are respected by convention

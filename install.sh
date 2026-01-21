#!/usr/bin/env bash
# Coordination Overlay Kit Installer
# Installs harness commands and scripts into a target repository.

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_COMMANDS_DIR="$SCRIPT_DIR/.claude/commands/h"
OVERLAY_SCRIPTS_DIR="$SCRIPT_DIR/scripts/h"

# --- Usage ---
usage() {
    cat <<EOF
Usage: $0 [target-repo-path]

Installs the coordination overlay kit into a target repository.

Arguments:
  target-repo-path   Path to the target repository (default: current directory)

What gets installed:
  - .claude/commands/h/*   Harness command specs
  - scripts/h/ralph.sh     RALPH shim script

Options:
  -h, --help    Show this help message

Notes:
  - Existing files are backed up with timestamps before overwriting
  - Does NOT copy any GSD, CLEO, or native tool files
  - Does NOT create gsd:* or ct:* commands
EOF
    exit 0
}

# --- Parse Arguments ---
TARGET_REPO="${1:-.}"

if [[ "$TARGET_REPO" == "-h" ]] || [[ "$TARGET_REPO" == "--help" ]]; then
    usage
fi

# Resolve to absolute path
TARGET_REPO="$(cd "$TARGET_REPO" && pwd)"

# --- Validation ---
echo "=== Coordination Overlay Kit Installer ==="
echo ""
echo "Source: $SCRIPT_DIR"
echo "Target: $TARGET_REPO"
echo ""

# Check source files exist
if [[ ! -d "$OVERLAY_COMMANDS_DIR" ]]; then
    echo "ERROR: Source commands not found: $OVERLAY_COMMANDS_DIR"
    echo "Are you running this from the coordination-overlay-kit directory?"
    exit 1
fi

if [[ ! -f "$OVERLAY_SCRIPTS_DIR/ralph.sh" ]]; then
    echo "ERROR: Source script not found: $OVERLAY_SCRIPTS_DIR/ralph.sh"
    exit 1
fi

# Check target is a directory
if [[ ! -d "$TARGET_REPO" ]]; then
    echo "ERROR: Target is not a directory: $TARGET_REPO"
    exit 1
fi

# Optional: Check if target is a git repo
if [[ ! -d "$TARGET_REPO/.git" ]]; then
    echo "WARNING: Target does not appear to be a git repository."
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# --- Backup Function ---
backup_if_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)
        local backup="${file}.backup.${timestamp}"
        echo "  Backing up: $file -> $backup"
        cp "$file" "$backup"
    fi
}

# --- Create Directories ---
echo "Creating directories..."

mkdir -p "$TARGET_REPO/.claude/commands/h"
mkdir -p "$TARGET_REPO/scripts/h"

# --- Install Commands ---
echo ""
echo "Installing harness commands..."

for cmd_file in "$OVERLAY_COMMANDS_DIR"/*.md; do
    if [[ -f "$cmd_file" ]]; then
        filename=$(basename "$cmd_file")
        target_file="$TARGET_REPO/.claude/commands/h/$filename"

        backup_if_exists "$target_file"

        echo "  Installing: .claude/commands/h/$filename"
        cp "$cmd_file" "$target_file"
    fi
done

# --- Install Scripts ---
echo ""
echo "Installing scripts..."

target_script="$TARGET_REPO/scripts/h/ralph.sh"
backup_if_exists "$target_script"

echo "  Installing: scripts/h/ralph.sh"
cp "$OVERLAY_SCRIPTS_DIR/ralph.sh" "$target_script"
chmod +x "$target_script"

# --- Summary ---
echo ""
echo "=== Installation Complete ==="
echo ""
echo "Installed to: $TARGET_REPO"
echo ""
echo "Commands installed:"
for cmd_file in "$OVERLAY_COMMANDS_DIR"/*.md; do
    if [[ -f "$cmd_file" ]]; then
        filename=$(basename "$cmd_file" .md)
        echo "  - h:$filename"
    fi
done
echo ""
echo "Scripts installed:"
echo "  - scripts/h/ralph.sh"
echo ""
echo "=== Next Steps ==="
echo ""
echo "1. (Optional) Set environment variables:"
echo "   export CLEO_BIN=/path/to/cleo        # If not in PATH"
echo "   export RALPH_BIN=/path/to/ralph.sh   # Default: ~/tooling/native/ralph/ralph.sh"
echo ""
echo "2. Start with:"
echo "   h:status    # Check current coordination state"
echo "   h:focus     # Verify/set CLEO task focus"
echo "   h:route     # Get recommended next action"
echo ""
echo "3. For docs, see:"
echo "   $SCRIPT_DIR/docs/INSTALL.md"
echo "   $SCRIPT_DIR/docs/ARCHITECTURE.md"

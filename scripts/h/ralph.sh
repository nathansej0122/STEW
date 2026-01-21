#!/usr/bin/env bash
# Harness RALPH Shim Script
# This is the ONLY executable automation in the coordination overlay.
# It wraps native RALPH with safety gates and bundle management.

set -euo pipefail

# --- Configuration ---
RALPH_BIN="${RALPH_BIN:-$HOME/tooling/native/ralph/ralph.sh}"
RALPH_DIR="${RALPH_DIR:-$HOME/tooling/native/ralph}"

# --- Usage ---
usage() {
    cat <<EOF
Usage: $0 <max_iters> <task-slug> [--tool <tool>]

Arguments:
  max_iters   Maximum number of RALPH iterations (required)
  task-slug   Task bundle identifier in .planning/ralph/<slug>/ (required)
  --tool      AI tool to use (default: claude)

Example:
  $0 5 add-priority-field --tool claude

The script will:
  1. Verify clean working tree
  2. Copy bundle files to RALPH expected locations
  3. Run RALPH with iteration limit
  4. Copy results back to bundle
  5. Log output for review
EOF
    exit 1
}

# --- Argument Parsing ---
if [[ $# -lt 2 ]]; then
    usage
fi

MAX_ITERS="$1"
TASK_SLUG="$2"
shift 2

TOOL="claude"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --tool)
            TOOL="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            usage
            ;;
    esac
done

# --- Determine Repo Root ---
# Script is at scripts/h/ralph.sh, so repo root is two levels up
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Change to repo root
cd "$REPO_ROOT"

# --- Paths ---
BUNDLE_DIR=".planning/ralph/$TASK_SLUG"
BUNDLE_PRD="$BUNDLE_DIR/prd.json"
BUNDLE_PROGRESS="$BUNDLE_DIR/progress.txt"
BUNDLE_RUNLOG="$BUNDLE_DIR/run.log"
ROOT_PRD="./prd.json"
ROOT_PROGRESS="./progress.txt"

# --- Preflight: Bundle Exists ---
echo "=== RALPH SHIM: Preflight Checks ==="

if [[ ! -d "$BUNDLE_DIR" ]]; then
    echo "ERROR: Bundle directory not found: $BUNDLE_DIR"
    echo "Create it first with: h:ralph-init $TASK_SLUG"
    exit 1
fi

if [[ ! -f "$BUNDLE_PRD" ]]; then
    echo "ERROR: prd.json not found in bundle: $BUNDLE_PRD"
    exit 1
fi

echo "Bundle found: $BUNDLE_DIR"

# --- Preflight: Clean Working Tree ---
# Allow only untracked files in the bundle directory
DIRTY_FILES=$(git status --porcelain | grep -v "^?? $BUNDLE_DIR/" | grep -v "^?? prd.json" | grep -v "^?? progress.txt" | grep -v "^?? scripts/ralph/" || true)

if [[ -n "$DIRTY_FILES" ]]; then
    echo "ERROR: Working tree is not clean."
    echo "The following files have uncommitted changes:"
    echo "$DIRTY_FILES"
    echo ""
    echo "Commit or stash changes before running RALPH."
    exit 1
fi

echo "Working tree: clean (bundle untracked files allowed)"

# --- Preflight: AI-OPS Check ---
if [[ -f ".planning/AI-OPS.md" ]]; then
    echo "AI-OPS: Present - ensure NEVER-AUTOMATE exclusions are honored"

    # Extract NEVER-AUTOMATE paths if defined (informational only)
    if grep -q "NEVER-AUTOMATE" ".planning/AI-OPS.md" 2>/dev/null; then
        echo "  (NEVER-AUTOMATE zones detected in AI-OPS.md)"
    fi
else
    echo "AI-OPS: Not found (proceeding without constraints)"
fi

# --- Materialize Native RALPH ---
echo ""
echo "=== Materializing RALPH ==="

mkdir -p scripts/ralph

if [[ ! -f "scripts/ralph/ralph.sh" ]]; then
    if [[ -f "$RALPH_BIN" ]]; then
        echo "Copying ralph.sh from $RALPH_BIN"
        cp "$RALPH_BIN" scripts/ralph/ralph.sh
        chmod +x scripts/ralph/ralph.sh
    else
        echo "ERROR: RALPH binary not found at $RALPH_BIN"
        echo "Set RALPH_BIN environment variable or install RALPH to ~/tooling/native/ralph/"
        exit 1
    fi
else
    echo "scripts/ralph/ralph.sh already exists"
fi

if [[ ! -f "scripts/ralph/CLAUDE.md" ]]; then
    RALPH_CLAUDE="$RALPH_DIR/CLAUDE.md"
    if [[ -f "$RALPH_CLAUDE" ]]; then
        echo "Copying CLAUDE.md from $RALPH_CLAUDE"
        cp "$RALPH_CLAUDE" scripts/ralph/CLAUDE.md
    else
        echo "WARNING: CLAUDE.md not found at $RALPH_CLAUDE"
    fi
else
    echo "scripts/ralph/CLAUDE.md already exists"
fi

# --- Setup Bundle Files ---
echo ""
echo "=== Setting Up Bundle Files ==="

# Copy prd.json to root
echo "Copying $BUNDLE_PRD -> $ROOT_PRD"
cp "$BUNDLE_PRD" "$ROOT_PRD"

# Restore progress.txt if exists in bundle
if [[ -f "$BUNDLE_PROGRESS" ]]; then
    echo "Restoring $BUNDLE_PROGRESS -> $ROOT_PROGRESS"
    cp "$BUNDLE_PROGRESS" "$ROOT_PROGRESS"
else
    echo "No previous progress.txt found (starting fresh)"
    # Create empty progress file
    touch "$ROOT_PROGRESS"
fi

# --- Run RALPH ---
echo ""
echo "=== Running RALPH ==="
echo "Command: ./scripts/ralph/ralph.sh --tool $TOOL $MAX_ITERS"
echo "Max iterations: $MAX_ITERS"
echo "Task slug: $TASK_SLUG"
echo ""

# Capture stdout and stderr to log file while also displaying
{
    ./scripts/ralph/ralph.sh --tool "$TOOL" "$MAX_ITERS" 2>&1 | tee "$BUNDLE_RUNLOG"
} || {
    RALPH_EXIT_CODE=$?
    echo ""
    echo "RALPH exited with code: $RALPH_EXIT_CODE"
    echo "Check log: $BUNDLE_RUNLOG"
}

# --- Post-Run: Copy Results Back ---
echo ""
echo "=== Post-Run: Saving Results ==="

# Copy prd.json back to bundle (may have been updated with passes: true)
if [[ -f "$ROOT_PRD" ]]; then
    echo "Copying $ROOT_PRD -> $BUNDLE_PRD"
    cp "$ROOT_PRD" "$BUNDLE_PRD"
fi

# Copy progress.txt back to bundle
if [[ -f "$ROOT_PROGRESS" ]]; then
    echo "Copying $ROOT_PROGRESS -> $BUNDLE_PROGRESS"
    cp "$ROOT_PROGRESS" "$BUNDLE_PROGRESS"
fi

echo "Run log saved: $BUNDLE_RUNLOG"

# --- Show Changes ---
echo ""
echo "=== Files Changed ==="
git diff --name-only || echo "(no changes to tracked files)"

echo ""
echo "=== Untracked Files ==="
git status --porcelain | grep "^??" | sed 's/^?? //' || echo "(none)"

echo ""
echo "=== RALPH Run Complete ==="
echo "Review changes with: git diff"
echo "Review log with: cat $BUNDLE_RUNLOG"
echo "Commit when satisfied: git add . && git commit -m 'feat: RALPH task $TASK_SLUG'"

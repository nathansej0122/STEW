---
name: h:commit
description: GSD-style commit with explicit staging, mode-based allowlists, and placeholder detection
allowed-tools: Bash, Read
---

<!-- FENCE CHECK: If output appears garbled, verify this file has balanced markdown fences. -->
<!-- Each "Run:" section must contain exactly ONE fenced bash block. -->

# Harness Commit

Commits changes using **explicit per-file staging** with mode-based allowlists.

## Required Environment Variables

- `STEW_COMMIT_MSG` — commit message (required)

## Optional Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `STEW_COMMIT_TYPE` | `chore` | Conventional commit type (feat, fix, chore, docs, refactor) |
| `STEW_COMMIT_SCOPE` | `harness` | Scope for commit message |
| `STEW_COMMIT_MODE` | `auto` | One of: `planning`, `harness`, `docs`, `auto` |
| `STEW_COMMIT_YES` | `0` | If 0, dry-run only; if 1, actually commit |
| `STEW_COMMIT_ALLOW_PLACEHOLDERS` | `0` | If 1, allow files with placeholder text |
| `STEW_COMMIT_ALLOW_MAIN` | `0` | If 1, allow commits to main/master |

## Run: Commit Check and Execute

```bash
# --- Input validation ---
if [ -z "${STEW_COMMIT_MSG:-}" ]; then
  echo "ERROR: STEW_COMMIT_MSG is required"
  exit 1
fi

TYPE="${STEW_COMMIT_TYPE:-chore}"
SCOPE="${STEW_COMMIT_SCOPE:-harness}"
MODE="${STEW_COMMIT_MODE:-auto}"
YES="${STEW_COMMIT_YES:-0}"
ALLOW_PLACEHOLDERS="${STEW_COMMIT_ALLOW_PLACEHOLDERS:-0}"
ALLOW_MAIN="${STEW_COMMIT_ALLOW_MAIN:-0}"

# --- Collect changed files (union of unstaged + staged + untracked) ---
# Untracked files included so newly created files (e.g., new commands, planning
# contract files) are visible. --exclude-standard respects .gitignore.
UNSTAGED=$(git diff --name-only 2>/dev/null)
STAGED=$(git diff --name-only --cached 2>/dev/null)
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null)
CHANGED_FILES=$(printf '%s\n%s\n%s' "$UNSTAGED" "$STAGED" "$UNTRACKED" | grep -v '^$' | sort -u)

if [ -z "$CHANGED_FILES" ]; then
  echo "Nothing to commit"
  exit 0
fi

# --- Get branch ---
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "BRANCH: $BRANCH"

# --- Refuse main/master unless allowed ---
if [ "$YES" = "1" ] && [ "$ALLOW_MAIN" != "1" ]; then
  if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
    echo "ERROR: Refusing to commit to $BRANCH without STEW_COMMIT_ALLOW_MAIN=1"
    exit 1
  fi
fi

# --- Mode detection (auto) ---
if [ "$MODE" = "auto" ]; then
  HAS_PLANNING=0
  HAS_HARNESS=0
  HAS_DOCS=0
  HAS_OTHER=0

  for f in $CHANGED_FILES; do
    case "$f" in
      .planning/*) HAS_PLANNING=1 ;;
      .claude/commands/h/*|scripts/h/*) HAS_HARNESS=1 ;;
      README.md|COMMANDS.md|INSTALL.md|BROWNFIELD.md|GREENFIELD.md|ARCHITECTURE.md|CONCEPTS.md|GOVERNANCE.md) HAS_DOCS=1 ;;
      *) HAS_OTHER=1 ;;
    esac
  done

  # Determine mode
  MODES_FOUND=$((HAS_PLANNING + HAS_HARNESS + HAS_DOCS))
  if [ "$HAS_OTHER" = "1" ]; then
    MODE="mixed-violation"
  elif [ "$MODES_FOUND" -gt 1 ]; then
    MODE="mixed-violation"
  elif [ "$HAS_PLANNING" = "1" ]; then
    MODE="planning"
  elif [ "$HAS_HARNESS" = "1" ]; then
    MODE="harness"
  elif [ "$HAS_DOCS" = "1" ]; then
    MODE="docs"
  else
    MODE="mixed-violation"
  fi
fi

echo "MODE: $MODE"

# --- Build allowlist based on mode ---
ALLOWED=""
VIOLATIONS=""

for f in $CHANGED_FILES; do
  MATCH=0
  case "$MODE" in
    planning)
      case "$f" in .planning/*) MATCH=1 ;; esac
      ;;
    harness)
      case "$f" in .claude/commands/h/*|scripts/h/*) MATCH=1 ;; esac
      ;;
    docs)
      case "$f" in README.md|COMMANDS.md|INSTALL.md|BROWNFIELD.md|GREENFIELD.md|ARCHITECTURE.md|CONCEPTS.md|GOVERNANCE.md) MATCH=1 ;; esac
      ;;
    mixed-violation)
      MATCH=0
      ;;
  esac

  # Always refuse .gitignore
  if [ "$f" = ".gitignore" ]; then
    MATCH=0
  fi

  if [ "$MATCH" = "1" ]; then
    ALLOWED="$ALLOWED $f"
  else
    VIOLATIONS="$VIOLATIONS $f"
  fi
done

# --- Placeholder detection for planning mode ---
PLACEHOLDER_VIOLATIONS=""
if [ "$MODE" = "planning" ] && [ "$ALLOW_PLACEHOLDERS" != "1" ]; then
  for f in $ALLOWED; do
    if [ -f "$f" ]; then
      if grep -qE '<path to|<one-line|TODO' "$f" 2>/dev/null; then
        PLACEHOLDER_VIOLATIONS="$PLACEHOLDER_VIOLATIONS $f"
      fi
    fi
  done
fi

# --- Output ---
echo ""
echo "ALLOWED_FILES:$ALLOWED"
echo "VIOLATIONS:$VIOLATIONS"
if [ -n "$PLACEHOLDER_VIOLATIONS" ]; then
  echo "PLACEHOLDER_VIOLATIONS:$PLACEHOLDER_VIOLATIONS"
fi

echo ""
echo "=== DIFFSTAT (unstaged) ==="
DIFF_UNSTAGED=$(git diff --stat 2>/dev/null)
[ -n "$DIFF_UNSTAGED" ] && echo "$DIFF_UNSTAGED" || echo "(none)"

echo ""
echo "=== DIFFSTAT (staged) ==="
DIFF_STAGED=$(git diff --stat --cached 2>/dev/null)
[ -n "$DIFF_STAGED" ] && echo "$DIFF_STAGED" || echo "(none)"

# --- Check for violations ---
if [ -n "$VIOLATIONS" ] || [ "$MODE" = "mixed-violation" ]; then
  echo ""
  echo "ERROR: Cannot commit - files outside allowlist for mode '$MODE'"
  echo "Violating files:$VIOLATIONS"
  echo ""
  echo "Options:"
  echo "  1. Specify explicit mode: STEW_COMMIT_MODE=planning|harness|docs"
  echo "  2. Commit file groups separately"
  exit 1
fi

if [ -n "$PLACEHOLDER_VIOLATIONS" ]; then
  echo ""
  echo "ERROR: Cannot commit - files contain placeholder text"
  echo "Files with placeholders:$PLACEHOLDER_VIOLATIONS"
  echo ""
  echo "Options:"
  echo "  1. Edit files to replace placeholder values"
  echo "  2. Allow placeholders: STEW_COMMIT_ALLOW_PLACEHOLDERS=1"
  exit 1
fi

# --- Dry run vs actual commit ---
COMMIT_MSG="${TYPE}(${SCOPE}): ${STEW_COMMIT_MSG}"
echo ""
echo "COMMIT_MESSAGE: $COMMIT_MSG"

if [ "$YES" != "1" ]; then
  echo ""
  echo "=== DRY RUN ==="
  echo "Would stage and commit:$ALLOWED"
  echo ""
  echo "To commit, re-run with STEW_COMMIT_YES=1"
  exit 0
fi

# --- Stage files individually (NEVER git add . or -A) ---
echo ""
echo "=== STAGING ==="
for f in $ALLOWED; do
  echo "git add \"$f\""
  git add "$f"
done

# --- Commit ---
echo ""
echo "=== COMMITTING ==="
git commit -m "$COMMIT_MSG"
echo ""
echo "COMMIT_COMPLETE"
```

## Modes

| Mode | Allowed Files |
|------|---------------|
| `planning` | `.planning/**` (with placeholder check) |
| `harness` | `.claude/commands/h/**`, `scripts/h/**` |
| `docs` | `README.md`, `COMMANDS.md`, `INSTALL.md`, `BROWNFIELD.md`, `GREENFIELD.md`, `ARCHITECTURE.md`, `CONCEPTS.md`, `GOVERNANCE.md` |
| `auto` | Infers from changed files; refuses if mixed |

## Always Refused

- `.gitignore` — never committed by this command
- Files outside the mode allowlist
- Files with placeholder text (`<path to`, `<one-line`, `TODO`) in planning mode unless `STEW_COMMIT_ALLOW_PLACEHOLDERS=1`

## Examples

### Planning mode (after editing STATE.md)

```bash
STEW_COMMIT_MODE=planning \
STEW_COMMIT_TYPE=chore \
STEW_COMMIT_SCOPE=planning \
STEW_COMMIT_MSG="initialize planning contract" \
STEW_COMMIT_YES=1 \
h:commit
```

### Harness mode (after updating h:* commands)

```bash
STEW_COMMIT_MODE=harness \
STEW_COMMIT_TYPE=feat \
STEW_COMMIT_SCOPE=harness \
STEW_COMMIT_MSG="add bootstrap command" \
STEW_COMMIT_YES=1 \
h:commit
```

### Docs mode (after updating documentation)

```bash
STEW_COMMIT_MODE=docs \
STEW_COMMIT_TYPE=docs \
STEW_COMMIT_SCOPE=stew \
STEW_COMMIT_MSG="document h:commit command" \
STEW_COMMIT_YES=1 \
h:commit
```

## Rules

1. **NEVER** use `git add .` or `git add -A`
2. **NEVER** commit `.gitignore`
3. **NEVER** commit to main/master without explicit `STEW_COMMIT_ALLOW_MAIN=1`
4. **NEVER** commit placeholder scaffolding without explicit `STEW_COMMIT_ALLOW_PLACEHOLDERS=1`
5. Always show what would be committed before actually committing (dry-run by default)

---
name: h:_classify
description: "Internal: One-time work classification for governed orchestration"
allowed-tools: Bash
---

# Internal Classifier

**Not user-callable. Called by h:route only.**

**CLEO focus is MANDATORY. STATE.md Pointer is REQUIRED.**

Classification is stored in `.planning/HARNESS_STATE.json`.

## Gate 0: STATE.md (REQUIRED)

```bash
if [ ! -f ".planning/STATE.md" ]; then
  echo "STATE_MD_MISSING"
  exit 1
fi

POINTER=$(grep -E "^\s*Pointer:" .planning/STATE.md 2>/dev/null | head -1 | sed 's/^[[:space:]]*Pointer:[[:space:]]*//')
if [ -z "$POINTER" ] || echo "$POINTER" | grep -q "^<"; then
  echo "STATE_POINTER_MISSING_OR_PLACEHOLDER"
  exit 1
fi
echo "STATE_POINTER_OK: $POINTER"
```

If blocked, do not proceed.

## Execution

Run these Bash tool calls in sequence:

### Step 1: Determine phase directory and plan file

```bash
# Get pointer from STATE.md
POINTER=$(grep -E "^\s*Pointer:" .planning/STATE.md 2>/dev/null | head -1 | sed 's/^[[:space:]]*Pointer:[[:space:]]*//')

PHASE_DIR=""
PLAN_FILE=""

# If pointer is a directory, that's the phase dir
if [ -d "$POINTER" ]; then
  PHASE_DIR="$POINTER"
elif [ -f "$POINTER" ]; then
  PHASE_DIR=$(dirname "$POINTER")
fi

# Find plan file
if [ -n "$PHASE_DIR" ] && [ -d "$PHASE_DIR" ]; then
  if [ -f "$PHASE_DIR/PLAN.md" ]; then
    PLAN_FILE="$PHASE_DIR/PLAN.md"
  else
    PLAN_FILE=$(ls "$PHASE_DIR"/*-PLAN.md 2>/dev/null | sort | head -1)
  fi
fi

# If pointer is itself a plan file
if [ -z "$PLAN_FILE" ] && [ -f "$POINTER" ] && echo "$POINTER" | grep -qE 'PLAN\.md$'; then
  PLAN_FILE="$POINTER"
fi

if [ -z "$PLAN_FILE" ]; then echo "NO_PLAN"; exit 0; fi
echo "PHASE_DIR=$PHASE_DIR"
echo "PLAN_FILE=$PLAN_FILE"
```

### Step 2: Compute plan hash

```bash
PLAN_HASH=$(sha256sum "$PLAN_FILE" | cut -d' ' -f1)
echo "PLAN_HASH=$PLAN_HASH"
```

### Step 3: Check for existing classification in HARNESS_STATE.json

```bash
if [ -f ".planning/HARNESS_STATE.json" ]; then
    python3 << 'PYEOF'
import json
import sys

try:
    with open('.planning/HARNESS_STATE.json', 'r') as f:
        state = json.load(f)

    classification = state.get('classification', {})
    existing_hash = classification.get('plan_hash', '')

    # Read current plan hash
    import subprocess
    result = subprocess.run(['sha256sum', state.get('classification', {}).get('plan_file', '')],
                          capture_output=True, text=True)
    # This will be compared externally

    if existing_hash:
        print(f"EXISTING_HASH={existing_hash}")
    else:
        print("NO_CACHED_CLASSIFICATION")
except:
    print("NO_CACHED_CLASSIFICATION")
PYEOF
else
    echo "NO_CACHED_CLASSIFICATION"
fi

# Compare hashes
if [ "$EXISTING_HASH" = "$PLAN_HASH" ]; then
    echo "CLASSIFICATION_CACHED"
    exit 0
fi
```

If output is `CLASSIFICATION_CACHED`, stop here.

### Step 4: Parse explicit automation block from plan

```bash
# Extract automation block and parse with python
AUTOMATION_BLOCK=$(sed -n '/^automation:/,/^[^ ]/p' "$PLAN_FILE" 2>/dev/null | head -5)

python3 << 'PYEOF'
import sys

block = """$AUTOMATION_BLOCK"""
result = {}
for line in block.strip().split('\n'):
    line = line.strip()
    if ':' in line and not line.startswith('automation:'):
        key, val = line.split(':', 1)
        result[key.strip()] = val.strip()

# Check if all required fields present
required = ['type', 'scope', 'ralph', 'ecc']
if all(k in result for k in required):
    # Validate enums
    valid_type = result.get('type') in ['conceptual', 'mechanical', 'mixed']
    valid_scope = result.get('scope') in ['bounded', 'unbounded']
    valid_ralph = result.get('ralph') in ['allowed', 'discouraged', 'forbidden']
    valid_ecc = result.get('ecc') in ['suggested', 'optional', 'unnecessary']

    if valid_type and valid_scope and valid_ralph and valid_ecc:
        print(f"EXPLICIT_TYPE={result['type']}")
        print(f"EXPLICIT_SCOPE={result['scope']}")
        print(f"EXPLICIT_RALPH={result['ralph']}")
        print(f"EXPLICIT_ECC={result['ecc']}")
        print("SOURCE=explicit")
    else:
        print("EXPLICIT_BLOCK_INVALID")
else:
    print("NO_EXPLICIT_BLOCK")
PYEOF
```

### Step 5: Apply fallback heuristics (only if no valid explicit block)

If Step 4 output contains `NO_EXPLICIT_BLOCK` or `EXPLICIT_BLOCK_INVALID`, run:

```bash
PLAN_CONTENT=$(cat "$PLAN_FILE" 2>/dev/null)

python3 << 'PYEOF'
import re

content = """$PLAN_CONTENT"""

# Gate 0: Validation-only → forbidden
validation_keywords = r'\b(verify|validate|check|confirm|ensure|assert|inspect|route|status)\b'
shell_read_actions = r'\b(ls|cat|grep|jq|stat|sha256sum|head|tail|wc|diff|file)\b'
mechanical_edit_signals = r'\b(rename|move|update|modify|edit|write|create|delete|remove|refactor)\b'

has_validation_signals = bool(re.search(validation_keywords, content, re.I)) or bool(re.search(shell_read_actions, content))
has_mechanical_signals = bool(re.search(mechanical_edit_signals, content, re.I))

files_modified_match = re.search(r'files_modified:\s*\[([^\]]*)\]', content)
files_modified_empty = True
if files_modified_match:
    files_list = files_modified_match.group(1).strip()
    if files_list:
        non_planning_files = [f for f in files_list.split(',') if '.planning' not in f and 'STATE.md' not in f and 'PLAN' not in f]
        files_modified_empty = len(non_planning_files) == 0

if has_validation_signals and (not has_mechanical_signals or files_modified_empty):
    print("INFERRED_TYPE=conceptual")
    print("INFERRED_SCOPE=bounded")
    print("INFERRED_RALPH=forbidden")
    print("INFERRED_ECC=optional")
    print("SOURCE=inferred")
    exit()

# Gate 1: Conceptual → forbidden
conceptual_patterns = r'\b(design|architect|research|evaluate|compare|decide|assess)\b'
has_file_paths = bool(re.search(r'[./][a-zA-Z0-9_-]+\.(ts|js|py|md|json|yaml|sh)', content))

if re.search(conceptual_patterns, content, re.I) and not has_file_paths:
    print("INFERRED_TYPE=conceptual")
    print("INFERRED_SCOPE=unbounded")
    print("INFERRED_RALPH=forbidden")
    print("INFERRED_ECC=optional")
    print("SOURCE=inferred")
    exit()

# Gate 2: Unbounded → forbidden
unbounded_patterns = r'\b(as needed|where appropriate|throughout the codebase)\b'
if re.search(unbounded_patterns, content, re.I):
    print("INFERRED_TYPE=mixed")
    print("INFERRED_SCOPE=unbounded")
    print("INFERRED_RALPH=forbidden")
    print("INFERRED_ECC=optional")
    print("SOURCE=inferred")
    exit()

# Gate 3: Mechanical + bounded → allowed
has_allowed_paths = 'Allowed Paths' in content or 'allowed paths' in content.lower()
has_excluded_paths = 'Excluded Paths' in content or 'excluded paths' in content.lower()

if has_allowed_paths and has_excluded_paths:
    print("INFERRED_TYPE=mechanical")
    print("INFERRED_SCOPE=bounded")
    print("INFERRED_RALPH=allowed")
    print("INFERRED_ECC=unnecessary")
    print("SOURCE=inferred")
    exit()

# Gate 4: Default → discouraged
security_keywords = r'\b(security|auth|password|credential|token|encrypt|secret)\b'
if re.search(security_keywords, content, re.I):
    ecc = "suggested"
else:
    ecc = "optional"

print("INFERRED_TYPE=mixed")
print("INFERRED_SCOPE=bounded")
print("INFERRED_RALPH=discouraged")
print(f"INFERRED_ECC={ecc}")
print("SOURCE=inferred")
PYEOF
```

### Step 6: Build and persist classification to HARNESS_STATE.json

Using the values from Step 4 (explicit) or Step 5 (inferred), run:

```bash
# Collect values (replace with actual values from previous steps)
TYPE="${EXPLICIT_TYPE:-$INFERRED_TYPE}"
SCOPE="${EXPLICIT_SCOPE:-$INFERRED_SCOPE}"
RALPH="${EXPLICIT_RALPH:-$INFERRED_RALPH}"
ECC="${EXPLICIT_ECC:-$INFERRED_ECC}"
SOURCE="${SOURCE}"
DECIDED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build and write HARNESS_STATE.json
python3 << PYEOF
import json
import os

state_file = '.planning/HARNESS_STATE.json'

# Load existing state or create new
if os.path.exists(state_file):
    with open(state_file, 'r') as f:
        state = json.load(f)
else:
    state = {}

# Update classification
state['classification'] = {
    'type': '$TYPE',
    'scope': '$SCOPE',
    'automation_fit': '$RALPH',
    'ecc': '$ECC',
    'plan_hash': '$PLAN_HASH',
    'plan_file': '$PLAN_FILE',
    'source': '$SOURCE',
    'decided_at': '$DECIDED_AT'
}

# Write back
with open(state_file, 'w') as f:
    json.dump(state, f, indent=2)

print('CLASSIFICATION_STORED')
PYEOF
```

### Step 7: Update STATE.md breadcrumb

```bash
TYPE="${EXPLICIT_TYPE:-$INFERRED_TYPE}"
RALPH="${EXPLICIT_RALPH:-$INFERRED_RALPH}"
ECC="${EXPLICIT_ECC:-$INFERRED_ECC}"

# Build breadcrumb line
BREADCRUMB="- Classification: RALPH $RALPH ($TYPE); ECC $ECC"

# Check if breadcrumb already exists and update or insert
if grep -q "^- Classification:" .planning/STATE.md 2>/dev/null; then
    sed -i "s/^- Classification:.*/$BREADCRUMB/" .planning/STATE.md
else
    # Append to end of file
    echo "" >> .planning/STATE.md
    echo "$BREADCRUMB" >> .planning/STATE.md
fi
```

### Step 8: Output

```bash
echo "CLASSIFICATION_STORED"
```

## Output Values

The command outputs exactly one of:
- `STATE_MD_MISSING` - STATE.md file missing
- `STATE_POINTER_MISSING_OR_PLACEHOLDER` - Pointer not set or is a placeholder
- `NO_PLAN` - No plan file found
- `CLASSIFICATION_CACHED` - Existing classification valid (plan unchanged)
- `CLASSIFICATION_STORED` - New classification persisted

## Classification JSON Schema (in HARNESS_STATE.json)

```json
{
  "classification": {
    "type": "conceptual|mechanical|mixed",
    "scope": "bounded|unbounded",
    "automation_fit": "allowed|discouraged|forbidden",
    "ecc": "suggested|optional|unnecessary",
    "plan_hash": "<sha256>",
    "plan_file": "<path>",
    "source": "explicit|inferred",
    "decided_at": "<ISO-8601 UTC>"
  }
}
```

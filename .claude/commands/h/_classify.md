---
name: h:_classify
description: "Internal: One-time work classification for governed orchestration"
allowed-tools: Bash
---

# Internal Classifier

**Not user-callable. Called by h:route only.**

## Execution

Run these Bash tool calls in sequence:

### Step 1: Determine phase directory and plan file

```bash
PHASE_DIR=$(grep -oP '(Phase Directory:|Current Phase:)\s*\K.*' .planning/STATE.md 2>/dev/null | head -1)
if [ -z "$PHASE_DIR" ]; then echo "NO_PHASE"; exit 0; fi
PLAN_FILE=$(ls "$PHASE_DIR"/*-PLAN.md "$PHASE_DIR"/PLAN.md 2>/dev/null | sort | head -1)
if [ -z "$PLAN_FILE" ]; then echo "NO_PLAN"; exit 0; fi
echo "PHASE_DIR=$PHASE_DIR"
echo "PLAN_FILE=$PLAN_FILE"
```

### Step 2: Get focused task ID

```bash
FOCUS_ID=$(cleo focus show -q 2>/dev/null)
if [ -z "$FOCUS_ID" ]; then echo "NO_FOCUS"; exit 0; fi
echo "FOCUS_ID=$FOCUS_ID"
```

### Step 3: Compute plan hash

```bash
PLAN_HASH=$(sha256sum "$PLAN_FILE" | cut -d' ' -f1)
echo "PLAN_HASH=$PLAN_HASH"
```

### Step 4: Check for existing classification

```bash
FOCUS_ID=$(cleo focus show -q 2>/dev/null)
TASK_OUTPUT=$(cleo show "$FOCUS_ID" 2>/dev/null)

# Extract base64-encoded classification and decode (last entry wins)
EXISTING_JSON=$(echo "$TASK_OUTPUT" | python3 -c "
import sys, re, json, base64
text = sys.stdin.read()
matches = re.findall(r'\[WORK_CLASSIFICATION_B64\]\s*([A-Za-z0-9+/=]+)', text)
if matches:
    candidate = matches[-1]  # last entry wins
    try:
        decoded = base64.b64decode(candidate).decode('utf-8')
        obj = json.loads(decoded)
        print(json.dumps(obj))
    except:
        pass
" 2>/dev/null)

if [ -n "$EXISTING_JSON" ]; then
    EXISTING_HASH=$(echo "$EXISTING_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('plan_hash',''))" 2>/dev/null)
    PLAN_FILE=$(grep -oP '(Phase Directory:|Current Phase:)\s*\K.*' .planning/STATE.md 2>/dev/null | head -1)
    PLAN_FILE=$(ls "$PLAN_FILE"/*-PLAN.md "$PLAN_FILE"/PLAN.md 2>/dev/null | sort | head -1)
    CURRENT_HASH=$(sha256sum "$PLAN_FILE" | cut -d' ' -f1)
    if [ "$EXISTING_HASH" = "$CURRENT_HASH" ]; then
        echo "CLASSIFICATION_CACHED"
        exit 0
    fi
fi
echo "NO_CACHED_CLASSIFICATION"
```

If output is `CLASSIFICATION_CACHED`, stop here.

### Step 5: Parse explicit automation block from plan

```bash
PLAN_FILE=$(grep -oP '(Phase Directory:|Current Phase:)\s*\K.*' .planning/STATE.md 2>/dev/null | head -1)
PLAN_FILE=$(ls "$PLAN_FILE"/*-PLAN.md "$PLAN_FILE"/PLAN.md 2>/dev/null | sort | head -1)

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

### Step 6: Apply fallback heuristics (only if no valid explicit block)

If Step 5 output contains `NO_EXPLICIT_BLOCK` or `EXPLICIT_BLOCK_INVALID`, run:

```bash
PLAN_FILE=$(grep -oP '(Phase Directory:|Current Phase:)\s*\K.*' .planning/STATE.md 2>/dev/null | head -1)
PLAN_FILE=$(ls "$PLAN_FILE"/*-PLAN.md "$PLAN_FILE"/PLAN.md 2>/dev/null | sort | head -1)

PLAN_CONTENT=$(cat "$PLAN_FILE" 2>/dev/null)

python3 << 'PYEOF'
import re

content = """$PLAN_CONTENT"""

# Gate 0: Validation-only → forbidden
# Detects plans that only verify/check/inspect without modifying files
validation_keywords = r'\b(verify|validate|check|confirm|ensure|assert|inspect|route|status)\b'
shell_read_actions = r'\b(ls|cat|grep|jq|stat|sha256sum|head|tail|wc|diff|file)\b'
mechanical_edit_signals = r'\b(rename|move|update|modify|edit|write|create|delete|remove|refactor)\b'

has_validation_signals = bool(re.search(validation_keywords, content, re.I)) or bool(re.search(shell_read_actions, content))
has_mechanical_signals = bool(re.search(mechanical_edit_signals, content, re.I))

# Check if files_modified in frontmatter is empty or only planning docs
files_modified_match = re.search(r'files_modified:\s*\[([^\]]*)\]', content)
files_modified_empty = True
if files_modified_match:
    files_list = files_modified_match.group(1).strip()
    if files_list:
        # Check if only planning docs (.planning/, STATE.md, etc.)
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
# Determine ECC based on content
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

### Step 7: Build and persist classification JSON

Using the values from Step 5 (explicit) or Step 6 (inferred), run:

```bash
# Collect values (replace with actual values from previous steps)
TYPE="${EXPLICIT_TYPE:-$INFERRED_TYPE}"
SCOPE="${EXPLICIT_SCOPE:-$INFERRED_SCOPE}"
RALPH="${EXPLICIT_RALPH:-$INFERRED_RALPH}"
ECC="${EXPLICIT_ECC:-$INFERRED_ECC}"
SOURCE="${SOURCE}"
FOCUS_ID=$(cleo focus show -q 2>/dev/null)
PLAN_FILE=$(grep -oP '(Phase Directory:|Current Phase:)\s*\K.*' .planning/STATE.md 2>/dev/null | head -1)
PLAN_FILE=$(ls "$PLAN_FILE"/*-PLAN.md "$PLAN_FILE"/PLAN.md 2>/dev/null | sort | head -1)
PLAN_HASH=$(sha256sum "$PLAN_FILE" | cut -d' ' -f1)
DECIDED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build JSON (single line)
CLASSIFICATION_JSON="{\"type\":\"$TYPE\",\"scope\":\"$SCOPE\",\"automation_fit\":\"$RALPH\",\"ecc\":\"$ECC\",\"plan_hash\":\"$PLAN_HASH\",\"source\":\"$SOURCE\",\"decided_at\":\"$DECIDED_AT\"}"

# Base64-encode to avoid CLEO jq parsing issues with quotes/braces
CLASSIFICATION_B64=$(printf '%s' "$CLASSIFICATION_JSON" | base64 -w 0)

# Persist to CLEO notes (base64-encoded, safe for jq)
cleo update "$FOCUS_ID" --notes "[WORK_CLASSIFICATION_B64] $CLASSIFICATION_B64"
```

### Step 8: Update STATE.md breadcrumb

```bash
PHASE_DIR=$(grep -oP '(Phase Directory:|Current Phase:)\s*\K.*' .planning/STATE.md 2>/dev/null | head -1)
TYPE="${EXPLICIT_TYPE:-$INFERRED_TYPE}"
RALPH="${EXPLICIT_RALPH:-$INFERRED_RALPH}"
ECC="${EXPLICIT_ECC:-$INFERRED_ECC}"

# Build breadcrumb line
BREADCRUMB="- Classification: RALPH $RALPH ($TYPE); ECC $ECC"

# Check if breadcrumb already exists and update or insert
if grep -q "^- Classification:" .planning/STATE.md 2>/dev/null; then
    # Replace existing breadcrumb
    sed -i "s/^- Classification:.*/$BREADCRUMB/" .planning/STATE.md
else
    # Insert after the current phase line (look for Phase Directory or Current Phase)
    sed -i "/^\(Phase Directory:\|Current Phase:\)/a $BREADCRUMB" .planning/STATE.md
fi
```

### Step 9: Output

```bash
echo "CLASSIFICATION_STORED"
```

## Output Values

The command outputs exactly one of:
- `NO_PHASE` - No phase directory found
- `NO_PLAN` - No plan file found
- `NO_FOCUS` - No CLEO task focused
- `CLASSIFICATION_CACHED` - Existing classification valid (plan unchanged)
- `CLASSIFICATION_STORED` - New classification persisted

## Classification JSON Schema

```json
{
  "type": "conceptual|mechanical|mixed",
  "scope": "bounded|unbounded",
  "automation_fit": "allowed|discouraged|forbidden",
  "ecc": "suggested|optional|unnecessary",
  "plan_hash": "<sha256>",
  "source": "explicit|inferred",
  "decided_at": "<ISO-8601 UTC>"
}
```

---
name: h:ecc-doc-update
description: Documentation update suggestions using ECC doc-updater agent spec (read-only)
allowed-tools: Read, Grep, Glob, Bash
---

# Harness ECC Documentation Update

You are analyzing documentation needs using the ECC (Everything Claude Code) doc-updater agent specification. **This is read-only; you provide suggestions but do NOT modify any files.**

## Load Agent Specification

Read the native ECC doc-updater spec:
```
~/tooling/native/everything-claude-code/agents/doc-updater.md
```

Follow the documentation patterns and criteria defined there.

## Load AI-OPS Context (if present)

Check for and read:
- `.planning/AI-OPS.md` - Operational constraints
- `.planning/AI-OPS-KNOWLEDGE.md` - Domain knowledge

These inform what documentation is important and required.

## Analysis Scope

Identify code changes that may need documentation:
```bash
# Recent changes
git diff --name-only HEAD~5..HEAD 2>/dev/null || git diff --name-only HEAD 2>/dev/null

# Check for existing docs
find . -name "*.md" -not -path "./.git/*" -not -path "./node_modules/*" 2>/dev/null | head -20
find . -name "README*" -not -path "./.git/*" 2>/dev/null
```

## Documentation Analysis Criteria

1. **API Changes** - New/modified endpoints, parameters, responses
2. **Config Changes** - New env vars, config options, defaults
3. **Feature Changes** - New features, changed behavior
4. **Breaking Changes** - Anything that affects existing users
5. **Architecture** - Significant structural changes
6. **Setup/Install** - Changes to installation or setup process

## Output Format

```
=== ECC DOCUMENTATION REVIEW ===

Scope: [X files changed, Y docs found]
AI-OPS Context: [Loaded/Not present]

=== DOCUMENTATION GAPS ===

[P1 - Required Updates]
- [Gap: what's missing and where]
  Affected code: [file:line]
  Suggested doc: [which doc file needs update]

[P2 - Recommended Updates]
- [Gap: what would be helpful]
  Affected code: [file:line]
  Suggested doc: [which doc file]

[P3 - Nice to Have]
- [Gap: optional improvement]

=== DOC-BY-DOC NOTES ===

**README.md**
- [What needs updating]

**docs/api.md** (or equivalent)
- [What needs updating]

**CHANGELOG.md** (if exists)
- [Entry needed for changes]

=== SUGGESTED UPDATES ===

1. Update [file]: Add section for [feature/change]
2. Update [file]: Document new [parameter/option]
3. Create [file]: New doc needed for [topic]

=== SUMMARY ===

[Brief assessment of documentation state]
Documentation debt: [Low/Medium/High]
```

## Rules

1. **Read-only** - Never modify documentation, only suggest
2. **Prioritize** - Most important gaps first
3. **Be specific** - Point to exact code and doc locations
4. **Consider audience** - Different docs for different users
5. **Suggest, don't execute** - User decides what to document

## Important

This command provides documentation analysis only. The user writes the documentation.

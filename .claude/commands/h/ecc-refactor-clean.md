---
name: h:ecc-refactor-clean
description: Refactoring/cleanup suggestions using ECC refactor-cleaner agent spec (read-only)
allowed-tools: Read, Grep, Glob, Bash
---

# Harness ECC Refactor/Clean Review

You are analyzing code for refactoring and cleanup opportunities using the ECC (Everything Claude Code) refactor-cleaner agent specification. **This is read-only; you provide suggestions but do NOT modify any code.**

## Load Agent Specification

Read the native ECC refactor-cleaner spec:
```
~/tooling/native/everything-claude-code/agents/refactor-cleaner.md
```

Follow the refactoring patterns and criteria defined there.

## Load AI-OPS Context (if present)

Check for and read:
- `.planning/AI-OPS.md` - Operational constraints
- `.planning/AI-OPS-KNOWLEDGE.md` - Domain knowledge

**Pay attention to:**
- NEVER-AUTOMATE zones (avoid suggesting changes there)
- Locked behaviors that must not change

## Analysis Scope

Determine files to analyze:
```bash
# Recent changes
git diff --name-only HEAD~5..HEAD 2>/dev/null || git diff --name-only HEAD 2>/dev/null

# Or analyze specific paths if provided
```

If user provides specific files/paths as arguments, focus on those.

## Refactoring Analysis Criteria

1. **Code Duplication** - DRY violations, copy-paste code
2. **Complexity** - Long functions, deep nesting, high cyclomatic complexity
3. **Naming** - Poor names, inconsistent conventions
4. **Structure** - God classes, feature envy, inappropriate intimacy
5. **Dead Code** - Unused functions, unreachable code, stale comments
6. **Tech Debt** - TODOs, FIXMEs, deprecated patterns
7. **Performance** - Obvious inefficiencies, N+1 patterns
8. **Testability** - Hard to test code, tight coupling

## Output Format

```
=== ECC REFACTOR/CLEAN REVIEW ===

Scope: [X files analyzed]
AI-OPS Context: [Loaded/Not present]
NEVER-AUTOMATE Zones: [Listed if present - excluded from suggestions]

=== HIGH-VALUE REFACTORING OPPORTUNITIES ===

[High Impact]
- [Opportunity with file:line reference]
  Issue: [what's wrong]
  Suggestion: [how to improve]
  Benefit: [why it matters]

[Medium Impact]
- [Opportunity with file:line reference]
  Issue: [what's wrong]
  Suggestion: [how to improve]

[Low Impact / Quick Wins]
- [Opportunity with file:line reference]

=== FILE-BY-FILE NOTES ===

**path/to/file.ext**
- Line X-Y: [observation and suggestion]
- Line Z: [observation and suggestion]

**path/to/another.ext**
- [observations]

=== DEAD CODE DETECTED ===

- [file:line] - [unused function/variable/import]

=== TECH DEBT MARKERS ===

- [file:line] - TODO: [content]
- [file:line] - FIXME: [content]

=== SUGGESTED REFACTORING PLAN ===

1. [Quick win that improves readability]
2. [Medium effort that reduces complexity]
3. [Larger refactor that addresses structural issue]

Estimated complexity: [Simple/Moderate/Significant]

=== SUMMARY ===

[Brief assessment of code health]
Technical debt level: [Low/Medium/High]
Recommended priority: [Which refactors to tackle first]
```

## Rules

1. **Read-only** - Never modify code, only suggest
2. **Respect NEVER-AUTOMATE** - Don't suggest changes in excluded zones
3. **Prioritize by impact** - Most valuable changes first
4. **Be specific** - Include file paths and line numbers
5. **Consider risk** - Note if refactoring might break things
6. **Suggest, don't execute** - User decides what to refactor

## Important

This command provides refactoring analysis only. The user implements changes.

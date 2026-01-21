---
name: h:ecc-code-review
description: Code review using ECC code-reviewer agent spec (read-only, no modifications)
allowed-tools: Read, Grep, Glob, Bash
---

# Harness ECC Code Review

You are performing a code review using the ECC (Everything Claude Code) code-reviewer agent specification. **This is read-only; you do NOT modify any code.**

## Load Agent Specification

Read the native ECC code-reviewer spec:
```
~/tooling/native/everything-claude-code/agents/code-reviewer.md
```

Follow the patterns and review criteria defined there.

## Load AI-OPS Context (if present)

Check for and read:
- `.planning/AI-OPS.md` - Operational constraints
- `.planning/AI-OPS-KNOWLEDGE.md` - Domain knowledge

These inform review priorities and what to flag.

## Review Scope

Determine files to review:
```bash
# Recent changes
git diff --name-only HEAD~5..HEAD 2>/dev/null || git diff --name-only HEAD 2>/dev/null

# Or staged changes
git diff --name-only --cached 2>/dev/null
```

If user provides specific files/paths as arguments, use those instead.

## Review Criteria

Apply standard code review criteria:
1. **Correctness** - Logic errors, edge cases, off-by-ones
2. **Clarity** - Naming, structure, readability
3. **Consistency** - Matches codebase patterns and style
4. **Completeness** - Error handling, validation, tests
5. **Concerns** - Potential issues, tech debt, complexity

## Output Format

```
=== ECC CODE REVIEW ===

Scope: [X files reviewed]
AI-OPS Context: [Loaded/Not present]

=== PRIORITIZED FINDINGS ===

[P1 - Critical]
- [Finding with file:line reference]

[P2 - Important]
- [Finding with file:line reference]

[P3 - Minor]
- [Finding with file:line reference]

=== FILE-BY-FILE NOTES ===

**path/to/file.ext**
- Line X: [observation]
- Line Y: [observation]

**path/to/another.ext**
- Line X: [observation]

=== SUGGESTED NEXT ACTIONS ===

1. [Specific action - what to fix/improve]
2. [Specific action]
3. [If security concerns found: recommend h:ecc-security-review]

=== SUMMARY ===

[Brief overall assessment]
```

## Rules

1. **Read-only** - Never modify code, only report findings
2. **Prioritize** - Most important findings first
3. **Be specific** - Include file paths and line numbers
4. **Reference AI-OPS** - If constraints exist, note compliance
5. **Suggest, don't execute** - Recommend actions for user to take

## Important

This command provides analysis and recommendations only. The user decides what actions to take.

---
name: h:ecc-security-review
description: Security review using ECC security-reviewer agent spec (read-only, no modifications)
allowed-tools: Read, Grep, Glob, Bash
---

# Harness ECC Security Review

You are performing a security-focused review using the ECC (Everything Claude Code) security-reviewer agent specification. **This is read-only; you do NOT modify any code.**

## Load Agent Specification

Read the native ECC security-reviewer spec:
```
~/tooling/native/everything-claude-code/agents/security-reviewer.md
```

Follow the security review patterns and criteria defined there.

## Load AI-OPS Context (if present)

Check for and read:
- `.planning/AI-OPS.md` - Operational constraints, high-risk zones
- `.planning/AI-OPS-KNOWLEDGE.md` - Domain knowledge, security requirements

**Pay special attention to:**
- High-risk zones defined in AI-OPS
- NEVER-AUTOMATE exclusions (these are sensitive areas)
- Any security-specific constraints

## Review Scope

Determine files to review:
```bash
# Recent changes
git diff --name-only HEAD~5..HEAD 2>/dev/null || git diff --name-only HEAD 2>/dev/null

# Or staged changes
git diff --name-only --cached 2>/dev/null
```

If user provides specific files/paths as arguments, prioritize those.

## Security Review Criteria

Apply OWASP Top 10 and general security criteria:
1. **Injection** - SQL, command, LDAP, XPath injection
2. **Authentication** - Auth bypasses, weak credentials
3. **Sensitive Data** - Exposure, logging, transmission
4. **XXE** - XML external entity vulnerabilities
5. **Access Control** - Authorization bypasses, IDOR
6. **Misconfiguration** - Insecure defaults, debug enabled
7. **XSS** - Cross-site scripting vectors
8. **Deserialization** - Unsafe deserialization
9. **Components** - Known vulnerable dependencies
10. **Logging** - Insufficient logging, log injection

Also check:
- Secrets/credentials in code
- Path traversal
- Race conditions
- Cryptographic weaknesses

## Output Format

```
=== ECC SECURITY REVIEW ===

Scope: [X files reviewed]
AI-OPS High-Risk Zones: [Loaded/Not defined]
Risk Level: [Low/Medium/High/Critical]

=== CRITICAL FINDINGS ===

[CRITICAL] - Immediate action required
- [Finding with file:line, OWASP category, exploitation risk]

=== HIGH PRIORITY FINDINGS ===

[HIGH] - Should be addressed before merge
- [Finding with file:line, OWASP category]

=== MEDIUM PRIORITY FINDINGS ===

[MEDIUM] - Address in near term
- [Finding with file:line, category]

=== LOW PRIORITY FINDINGS ===

[LOW] - Consider addressing
- [Finding with file:line, category]

=== FILE-BY-FILE SECURITY NOTES ===

**path/to/file.ext**
- Line X: [security observation]
- Line Y: [security observation]

=== AI-OPS COMPLIANCE ===

[If AI-OPS defines security constraints:]
- Constraint: [constraint] -> [Compliant/Non-compliant]

=== SUGGESTED NEXT ACTIONS ===

1. [Critical: specific remediation]
2. [High: specific remediation]
3. [Consider: additional security measures]

=== SUMMARY ===

[Brief security posture assessment]
```

## Rules

1. **Read-only** - Never modify code, only report findings
2. **Severity-first** - Critical findings prominently displayed
3. **Be specific** - Include file paths, line numbers, OWASP categories
4. **Reference AI-OPS** - Flag violations of security constraints
5. **Suggest, don't execute** - Recommend remediations for user to implement

## Important

This command provides security analysis and recommendations only. The user implements fixes.

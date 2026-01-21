# GOVERNANCE — How STEW Decides What Is Allowed

This document explains **why STEW blocks, allows, or hides actions**.

It is not about commands. It is about **judgment**.

If something feels "overly restrictive," this is the document that explains why that restriction exists and what problem it prevents.

---

## Governance Is the Product

STEW is not primarily a convenience tool.

It is a **governance layer** that sits between:
- human intent
- planning artifacts
- powerful automation

Most AI tooling fails because it optimizes for speed instead of correctness.

STEW optimizes for:
- determinism
- auditability
- safety
- predictable cost

---

## What STEW Governs (and What It Does Not)

STEW **governs**:
- when automation may be invoked
- whether review is required, optional, or pointless
- what the next allowed action is

STEW does **not** govern:
- how code is written
- what design decisions you choose
- how GSD plans are authored

Governance is about *when*, not *how*.

---

## Classification Is the Core Mechanism

All governance decisions flow from **classification**.

Classification answers four questions:

1. What kind of work is this?
2. How wide is the scope?
3. Is automation appropriate?
4. Is review useful?

Once answered, these questions are **cached**.

They are not re-argued.

---

## Explicit Beats Inferred (Always)

If a plan contains an explicit automation block:

```yaml
automation:
  type: conceptual | mechanical | mixed
  scope: bounded | unbounded
  ralph: allowed | discouraged | forbidden
  ecc: suggested | optional | unnecessary
```

STEW **does not argue**.

It accepts this as authoritative intent and records it.

This exists so:
- experienced users can be precise
- governance does not require heuristics
- intent is transparent and inspectable

---

## Fallback Classification (When Intent Is Not Explicit)

If no automation block exists, STEW classifies once using conservative rules.

The goal is not to guess perfectly.

The goal is to **avoid unsafe automation**.

---

## Gate 0: Validation-Only Work

Validation work is the most common source of accidental automation.

These plans:
- verify
- check
- inspect
- compare
- route

They often include shell commands like:
- ls
- cat
- grep
- jq

These are **read-only** actions.

For validation-only plans:
- automation is forbidden
- review is optional

This prevents RALPH from being invoked where there is nothing to build.

---

## Conceptual vs Mechanical Work

### Conceptual Work

Conceptual plans:
- explore options
- evaluate tradeoffs
- reason about design

Automation is forbidden.

No system should autonomously decide design.

---

### Mechanical Work

Mechanical plans:
- list explicit files
- perform repetitive edits
- apply known transformations

Automation may be allowed **only if scope is bounded**.

This is where RALPH earns its keep.

---

## Why Scope Matters More Than Intent

Automation fails not because intent is wrong, but because scope leaks.

Unbounded scope means:
- "throughout the codebase"
- "where appropriate"
- "all relevant files"

These phrases are automation poison.

STEW forbids automation when scope is unbounded, regardless of intent.

---

## Why STEW Hides Tools Instead of Warning

If a tool is forbidden:
- STEW does not suggest it
- STEW does not mention it

This is deliberate.

Warnings get ignored.

Hidden options do not.

---

## ECC Is Not a Safety Net

ECC is not there to fix bad automation.

ECC exists to:
- surface issues
- flag risk
- guide human judgment

If ECC is marked unnecessary, it is because:
- the work is mechanical
- risk is low
- review would add noise

This saves time and tokens.

---

## Classification Is Sticky (By Design)

Once a plan is classified:
- the decision is persisted
- future routing reuses it

To change classification:
- change the plan
- or add an explicit automation block

This prevents flip-flopping and re-interpretation.

---

## Why This Is Not Over-Engineering

Without governance:
- automation is tempting
- scope creeps
- reviews are skipped
- costs explode

Governance is what lets you move *fast without breaking things*.

STEW exists because discipline does not scale without structure.

---

## Final Principle

If STEW blocks you, it is not punishing you.

It is protecting you from:
- accidental automation
- silent scope expansion
- repeated AI reasoning

You can always override by making intent explicit.

That is the contract.


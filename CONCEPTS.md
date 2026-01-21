# CONCEPTS — How STEW Works (Mental Model)

This document explains **how to think about STEW**. Read this before running commands.

STEW only works if you understand *who is responsible for what* and *what STEW refuses to do*.

---

## The Core Idea

STEW is a **governance and routing layer**.

It does not plan.
It does not execute.
It does not decide outcomes.

It reads state from other tools and recommends exactly **one safe next action**.

---

## The Five Actors (Authoritative Roles)

Every action in this system belongs to exactly one actor.

| Actor | Owns | Does NOT own |
|----|----|----|
| **CLEO** | Task identity, focus, continuity | Planning, automation |
| **GSD** | Plans, phases, execution order | Focus, governance |
| **RALPH** | Mechanical execution | Scope, intent |
| **ECC** | Review and critique | Execution |
| **STEW** | Routing and governance | Decisions, execution |

If two tools appear to overlap, something is wrong.

---

## Single Sources of Truth (SST)

STEW enforces **non-negotiable sources of truth**:

| Question | Answer |
|----------|--------|
| What is active? | CLEO focus (mandatory) |
| Where is the plan? | STATE.md Pointer |
| What should happen? | GSD plans |
| What is allowed? | Governance rules |
| What already happened? | Persisted state |

STEW never invents intent and never overrides these sources.

---

## What STEW Actually Does

On every run of `h:route`, STEW:

1. Confirms a CLEO task is focused (mandatory)
2. Confirms STATE.md has a valid Pointer
3. Confirms governance files exist (`AI-OPS.md`, `STATE.md`)
4. Determines the current phase
5. Checks whether a plan exists
6. Ensures the plan is classified (once)
7. Recommends exactly **one** next command

That is all.

---

## Classification (Why Automation Is Usually Hidden)

STEW classifies work **once per plan** and persists the result.

Classification answers:
- Is this work conceptual, mixed, or mechanical?
- Is the scope bounded?
- Is autonomous execution allowed?
- Is review useful?

### Explicit vs Inferred

- **Explicit**: A plan declares an `automation:` block
- **Inferred**: STEW infers intent once if no block exists

Once stored, STEW never re-classifies unless the plan changes.

---

## Why RALPH Is Often Forbidden

Most plans:
- verify state
- inspect files
- reason about structure
- coordinate tools

These are **not safe to automate**.

RALPH only appears when:
- work is mechanical
- scope is bounded
- intent is explicit or clearly inferred

If RALPH is hidden, that is a safety feature.

---

## Why ECC Is Sometimes Hidden

ECC is a review tool.

It is hidden when:
- work is purely mechanical
- no risk indicators are present

Showing ECC only when useful avoids noise and review fatigue.

---

## Determinism and Token Control

STEW is deliberately boring:

- No re-reasoning
- No adaptive behavior
- No learning loops
- No hidden state

All important decisions are:
- written down
- persisted
- inspectable

This prevents runaway token usage and hallucinated changes.

---

## What STEW Will Never Do

STEW will never:
- execute commands for you
- override a plan
- bypass governance
- invent scope
- guess intent twice

If STEW blocks, the correct action is to **fix state**, not force execution.

---

## How This Feels in Practice

When used correctly:
- workflows are slower but safer
- mistakes are obvious early
- automation is deliberate
- reviews are targeted

This is intentional.

---

## CLEO is Mandatory

Previous versions of STEW treated CLEO as optional.

**CLEO is now mandatory.**

Every harness command gates on CLEO focus. Without it:
- `h:status` blocks
- `h:focus` blocks
- `h:route` blocks

This ensures task identity is always stable and unambiguous.

CLEO state is auto-discovered based on PROJECT_KEY (derived from git remote or repo basename). No environment variables required.

---

## Next Documents

- **GREENFIELD.md** — starting a new project
- **BROWNFIELD.md** — integrating into an existing project

Do not skip directly to commands without understanding this model.

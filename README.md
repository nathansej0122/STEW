# STEW — Structured Toolchain Execution Wrapper

## What This Is

STEW is a **governance layer for long‑running AI‑assisted development**.

It is built for situations where AI workflows degrade over time:
- repeated re-explaining of context
- repeated re-evaluation of safety and scope
- inconsistent decisions across sessions
- runaway token usage
- automation that becomes harder to undo than to do manually

STEW does not try to make AI "faster." It makes AI **predictable, inspectable, and cost-controlled** by moving intent and judgment into explicit state.

---

## Who This Is For

STEW is for people doing **serious, ongoing work** with AI assistance:
- multi-week/month software projects
- solo developers juggling multiple repos
- anyone paying real money for tokens and wanting predictable spend
- engineers who prefer explicit state over conversational re-derivation

If you mainly want quick answers or one-off scripts, this will feel heavy.

---

## Who This Is Not For

STEW is not a fit if you want:
- an autonomous "agent" that just does work
- a copilot-style chat workflow
- maximum speed at the expense of reversibility
- automation without governance

STEW is intentionally strict.

---

## The Five Actors

| Tool | Status | What it owns |
|---|---|---|
| **CLEO** | **MANDATORY** | Task identity (focus) |
| **GSD (Get Shit Done)** | Required | Plans, phases, execution order |
| **ECC** | Optional | Review agents (code, security, refactor, docs) |
| **RALPH** | Optional | Bounded mechanical automation |
| **STEW** | Required | Routing & governance |

**Planning contract**: STATE.md is required (provides work location via Pointer line).

CLEO is mandatory. Commands hard-fail without CLEO focus. Run `h:cleo-init` to bootstrap.

For commits, use `h:commit` with explicit mode-based staging (never `git add .`).

---

## What You Get From Bundling These Tools

Separately, these tools are useful.

Together, they eliminate repeated AI re-reasoning by splitting responsibilities:
- **CLEO** keeps task identity stable across sessions.
- **GSD** externalizes intent into plans and phases.
- **STEW** caches safety/automation judgments once and reuses them.
- **ECC** appears only when critique is likely to matter.
- **RALPH** is available only when automation is earned.

This turns expensive, repeated reasoning into cheap, persistent state.

---

## High-Level Flow

```
User
  ↓
h:cleo-init (bootstrap: initialize CLEO if needed)
  ↓
CLEO (focus: what task is active) [MANDATORY]
  ↓
STATE.md (pointer: where is the plan)
  ↓
GSD (plans: what should happen)
  ↓
h:route (reads everything)
  ├─ recommends gsd:* commands
  ├─ may suggest h:ralph-* (only if allowed)
  └─ may suggest h:ecc-* (only if useful)
```

---

## Documentation Map

Read these in order:

1. **INSTALL.md** — mandatory setup and prerequisites
2. **CONCEPTS.md** — mental model and why this isn't redundant
3. **GREENFIELD.md** — starting a new project
4. **BROWNFIELD.md** — integrating into an existing project
5. **COMMANDS.md** — all `h:*` commands explained
6. **GOVERNANCE.md** — classification and gating rules

---

## What This Repo Does Not Contain

STEW does not vendor native tools. These live in a shared location (see INSTALL.md):
- CLEO
- GSD
- ECC
- RALPH

This is intentional to avoid drift and keep behavior predictable.

---

## Status

STEW is opinionated by design. If something feels restrictive, it usually is.

If STEW blocks, fix the underlying state rather than bypassing governance.

© 2026 Variegate Labs LLC. Released under the MIT License.

# About This Prompt Suite

This folder contains a system of companion prompts for creating and maintaining coding projects with AI agents. Each prompt has one job; together they cover a project's full life: **plan → scaffold → build → maintain → retire**. This document explains what each file is for and how they fit together.

## The philosophy

- **Plans come first.** Nothing here generates ideas or designs — every project starts from a fully fleshed-out plan produced elsewhere. The prompts turn that plan into a working, governed repository.
- **Plan-first extends past the scaffold.** Ordinary feature work is gated the same way: unscoped work gets a plan (feature doc or short written plan), the owner approves it, and only then does build start — never both in one uninterrupted pass. Trivial mechanical fixes are exempt. The owner merges to main; agents never merge or force-push (mandatory at High tier).
- **Only what's applicable.** Projects get a universal core plus conditional modules justified by the plan (including monorepo/workspace layout, scoping docs, and deployment runbooks). Nothing is scaffolded "just in case."
- **Security is tiered, not one-size-fits-all.** Every project gets a Low / Medium / High security tier, proposed by the agent from a rubric and confirmed by me. Controls scale with real risk.
- **The repo must be self-sufficient.** These prompts are only visible at scaffold time. Their durable rules are transcribed into each project's `CLAUDE.md`, `AGENTS.md`, and `SECURITY.md`, so future agent sessions behave correctly without ever seeing the prompts.
- **Audit, then act.** Review-type prompts report findings and queue tasks; they fix nothing without my approval.
- **Reviews converge by rule, not by exhaustion.** Plan-stage review loops are bounded: invariants freeze, findings are classified (product vs assurance-harness), stop signals end the loop, and adversarial energy concentrates on real code. See the structure prompt's Review convergence rules.

## The files

| File                            | Role                                                                                                      | When it's used                                               |
| ------------------------------- | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| `project_kickoff_prompt.md`     | Entry point. Wraps the finalized plan and invokes both companions below.                                  | Once, at project creation                                    |
| `project_structure_prompt.md`   | Repo structure, documentation system, session workflow, working discipline, quality gates.                | At creation (via kickoff)                                    |
| `project_security_prompt.md`    | Tiered security & privacy controls (Low/Medium/High), tier rubric, escalation, decommissioning.           | At creation (via kickoff), on retrofits, and at tier changes |
| `project_maintenance_prompt.md` | Monthly portfolio audit: doc drift, dependencies, credentials, spend, backups, tier re-checks, lifecycle. | Recurring, across all projects                               |
| `PROJECTS.md`                   | Portfolio index — one row per project (purpose, status, tier, credentials, spend, remote, last touched) plus the maintenance sweep log. Lives outside any repo (suggested `~/projects/PROJECTS.md`), not in this suite. | Continuously; the hub every other file writes to             |

## How they interact

**At creation:** I paste the kickoff prompt with the plan. The agent reads both companion prompts, derives the project profile, and presents **one combined proposal** — modules in/out with reasons, plus the proposed security tier with rubric justification. I confirm (the tier can change the module list). The agent then scaffolds, initializes git with a private remote (or local-only when no GitHub account is set up), registers the project in `PROJECTS.md`, transcribes the durable rules into the repo, and finishes with **one combined handoff report**. Ownership is split cleanly: the structure prompt owns files and workflow; the security prompt owns all security and privacy controls.

**During builds:** each project is self-governing. Sessions start from the project's `PROMPT.md` (volatile handoff), consult `CLAUDE.md`/`AGENTS.md` for rules, and end by updating `CHANGELOG.md` and rewriting `PROMPT.md` (mutating sessions only — read-only sessions leave it untouched). New work passes the plan-first approval gate before build starts. The confirmed tier's controls live as a checklist in `SECURITY.md`; per-release controls sit in the `AGENTS.md` release checklist. Medium+ projects get code review at each feature completion. Hot docs (`PLAN.md`, `SECURITY.md`, `CHANGELOG.md`, `PROMPT.md`) carry concrete size ceilings with archival destinations, so they stay cheap to retrieve.

**Over time:** the maintenance prompt sweeps the portfolio on a monthly backstop cadence, plus event-triggered targeted syncs (release/milestone, pivot, deployment or audience change, tier/credential/spend change, pause/retirement — flagged owner-side by each release report), reconciling `PROJECTS.md` against reality and checking each active project for drift, vulnerable dependencies, stale credentials, spend anomalies, and tripped tier-escalation triggers. Tier escalations re-invoke the security prompt's rubric; the gap between old and new tier becomes explicit tasks. Retirement runs the security prompt's decommissioning checklist — credentials revoked, deployments down, data handled per retention rules, repo archived.

```text
plan (external)
   │
   ▼
kickoff ──► structure + security ──► scaffolded, registered project
                                          │  (self-governing builds)
                                          ▼
                maintenance sweep ◄──► PROJECTS.md ◄──► escalation / retrofit / decommission
```

## Conventions

- **Versioning:** every prompt carries a `Version:` and `Last updated:` line, bumped on any edit. Scaffolded projects record the versions they were built under in their `CLAUDE.md`, so the maintenance sweep can flag projects that predate material rule changes.
- **No cloud-synced folders for repos** (decided 2026-07-04): projects live in plain local folders with private GitHub remotes (or local-only when no GitHub account is set up). Cloud sync corrupts git repositories.
- **`PROJECTS.md` is owner-side** (decided 2026-07-04): the portfolio index is my personal infrastructure. Repos never reference it and collaborators never update it; in-repo docs (`SECURITY.md`, `CHANGELOG.md`) are the interface, and the maintenance sweep syncs the index from them. It lives outside the repos, not in this suite.
- **Missing companion = stop.** Each prompt names its companions; if one wasn't provided, the agent asks rather than improvising.

# About the solo-speed project suite

Version: 1.0 — Last updated: 2026-09-04

A speed profile for a **solo owner building a prototype or MVP with AI agents**. It overlays the
`project-initiation-suite` (which stays the governance kernel: kickoff, structure, security,
maintenance) and replaces only the parts that were sized for shared, production code: the
review gate, the round cap, the documentation cadence, the merge rule and the owner's
involvement pattern. Created from a solo prototype run in September 2026, where the build took two days
and the gating took most of the rest.

## The philosophy

- **Gates scale with blast radius, not with the phase.** A change that can lose the owner's
  data or silently corrupt state (a migration, storage, import/export) gets the full pair; a
  toolbar gets one reviewer and two rounds. "Load-bearing" means *what breaks if this is
  wrong*, never *how important the feature feels*.
- **Build fast, then decide the gate from the record.** Speed is measured, not felt: phases per
  day, review rounds per phase, passes before merge, time in review versus time building. When
  the owner asks whether the pace is warranted, the answer comes from those numbers.
- **The owner grants the levers, up front, as one-click decisions.** The manager never quietly
  relaxes a gate. Every lever below has a default, a cost and an owner's yes recorded in the
  repo.
- **Cut rounds and ceremony, never the safety net.** Tests stay. Hard rules stay. The reviewer
  is never dropped below high effort. What goes is the third round, the per-phase docs sync,
  the metrics row nobody reads, the pair on a prototype.
- **Human checks are placed, not deferred.** The one owner check that gates a build path (pen
  feel before ink tools; legibility before layout work) happens before that build, in fifteen
  minutes; the rest batch to the end of the run.
- **Re-tighten on triggers.** A second user, money, a shared repo, an external audience or a
  security-tier change puts the kernel's gates back. The profile is for the stretch where the
  only person who can be hurt is the owner.

## The files

| File | Role | When |
|---|---|---|
| `solo-speed-kickoff-prompt.md` | Paste with the project-initiation kickoff: collects the owner's six lever decisions and writes the speed-gates block into the repo | At project creation |
| `solo-speed-switch-prompt.md` | Convert a running project to the profile: pace review, levers, plan amendment outside the repo, then apply and run | Mid-project, when the owner says it is slow |
| `pace-review-prompt.md` | "Is the pace warranted?" — an assessment from the record, separating build time from gate time; ends in one-click questions | Any time the owner asks |
| `speed-gates-template.md` | The block transcribed into the repo (`PLAN.md` gates section or `AGENTS.md`): levers, defaults, non-negotiables, re-tighten triggers | Written by the two prompts above |
| `lessons.md` | Dated lessons per run | After each run |
| `CHANGELOG.md` | One line per suite-version bump | On edit |

## Flow

```text
new project:  PIS kickoff + solo-speed kickoff ──► gates block in repo ──► run to phase N
running one:  pace review ──► levers (owner, one click) ──► amendment (outside repo) ──► apply ──► run
either:       foundation phase first ──► independent phases in parallel worktrees ──► single review,
              two rounds, merge ──► docs sync once at the end ──► owner report + human checks
```

## Relations

- `project-initiation-suite`: the kernel. Its structure prompt's review-convergence rules and
  the three-round cap remain the default for shared and production work; this suite is the
  named, owner-granted deviation for solo prototypes.
- `agent-stack-comparison-suite`: a twin run doubles every cost in this suite. Run the
  comparison on a short frozen plan, then pick one lane and switch it to the speed profile.

## Conventions

Same as the kernel: every prompt carries `Version:` and `Last updated:`; the repo records the
suite version it runs under; the repo never references the folder these prompts live in (state any needed rule inline).

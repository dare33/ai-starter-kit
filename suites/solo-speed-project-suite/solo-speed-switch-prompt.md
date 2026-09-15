# Solo-speed switch prompt

Version: 1.0 — Last updated: 2026-09-04
Companions: `pace-review-prompt.md`, `speed-gates-template.md`. Missing companion = stop and ask.

Use on a **running** project when the owner says it is moving too slowly, or when a deadline
appears (a demo, a meeting, a first outside user). Do the steps in order; each has an owner
decision or an artifact at the end, and nothing in the repo changes until step 5.

## Steps

1. **Read the record.** `PROMPT.md`, `CHANGELOG.md`, the feature docs' review lines and
   ledgers, `metrics.md` if present, `git log`. Note phases done, rounds per phase, passes
   before each merge, in-flight branches that are built but unreviewed or unmerged.
2. **Pace review.** Run `pace-review-prompt.md`. Deliver it as an assessment, then stop for
   the owner's answer. Do not touch the repo.
3. **Levers.** Ask the six lever questions from the kickoff prompt, one click each, with the
   record's numbers beside each default. Add one question for any human check that gates a
   build path still ahead.
4. **Amendment, outside the repo.** Draft the plan amendment in the scratch area, in the
   plan's own shape: decision rows for the plan's decisions table; one phase per feature
   group with agent-checkable acceptance criteria, review gate and branch name; a content or
   owner track for work that is not code; a difficulty-and-order table; changes to the
   plan's Later list and risks; the owner's front-loaded decisions listed by name. Include the
   speed-gates block. Hand the owner the file. Wait for approval.
5. **Apply.** Paste the amendment into the plan (a mechanic can do it); write the short
   feature specs; record the levers as the speed-gates block; commit as docs-only. If the
   repo has an in-flight built-but-unreviewed branch that the new phases build on, review
   and merge it first under the new gates.
6. **Run.** Foundation phase first, alone, with the pair if it can lose data. Then the
   independent phases in parallel worktrees, one implementer each, one reviewer each at high
   effort, two rounds, merge. Keep a single manager thread adjudicating; fold findings with
   the implementer, never the reviewer; never fold while a reviewer reads the branch.
7. **Docs sync once.** At the end of the run: one CHANGELOG entry, the session handoff
   rewritten, metrics if kept, the feature docs' review lines and ledgers.
8. **Report.** Plain English: what was built, what was verified and where, what was cut and
   why, the owner checks now due, and the re-tighten triggers to watch.

## What to say if the owner asks whether the machinery was worth it

Answer from the record, in this order: what the build produced per day; what the gating cost
per phase; which parts paid for themselves (usually the tests and the domain split); which did
not (usually the late rounds, the per-phase ceremony, the pair on a prototype). Then the
levers. Never defend the process; the owner is deciding, not asking for reassurance.

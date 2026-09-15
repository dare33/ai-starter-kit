# Solo-speed kickoff prompt

Version: 1.0 — Last updated: 2026-09-04
Companions: `project-initiation-suite/project_kickoff_prompt.md` (and its structure + security
prompts), `speed-gates-template.md`. Missing companion = stop and ask.

Paste this together with the project-initiation kickoff and the plan. It adds a **speed
profile** to the scaffold. The kernel still decides modules and the security tier; this prompt
decides how fast the build is allowed to go and records who granted it.

## What you do

1. Read the plan and the kernel's proposal. Confirm the project qualifies: one owner, no other
   user's data, no money, Low security tier, private repo, no external audience during the
   run. If any of these fails, say so and stop — the profile does not apply.
2. Ask the owner the **six lever questions** with the harness's structured question tool,
   one click each, defaults marked. Never infer an answer.
   1. **Deadline and horizon.** The date the prototype must be in the owner's hands, and the
      phase number to run to without owner involvement.
   2. **Merge.** Standing exception for the run (a phase branch merges once its acceptance
      criteria pass and its review clears; fast-forward or ordinary merge only; lapses when the
      owner says) — yes or no.
   3. **Review.** Default: one reviewer at high effort per phase; the cross-vendor pair only
      on phases that can lose data or corrupt state (the template names them). Alternatives:
      pair everywhere; single everywhere.
   4. **Rounds.** Default: two rounds, then merge with residuals in the feature doc's ledger.
   5. **Docs cadence.** Default: a short feature spec before each build; CHANGELOG, the session
      handoff and any metrics once at the end of the run.
   6. **Human checks.** Which owner checks gate a build path and must happen before it (list
      them from the plan); everything else batches to the end.
3. Write the answers into the repo as the speed-gates block from `speed-gates-template.md`:
   a section in `PLAN.md` (dated, "owner-granted") and a pointer in `AGENTS.md`'s quality
   gates. Record the suite version beside the kernel's versions in `CLAUDE.md`.
4. Give every phase in the plan **agent-checkable acceptance criteria** and mark which owner
   check, if any, gates it. Order the phases so a foundation phase (schema, storage, shared
   types) lands first and the independent phases can run in parallel worktrees after it.
5. Finish the kickoff with the kernel's combined handoff report plus one paragraph: the
   levers granted, the horizon, the date, and the first owner check and when it falls.

## Rules that do not bend

The reviewer is never below high effort. One writer per worktree. Tests are not cut to buy
speed. Hard rules and the security tier stand. The manager reports every lowering of effort
or model and never raises either without the owner. A failed build returns to the manager,
never to a silent model swap. The repo never references the owner's note systems.

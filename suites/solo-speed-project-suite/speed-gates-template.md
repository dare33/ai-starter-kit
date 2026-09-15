# Speed-gates block (template)

Version: 1.0 — Last updated: 2026-09-04

Transcribe into the repo as a dated section of `PLAN.md` (for example "Post-MVP gates (owner,
<date>)") with a pointer from `AGENTS.md`'s quality gates. Replace every `<…>`. Keep the
non-negotiables verbatim. The repo must not name the owner's note systems or this suite's
path; the suite version goes in `CLAUDE.md` beside the kernel's versions.

```markdown
### Speed gates (owner, <date>) — solo-speed suite v1.0

Granted for <phases N–M> by the owner on <date>, for <the goal: a prototype by <date> for …>.

- **Review.** One independent reviewer at high effort per phase, two rounds, then merge with
  the remaining findings recorded as residuals in the feature doc's ledger. The cross-vendor
  pair runs only on: <phases that can lose the owner's data or corrupt state — migrations,
  storage, import/export, auth>. A reviewer is never below high effort.
- **Merge.** A phase branch merges once its acceptance criteria pass in-session and its review
  clears; fast-forward or ordinary merge only; never force-push, never rewrite pushed history.
  This exception lapses when the owner says <the run is done / the MVP is declared>.
- **Docs.** A short feature spec before each build (brief, design, decisions, acceptance
  criteria, test commands). `CHANGELOG.md`, the session handoff and <metrics> are written once
  at the end of the run, not per phase. Fold-decision records are not kept; residuals are.
- **Autonomy.** Run to <phase M> without owner involvement. Pause that phase only for: a
  credential, a deployment, a second user's data or spend; a reviewer finding that a change
  can lose data; a double failure of a pre-decided fallback. Finish everything not blocked.
- **Owner checks.** Before <phase K>: <the check that gates its build path, ~15 minutes>. All
  other human checks batch to the end of the run.
- **Parallelism.** Foundation phase first, alone. Then independent phases in parallel
  worktrees, one writer per worktree, one implementer and one reviewer each; never fold while
  a reviewer reads the branch. Up to <N> concurrent agents.
- **Not cut.** Tests. The hard rules. The security tier. Effort is lowered only with a report
  and never raised without the owner; models are never swapped silently.
- **Re-tighten when** any of these appears: a second user, money, a shared repo, an external
  audience, a security-tier change. Then the kernel's gates return for the affected work.
```

## Notes for the writer

- "Can lose data" is the test for the pair, not "feels important". Name the phases; do not
  leave it to judgement mid-run.
- Put the owner's own words for the goal and date in the first line; the block is the record
  of a grant, and the grant is theirs.
- If the owner waives metrics, say so in the Docs line rather than deleting the file.

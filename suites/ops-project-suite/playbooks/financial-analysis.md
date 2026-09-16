# Playbook — Financial Analysis

Version: 0.5 (kit copy 2026-09-16) · Last updated: 2026-09-16
Cross-exercise layer; exercise-specific judgment lives in the domain playbooks
(e.g. `<projects folder>/playbooks/annual-fee-review-playbook.md`).

## Hard constraints are absolute, per line

- A legislated cap or award floor applies to **every line**, not the average. Build an
  automated "over cap" check column, keep it green, sweep every line before calling it final.
- **Rounding direction is a ruling, recorded before figures ship.** Rounding *up* can
  breach a cap; rounding *down* can look like a deliberate reduction — or underpay a
  person. The domain playbook proposes the direction per line type; kickoff confirms it
  into `CLAUDE.md` §Confirmed parameters with its source; that entry governs. With no
  entry: floor capped charges to the cent, round pay up, log the missing ruling in
  `prompt.md` §Open decisions. A line that is both pay and capped is never
  resolved by rounding the person down — lower the pre-rounded base so rounding up still
  sits within the cap, or stop and ask. Formulas: `ROUNDDOWN(value,2)` or
  `FLOOR(value,0.01)` floor to the cent; `FLOOR(value,2)` floors to a multiple of $2 and
  is wrong. Require a comment on any intentional rounding.

## Model architecture

- **One `Assumptions` baseline cell drives everything;** rate changes are a one-cell edit,
  never find-and-replace. Detail → summary by live formula; recalc on open. **Live formulas
  over pasted values**, with one canonical rate/wage table every row looks up.
- **Roll-ups: AVERAGE the per-unit averages, never SUM them** where an average is meant
  (a `SUMIFS` in place of `AVERAGEIFS` once showed ~$1,841 for a ~$150 fee). The Σ in the
  ratio below cancels; the $ columns must still average.
- **Name the roll-up method, with its formula, in §Confirmed parameters** (weighting basis,
  source, date); the summary tab states the applied method but is not a second authority.
  Not interchangeable: *ratio of the averages* = Σ(unit avg new) / Σ(unit avg old) − 1 —
  one unit one vote, each unit's % weighted by its old price level (the original runs used this);
  *mean of unit %s* = mean over units of (new/old − 1) — the only one equal-weighted in
  the % itself; *ratio of totals* = Σnew / Σold − 1, size-weighted. The gap between
  methods depends on the data. Reconcile per-line totals to the aggregate before anything
  is called final; the portfolio % carries its method's name; the expected gap between
  methods is recorded, not forced to zero.
- Summary matrices are for reading; **billing/payroll outputs are long-format** — one row
  per real line with its own value, rounded the way §Confirmed parameters says for that
  line type (never silently floored).

## Data quality — trust nothing returned

- **Scan every return line-by-line;** decisions hide in-sheet, in comments, in separate
  docs and in emails — reconcile all four. A change counts only when the **value is in the
  sheet AND the justification column is filled**; reject out-of-band justifications.
- Verify inclusion/exclusion flags before trusting any average; hard-typed values where
  formulas belong mask reality — restore the formula, flag it.
- **Flag source anomalies, don't silently fix** — record them in `prompt.md` open items
  until the owner rules.

## Verification logging (mandatory when Stakes: high — and during any bulk merge, at any stakes; see excel-word-ops §Merge)

Keep `verification-log.md` in the project root: after every merge/rebuild record rows in
vs out, formula-error count, spot-check results and the backup path, so QA figures are
retrievable without re-deriving them.

**Audited, not just logged (Stakes: high):** at milestones and at closeout, spawn the
`reviewer` role AND the `reviewer-gpt` role on the final artefacts (name them: the
workbook/document and `verification-log.md`), each with a one-paragraph brief naming what
to attack, to re-derive 2–3 randomly chosen QA lines. If GPT was never set up on this Mac,
a single-reviewer pass is the accepted ceiling — write that down and continue; if GPT is
set up but the pass failed to run, report it as OUTSTANDING and do not call the audit
passed. A finding stops the step until reconciled or consciously accepted with the reason
written down. Self-attested QA is a start, not a finish.

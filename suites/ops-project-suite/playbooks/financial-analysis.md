# Playbook — Financial Analysis

Version: 0.4 (kit copy 2026-09-16) · Last updated: 2026-09-16
Distilled from the spreadsheet projects this suite was built from. Exercise-specific
judgment lives in the domain playbooks (e.g.
`~/developer/playbooks/annual-fee-review-playbook.md`); this is the cross-exercise layer.

## Hard constraints are absolute, per line

- A legislated cap or award floor applies to **every line**, not the average. Build an
  automated check column ("⚠ Over cap" style) and keep it green; run a full per-line sweep
  before anything is called final.
- Rounding is a compliance event: rounding *up* can breach a cap; rounding *down* can look
  like a deliberate reduction. Pre-fill capped values with `ROUNDDOWN`/`FLOOR(...,2)`;
  require a comment on any intentional rounding.

## Model architecture

- **One `Assumptions` baseline cell drives everything.** Rate changes are a one-cell edit,
  never find-and-replace. Detail tabs → summary tabs by live formula; recalc on open.
- **Live formulas over pasted values** in consolidations, with one canonical reference
  table (rate/wage tables) in the master that all rows look up.
- **Roll-ups: AVERAGE the per-unit averages, never SUM them** where an average is meant;
  pick one portfolio-% definition (ratio-of-averages is the tested default) and state it
  on the summary tab.
- Summary matrices are for reading; **billing/payroll outputs are long-format** — one row
  per real line with its own value, floored to the cent.

## Data quality — trust nothing returned

- **Scan every return line-by-line;** never assume "mostly at the default". Decisions hide
  in-sheet, in comments, in separate docs, and in emails — reconcile all four before
  trusting a return.
- A change is only accepted when the **value is in the sheet AND the justification column
  is filled**. Reject out-of-band justifications.
- Verify inclusion/exclusion flags before trusting any average; check for hard-typed values
  where formulas should be (they mask reality — restore the formula, flag the anomaly).
- **Flag source anomalies, don't silently fix** — record them (missing rates, corrupted
  cells) in `prompt.md` open items until the owner rules.

## Verification logging (mandatory when Stakes: high — and during any bulk merge, at any stakes; see excel-word-ops §Merge)

Keep `verification-log.md` in the project root: after every merge/rebuild, record row
counts in vs out, formula-error count, spot-check results, and the backup path. The QA
figures must be retrievable without re-deriving them.

**Audited, not just logged (Stakes: high):** at major milestones and at closeout, run the
kit's `reviewer` agent on it (ask Claude to "spawn the reviewer role on <file>" with a
one-paragraph brief naming what to attack), and `/gpt review <file>` as well when GPT is
set up, to re-derive 2–3 randomly chosen QA lines from the artifacts. A finding stops the
step until it is reconciled or consciously accepted with the reason written down.
Self-attested QA is a start, not a finish.

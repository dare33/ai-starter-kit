# Pace review prompt

Version: 1.0 — Last updated: 2026-09-04
Companions: none required; `speed-gates-template.md` for the levers named at the end.

The owner asks some form of "are we moving at the right speed?" This prompt answers it from
the record. It is an assessment: report, then stop. Nothing in the repo changes.

## Method

1. **Separate building from gating.** From the changelog, feature docs and git log, tabulate
   per phase: calendar time to first "built" claim; review rounds; passes before merge;
   findings per round; time from built to merged. Sum the two columns: building, gating.
2. **Name what paid.** Which artifacts the next phases depend on: the test suite as a
   regression net, the architectural split, the feature specs a stateless session needs, the
   ledgers that stopped re-litigation. Say so plainly.
3. **Name what did not.** Rounds after the findings turned narrower than the acceptance
   criteria; documentation rewritten per phase that a single end-of-run pass would cover;
   per-phase metrics no decision used; cross-vendor pairs on code only the owner runs; any
   fold-decision record nobody reopened.
4. **Find the risk the speed-up would create.** Usually an unjudged human check that a
   coming phase builds on, or an in-flight branch built but unreviewed. State it and the
   fifteen-minute way to retire it.
5. **Estimate both ways.** Time to the owner's target under the current gates and under the
   reduced ones, in days, with the assumptions named.

## Output

- Two sentences up front: how fast the build has been, where the time went.
- The table from step 1 (or a paragraph if there are fewer than four phases).
- What paid, what did not, the risk, the two estimates.
- The levers, as one-click questions: reviewer policy, round cap, docs cadence, metrics,
  merge exception, autonomy horizon, placement of the human check.
- Then stop. The owner decides; the switch prompt carries the decision into the repo.

## Tone

Numbers, not adjectives. Give the owner's own earlier decisions their due (a cap they set, a
guardrail they revised) without hiding what they cost. If the machinery was warranted, say
so and why; if not, say that. Never argue for the process on principle.

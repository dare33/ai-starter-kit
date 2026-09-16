# Playbook — Legal Review

Version: 0.1 (kit copy 2026-09-16) · Last updated: 2026-09-16
For reviewing contracts, leases, compliance docs, and employment matters for a small
business or a personal matter. Australian context (Fair Work, ACECQA/National Law for
childcare, state regs) unless stated otherwise.

## Framing — always

- Output is **analysis to inform the owner's decision, not legal advice**. Say so once per
  deliverable. Anything with dismissal, litigation, or regulator exposure ends with an
  explicit recommendation to get ER/legal sign-off before acting.
- Never present a legal position without stating confidence and what would verify it
  (statute section, award clause, the contract's own words).

## Review workflow

1. **Fix the question first** — what decision does this review serve? Review against that,
   not everything.
2. **Cite by clause.** Every finding names its clause/section number and quotes the
   operative words. No un-anchored claims about "what the contract says".
3. **Findings land in a risk table:** clause → issue → risk (high/med/low) → recommended
   action → who decides. High = money, termination rights, liability, IP, personal
   guarantees, regulator exposure.
4. **Check the boring load-bearing clauses** even when asked about something else: term +
   renewal/notice dates, termination triggers, indemnities, liability caps, assignment,
   payment escalators (CPI/market review), and anything by reference ("as per Schedule X"
   — read Schedule X).
5. **Dates become actions.** Notice windows and renewal deadlines go into the project's
   `todo.md` (or a reminder) at review time, not discovery time.

## Document discipline

- Review the **exact version** supplied; record filename + date reviewed in the changelog.
  Counterparty redlines: diff against the last agreed version before reading their summary.
- Marked-up returns use tracked changes/comments — never silent edits.
- Statutory/award facts are verified against the current primary source **at review time**
  (rates and thresholds change annually) and carry the checked date.
- Employment performance/dismissal matters: use the `performance-management` skill if
  installed — it encodes the Fair Work process.

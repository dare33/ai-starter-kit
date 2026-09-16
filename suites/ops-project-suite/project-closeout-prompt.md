# Project Closeout Prompt — Ops Project Suite

Version: 0.6 (kit copy 2026-09-16) · Last updated: 2026-09-16

> Paste this into a session opened in the finished project folder.
> This is the step that makes the suite compound — do not skip it.

---

You are closing out an operational project governed by the ops-project-suite. Steps:

## 1. Verify it's actually done

Read the project's `prompt.md` and `todo.md`. If open items remain, list them plainly and
stop — closeout only proceeds on the owner's confirmation.

Read the suite version recorded in the project's `CLAUDE.md`; if it differs from the
version at the top of `~/ai-starter-kit/suites/ops-project-suite/ABOUTME.md`, list the
`CHANGELOG.md` lines between them and say which changed rules this project did not follow.

If `Stakes: high`: run the **verification audit** — re-derive 2–3 randomly chosen
`verification-log.md` lines from the artefacts themselves — a figure recomputed, or for a
document/legal project a claim re-checked against its clause or source. If the log is
absent or holds only its header, the audit instead re-derives 2–3 final figures or claims
from the artefacts against their sources directly — say so. Then run the reviewers on the
final artefacts (name them: the workbook or document, and `verification-log.md` if it has
entries): spawn the `reviewer` role AND the
`reviewer-gpt` role, each with a one-paragraph brief naming the exact artefacts and what
to attack; if `reviewer-gpt` is unavailable because GPT was never set up on this Mac, a single-reviewer pass is the accepted ceiling — write that down as the reason and continue; if GPT is set up but the pass failed to run, report it as OUTSTANDING and do not call the audit passed. Self-attested QA is a start,
not a finish. A finding or discrepancy stops closeout until it is reconciled or consciously
accepted with the reason written down.

## 2. Distill lessons into the local lessons home (the core step)

Read the project's `lessons.md` and `changelog.md` and split every durable takeaway by kind.

**Data boundary (mandatory, before anything crosses):** the local lessons home
(`<projects folder>/lessons/` and `<projects folder>/playbooks/`) is meant to be shared and
may be synced, and the boundary has applied since the project's first day, not only now.
Strip or generalise anything person-identifiable — individual rates/salaries, names tied to
numbers, non-public client identities — from every lesson, playbook edit, and `PROJECTS.md`
row before it leaves the project folder. Process lessons never need row-level data.

**Layering rule (the sorting criterion):** suite playbooks are task-family generic — any
merge, any comms exercise, any review. A lesson that names a specific organisation,
exercise, or dataset can NOT land in a suite playbook; it goes to the domain layer and is
referenced. A task family no playbook covers → draft a new ≤4KB playbook in the suite's
`playbooks/` folder marked `reviewed: pending <date>` at the top, add a line to the suite
`CHANGELOG.md`, and tell the owner — it is not load-bearing until the next kickoff's
review clears it; never a new suite (suites split on lifecycle, not tool).

- **Generic tool/technique gotchas** (Excel internals, Drive-mount behaviour, docx tricks)
  → append to the matching `<projects folder>/lessons/<topic>.md`. Never duplicate an entry
  that's already there; sharpen it instead.
- **Domain judgment** (process design, policy framing, workflow order, what to confirm
  before starting) → update or create `<projects folder>/playbooks/<exercise>-playbook.md`
  (example: `annual-fee-review-playbook.md`). Mark every new or changed judgment rule
  `reviewed: pending <date>` — closeout does NOT review its own distillation. The playbook
  must open with a **boot sequence** for the next run: **first, clear any
  `reviewed: pending` entries** — spawn the `reviewer` role AND the `reviewer-gpt` role,
  each with a one-paragraph brief naming the exact artefacts (list them) and what to
  attack; if `reviewer-gpt` is unavailable because GPT was never set up on this Mac, a single-reviewer pass is the accepted ceiling — write that down as the reason and continue; if GPT is set up but the pass failed to run, report it as OUTSTANDING and do not call the audit passed; a finding stops the step
  until it is reconciled or consciously accepted with the reason written down — **the
  playbook is not load-bearing until they're cleared**; then clone this folder as
  scaffold, confirm this year's parameters + sources, reset state files, re-issue
  templates, set deadline + default.
- **Suite-level friction** (a template section that misled, a missing playbook rule; check
  lessons.md §Suite friction) → write the proposed edit into `lessons.md` §Suite friction and send it to whoever
  shared the kit; do not edit the suite files in `~/ai-starter-kit` yourself (that folder
  is updated by pulling the latest kit, and a local edit would be lost or conflict).

**Promote, then prune (mandatory).** A lesson's best form is a changed default, not a
remembered note. When a takeaway becomes a template default, playbook rule, check column,
or boot-sequence step, **delete its prose form** from the lessons file / playbook — one
fact, one home. Then enforce ceilings: playbooks ≤ ~4KB, domain playbooks ≤ ~6KB. If an
update would breach a ceiling, promote or prune until it fits — never ship a bigger file.
Also dedupe: the target file may already carry the lesson — sharpen, don't append twins.

## 3. Retire the folder cleanly

- `prompt.md`: replace contents with a 5-line closed summary (outcome, date, pointer to the
  playbook). `todo.md`: everything ticked or explicitly carried to the playbook's boot list.
- Sweep stray files into `working-docs/temp/superseded/`.
- **Retention ruling:** `temp/` and `temp/superseded/` hold every backup of sensitive
  data made during the project. Ask the owner plainly: keep the backups for audit, or
  delete them now that the project is closed? Record the ruling in the final
  `changelog.md` entry.

## 4. Update the portfolio index

- `<projects folder>/PROJECTS.md` row → Status becomes `done`, Last touched = today, and
  the Purpose column gets ` → carry-forward: <playbook>` appended (e.g. `[ops] annual fee
  review against the CPI cap → carry-forward: annual-fee-review-playbook.md`), or
  ` → carry-forward: none` when the project produced no durable domain judgment — a
  one-off letter or document run legitimately has none. No client/personal names or
  amounts land in the row at closeout either — the same boundary that applied at kickoff.

Finish with a one-paragraph report: what was distilled where, and the single file next
time's session should open first (or "nothing to carry forward" when that is the truth).

# Project Closeout Prompt — Ops Project Suite

Version: 0.5 (kit copy 2026-09-16) · Last updated: 2026-09-16

> Paste this into a session with the finished project folder mounted.
> This is the step that makes the suite compound — do not skip it.

---

You are closing out an operational project governed by the ops-project-suite. Steps:

## 1. Verify it's actually done

Read the project's `prompt.md` and `todo.md`. If open items remain, list them plainly and
stop — closeout only proceeds on the owner's confirmation.

If `Stakes: high`: run the **verification audit** — re-derive 2–3 randomly chosen
`verification-log.md` QA lines from the artifacts themselves. Run the kit's `reviewer`
agent on it (ask Claude to "spawn the reviewer role on <file>" with a one-paragraph brief
naming what to attack), and `/gpt review <file>` as well when GPT is set up. Self-attested
QA is a start, not a finish. A finding or discrepancy stops closeout until it is reconciled
or consciously accepted with the reason written down.

## 2. Distill lessons into the local lessons home (the core step)

Read the project's `lessons.md` and `changelog.md` and split every durable takeaway by kind.

**Data boundary (mandatory, before anything crosses):** the local lessons home
(`~/developer/lessons/` and `~/developer/playbooks/`) is meant to be shared and may be
synced. Strip or generalise anything person-identifiable — individual rates/salaries, names
tied to numbers, non-public client identities — from every lesson, playbook edit, and
`PROJECTS.md` row before it leaves the project folder. Process lessons never need
row-level data.

**Layering rule (the sorting criterion):** suite playbooks are task-family generic — any
merge, any comms exercise, any review. A lesson that names a specific organisation,
exercise, or dataset can NOT land in a suite playbook; it goes to the domain layer and is
referenced. A task family no playbook covers → create a new ≤4KB playbook in the suite,
never a new suite (suites split on lifecycle, not tool — that's why coding repos have
their own).

- **Generic tool/technique gotchas** (Excel internals, Drive-mount behaviour, docx tricks)
  → append to the matching `~/developer/lessons/<topic>.md`. Never duplicate an entry
  that's already there; sharpen it instead.
- **Domain judgment** (process design, policy framing, workflow order, what to confirm
  before starting) → update or create `~/developer/playbooks/<exercise>-playbook.md`
  (example: `annual-fee-review-playbook.md`). Mark every new or changed judgment rule
  `reviewed: pending <date>` — closeout does NOT review its own distillation. The playbook
  must open with a **boot sequence** for the next run: **first, clear any
  `reviewed: pending` entries** — run the kit's `reviewer` agent on it (ask Claude to
  "spawn the reviewer role on <file>" with a one-paragraph brief naming what to attack),
  and `/gpt review <file>` as well when GPT is set up; a finding stops the step until it
  is reconciled or consciously accepted with the reason written down — **the playbook is
  not load-bearing until they're cleared**; then clone this folder as scaffold, confirm
  this year's parameters + sources, reset state files, re-issue templates, set deadline +
  default.
- **Suite-level friction** (a template section that misled, a missing playbook rule; check
  lessons.md §Suite friction) → propose the edit to the suite file itself, with the version
  bump, for the owner's approval.

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

- `~/developer/PROJECTS.md` row → status `done`, naming the carry-forward playbook.

Finish with a one-paragraph report: what was distilled where, and the single file next
year's session should open first.

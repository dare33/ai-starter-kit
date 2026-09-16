# Project Kickoff Prompt — Ops Project Suite

Version: 0.4 (kit copy 2026-09-16) · Last updated: 2026-09-16

> Paste this into a fresh session with the new project folder mounted. It scaffolds the
> governance set and registers the project.

---

You are setting up a new operational project folder using the ops-project-suite at
`~/ai-starter-kit/suites/ops-project-suite/`. Read `ABOUTME.md` there first. Then:

## 1. Gather parameters (ask, don't assume)

Ask the owner, one question at a time, with the one-click question tool if available
(plain chat otherwise):

- **Project name + folder** (kebab-case, e.g. `annual-fee-review-2027`).
- **Which folder under `~/developer`** this lives in.
- **One-paragraph purpose** and the key constraint(s) — e.g. a legislated cap, an award
  floor, a filing deadline. Constraints with legal force get their own KEY RULE. For every
  hard constraint, also ask **where it comes from** (statute/reg, award clause, email,
  file) — the value lands in `CLAUDE.md` §Confirmed parameters *with its source, dated*,
  so next year's run re-verifies the source instead of re-researching the number.
- **Stakes:** high or normal. Plainly: high means this touches money owed to or by real
  people, contracts, or legal exposure; otherwise it's normal. High stakes switches on
  verification logging and strict edit workflow. Default to normal.
- **Where the project folder lives and who has access** (local, cloud mount, shared
  drive; readers/writers). Mandatory when stakes are high — recorded in `CLAUDE.md`
  §Security defaults.
- **Applicable playbooks** — offer the current contents of `playbooks/` (an open set; it
  grows as closeouts add new task families). Also ask whether a domain-layer note applies
  (e.g. an organisation's comms patterns) and name it in `CLAUDE.md` §Playbooks.
- **Is there a prior-year folder or domain playbook?** If yes, the prior folder is the
  scaffold for working files (clone its structure, clear its state) and the domain playbook
  (e.g. `~/developer/playbooks/annual-fee-review-playbook.md`) is the judgment layer — read
  its boot sequence.

## 2. Scaffold the folder

- Create: `working-docs/`, `working-docs/temp/`, `working-docs/temp/superseded/`,
  `working-docs/supporting-evidence/`.
- Copy each file from `templates/` into the project root, dropping the `-template` suffix
  (`CLAUDE-template.md` → `CLAUDE.md`, etc.).
- Fill every `<placeholder>` in `CLAUDE.md` and `prompt.md` from step 1. Delete any section
  that doesn't apply — the hub must stay ≤ ~4KB. Record the suite version in `CLAUDE.md`.
- Inline the 5-line safety card from `playbooks/excel-word-ops.md` §Safety card into
  `CLAUDE.md` if the project touches Office files at all.

## 3. Register

- Create `~/developer/lessons/` and `~/developer/playbooks/` if missing. On FIRST use of
  this suite, copy the suite's `lessons/*.md` seeds into `~/developer/lessons/` (never
  overwrite an existing file).
- Add a row to `~/developer/PROJECTS.md` — create it from the header + example row in
  `suites/project-initiation-suite/project_maintenance_prompt.md` if it doesn't exist yet:
  name, purpose, stakes, folder path, playbooks named, date.

## 4. Self-check (mechanical — run before reporting, fix anything that fails)

- No unfilled `<placeholder>` remains anywhere in the scaffolded files (grep for `<`).
- `CLAUDE.md` is ≤ ~4KB and records the suite version.
- If `excel-word-ops` is a named playbook, the safety card is inlined in `CLAUDE.md`.
- `~/developer/lessons/` and `~/developer/playbooks/` exist.
- The `~/developer/PROJECTS.md` row exists.
- Every hard constraint in §Confirmed parameters carries a source and a date.
- §Security defaults is present, and the folder-location line is filled when stakes are high.

## 5. Hand off

Finish with a short report: folder tree created, playbooks wired, stakes level, self-check
result, the first three actions now sitting in `prompt.md`, and anything from step 1 you
couldn't resolve. Do not begin substantive work in the kickoff session unless the owner
says so.

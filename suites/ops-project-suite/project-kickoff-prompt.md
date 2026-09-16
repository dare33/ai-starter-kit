# Project Kickoff Prompt — Ops Project Suite

Version: 0.5 (kit copy 2026-09-16) · Last updated: 2026-09-16

> Paste this into a fresh session opened in the new project folder. It scaffolds the
> governance set and registers the project.

---

You are setting up a new operational project folder using the ops-project-suite at
`~/ai-starter-kit/suites/ops-project-suite/`. Read `ABOUTME.md` there first. Then:

## 1. Gather parameters (ask, don't assume)

Ask the owner, one question at a time, with the one-click question tool if available
(plain chat otherwise):

- **Projects folder.** Read the `WRITE_PARENTS` line of `~/.claude/scripts/codex-agent.sh`
  to resolve it (default `~/developer`), or ask if that file isn't present. Write the
  resolved ABSOLUTE path into the new project's `CLAUDE.md` §Confirmed parameters, and use
  it (not a placeholder) everywhere §Playbooks names a lessons-home file.
- **Project name + folder** (kebab-case, e.g. `annual-fee-review-2027`), inside the
  projects folder just resolved.
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
  (e.g. `<projects folder>/playbooks/annual-fee-review-playbook.md`) is the judgment layer
  — read its boot sequence.

## 2. Scaffold the folder

- Create the project folder `<projects folder>/<name>` and open the session there if not
  already.
- Create: `working-docs/`, `working-docs/temp/`, `working-docs/temp/superseded/`,
  `working-docs/supporting-evidence/`.
- Copy each file from `templates/` into the project root, dropping the `-template` suffix
  (`CLAUDE-template.md` → `CLAUDE.md`, `AGENTS-template.md` → `AGENTS.md`, etc.).
- Fill every `<placeholder>` in `CLAUDE.md` and `prompt.md` from step 1. Delete any section
  that doesn't apply — the hub must stay ≤ ~4KB. Record the suite version in `CLAUDE.md`.
- Inline the 5-line safety card from `playbooks/excel-word-ops.md` §Safety card into
  `CLAUDE.md` if the project touches Office files at all.
- If Stakes is high, create `verification-log.md` with a 3-line header: what the file is,
  then one line per verified figure in the form `date | artefact | figure | source | who
  checked`.

## 3. Register

- Create `<projects folder>/lessons/` and `<projects folder>/playbooks/` if missing. On
  FIRST use of this suite, copy the suite's `lessons/*.md` seeds into
  `<projects folder>/lessons/` (never overwrite an existing file).
- Add a row to `<projects folder>/PROJECTS.md` — create it from the header in
  `~/ai-starter-kit/suites/project-initiation-suite/project_maintenance_prompt.md` if it
  doesn't exist yet. Use that exact header, and fill the row with: Project = the project
  name; Purpose = `[ops] <one-line purpose, no client names, personal names, or amounts>`;
  Status = `active`; Tier = `ops · stakes normal|high`; Credentials = `none` (or what
  applies); Expected spend = `none`; Remote = the absolute project folder path (local, no
  git); Last touched = today. The row is index data, not project data — it never carries
  more than that one generic line, from the first day.

  Example row:
  `| annual-fee-review-2027 | [ops] annual fee review against the CPI cap | active | ops · stakes high | none | none | /Users/you/developer/annual-fee-review-2027 (local, no git) | 2026-09-16 |`

## 4. Self-check (mechanical — run before reporting, fix anything that fails)

- No unfilled `<placeholder>` remains anywhere in the scaffolded files (grep for `<`).
- No `v0.` literal remains anywhere in the scaffolded files.
- `CLAUDE.md` is ≤ ~4KB and records the suite version.
- If `excel-word-ops` is a named playbook, the safety card is inlined in `CLAUDE.md`.
- `<projects folder>/lessons/` and `<projects folder>/playbooks/` exist.
- The `<projects folder>/PROJECTS.md` row exists and carries no client/personal names or
  amounts.
- `verification-log.md` exists with its 3-line header when Stakes is high.
- Every hard constraint in §Confirmed parameters carries a source and a date.
- §Security defaults is present, and the folder-location line is filled when stakes are high.

## 5. Hand off

Finish with a short report: folder tree created, playbooks wired, stakes level, self-check
result, the first three actions now sitting in `prompt.md`, and anything from step 1 you
couldn't resolve. End with the literal instruction: "Next time, open the Code session in
<absolute project folder> — not your home folder." Do not begin substantive work in the
kickoff session unless the owner says so.

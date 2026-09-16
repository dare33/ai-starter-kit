# Project Maintenance Prompt

Version: 1.7 — Last updated: 2026-09-16 (kit-only addition: ops-tier row handling for
rows scaffolded by the ops-project-suite, see below)

Companions: `project_structure_prompt.md`, `project_security_prompt.md`, and `PROJECTS.md` (the portfolio index, kept outside any repo, suggested `~/developer/PROJECTS.md`).

`PROJECTS.md` row format — create the file with this header if it doesn't exist yet:

| Project | Purpose | Status | Tier | Credentials | Expected spend | Remote | Last touched |
| --- | --- | --- | --- | --- | --- | --- | --- |
| example-project | one-line purpose | active | Low | none | $0/mo | github.com/you/example-project (or local only) | 2026-09-15 |

- Rows whose Tier starts with `ops` are non-code projects from the ops-project-suite: for those, skip SECURITY.md, dependency audits, git history and remote checks; confirm only that the folder exists and the Status is current.

Portfolio root: `<fill in at use — the folder containing my project folders>`

Run this sweep over my project portfolio. Cadence: monthly backstop for an active portfolio, quarterly at minimum. Additionally, sync the affected project's index row (a targeted mini-sweep of Step 0 plus that project, not the full portfolio) immediately when any of these events happens: major release or milestone closure; platform or architecture pivot; deployment or audience change; security-tier, credential, or spend change; pause or retirement. These triggers are owner-side: repos still never reference `PROJECTS.md` — the trigger fires off in-repo `CHANGELOG.md`/`SECURITY.md` events (each release report flags when an owner-side sync is due, per the structure prompt's quality gates).

This is an audit, not a repair job: report findings and queue tasks; fix nothing without my approval. The only writes permitted without asking are `PROJECTS.md` row updates that bring the index in line with reality.

The sweep is also the official sync path between repos and the index: `PROJECTS.md` is owner-side personal infrastructure, and collaborators never write to it. Lifecycle, tier, and spend changes made by anyone surface in each repo's `SECURITY.md` and `CHANGELOG.md`, and get reconciled into the index here.

## Step 0 — Reconcile the index

1. Read `PROJECTS.md` and list the project folders on disk.
2. Note the date and headline findings of the previous sweep from the Sweep log in `PROJECTS.md`; all "since the last sweep" checks below run from that date. If no sweep is logged, treat each project's scaffold date as the baseline.
3. Flag any project on disk that is missing from the index, and any index row whose folder or remote no longer exists.
4. Refresh "Last touched" dates from git history where stale, and the "Expected spend" column from each project's `SECURITY.md` — the authoritative record of expected spend.

## Per active project

Read each project's `CLAUDE.md` and `SECURITY.md` first, then check:

1. **Doc reality** — `CLAUDE.md`'s module inventory (present and deliberately-absent lists) matches disk; `README.md` status/layout/commands, `docs/index.md`, and `features/README.md` match reality; `PROMPT.md` reflects the actual current state; `CHANGELOG.md` covers recent git history; hot docs (`PLAN.md`, `SECURITY.md`, `CHANGELOG.md`, `PROMPT.md`) are within the structure prompt's documentation ceilings. Flag drift and oversized docs.
2. **Dependencies** — run the stack's audit (`npm audit`, `pip-audit`, or equivalent). Flag criticals and highs; summarize the rest.
3. **Credentials** — reconcile the inventory in `SECURITY.md` against `.env.example` and code. Flag unused credentials for revocation and any past the rotation cadence for the project's tier (see the security prompt: Medium 12 months, High 6 months).
4. **Remote visibility** — confirm the repository remote is still private (or its recorded intended visibility), and that the git host's security features (secret scanning, dependency alerts) remain enabled.
5. **Spend** — compare visible API or hosting spend against the expected spend recorded in `SECURITY.md`; where spend isn't visible to you, list exactly what I should check manually.
6. **Backups** — the restore path in `SECURITY.md` is documented and current; for High-tier projects, confirm a restore test happened within the period.
7. **Tier re-check** — has any escalation trigger from the security prompt tripped since the last sweep (new data types, wider audience or deployment, visibility change, new credentials, third-party breach, critical dependency CVE)?
8. **Lifecycle** — untouched for 3+ months: propose pausing or retiring. Paused or idle while holding live credentials or a deployed surface: propose the decommissioning checklist.
9. **Prompt drift** — compare the prompt versions recorded in the project's `CLAUDE.md` against the current versions of the kickoff, structure, and security prompts; note material rule changes the project predates.

## Paused and retired projects

- Retired: spot-check that decommissioning was completed — no live credentials, no running deployments.
- Paused: confirm the stated reason and re-check date still stand; escalate any paused Medium+ project with a live surface or credentials.
- Paused: flag any avoidable spend still running (hosting, subscriptions, paid API plans) — a paused project should cost nothing, or its ongoing spend needs a stated reason.

## Report

Finish with a single portfolio report, risk-ordered:

- Per project: OK, or findings with severity.
- Decisions I need to make: revocations, retirements, tier changes, spend anomalies.
- After my confirmation (not before), write agreed findings into each affected project's `PROMPT.md` as explicit tasks.
- Note which `PROJECTS.md` rows were updated during the sweep.
- Close the sweep by adding a row to the Sweep log in `PROJECTS.md`: date, projects covered, headline findings. This row is permitted without asking, like other index updates.

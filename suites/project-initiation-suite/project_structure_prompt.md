Version: 2.0 (kit copy: remote optional) — Last updated: 2026-09-15

I want you to scaffold a new project using my preferred repo operating structure. A fully fleshed-out plan already exists for this project — treat it as the source of truth for every decision below. Do not copy domain-specific features or content from any previous project.

Companion: `project_security_prompt.md` governs all security and privacy controls for the project. If it was not provided alongside this prompt, ask for it before scaffolding anything that touches credentials, personal data, or a deployed surface.

## Step 0 — Derive the project profile from the plan

Before creating anything, extract the following from the plan. Only ask concise blocker questions if something is genuinely missing from the plan and cannot be safely defaulted:

- Project name and slug
- Owner and audience
- Project type(s) — one or more of: web app, API/service, CLI tool, library/package, data pipeline or analysis, dashboard/report, static site, automation/scripts, mobile app, infrastructure, docs/knowledge base
- Primary stack, language, and package manager
- Inputs (data sources, APIs, user input) and output surfaces (report, workbook, dashboard, API, CLI, site, package)
- Data sensitivity: public, internal, confidential, or regulated/PII
- Deployment target, if any (local only, CI, hosted, published package)
- Expected running costs and budget cap (API spend, hosting, subscriptions), and who pays
- Ownership: internal, or built for / delivered to a client — and if so, who owns the code and data

If a detail is unknown, use a neutral placeholder and clearly mark it as a placeholder. Never invent facts.

Confirmation gate: when the project security prompt is provided alongside this one, present a single combined proposal before creating anything — the derived project profile, the modules you will include and exclude with one-line reasons, and the proposed security tier with justification — and wait for my confirmation. The confirmed tier may change the module list (for example, a High tier forces CI config so audits can be automated). When this prompt is used alone, proceed autonomously with placeholders as above.

## Step 1 — Core scaffold (every project)

Create one self-contained project folder named `<project-slug>/`. These files and folders are always created, regardless of project type:

```text
<project-slug>/
  CLAUDE.md
  AGENTS.md
  README.md
  PROMPT.md
  PLAN.md
  CHANGELOG.md
  .gitignore
  docs/
    index.md
    archive/
      README.md
    spikes/
      SPIKES.md
```

- `CLAUDE.md` lives at the project root and is the project constitution and doc map for Claude-oriented sessions.
- `AGENTS.md` is the model-neutral contributor policy for any coding agent.
- Do not create a parent-level `CLAUDE.md` unless the parent folder intentionally governs multiple related projects.
- `PLAN.md` is seeded from the existing plan, not rewritten from scratch.
- For projects that contain code, add `src/` (or the stack-idiomatic source root), `tests/`, and the stack manifest per the conditional table in Step 2: `pyproject.toml` + `src/<package_name>/` for Python, `package.json` + `src/` for Node/TS, `Cargo.toml` + `src/` for Rust, `go.mod` + idiomatic package layout for Go, and so on. Keep the same architecture principle everywhere: entry points are thin, reusable logic lives in source modules, and tests exercise source modules rather than shelling through entry points wherever practical.
- Initialize a git repository and make an initial commit once the scaffold is complete. `.gitignore` must be written before that first commit. Create a private GitHub remote and push if a GitHub account is set up; otherwise keep the repo local, record that in `CLAUDE.md`, and add the remote later. Projects live in plain local folders — never inside cloud-synced directories (Google Drive, OneDrive, Dropbox), which corrupt git repositories.
- Register the project in `PROJECTS.md`, the portfolio index kept outside any repo (suggested `~/projects/PROJECTS.md`): purpose, status, security tier, credentials held, expected monthly spend (mirrored from `SECURITY.md`, which is the authoritative record), remote, and date. This is an owner-side step that happens outside the repo: the index is my personal portfolio lens, and its upkeep is never a repo obligation. In-repo sessions record lifecycle, tier, and spend changes in `CHANGELOG.md` and `SECURITY.md` as they already must; my maintenance sweep syncs the index from those. If this prompt is used without the kickoff prompt and the portfolio root or index location isn't evident, ask for them rather than guessing.

## Step 2 — Conditional modules (only if the plan calls for them)

Do not create empty directories or docs "just in case." Every scaffolded module below must be justified by the plan. If a need emerges later, add the module then. Include:

| Module | Include when |
|---|---|
| `src/` (stack-idiomatic source root), stack manifest, and `tests/` with `README.md` | The project contains code — i.e. anything beyond pure docs/content |
| `apps/` + `packages/` workspace layout (monorepo) | The project ships more than one app surface (e.g. web + native) from one repo; see Monorepo conventions below |
| `data/` with `raw/`, `processed/`, `README.md` | The project ingests, stores, or transforms source data |
| `schemas/` with `README.md` | There are data contracts, API contracts, or validated file formats |
| `outputs/` with `README.md` | The project generates artifacts (reports, exports, summaries, builds consumed elsewhere) |
| `scripts/` with `README.md` | There are pipeline, build, or maintenance commands beyond the package manager's standard ones |
| `config/` with `README.md` | There is external, non-secret configuration beyond the stack manifest |
| `.env.example` | The project needs environment variables, credentials, or API keys at runtime |
| `SECURITY.md` | The project touches credentials, private/confidential data, PII, or has a deployed/exposed surface. Exception: when my project security prompt is applied alongside this one, it governs `SECURITY.md` and always creates it, regardless of tier |
| `docs/methodology.md` | There is a model, calculation, analysis, or scoring logic whose assumptions need documenting |
| `docs/data_handling.md` | The confirmed security tier requires it (see the project security prompt); default trigger is regulated, confidential, or personal data |
| `docs/bugfixes.md` | Expected to accumulate non-trivial debugging history (default: include for apps/pipelines, skip for small libraries/scripts) |
| `docs/scoping/<topic>.md` | Roadmap-stage exploration precedes buildable feature work — possibilities, platform reality, unresolved choices; not buildable contracts. The cluster gets a start-here README once it grows |
| `docs/deploy.md` (or `docs/distribution.md`) | The project has a deployed or distributed surface needing a repeatable runbook: deploy steps, live verification, store/distribution procedure |
| `PATCHNOTES.md` | There is a user-facing product surface (app, dashboard, report, site) whose changes users need to see; skip for internal tooling and libraries |
| `features/` with `README.md`, `TEMPLATE.md` | The project has multiple distinct features to build and track; skip for single-purpose tools |
| `migrations/` | There is a database with schema evolution |
| `public/` or `static/` | The project serves static assets |
| `notebooks/` | Exploratory analysis is part of the workflow |
| CI config (e.g. `.github/workflows/`) | The plan specifies CI, deployment, or a published package |
| `Dockerfile` / infra config | The plan specifies containerized or hosted deployment |

When a module is excluded, its associated conventions and change rules below simply do not apply.

## Session protocol

1. Start every session by reading `PROMPT.md`.
2. Read `AGENTS.md` or `CLAUDE.md` when policy, safety rules, project map, or session behavior is needed.
3. Open `PLAN.md` only at sections named by `PROMPT.md`, unless broader architecture context is necessary.
4. Read feature docs only when `PROMPT.md`, `PLAN.md`, or the task points to the relevant feature.
5. Unscoped work (no approved plan or feature doc) is planned first: draft the plan, present it, and stop for owner approval before building (see Working discipline; trivial mechanical fixes are exempt).
6. End every mutating session by updating `CHANGELOG.md` if anything changed, then rewriting `PROMPT.md` wholesale. After a read-only session, leave `PROMPT.md` untouched — update it only when the owner separately authorizes recording a materially changed external state.
7. Finished items leave `PROMPT.md`; durable history belongs in `CHANGELOG.md`.
8. If `PLAN.md` is touched, re-check `PROMPT.md` before finishing.

## Transcription rule

This prompt is only visible to the scaffolding session. Transcribe its durable rules into the repo so future sessions behave identically without it:

- Session protocol and change rules → `CLAUDE.md`.
- Architecture conventions, working discipline, quality gates, and the release checklist → `AGENTS.md`.
- The confirmed security tier and its controls → `SECURITY.md`, per the project security prompt.
- Portfolio-index obligations (`PROJECTS.md`) are owner-side and must NOT be transcribed into `CLAUDE.md` or `AGENTS.md`. The repo stays self-contained for collaborators: its own docs are the only interface it imposes.
- `CLAUDE.md` opens with a short numbered "Hard rules (read before writing anything)" block of absolute prohibitions (recommended at Medium tier and above). Those absolutes may be deliberately repeated in `AGENTS.md` — mark each copy "repeated because absolute" so the duplication is visible and drift between copies is detectable.

`CLAUDE.md` and `AGENTS.md` must be self-sufficient: a future agent with no access to this prompt should behave identically.

## Doc ownership

Core docs (always present):
- `CLAUDE.md`: project constitution, doc map, session rules, and high-level operating model. Must list which conditional modules exist in this project AND which are deliberately absent (annotated "add only when justified"), so agents neither hunt for absent modules nor speculatively create them.
- `AGENTS.md`: contributor policy, sourcing/data standards, style, security guardrails, and quality bar.
- `PROMPT.md`: volatile session handoff with current state, required reading, open items, next concrete step, recently changed files, commands to run, and known risks.
- `PLAN.md`: stable architecture, decisions, and durable design — seeded from the finalized plan.
- `CHANGELOG.md`: newest-first history of what changed and why. Prepend new entries at the top.
- `README.md`: short intro, quick start, output map, and common commands.
- `docs/index.md`: compact documentation map to reduce unnecessary context loading.
- `docs/spikes/`: short research outcomes and decisions.
- `docs/archive/`: old bulky history moved out of active docs.

Conditional docs (only when scaffolded):
- `SECURITY.md`: owned by the project security prompt; see its template for contents.
- `docs/methodology.md`: full methodology, assumptions, source definitions, and calculation rules.
- `docs/data_handling.md`: data classification, provenance, retention, redaction, and privacy handling.
- `features/<name>/`: one feature per folder — the approved, buildable contract (plan-approved per Working discipline).
- `PATCHNOTES.md`: user-facing product notes only.
- `docs/scoping/`: roadmap-stage exploration — possibilities, platform reality, unresolved choices. Not buildable; when a scoping topic becomes real work, a feature doc consumes it.
- `docs/deploy.md` (or `docs/distribution.md`): repeatable operational runbook — deploy steps, live verification, store/distribution procedure.
- `docs/security/reviews/`: detailed security/code review write-ups, so `SECURITY.md` stays lean (see Documentation ceilings).

`PROMPT.md` must stay compact and structured — soft ceiling ~150 lines, current-session information only (history belongs in `CHANGELOG.md`). Current State and Next Step are mandatory and always first. `Guardrails` and `Held / Do Not Start` are standing sections: once created, they are carried across every rewrite until the owner retires them. The remaining sections are optional and reorderable — include what the next session actually needs.

```md
# Session Prompt

## Current State

## Next Step

## Guardrails
<!-- standing invariants carried across rewrites: merge policy, known traps, absolute prohibitions restated -->

## Held / Do Not Start
<!-- explicit scope fences, released only by the owner -->

## Required Reading
- `path/to/file.md`: reason

## Recently Changed
- `path/to/file`: reason

## Commands To Run
- `command`: purpose

## Open Items

## Known Risks

## Do Not Read Unless Needed
- `path/to/large/or/old/file`: reason
```

## Architecture conventions (universal)

- Keep business logic, parsing, validation, and transformation code in the source root; entry points (scripts, CLI commands, route handlers, main functions) stay thin.
- Keep external configuration out of code; secrets must never be stored in config files.
- Keep tests in `tests/` (or the stack-idiomatic location), with fixtures small enough to commit safely.
- Declare compatibility AND pin the actual runtime — they are different things. A compatibility range (`engines` in `package.json`, `requires-python`, or equivalent) states what should work; a runtime selection file (`.python-version`, `.node-version` / Volta / asdf, `rust-toolchain.toml`, or equivalent) makes builds reproducible. Require both, with CI pinned to the same runtime, alongside the dependency lockfile.
- Prefer deterministic builds and explicit command entry points.
- Prefer commands that are easy to run locally and in CI.

Monorepo conventions (when the workspace module applies):
- Single root lockfile; root commands (`dev`/`build`/`test`/`typecheck`/`lint`) delegate and fan out consistently across workspaces.
- Shared logic lives in a portable core package (`packages/core` or equivalent): no DOM or platform APIs.
- Platform apps under `apps/` stay thin consumers of the core — the thin-entry-point principle, one level up.
- Tests and configs are workspace-local; the `src/`-row conventions apply per workspace.
- Generated native directories (`ios/`, `android/`, `.expo/`) are not committed.

Architecture conventions (when the module applies):
- Data contracts live in `schemas/`.
- Prefer one generated summary file, such as `outputs/model_summary.json`, as the single source for reports and dashboards.
- Dashboards and reports must not contain hard-coded business numbers; they consume generated data files.

## Working discipline

Transcribed into `AGENTS.md`; applies to every session that writes code:

- Work on a branch per feature or task, even solo; a branch is mergeable only when its acceptance criteria pass.
- The owner merges to main and releases holds explicitly; agents never merge to main or force-push. Mandatory at High tier, recommended at every tier — where merge-to-main auto-deploys, owner merge is also the deploy gate.
- Plan first, build second: unscoped work (no approved plan or feature doc) follows a fixed order — draft the plan (a feature doc from the template, or a short written plan for non-feature work), present it to the owner, and STOP. Build starts only on explicit owner approval, in a later step; planning and building never happen in one uninterrupted pass. Record the approval date in the feature doc header; for non-feature plans, in the plan file or the `CHANGELOG.md` entry when the work lands. Exempt: trivial mechanical changes (typos, comment/doc corrections, lint fixes).
- Commit small and often with meaningful messages, so history is bisectable and rollback is cheap.
- Review the diff before each commit; never force-push or rewrite pushed history.
- Fix the producer, not the copy: before editing any file, ask "what writes this file?" If it is generated, mirrored, or installed from an upstream source, edit that source, re-run the producer (generator, install step, or mirror), and diff the regenerated copy — an edit to the copy alone is silently reverted on the next run, and the tell is asymmetric history (the fix in the copy's log, nowhere on the producing side).
- "Done" means tests were run and passed in this session — not merely written.
- Agents never edit real `.env` files, paste credential values into code or logs, or commit secrets; the human handles secret values by hand.
- Match model and effort to the task: cheaper/faster models and lower effort for mechanical work (renames, formatting, boilerplate); stronger models and review passes reserved for design, debugging, and security-relevant changes.

## Security & privacy

All security and privacy controls — secrets handling, data privacy and sourcing, deployment hardening, security tooling — are governed by the project security prompt, at the tier confirmed in Step 0. This prompt owns only the structural pieces:

- `.gitignore` exists and is written before the first commit.
- `.env.example` is scaffolded whenever the project uses environment variables.
- `SECURITY.md` and `docs/data_handling.md` are created when the security tier requires them.

## Output and reproducibility guardrails (when the project generates artifacts)

- Generated outputs must be reproducible from source data, configuration, and scripts.
- Never hand-edit generated outputs. Edit data, model, config, templates, or scripts, then rebuild.
- Generated files should include "do not edit by hand" comments where useful.
- Validation and verification scripts should fail loudly on stale outputs, missing provenance, schema errors, formula errors, inconsistent summaries, or broken links.
- Archive old bulky history under `docs/archive/` per the Documentation ceilings below.
- Keep user-facing output polished, concise, and traceable to generated data.

## Documentation ceilings and archival

Hot docs carry content contracts and concrete rotation triggers — "archive when too large" is not actionable. Defaults below; a project may adjust them, but must state numbers:

- `PLAN.md`: current architecture and accepted decisions only. Detailed historical deliberation moves to ADRs or `docs/archive/` — at each milestone close, or when the file passes ~32 KB.
- `SECURITY.md`: current tier, controls, assets, and runbook. Detailed review write-ups live under `docs/security/reviews/`; rotate escalation history to `docs/archive/` past ~32 KB.
- `CHANGELOG.md`: concise release-level entries. Rotate into `docs/archive/` by major version, or past ~64 KB.
- `PROMPT.md`: soft ceiling ~150 lines; current-session information only.
- Feature docs: the detailed review outcome lives in the feature doc only; `SECURITY.md` and `CHANGELOG.md` reference it in one line rather than duplicating it.

## Quality gates (universal)

- Every feature or unit of work must define acceptance criteria.
- Every non-trivial model, calculation, parser, or transformation must have tests or validation fixtures.
- Every release or handoff should report:
  - Files changed
  - Commands run
  - Tests or validations passed
  - Outputs regenerated (if applicable)
  - Known limitations
  - Next concrete step
  - If the release closes a milestone or changes tier, spend, audience, or deployment surface: a note that owner-side portfolio records need syncing
- If tests or validation are skipped, state why.
- A change delivered across multiple PRs defines a shared regression gate up front: identical output on legacy fixtures, and every intentional behavior change enumerated in an explicit allowed-change list, each with its own test.
- The report items above seed the release checklist in `AGENTS.md`; the confirmed security tier's per-release controls (dependency audits, security review passes, restore tests) are appended to it per the security prompt's Enforcement section.
- For Medium-security-tier projects and above, reviews follow the **review-before-load-bearing** model (adopted 2026-08-11 from a production project's constitution, rule 15), transcribed into each project's `AGENTS.md`; it runs at each feature completion, not only at release:
  - **Independence:** reviewed by a non-author human, or an independent fresh session / second model — never the thread that produced the work. Where two reviewers from different vendors run blind and in parallel on byte-identical mandates, expect overlap where the defect is mechanical and complementary coverage where it is interpretive: a finding both make is near-certain (fix without debate), and a disagreement between them is itself diagnostic — adjudicate it against sources rather than picking a side.
  - **Rigor matches stakes; highest applicable level wins.** *Semantic* = changes meaning, effect, output, obligation, or runtime/deployment behaviour; if a change can't be shown non-semantic, classify up. Trivial demonstrably-non-semantic changes → no review. Any other non-trivial change → one independent review before merge. Design docs, feature-doc ratification, new architecture patterns, and semantic changes to governance/security/data-handling policy → adversarial review (reviewer instructed to refute), findings folded and logged before ratification. Security-sensitive surfaces per the confirmed tier → `/security-review` in addition to the applicable row; High tier applies this at every feature completion touching auth, data handling, or exposure.
  - **Gate-specific ready verdicts:** a review clears its gate only with a verdict naming the gate, every blocking finding resolved or consciously accepted with recorded rationale. A changes-required verdict never authorises crossing; the folding session cannot upgrade its own verdict — re-review the folded result.
  - **Recorded:** reviewer identity in one exact form (`non-author human <name>` / `independent fresh session / second model <id>`); durable docs carry a `Reviewed:` marker (date · reviewer · findings count/severity · verdict). A review still owed is tracked in `PROMPT.md` and never authorises merge.
  - **Verify the deed:** reviews covering tests scan for neutering tells (`|| true`, stubbed bodies, asserted-but-unrun tests); "done" means tests ran and passed in that session.
  - **Bounded adversarial rounds** (owner rulings 2026-08-08, after a 32-round review loop on a production project): at most **three rounds per gate**; a third changes-required verdict stops the loop and goes to **owner triage** — a plain-English table, per finding: what goes wrong, how likely / how it arises, cost to fix, risk if accepted, plus a one-line recommendation (fix / accept-with-rationale / log-as-deferred) and an overall recommendation; technical detail in an appendix. The ruling is recorded and the loop resumes only for findings ruled "fix"; the cap is per gate, not per PR. Fold-surface findings (on material a fold added this loop, or on claims about what a check proves) go to the deferred ledger by default, not back into the loop. Folds sweep the defect **class** across touched files (sites listed; re-review verifies the sweep first); a repeat of last round's shape on a sibling site counts against the cap. Checks state only what they read — over-claiming output is a wording defect, not a security finding. Governance-doc decision edits travel in their own small adversarial-level change, never inside a feature change. After the cap-triage fold, run **one bounded confirmation round** on the folded result before merge (practice since 2026-08-22, after the cap rulings): it sits outside the three-round cap, it is the one place fold-surface findings are examined rather than deferred, and it catches defects the fold itself introduced. Merge if clean; a finding it makes goes to owner triage (fix / accept-with-rationale / defer), and a ruled fix is verified by a targeted re-check of that fix, not another full round. A confirmation seat's return is validated before it counts (head sha, delta file list, one load-bearing fact) — a seat restating an archived report is not a fresh review.

### Review convergence (plan-stage reviews)

When a plan is reviewed before code exists (Medium tier and above), these rules are transcribed into `AGENTS.md` and govern the loop:

1. **Freeze invariants before iterating.** Before a second review round on the same plan, record the small set of non-negotiable security/data-integrity invariants it must uphold (High tier: in `SECURITY.md`). Only findings implicating a frozen invariant through a plausible *production* path — honest code plus realistic failure (I/O errors, process death, races, platform semantics); a deliberately adversarial implementation of trusted first-party code is not a production path — may reopen an approved or amended plan.
2. **Classify findings**: product defect (original / reopened / newly introduced), assurance-harness defect, doc inconsistency, optional hardening, accepted residual. Harness findings fix the tests or test plan, never the design. Cumulative finding count is never a health signal.
3. **Stop by rule, not exhaustion.** Prose review stops after two consecutive rounds with zero product-class findings, or two rounds dominated by assurance-machinery findings. It ends with ONE scope-frozen closure review, binary GO/NO-GO, which may not add new threat-model requirements; adjacent discoveries go to a deferred-findings ledger in the feature doc, triaged at the next milestone.
4. **Executable evidence.** A plan may not assert platform/upstream behavior a control depends on without a small runnable spike or a version-pinned citation. Implementation artifacts — exact test choreography, literal counts, verbatim UI copy — stay out of planning prose and are reviewed on real code, where the review stays fully adversarial.

## Change rules

- Any business-logic or model change must update `CHANGELOG.md`, plus `docs/methodology.md` and any generated methodology output if those exist.
- Any data handling, credential, privacy, or exposure change must update `SECURITY.md` or `docs/data_handling.md` (create them at that point if not yet scaffolded).
- Any user-visible dashboard, app, report, or copy change must update `PATCHNOTES.md` if it exists.
- Any architecture decision with durable impact must be recorded in `PLAN.md`.
- Adding or removing a conditional module must update the `CLAUDE.md` module inventory (present and deliberately-absent lists) in the same change — never as a follow-up.
- Any module, workspace, deployment-surface, or milestone change triggers a coordinated check of: the `CLAUDE.md` module inventory, `README.md` status/layout/commands, `docs/index.md`, `features/README.md`, and CI/root commands. Where practical, wire a lightweight `verify:docs` topology check so this drift fails loudly instead of accumulating.

## Command conventions

- Name scripts and commands by function, in the stack's idiom — for example `build`, `test`, `validate:data`, `verify`, `release`, or standalone scripts like `build_model.py`, `export_summary.py`, `validate_data.py`, `verify_outputs.py`.
- Only define the commands the project actually needs; a library may need only `build` and `test`, a pipeline may need the full set.
- Register commands in the stack's standard runner (package scripts, `Makefile`, `justfile`, or equivalent) so they run identically locally and in CI.
- Provide one canonical `verify` (or `ci`) command covering every active workspace's lint, typecheck, tests, build, and platform health checks; CI runs that same command.

## Feature convention (when `features/` is scaffolded)

- `features/TEMPLATE.md` should include:
  - Status
  - Owner
  - Authored date
  - Plan-approval date (build starts only after owner approval — see Working discipline)
  - Target milestone; link to the scoping doc consumed, if any
  - Brief / goal
  - User or decision value
  - Design
  - Platform/environment delta review — what differs per surface (when the project ships more than one)
  - Dependency rationale — new dependencies, why, alternatives considered (when the feature adds any)
  - Data and security considerations — including new data at rest, egress, permissions/entitlements, and credential impact
  - Decisions
  - Build plan
  - Acceptance criteria
  - Test / validation plan, with exact surface-specific validation commands
  - Code/security review outcomes (tier-dependent; the detailed outcome lives here only — see Documentation ceilings)
  - Deferred findings ledger — adjacent review discoveries that don't meet the reopen bar (see Review convergence); triaged at the next milestone, never silently amended into the plan
  - Representative real-data or device acceptance pass, when automated coverage alone is insufficient
- When-applicable fields stay in the template but collapse to "n/a" for features they don't touch, so small features stay cheap.
- `features/README.md` should have one line per feature.
- Feature docs are leaf docs: read the relevant feature file, not every feature.

## Initial scaffold content

- Seed `PLAN.md` and `README.md` from the finalized plan; use neutral placeholder text everywhere else.
- Seed the first `PROMPT.md` so the next session is immediately productive: Current State describes the fresh scaffold, Next Step points at the first item of the build plan in `PLAN.md`, and Required Reading names the plan sections needed for it.
- Seed `CHANGELOG.md` with an initial entry: project scaffolded, the date, and the versions of the kickoff, structure, and security prompts used.
- Record in `CLAUDE.md` the versions of the kickoff, structure, and security prompts the project was scaffolded under (as applicable), so future retrofits can diff against newer versions.
- Do not add domain-specific assumptions beyond what the plan states.
- Include short examples only when they clarify structure.
- Keep documents concise enough for efficient agent context.
- Prefer explicit TODO placeholders over invented facts.
- If the project is built for or delivered to a client, record in `README.md` who owns the code and data, the applicable license, and what happens to both at contract end.

## Verification and handoff

Before reporting, verify:

- No empty directories; every created module traces to a plan requirement.
- The module inventory in `CLAUDE.md` (present and deliberately-absent lists) matches what actually exists on disk.
- All placeholders are explicitly marked.
- `.gitignore` was in place before the first commit.
- The project has a private remote, or is recorded as local-only with the remote to add later, and a row in `PROJECTS.md`.

Then finish with a single combined report: the project profile derived; modules included and excluded with one-line reasons; when the security prompt is applied, the confirmed tier with rubric scores and controls implemented or deferred; and any placeholders that need my input.

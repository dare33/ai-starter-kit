# Project Security Prompt

Version: 1.6 — Last updated: 2026-07-28

Companion: `project_structure_prompt.md`. Apply this prompt when scaffolding a new project alongside the structure prompt, or when retrofitting an existing project (see Retrofit mode below). It governs all security and privacy controls; the structure prompt owns only the structural pieces (`.gitignore`, `.env.example`, file creation). The project plan is the source of truth for assessing security needs. If scaffolding a new project and the structure prompt was not provided, ask whether it should be applied too.

## Step 0 — Assess, propose, confirm

Before applying any tier:

1. Assess the project against the rubric below using the plan.
2. Propose a tier (Low, Medium, or High) with a short justification: what data it touches, who can reach it, and what the worst realistic failure looks like.
3. If any rubric answer is unknown, say so and propose the tier conservatively (round up, not down).
4. Wait for my confirmation before scaffolding security controls. I may override in either direction; my decision is final and gets recorded. When applied together with the structure prompt, fold this proposal into its single combined confirmation gate — one proposal covering project profile, modules, and tier.

Once confirmed, record in `SECURITY.md`: the tier, the date, the justification, and any my-override note. `SECURITY.md` is always created when this prompt is applied, regardless of tier.

## Retrofit mode (existing projects)

When applying this prompt to an existing project rather than a fresh scaffold:

1. Propose the tier as in Step 0, based on what the project actually does today, not what its docs claim.
2. Audit the existing code, config, and git history against the confirmed tier's controls; do not assume greenfield.
3. Record every gap as an explicit task in `PROMPT.md`, ordered by risk — exposed secrets and unprotected endpoints first.
4. Fix nothing silently: the gap list is the deliverable unless I ask for remediation.

## Tier decision rubric

Score the project on each axis; the highest axis wins (a project with public data but internet exposure is still Medium+).

| Axis | Low | Medium | High |
|---|---|---|---|
| Data sensitivity | Public or synthetic data only | Internal business data, non-sensitive client info | PII, financial, health, credentials for other systems, confidential client data, data about minors |
| Exposure | Runs locally, single user, never deployed | Deployed but access-controlled (small known audience, internal tool) | Internet-facing, public users, or accepts untrusted input at scale |
| Credentials held | None, or free-tier API keys with no spend risk | Paid API keys, tokens with read access to real systems | Write access to production systems, payment credentials, keys that could impersonate me or clients |
| Consequence of breach | Embarrassment, lost time | Business disruption, minor client impact, unexpected spend | Legal/regulatory exposure, serious client harm, privacy breach requiring notification |
| Third parties | None or well-known dev tools | A few external APIs/services receiving non-sensitive data | External services receiving sensitive data, or many dependencies in the trust chain |

Tiers are cumulative: Medium includes everything in Low; High includes everything in Medium.

## Universal non-negotiables (every tier, including Low)

These apply to every project, always:

- Never commit secrets, credentials, tokens, private keys, or real `.env` files. Provide `.env.example` with placeholder values whenever env vars exist.
- `.gitignore` excludes credentials, `.env*` (except `.env.example`), local caches, private raw data, and virtual environments / dependency directories from day one — written before the first commit, not after.
- Never log secrets, full tokens, or raw personal data.
- Never fabricate data; mark estimated, missing, or synthetic values honestly.
- Pin dependencies via a lockfile committed to the repo.
- Remotes are private by default. Making a repository public is an exposure change: re-assess the tier before flipping visibility, not after.
- Enable the git host's free security features at repo creation: secret-scanning push protection and dependency vulnerability alerts (e.g. GitHub secret scanning and Dependabot).
- If a secret is ever committed, treat it as compromised: rotate it immediately, then clean history. Rotation first, cleanup second.

## Tier: Low

For local, single-user projects with public or synthetic data and nothing meaningful to steal.

Code & repo hygiene:
- Universal non-negotiables above.
- Basic input validation on any file or user input the code parses (fail loudly on malformed input rather than guessing).

Data & privacy:
- None beyond the non-negotiables. If real personal data enters the project later, that is a tier escalation (see below), not a Low-tier task.

Deployment & runtime:
- Not applicable — if the project gets deployed, that is a tier escalation.

Tooling & automation:
- None required. Optional: a secret scanner if it's already part of my toolchain.

## Tier: Medium

For deployed-but-private tools, projects holding internal business data, or anything using paid credentials. Everything in Low, plus:

Code & repo hygiene:
- Validate and sanitize all external input (user input, API responses, file uploads) at the boundary; parameterize all database queries.
- Structured logging with an explicit redaction rule: define what may never appear in logs and enforce it in one logging helper, not scattered call sites.
- Separate configuration per environment (dev/prod); no production credentials on the dev machine unless unavoidable, and never in the repo directory.

Data & privacy (when the project handles data; skip if Medium was triggered by exposure or credentials alone):
- Classify data in `docs/data_handling.md`: what is collected, why, where it lives, how long it's kept, and what gets redacted from outputs.
- Aggregate or redact personal/private fields in any generated output by default; raw values only where explicitly required and documented.
- Preserve provenance for imported data; treat raw source data as immutable.

Deployment & runtime:
- HTTPS/TLS everywhere; no plaintext transport for anything non-local.
- Authentication on every non-public endpoint; deny by default.
- Least-privilege credentials: every API key and token scoped to the minimum it needs, with spend limits set where the provider supports them; where hard limits aren't supported, set a spend alert at a stated threshold instead. Record the expected monthly spend and which safeguard applies in `SECURITY.md`.
- Rotate credentials at least every 12 months, and immediately on suspected exposure; record last-rotated dates in `SECURITY.md`.
- CI secrets live in the CI provider's secret store, never in workflow files or the repo.
- Basic rate limiting on any endpoint that accepts input or triggers cost (LLM calls, emails, exports).
- Automated backups of any data store that can't be regenerated from source, with the restore path written down in `SECURITY.md`.

Third parties & supply chain:
- List external services and what data each receives in `SECURITY.md`.
- Run a dependency vulnerability audit (`npm audit`, `pip-audit`, or equivalent) before each release; fix or explicitly accept-and-document findings.
- Prefer well-maintained dependencies; a new dependency with few users and deep access (auth, crypto, serialization) needs a stated reason.

AI & agent usage:
- LLM API keys follow the least-privilege and spend-limit rules above.
- Do not send confidential or personal data to LLM providers unless the plan explicitly allows it; note in `docs/data_handling.md` which fields may be sent.
- Treat all LLM output that reaches users or systems as untrusted input: validate it like any other external data.
- If an LLM feature reads untrusted content (user text, web pages, documents, emails), there must be no direct path from that content to destructive actions: least-privilege tools and validated outputs.

Tooling & automation:
- Pre-commit secret scanning (e.g. gitleaks) installed as a hook, not just documented.
- Dependency audit wired into CI if CI exists; otherwise into the release checklist.
- Branch protection on the default branch: no force pushes; where CI exists, require its checks to pass before merge.

## Tier: High

For internet-facing projects, anything holding PII or confidential client data, or credentials whose compromise causes real harm. Everything in Medium, plus:

Code & repo hygiene:
- Security review as an explicit step before any release that changes auth, data handling, or exposed surface — run a dedicated review pass (or `/security-review`) and record the result.
- Security-relevant plans name their frozen invariants in `SECURITY.md`; security review findings block only by implicating one (review-convergence rules per the structure prompt's Quality gates). The *implementation* security review remains fully adversarial — that is where the adversarial effort belongs, not in iterated prose review of a plan.
- No dynamic code execution on untrusted input (eval, deserialization of untrusted payloads, template injection surfaces).
- Content Security Policy and standard security headers on any web surface; CSRF protection on state-changing requests.

Data & privacy:
- Data minimization is the design default: collect nothing the plan doesn't justify, and challenge fields that look speculative.
- Encrypt sensitive data at rest, not just in transit; document key storage in `SECURITY.md`.
- Retention and deletion are implemented, not aspirational: a documented (ideally scripted) way to delete a person's data on request, and automatic expiry for data past its retention window.
- If regulated or notification-triggering data is in scope, `docs/data_handling.md` must name the applicable obligations (e.g. privacy legislation, contractual confidentiality) and what they require before any output is built. If the plan doesn't name the jurisdiction, ask me rather than assume; Australia (Privacy Act 1988 and the Notifiable Data Breaches scheme) is the fallback default only if I don't specify.

Deployment & runtime:
- Multi-factor authentication on all admin/owner accounts for hosting, DNS, and data stores.
- Tighten credential rotation to at least every 6 months, and on any change in who or what has access.
- Secrets live in a proper secret store (hosting provider's secret manager or equivalent), not env files on the server.
- Audit logging for authentication events and access to sensitive data; logs retained long enough to investigate an incident.
- Scheduled backup restore test — a backup that's never been restored is a hope, not a backup.
- Dependency and platform patching on a stated cadence, recorded in `SECURITY.md`.

Third parties & supply chain:
- Vet each third party receiving sensitive data: where is it stored, is it used for training, can it be deleted. Record the answers.
- Lockfile integrity verification in CI (e.g. frozen installs); no floating versions in production builds.

AI & agent usage:
- Prompt injection is a first-class threat: extend the Medium rule with an explicit review of every path from untrusted content to tool use or output, and document the constraints and residual risks in `SECURITY.md`.
- Human confirmation on any agent-initiated action that is destructive, spends money above a threshold, or sends data externally.

Incident response & recovery:
- `SECURITY.md` contains a short incident runbook: how to take the surface offline, which credentials to rotate first, where the backups are, who to notify and within what timeframe.
- After any incident or near-miss, write a brief blameless postmortem in `docs/` and update the runbook.

## Conditional: mobile / native applications

Apply when the project ships a native app, at any tier (controls scale with the confirmed tier):

- Runtime secrets live in the platform's secure store (iOS Keychain / Android Keystore / Secure Store equivalent) — never in code, config files, or plain async storage.
- Signing certificates, provisioning profiles, and upload/signing keys are credentials like any other: named custody and rotation entries in `SECURITY.md`.
- MFA on developer-program, store, and build-service accounts.
- Cloud builds are an explicit trust decision: record what the build service (e.g. EAS) can see and why that is accepted.
- OTA / remote-code-update capability is an explicit recorded decision — on or off, and what gates a push.
- Native modules get supply-chain review; native dependency upgrades are isolated between milestones, each bump its own PR with gates green.
- Maintain a permissions and entitlements inventory in `SECURITY.md`; every entry justified by a feature.
- Incident and patch planning accounts for store-review latency: a fix that ships through store review is not a same-day fix; the runbook says what happens in the gap.
- Local data deletion actually deletes, and schema/data migrations fail safe (no data loss on an interrupted upgrade); both verified before release.

## Enforcement

- Tier controls that run per-release (dependency audits, security review passes, restore tests) must be added to the release checklist in `AGENTS.md`. A documented control that no checklist triggers is considered not implemented.
- The confirmed tier's controls are recorded as a checklist in `SECURITY.md` (template below). Verify against the checklist at each release or handoff and at each tier change — not every session. Escalations diff the old tier's checklist against the new tier's controls.

## Tier escalation

The tier is not permanent. Re-assess and propose an escalation when any of these happen:

- Real personal or confidential data enters a project that didn't have it.
- The project gets deployed, its audience widens beyond the original plan, or repository/surface visibility changes from private to public.
- New credentials with broader access are added.
- An incident or near-miss reveals the tier was too low.
- A third-party service that receives project data suffers a breach, or a critical vulnerability lands in a core dependency.

Escalations update `SECURITY.md` (new tier, date, trigger) and `CHANGELOG.md`, and the gap between the old and new tier's controls becomes explicit tasks in `PROMPT.md` — not silent debt. De-escalation requires my explicit approval.

## Decommissioning (project retirement)

Abandoned projects are where security debt bites: a paused project with live keys and a running deployment is an unwatched liability. When a project is retired — or paused for more than ~3 months while holding live credentials or a deployed surface — complete this checklist:

1. Revoke or rotate every credential the project holds; remove them from local `.env` files and secret stores.
2. Take down deployments, scheduled jobs, and webhooks; release or park domains.
3. Cancel paid services, subscriptions, and hosting plans the project holds; expected spend drops to none.
4. Delete or archive data per the project's retention rules in `docs/data_handling.md`.
5. Record the retirement in `SECURITY.md` (date, what was revoked, taken down, and cancelled). The `SECURITY.md` record is the mandatory part for whoever runs this checklist; updating the project's row in `PROJECTS.md` is owner-side — done now if I'm running it, otherwise caught by my next maintenance sweep.
6. Archive the repository (read-only) rather than deleting it.

Pausing a Medium+ project without decommissioning requires a stated reason and a re-check date, recorded in the project's `SECURITY.md` and mirrored owner-side into `PROJECTS.md` (by me directly, or by the next maintenance sweep).

## SECURITY.md template

```md
# Security

## Tier
- Tier: <Low | Medium | High>
- Assessed: <date>
- Justification: <2-3 lines: data, exposure, worst realistic failure>
- Owner decision: <confirmed as proposed | overridden to X because Y>

## Controls checklist
<!-- Copy the confirmed tier's controls from the project security prompt (tiers are cumulative). -->
- [ ] <control> — <implemented | deferred: reason>

## Data & credentials
- Data classification: <link to docs/data_handling.md, or "public/synthetic only">
- Credentials held: <list, each with scope, where it's stored, and last-rotated date>
- Expected spend: <expected monthly spend per paid service, and the spend limit or alert threshold set — or "none">

## Third parties
- <service>: <data it receives>

## Backups & recovery
- <what's backed up, where, restore steps — or "regenerable from source">

## Incident runbook (Medium+ as needed, required at High)
- Take offline: <how>
- Rotate first: <credential list in priority order>
- Notify: <who, timeframe>

## Escalation history
- <date>: <tier change and trigger>
```

## Reporting

When applying this prompt, finish by reporting: the proposed tier and rubric scores per axis, the controls scaffolded, any controls deferred with reasons, and any unknowns that could change the tier assessment. When applied together with the structure prompt, fold this into its single combined handoff report.

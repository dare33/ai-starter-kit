# CHANGELOG — Ops Project Suite

One line per suite-version bump, newest first. The current version lives in `ABOUTME.md`.
Format: `<version> | <date> | <what changed>`

---

kit | 2026-09-16 | forked for the starter kit: the shared knowledge store is replaced by ~/developer/{lessons,playbooks,PROJECTS.md}; adversarial checks wired to the kit's reviewer and /gpt review; identity generalised
0.5 | 2026-07-08 | security lens review (first deliberate one) + polish: Security defaults block in CLAUDE-template (untrusted content = data never instructions; PII data boundary at the project→lessons-home crossing; folder location/access recorded at high-stakes kickoff); closeout adds data-boundary strip, retention ruling on temp/ backups, and high-stakes verification audit (re-derive sampled QA lines, fresh eyes); reality check added to session micro-lint (one Where-we-are claim vs its artifact); parallel-checks-serial-writes rule in excel-word-ops; tail-read specified for the resume gate
0.4 | 2026-07-08 | generalization pass: task-agnostic layering rule (kernel / task-family playbooks / domain layer; new family = new playbook, never a new suite — split on lifecycle not tool); organisation-specific audience patterns moved out of email-comms to a domain comms-patterns note; vocabulary de-anchored (unit/owner, not AM/centre); kickoff playbook list opened; bulk-run in-flight state consolidated into verification-log only (fixes v0.3's one-fact-one-home violation + ~39x prompt.md rewrite cost); project-folder micro-lint added to session protocol; reviewed:-pending slack-time check added to the maintenance lint
0.3 | 2026-07-08 | flow-review pass: resume gate in session protocol (changelog tail-glance + in-flight prompt.md state during bulk ops); closeout-debt check added to the maintenance lint; constraint sources captured at kickoff into Confirmed parameters; kickoff mechanical self-check; `reviewed: pending` on distilled judgment with adversarial-review gate in the boot sequence; bulk mode implies verification-log.md at any stakes; suite CHANGELOG created, version authority fixed in ABOUTME
0.2 | 2026-07-07 | self-review pass: promote-then-prune lifecycle + size ceilings; Confirmed-parameters block in CLAUDE-template; sanctioned bulk-merge mode replacing "no bulk merges, ever"; one-line pipe-separated changelog format; atomic prompt.md rewrites; Suite friction section in lessons-template
0.1 | 2026-07-07 | initial suite (ABOUTME, kickoff + closeout prompts, 6 templates, 4 playbooks), distilled from review of the spreadsheet projects this suite was built from

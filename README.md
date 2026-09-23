# ai-starter-kit

A shareable Claude Code setup: global working rules (good practice +
orchestration), five subagent role files, the `/gpt` command and hardened Codex
wrapper for calling GPT models from inside Claude Code, and three project prompt
suites (full, fast, and ops).

New users: read `GETTING-STARTED.md` (one page). The Claude Code session that
performs the install follows `SETUP-AGENT.md`; no terminal use is needed.

## Contents

```
install.sh                      copies everything below into ~/.claude (backs up first); --check reports drift, changes nothing
GETTING-STARTED.md              one-page guide for the person installing
SETUP-AGENT.md                  phase-by-phase runbook for the Claude Code session doing the install
KIT_VERSION                     the kit's current version number
CHANGELOG.md                    what changed in each release, in plain English
MODELS.md                       which model version each role's tier currently means
claude/
  CLAUDE.md                     global rules — installed to ~/.claude/CLAUDE.md
  previous/CLAUDE-1.0.0.md      the exact 1.0.0 kit body, kept so install.sh (and Phase 9) can tell your own edits from the old template on a first update
  agents/                       implementer, mechanic, scout, reviewer, reviewer-gpt
  commands/gpt.md               the /gpt command
  scripts/codex-agent.sh        the Codex wrapper (macOS; needs codex via Homebrew)
  settings-allow.json           the permission rule install.sh merges into settings.json
  settings-env.json             the model tier pins install.sh merges into settings.json
suites/
  project-initiation-suite/     full governance: kickoff, structure, security, maintenance
  solo-speed-project-suite/     speed profile for solo prototypes (overlays the full suite)
  ops-project-suite/            for non-code projects: documents, spreadsheets, comms, financial checks, legal reads
```

## Requirements

- macOS (v1), your own Mac with an administrator account (the default for a
  personal Mac). The wrapper uses BSD `stat` and trusts codex only at
  `/opt/homebrew/bin` or `/usr/local/bin`. An Apple-silicon Mac for the GPT
  add-on (any Mac for the rest) — Homebrew dropped Intel Macs to its lowest support
  tier in September 2026, and its installer refused an Intel install when checked on 2026-09-15. Windows is not supported yet; ask the person who sent
  you the kit if you need it.
- Claude Code (Pro or Max plan). Codex CLI via `brew install --cask codex`
  plus a ChatGPT login for the GPT roles — a paid plan gives more usage, and
  if the login says your plan doesn't include Codex, skip it; without it the
  `/gpt` command and `reviewer-gpt` report "unavailable" and everything else
  still works.

## Updating

Paste this into Claude: *Pull the latest kit
(`git -C ~/ai-starter-kit pull --ff-only`), then run Phase 9 of
~/ai-starter-kit/SETUP-AGENT.md*. It reads what changed (see
`CHANGELOG.md`), reinstalls, and checks the result — backing up every file
it replaces into a dated folder under `~/.claude/backups/`. Your own notes
in `CLAUDE.md` and your settings (projects folder, spelling, whether GPT is
set up) are kept; the kit's own rules, agent files and pins are replaced.
(Updating from the very first release, 1.0.0: this first update also moves
your existing choices into the file that later updates read directly —
automatic, and Phase 9 shows you the result to check.)
See `MODELS.md` and `KIT_VERSION` for exactly what a given release currently
means.

## Provenance

Derived from one person's working setup as of September 2026, with personal
references, business context and the owner's private knowledge-base rules
removed. The wrapper's security history is kept in its comments on purpose:
each hardening step records the attack it closes.

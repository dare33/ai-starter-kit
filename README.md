# ai-starter-kit

A shareable Claude Code setup: global working rules (good practice +
orchestration), five subagent role files, the `/gpt` command and hardened Codex
wrapper for calling GPT models from inside Claude Code, and two project prompt
suites (full and fast).

New users: read `GETTING-STARTED.md` (one page). The Claude Code session that
performs the install follows `SETUP-AGENT.md`; no terminal use is needed.

## Contents

```
install.sh                      copies everything below into ~/.claude (backs up first)
GETTING-STARTED.md              one-page guide for the person installing
SETUP-AGENT.md                  phase-by-phase runbook for the Claude Code session doing the install
claude/
  CLAUDE.md                     global rules — installed to ~/.claude/CLAUDE.md
  agents/                       implementer, mechanic, scout, reviewer, reviewer-gpt
  commands/gpt.md               the /gpt command
  scripts/codex-agent.sh        the Codex wrapper (macOS; needs codex via Homebrew)
  settings-allow.json           the permission rule install.sh merges into settings.json
suites/
  project-initiation-suite/     full governance: kickoff, structure, security, maintenance
  solo-speed-project-suite/     speed profile for solo prototypes (overlays the full suite)
```

## Requirements

- macOS (v1), your own Mac with an administrator account (the default for a
  personal Mac). The wrapper uses BSD `stat` and trusts codex only at
  `/opt/homebrew/bin` or `/usr/local/bin`. An Apple-silicon Mac for the GPT
  add-on (any Mac for the rest) — the official Homebrew installer refuses to
  run on an Intel Mac. Windows is not supported yet; ask the person who sent
  you the kit if you need it.
- Claude Code (Pro or Max plan). Codex CLI via `brew install --cask codex`
  plus a ChatGPT login for the GPT roles — a paid plan gives more usage, and
  if the login says your plan doesn't include Codex, skip it; without it the
  `/gpt` command and `reviewer-gpt` report "unavailable" and everything else
  still works.

## Updating

Pull the latest kit and re-run `./install.sh`. It backs up every file it
replaces into a dated folder under `~/.claude/backups/`, so a local edit to
`CLAUDE.md` is never lost — diff against the backup and re-apply what you
want.

## Provenance

Derived from one person's working setup as of September 2026, with personal
references, business context and the owner's private knowledge-base rules
removed. The wrapper's security history is kept in its comments on purpose:
each hardening step records the attack it closes.

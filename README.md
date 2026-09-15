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

- macOS (v1). The wrapper uses BSD `stat` and trusts codex only at `/opt/homebrew/bin`
  or `/usr/local/bin`. Windows is not supported yet; a PowerShell port of the wrapper
  exists and can be added when someone needs it.
- Claude Code (Pro or Max plan). Codex CLI via `brew install codex` plus a
  ChatGPT Plus/Pro login for the GPT roles; without it the `/gpt` command and
  `reviewer-gpt` report "unavailable" and everything else still works.

## Updating

Pull the latest kit and re-run `./install.sh`. It backs up every file it
replaces with a dated suffix, so a local edit to `CLAUDE.md` is never lost —
diff against the backup and re-apply what you want.

## Provenance

Derived from one person's working setup as of September 2026, with personal
references, business context and the owner's private knowledge-base rules
removed. The wrapper's security history is kept in its comments on purpose:
each hardening step records the attack it closes.

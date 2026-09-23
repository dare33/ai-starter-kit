# MODELS.md — the kit's model registry

A role file names a **tier** (`opus`, `sonnet`, `haiku`, `fable` on the
Claude side; `sol`, `terra`, `luna`, `astra` on the GPT side), never a
specific model version. This file is the record of what each tier means
today. When a vendor ships a new model and it's time to move a tier onto it,
that's a pin move plus a new row here — nothing in `CLAUDE.md`, an agent
file, or `/gpt` has to change. For you, moving a tier means nothing to do:
pull the kit and run Phase 9 (see `SETUP-AGENT.md`), and the pin and this
file are already updated for you. For whoever maintains the kit, it means
editing exactly two places: the pin (in `settings-env.json` or the wrapper's
tier map, depending on the vendor) and this file's row for that tier.

**Watch note:** the `haiku` pin below (`claude-haiku-4-5-20251001`) is
scheduled to retire no sooner than 2026-10-15. A kit update will move it
before then; if you see a "model retired" error from a `haiku`-tier agent
before you've updated, pull the kit and run Phase 9.

## Current pins

### Claude tiers

| tier   | current pin                  | since      | minimum tool version    |
|--------|-------------------------------|------------|--------------------------|
| opus   | `claude-opus-5-5[1m]`         | 2026-09-23 | Claude Code 2.1.280+     |
| sonnet | `claude-sonnet-5`             | 2026-09-23 | no minimum beyond the current app |
| haiku  | `claude-haiku-4-5-20251001`   | 2026-09-23 | no minimum beyond the current app |
| fable  | `claude-fable-5-1`            | 2026-09-23 | no minimum beyond the current app |

### GPT tiers (via the Codex wrapper)

| tier  | current pin      | since      | minimum tool version | notes |
|-------|------------------|------------|-----------------------|-------|
| sol   | `gpt-6-sol`      | 2026-09-23 | codex-cli 0.156.0+ (the Homebrew cask installs 0.156.0) | rejects the `minimal` effort level (accepted: none, low, medium, high, xhigh, max) |
| terra | `gpt-5.6-terra`  | 2026-08-13 | no minimum beyond the current app | — |
| luna  | `gpt-6-luna`     | 2026-09-23 | codex-cli 0.156.0+ (the Homebrew cask installs 0.156.0) | rejects the `minimal` effort level (accepted: none, low, medium, high, xhigh, max) |
| astra | `gpt-6-astra`    | 2026-09-15 | codex-cli 0.154.0+ | — |

## Where each pin lives

- **Claude tiers** live in the `env` block of `~/.claude/settings.json`:
  `ANTHROPIC_DEFAULT_OPUS_MODEL`, `ANTHROPIC_DEFAULT_SONNET_MODEL`,
  `ANTHROPIC_DEFAULT_HAIKU_MODEL`, `ANTHROPIC_DEFAULT_FABLE_MODEL`. An agent
  file's `model: opus` (etc.) resolves through that pin.
- **GPT tiers** live in the `MODEL_TIER_*` map inside
  `~/.claude/scripts/codex-agent.sh` (the Codex wrapper installed from this
  kit). A role's `--model sol` (etc.) resolves through that map; the wrapper
  refuses a map entry whose slug doesn't end in the tier's own name.

## How a new model reaches you

Pull the kit, run the installer. `install.sh` moves both kinds of pin for
you — the Claude ones into `settings.json`'s `env` block, the GPT ones
already baked into the wrapper it copies in — so nothing else needs to
change on your machine. See `SETUP-AGENT.md`'s Phase 9 for the exact steps.

## Per-user tier overrides

The `sol` and `luna` pins above were only proven on the kit author's own
ChatGPT plan — a newer model can reach different plans at different times,
so your plan may not yet serve the current pin even though the kit itself is
up to date. If the GPT probe in Phase 6 or Phase 9 gets an API refusal that
names the model (rather than a quota message or a codex-version problem),
the setup assistant falls back to probing the previous generation of each
tier separately (`gpt-5.6-sol`, `gpt-5.6-luna` — two independent probes,
since one tier can lag a plan without the other doing so) and, for whichever
one's probe passes, records it as an override: `TIER_SOL` / `TIER_LUNA` in
`~/.claude/ai-starter-kit.conf`. When either is set, the installer
substitutes it into the wrapper's tier map in place of the kit-wide pin for
that one tier only — the wrapper's own same-family check still applies, so
an override can never be a different tier in disguise. Nothing about this is
automatic: a later update re-checks it (Phase 9 re-probes the current pin
and offers to remove the override once your plan has caught up), but
nothing re-probes on its own between updates.

## Known limit (documented Claude Code behaviour)

Claude Code resolves a subagent's model in this order: a per-invocation
model parameter, then the agent file's `model:` frontmatter, then the
`CLAUDE_CODE_SUBAGENT_MODEL` environment variable (if set — this kit doesn't
set it, so it won't apply unless you've set it yourself), then the session's
own model. Normally the frontmatter's tier name resolves through
the pin above — but **if the session you're working in is already running a
model of the same family as the tier (for example, an Opus session spawning
an `opus`-tier subagent), the subagent gets the session's exact model
instead of the pin.** This can't drift a pin silently across an update from
a different-family session, but it does mean that for anything load-bearing,
spawned from a same-family session, you should pass the full model ID from
the table above directly rather than relying on the tier name.

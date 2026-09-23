# Changelog

All notable changes to this kit are recorded here, in plain English, so
anyone installing it can tell what changed without reading the code. Format
loosely follows [Keep a Changelog](https://keepachangelog.com/).

## 1.1.2 - 2026-09-23

Claude Code deletes the record of each session from your Mac after 30 days unless a
setting says otherwise, so an older session could no longer be reopened or searched. The
installer now sets that retention to a year (`cleanupPeriodDays: 365` in
`~/.claude/settings.json`), and only if the setting is not already there - a value you
have set yourself is left alone. The update check reports it alongside the model pins.
Nothing else changes. Usual update (the one pasted message in `README.md`).

## 1.1.1 - 2026-09-23

Five improvements to the ops-project-suite (documents/admin projects) - four learned from
the first two real closeouts, plus one workspace ruling: a high-stakes domain playbook is
now allowed to run over the usual size limit when the only thing left to cut is a
judgement call, as long as the reason is written down; a closed-out project's status file
keeps its four standard headings, because that's what the template always uses, and a
closed-out project in the same shape as every other one stays easy to read and compare;
the end-of-project verification check, which already refused to be skipped, now takes
its sample from your changelog, to-do list or project notes when there's no verification
log to sample from; a project's decision and verification logs are left in place during
tidy-up rather than swept into the "stray files" folder; and any large or confidential set
of documents you receive from someone else (a data room, a broker pack, anything over
about 100 MB or under a return/destroy obligation) is now kept in a folder outside the
project - for example your iCloud Drive - instead of inside it, with just a log and a
checksum list in the project (the log from kickoff, the checksum list added to as documents
arrive) recording what was received and its status. There's nothing to do on your side beyond the usual update (the
one pasted message in `README.md`).

## 1.1.0 - 2026-09-23

Added a "tier" layer for models, so a future model release no longer means
editing your rules file or any agent file.

- Every role now names a **tier** (`opus`/`sonnet`/`haiku`/`fable` on the
  Claude side, `sol`/`terra`/`luna`/`astra` on the GPT side) instead of a
  specific model. Which exact model each tier currently means is recorded
  in one new file: `MODELS.md`.
- The Claude tiers are pinned in the `env` block of `~/.claude/settings.json`
  (a new file, `claude/settings-env.json`, carries these pins); the GPT
  tiers are pinned in the Codex wrapper's own tier map.
- Three tier moves happened as part of this release: the `opus` tier now
  means Opus 5.5, the `sol` tier now means GPT-6 Sol, and the `luna` tier
  now means GPT-6 Luna. The `sol` and `luna` pins need codex-cli 0.156.0 or
  newer — the Homebrew cask already installs that version, but if you
  installed the GPT add-on a while ago, `brew upgrade --cask codex` first
  (Phase 9 checks this for you).
- The Codex wrapper moves to v2.10 and the `/gpt` command to v2.6 to reflect
  the tier map and the new naming.
- `install.sh` now also merges the tier pins into `settings.json`, the same
  careful way it already merges its permission rule, and gains a `--check`
  mode that reports what's installed versus what the kit currently ships,
  without changing anything.
- Your personalisation now survives an update. A new file,
  `~/.claude/ai-starter-kit.conf`, remembers your projects folder, spelling
  preference, and whether GPT is set up; a marker line in
  `~/.claude/CLAUDE.md` separates your own notes (kept on every update from
  here on) from the kit's own rules (replaced on every install). Earlier
  releases lost the spelling and GPT-availability edits on every update —
  this is fixed from here on. If you're updating from 1.0.0, this update
  itself does the one-time work of moving those existing choices into the
  new file automatically, and Phase 9 shows you the result so you can check
  nothing was missed — after that, every update just keeps them. The kit now
  also ships the exact 1.0.0 rules file (`claude/previous/CLAUDE-1.0.0.md`)
  so this migration can compare your installed file against it line by line
  and carry across anything you wrote that the kit's own template never had,
  not just the settings it already knew to look for.
- `SETUP-AGENT.md` gains a "Phase 9 — Update" section: the one path for
  every future kit release (pull, read the changelog, run the installer,
  then `--check` to confirm).
- `MODELS.md` notes that the `haiku` pin retires no sooner than 2026-10-15;
  a future kit update will move it before then.

## 1.0.0 - 2026-09-16

The first shareable release: global working rules, five subagent role
files (implementer, mechanic, scout, reviewer, reviewer-gpt), the `/gpt`
command (v2.5) and the Codex wrapper (v2.8) for calling GPT models from
inside Claude Code, and three project prompt suites (full, fast, and ops).

#!/bin/bash
# ai-starter-kit installer — copies the Claude Code setup into ~/.claude.
# Safe to re-run: existing files are backed up with a date suffix first.
# Usage:  ./install.sh            (repos expected under ~/projects)
#         PROJECTS_DIR=~/code ./install.sh
set -euo pipefail

KIT="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"
STAMP="$(date +%Y%m%d-%H%M%S)"

say()  { printf '\n==> %s\n' "$1"; }
warn() { printf '    WARNING: %s\n' "$1"; }
backup() { [ -e "$1" ] && cp -p "$1" "$1.bak-$STAMP" && printf '    backed up %s\n' "$1" || true; }

if [ "$(uname -s)" != "Darwin" ]; then
  warn "This kit's GPT wrapper (codex-agent.sh) is macOS-only. Everything else installs fine."
fi

say "Installing into $CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/scripts"

# 1. Global CLAUDE.md
backup "$CLAUDE_DIR/CLAUDE.md"
cp "$KIT/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
printf '    installed CLAUDE.md\n'

# 2. Agent role files
for f in "$KIT"/claude/agents/*.md; do
  backup "$CLAUDE_DIR/agents/$(basename "$f")"
  cp "$f" "$CLAUDE_DIR/agents/"
done
printf '    installed agents: %s\n' "$(ls "$KIT/claude/agents" | tr '\n' ' ')"

# 3. /gpt command
backup "$CLAUDE_DIR/commands/gpt.md"
cp "$KIT/claude/commands/gpt.md" "$CLAUDE_DIR/commands/gpt.md"
printf '    installed /gpt command\n'

# 4. Codex wrapper, with the projects folder baked in
backup "$CLAUDE_DIR/scripts/codex-agent.sh"
mkdir -p "$PROJECTS_DIR"
sed "s|^WRITE_PARENTS=(.*)$|WRITE_PARENTS=(\"\$REAL_HOME/${PROJECTS_DIR#"$HOME"/}\")|" \
  "$KIT/claude/scripts/codex-agent.sh" > "$CLAUDE_DIR/scripts/codex-agent.sh"
chmod +x "$CLAUDE_DIR/scripts/codex-agent.sh"
bash -n "$CLAUDE_DIR/scripts/codex-agent.sh"
printf '    installed codex-agent.sh (repos may be edited by GPT only under %s)\n' "$PROJECTS_DIR"

# 5. Permission rule so Claude Code may run the wrapper without prompting
SETTINGS="$CLAUDE_DIR/settings.json"
RULE_ABS="Bash($HOME/.claude/scripts/codex-agent.sh:*)"
RULE_TILDE="Bash(~/.claude/scripts/codex-agent.sh:*)"
if [ ! -f "$SETTINGS" ]; then
  sed "s|__HOME__|$HOME|" "$KIT/claude/settings-allow.json" > "$SETTINGS"
  printf '    created settings.json with the wrapper allow rule\n'
elif command -v python3 >/dev/null 2>&1; then
  backup "$SETTINGS"
  python3 - "$SETTINGS" "$RULE_ABS" "$RULE_TILDE" <<'PY'
import json, sys
path, *rules = sys.argv[1:]
with open(path) as f:
    data = json.load(f)
allow = data.setdefault("permissions", {}).setdefault("allow", [])
for r in rules:
    if r not in allow:
        allow.append(r)
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
  printf '    merged the wrapper allow rule into settings.json\n'
else
  warn "settings.json exists and python3 is missing. Add these two lines to permissions.allow by hand:"
  printf '      "%s"\n      "%s"\n' "$RULE_ABS" "$RULE_TILDE"
fi

# 6. Codex CLI check (for the GPT side)
say "Checking the GPT side (OpenAI Codex CLI)"
if CODEX_BIN="$(command -v codex 2>/dev/null)"; then
  case "$CODEX_BIN" in
    /opt/homebrew/bin/codex|/usr/local/bin/codex) printf '    codex found at %s (trusted location)\n' "$CODEX_BIN" ;;
    *) warn "codex is at $CODEX_BIN, which the wrapper refuses. Install it with Homebrew instead: brew install codex" ;;
  esac
  if [ -f "$HOME/.codex/auth.json" ]; then
    printf '    codex is logged in\n'
  else
    warn "codex is not logged in yet. Run: codex login   (needs a ChatGPT Plus or Pro plan)"
  fi
else
  warn "codex CLI not found. Install with: brew install codex   then: codex login"
  printf '    Claude Code works without it; only the GPT roles (/gpt, reviewer-gpt) need it.\n'
fi

say "Done. Open a new Claude Code session and type:  /gpt what does this folder contain?"
printf '    Prompt suites are in %s/suites — see GETTING-STARTED.md for how to use them.\n' "$KIT"

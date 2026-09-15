#!/bin/bash
# ai-starter-kit installer — copies the Claude Code setup into ~/.claude.
# Safe to re-run: existing files are backed up (with a dated folder) first,
# and a previous "## About me" section in CLAUDE.md is preserved.
# Usage:  ./install.sh            (repos expected under ~/projects)
#         PROJECTS_DIR=~/code ./install.sh
set -euo pipefail

KIT="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$CLAUDE_DIR/backups/$STAMP"

say()  { printf '\n==> %s\n' "$1"; }
warn() { printf '    WARNING: %s\n' "$1"; }
backup() {
  local src="$1" rel dst
  [ -e "$src" ] || return 0
  rel="${src#"$CLAUDE_DIR"/}"
  dst="$BACKUP_DIR/$rel"
  if mkdir -p "$(dirname "$dst")" && cp -p "$src" "$dst"; then
    printf '    backed up %s\n' "$src"
  else
    printf '    WARNING: could not back up %s; stopping before changing anything\n' "$src"
    exit 1
  fi
}

# Resolve and validate PROJECTS_DIR before touching anything else, so a bad
# value can't leave a half-finished install.
RAW_PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"
case "$RAW_PROJECTS_DIR" in
  "~") RAW_PROJECTS_DIR="$HOME" ;;
  "~/"*) RAW_PROJECTS_DIR="$HOME/${RAW_PROJECTS_DIR#"~/"}" ;;
esac
if ! mkdir -p "$RAW_PROJECTS_DIR"; then
  warn "could not create the projects folder at $RAW_PROJECTS_DIR"
  exit 1
fi
if ! PROJECTS_DIR="$(cd "$RAW_PROJECTS_DIR" && pwd -P)"; then
  warn "could not resolve the projects folder at $RAW_PROJECTS_DIR"
  exit 1
fi
case "$PROJECTS_DIR" in
  "$HOME"|"$HOME"/*) ;;
  *)
    warn "projects folder must be inside your home folder (got $PROJECTS_DIR)"
    exit 1
    ;;
esac

if [ "$(uname -s)" != "Darwin" ]; then
  warn "This kit's GPT wrapper (codex-agent.sh) is macOS-only. Everything else installs fine."
fi

say "Installing into $CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/scripts"

# 1. Global CLAUDE.md — preserve an existing "## About me" section if present
backup "$CLAUDE_DIR/CLAUDE.md"
if [ -f "$CLAUDE_DIR/CLAUDE.md" ] && head -n1 "$CLAUDE_DIR/CLAUDE.md" | grep -qx '## About me'; then
  ABOUT_ME="$(awk '/^# / {exit} {print}' "$CLAUDE_DIR/CLAUDE.md")"
  { printf '%s\n\n' "$ABOUT_ME"; cat "$KIT/claude/CLAUDE.md"; } > "$CLAUDE_DIR/CLAUDE.md.new"
  mv "$CLAUDE_DIR/CLAUDE.md.new" "$CLAUDE_DIR/CLAUDE.md"
  printf '    kept your About me section\n'
else
  cp "$KIT/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
fi
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

# 4. Codex wrapper, with the projects folder baked in. Build the replacement
# line with python3 (or awk -v as a fallback) rather than sed, so a
# PROJECTS_DIR containing sed-special characters (&, |, \) can't corrupt it.
backup "$CLAUDE_DIR/scripts/codex-agent.sh"
REL_PROJECTS="${PROJECTS_DIR#"$HOME"/}"
if command -v python3 >/dev/null 2>&1; then
  python3 - "$KIT/claude/scripts/codex-agent.sh" "$CLAUDE_DIR/scripts/codex-agent.sh" "$REL_PROJECTS" <<'PY'
import re, sys
src, dst, rel = sys.argv[1:]
with open(src) as f:
    s = f.read()
new_line = 'WRITE_PARENTS=("$REAL_HOME/' + rel + '")'
s, n = re.subn(r'^WRITE_PARENTS=\(.*\)$', lambda m: new_line, s, count=1, flags=re.M)
if n != 1:
    sys.exit("WRITE_PARENTS line not found in " + src)
with open(dst, "w") as f:
    f.write(s)
PY
else
  awk -v rel="$REL_PROJECTS" '
    /^WRITE_PARENTS=\(.*\)$/ { print "WRITE_PARENTS=(\"$REAL_HOME/" rel "\")"; next }
    { print }
  ' "$KIT/claude/scripts/codex-agent.sh" > "$CLAUDE_DIR/scripts/codex-agent.sh"
fi
chmod +x "$CLAUDE_DIR/scripts/codex-agent.sh"
bash -n "$CLAUDE_DIR/scripts/codex-agent.sh"
grep -qF "WRITE_PARENTS=(\"\$REAL_HOME/$REL_PROJECTS\")" "$CLAUDE_DIR/scripts/codex-agent.sh" \
  || warn "could not confirm the installed wrapper's WRITE_PARENTS line"
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
try:
    with open(path) as f:
        data = json.load(f)
except (json.JSONDecodeError, ValueError):
    print("    WARNING: ~/.claude/settings.json is not valid JSON; I did not change it. Add these two lines to permissions.allow by hand:")
    for r in rules:
        print(f'      "{r}"')
    sys.exit(0)
allow = data.setdefault("permissions", {}).setdefault("allow", [])
changed = False
for r in rules:
    if r not in allow:
        allow.append(r)
        changed = True
if changed:
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("    merged the wrapper allow rule into settings.json")
else:
    print("    wrapper allow rule already present in settings.json")
PY
else
  warn "settings.json exists and python3 is missing. Add these two lines to permissions.allow by hand:"
  printf '      "%s"\n      "%s"\n' "$RULE_ABS" "$RULE_TILDE"
fi

# 6. Codex CLI check (for the GPT side) — trusted, absolute locations only;
# `command -v codex` would also accept a codex earlier on PATH that the
# wrapper itself would refuse to run.
say "Checking the GPT side (OpenAI Codex CLI)"
CODEX_BIN=""
for c in /opt/homebrew/bin/codex /usr/local/bin/codex; do
  [ -x "$c" ] && CODEX_BIN="$c" && break
done
if [ -n "$CODEX_BIN" ]; then
  printf '    codex found at %s (trusted location)\n' "$CODEX_BIN"
  if [ -f "$HOME/.codex/auth.json" ]; then
    printf '    codex is logged in\n'
  else
    warn "codex is not logged in yet. Run: codex login   (needs a ChatGPT Plus or Pro plan)"
  fi
else
  warn "codex CLI not found. GPT is optional: only /gpt and reviewer-gpt need it. Install with: brew install --cask codex   then: codex login"
  printf '    Claude Code works without it.\n'
fi

say "Done. Open a new Claude Code session and type:  /gpt what does this folder contain?"
printf '    Prompt suites are in %s/suites — see GETTING-STARTED.md for how to use them.\n' "$KIT"
printf '    Backups of anything replaced (if any) are in %s\n' "$BACKUP_DIR"

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
ANY_BACKUP=0
backup() {
  local src="$1" rel dst
  [ -e "$src" ] || return 0
  rel="${src#"$CLAUDE_DIR"/}"
  dst="$BACKUP_DIR/$rel"
  if mkdir -p "$(dirname "$dst")" && cp -p "$src" "$dst"; then
    ANY_BACKUP=1
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

# Character whitelist, checked before this value goes anywhere near the
# shell script we write out later (the codex wrapper's WRITE_PARENTS line —
# no character that could break out of a quoted string is let through. This
# same whitelist is re-applied below to the resolved path and to
# REL_PROJECTS, since a symlink can turn an innocent-looking value into one
# that contains an unsafe character only after it is resolved.
check_whitelist() {
  case "$1" in
    *[!A-Za-z0-9._/\ -]*)
      warn "the projects folder path can only contain letters, numbers, spaces, and . _ - / (got $1)"
      exit 1
      ;;
  esac
}
check_whitelist "$RAW_PROJECTS_DIR"

# Reject a `..` path component outright, before any mkdir — the whitelist
# above allows the `.` character (needed for names like "My.Projects"), so
# `..` needs its own check, and it has to run before anything is created so
# a rejected value can never leave a stray directory behind.
case "/$RAW_PROJECTS_DIR/" in
  */../*)
    warn "the projects folder path cannot contain a .. component (got $RAW_PROJECTS_DIR)"
    exit 1
    ;;
esac

# Reject the home folder itself, and validate containment on the
# expanded-but-not-yet-resolved path, before creating anything — so a
# rejected value never leaves a stray directory behind.
if [ "$RAW_PROJECTS_DIR" = "$HOME" ]; then
  warn "the projects folder must be a folder INSIDE your home folder, not the home folder itself (got $RAW_PROJECTS_DIR)"
  exit 1
fi
case "$RAW_PROJECTS_DIR" in
  "$HOME"/*) ;;
  *)
    warn "projects folder must be inside your home folder (got $RAW_PROJECTS_DIR)"
    exit 1
    ;;
esac

if ! mkdir -p "$RAW_PROJECTS_DIR"; then
  warn "could not create the projects folder at $RAW_PROJECTS_DIR"
  exit 1
fi
if ! PROJECTS_DIR="$(cd "$RAW_PROJECTS_DIR" && pwd -P)"; then
  warn "could not resolve the projects folder at $RAW_PROJECTS_DIR"
  exit 1
fi
# Re-run the SAME character whitelist on the resolved (symlink-following)
# path: a symlink such as ~/projects -> a folder named
# `evil");echo INJECTED;#` passes the check above (it's checked before
# resolution) but must still be refused once resolved, before it goes near
# the wrapper we write out below.
check_whitelist "$PROJECTS_DIR"
# Belt and braces: re-check containment on the resolved (symlink-following)
# path too — a symlink could point outside home even though the unresolved
# path looked fine above.
case "$PROJECTS_DIR" in
  "$HOME"|"$HOME"/*) ;;
  *)
    warn "projects folder must be inside your home folder (got $PROJECTS_DIR)"
    exit 1
    ;;
esac
if [ "$PROJECTS_DIR" = "$HOME" ]; then
  warn "the projects folder must be a folder INSIDE your home folder, not the home folder itself (got $PROJECTS_DIR)"
  exit 1
fi

if [ "$(uname -s)" != "Darwin" ]; then
  warn "This kit's GPT wrapper (codex-agent.sh) is macOS-only. Everything else installs fine."
fi

say "Installing into $CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands" "$CLAUDE_DIR/scripts"

# 1. Permission rule so Claude Code may run the wrapper without prompting.
# Done FIRST, before anything else is copied, so a malformed or
# unexpected-shape settings.json is reported up front rather than after
# the rest of the install has already run.
SETTINGS="$CLAUDE_DIR/settings.json"
RULE_ABS="Bash($HOME/.claude/scripts/codex-agent.sh:*)"
RULE_TILDE="Bash(~/.claude/scripts/codex-agent.sh:*)"
if [ ! -f "$SETTINGS" ]; then
  sed "s|__HOME__|$HOME|" "$KIT/claude/settings-allow.json" > "$SETTINGS"
  printf '    created settings.json with the wrapper allow rule\n'
elif command -v python3 >/dev/null 2>&1; then
  backup "$SETTINGS"
  python3 - "$SETTINGS" "$RULE_ABS" "$RULE_TILDE" <<'PY'
import json, os, sys
path, *rules = sys.argv[1:]
tmp = None
try:
    with open(path) as f:
        data = json.load(f)
    if not isinstance(data, dict):
        raise ValueError("settings.json is not a JSON object")
    perms = data.setdefault("permissions", {})
    if not isinstance(perms, dict):
        raise ValueError("permissions is not a JSON object")
    allow = perms.setdefault("allow", [])
    if not isinstance(allow, list):
        raise ValueError("permissions.allow is not a list")
    changed = False
    for r in rules:
        if r not in allow:
            allow.append(r)
            changed = True
    if changed:
        # Atomic write: build the new file next to the original, confirm it
        # actually re-parses, then swap it in with a single rename — so a
        # crash or a read-only folder midway through leaves the original
        # byte-identical rather than half-written.
        tmp = path + ".tmp"
        with open(tmp, "w") as f:
            json.dump(data, f, indent=2)
            f.write("\n")
        with open(tmp) as f:
            json.load(f)
        os.replace(tmp, path)
        print("    merged the wrapper allow rule into settings.json")
    else:
        print("    wrapper allow rule already present in settings.json")
except Exception:
    if tmp and os.path.exists(tmp):
        try:
            os.remove(tmp)
        except Exception:
            pass
    print("    WARNING: ~/.claude/settings.json is not in a shape I can safely merge into (not valid JSON, or permissions/allow isn't the expected object/list), or the folder could not be written to; the original file is untouched. the setup assistant will add these two lines to permissions.allow for you:")
    for r in rules:
        print(f'      "{r}"')
PY
else
  warn "settings.json exists and python3 is missing. Add these two lines to permissions.allow by hand:"
  printf '      "%s"\n      "%s"\n' "$RULE_ABS" "$RULE_TILDE"
fi

# 2. Global CLAUDE.md — preserve an existing "## About me" section if present
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

# 3. Agent role files
for f in "$KIT"/claude/agents/*.md; do
  backup "$CLAUDE_DIR/agents/$(basename "$f")"
  cp "$f" "$CLAUDE_DIR/agents/"
done
printf '    installed agents: %s\n' "$(ls "$KIT/claude/agents" | tr '\n' ' ')"

# 4. /gpt command
backup "$CLAUDE_DIR/commands/gpt.md"
cp "$KIT/claude/commands/gpt.md" "$CLAUDE_DIR/commands/gpt.md"
printf '    installed /gpt command\n'

# 5. Codex wrapper, with the projects folder baked in. Build the replacement
# line with python3 (or awk -v as a fallback) rather than sed, so a
# PROJECTS_DIR containing sed-special characters (&, |, \) can't corrupt it.
backup "$CLAUDE_DIR/scripts/codex-agent.sh"
REL_PROJECTS="${PROJECTS_DIR#"$HOME"/}"
# Belt and braces again: this should be unreachable given the checks above,
# but if the relative path ever comes out absolute or unchanged, stop rather
# than write a bad WRITE_PARENTS line into the installed wrapper.
case "$REL_PROJECTS" in
  /*|"$PROJECTS_DIR")
    warn "could not compute a projects folder relative to your home folder (got $PROJECTS_DIR)"
    exit 1
    ;;
esac
# Same whitelist again, on the exact value about to be written into the
# wrapper's WRITE_PARENTS line.
check_whitelist "$REL_PROJECTS"
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
    warn "codex is not logged in yet. Run: codex login   (a paid ChatGPT plan gives more usage; if it says your plan doesn't include Codex, that's fine — skip it)"
  fi
else
  warn "codex CLI not found. GPT is optional: only /gpt and reviewer-gpt need it. Install with: brew install --cask codex   then: codex login"
  printf '    Claude Code works without it.\n'
fi

say "Done."
if [ -n "$CODEX_BIN" ]; then
  printf '    Open a new Claude Code session and type:  /gpt what does this folder contain?\n'
else
  printf '    GPT is not set up (optional); everything else is ready.\n'
fi
printf '    Prompt suites are in %s/suites — see GETTING-STARTED.md for how to use them.\n' "$KIT"
if [ "$ANY_BACKUP" = 1 ]; then
  printf '    Backups of anything replaced are in %s\n' "$BACKUP_DIR"
fi

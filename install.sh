#!/bin/bash
# ai-starter-kit installer — copies the Claude Code setup into ~/.claude.
# Safe to re-run: existing files are backed up (with a dated folder) first,
# and personalisation survives — a persisted settings file
# (~/.claude/ai-starter-kit.conf) plus everything above the managed-block
# marker in ~/.claude/CLAUDE.md.
# Usage:  ./install.sh            (uses the conf file, or ~/developer on first run)
#         PROJECTS_DIR=~/code ./install.sh   (wins over the conf file, then saved to it)
#         ./install.sh --check   (reports drift against what the kit would install; writes nothing under ~/.claude)
set -euo pipefail

# python3 is required (it renders every file this installer writes — no
# fallback is kept for its absence). Apple's command line tools provide it;
# check this before anything else so the failure is a plain one-line message
# rather than a shell error partway through, before anything is written.
# `command -v python3` is not enough on macOS: Apple ships a stub at
# /usr/bin/python3 that satisfies `command -v` but exits non-zero (and prints
# a licence/install nag) until the command line tools are actually present —
# so this runs the interpreter instead of just locating it.
if ! python3 -c '' >/dev/null 2>&1; then
  printf 'ERROR: python3 is required and was not found. Install Apple'"'"'s command line tools: run `xcode-select --install` in Terminal, or finish Phase 1 of SETUP-AGENT.md.\n' >&2
  exit 2
fi

KIT="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
CONF="$CLAUDE_DIR/ai-starter-kit.conf"
MARKER='<!-- ai-starter-kit managed: everything below this line is replaced by the kit installer -->'
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$CLAUDE_DIR/backups/$STAMP"

say()  { printf '\n==> %s\n' "$1"; }
warn() { printf '    WARNING: %s\n' "$1"; }

usage() {
  printf 'Usage: ./install.sh            (uses the conf file, or ~/developer on first run)\n'
  printf '       PROJECTS_DIR=~/code ./install.sh\n'
  printf '       ./install.sh --check   (reports drift; writes nothing under ~/.claude)\n'
}

# Argument handling (L7): no argument, or exactly one argument that is
# --check, are the only valid invocations — anything else is a usage error,
# not something to guess at.
CHECK_MODE=0
case "$#" in
  0) ;;
  1)
    case "$1" in
      --check) CHECK_MODE=1 ;;
      *) usage; exit 2 ;;
    esac
    ;;
  *) usage; exit 2 ;;
esac

# --------------------------------------------------------------------------
# The conf file: ~/.claude/ai-starter-kit.conf, shell-style KEY=value lines.
# Read at the start of EVERY run (install and --check) so personalisation
# from an earlier install survives an update. Parsed by hand, not sourced —
# this file can in principle be hand-edited, and a plain read loop can never
# execute anything it contains. A line that isn't shaped like KEY=value, or a
# recognised key with a value outside its own whitelist, means the conf file
# has been hand-edited into something this installer can no longer trust —
# that is loud and fatal (exit 2), not a warn-and-default: silently picking a
# default in place of a bad value is exactly how a typo turns into a folder
# nobody meant to use. An unrecognised KEY is different — forward
# compatibility with a future key needs the file to still work — so that
# case alone stays a warning.
# --------------------------------------------------------------------------
CONF_PROJECTS_DIR=""
CONF_SPELLING=""
CONF_GPT=""
CONF_KIT_VERSION=""
CONF_TIER_SOL=""
CONF_TIER_LUNA=""
GPT_SENTENCE="GPT is not set up on this machine yet; report the reviewer-gpt pass as OUTSTANDING and say so plainly, until \`codex login\` has been run."
# Same shape the wrapper itself enforces for a tier's slug (codex-agent.sh's
# _codex_slug_re), just anchored to one tier name instead of the whole
# family — an override can only ever be a slug of the tier it overrides. In
# a variable, not inline, for the same reason the wrapper keeps its own in
# one: bash 3.2 (macOS /bin/bash) mis-parses quoted regex operands to =~.
TIER_SOL_RE='^gpt-[1-9][0-9]*(\.[0-9]+)?-sol$'
TIER_LUNA_RE='^gpt-[1-9][0-9]*(\.[0-9]+)?-luna$'

# Marker detection: a line counts as the managed-block marker if it equals
# $MARKER exactly, OR starts with $MARKER but has trailing junk after it
# (once trailing whitespace is stripped) — e.g. a marker line someone
# accidentally left a trailing space on, or appended a comment to. Either
# shape is normalised back to the exact marker text whenever this installer
# writes the file, so this only has to be generous on the READ side; it must
# never match twice or the personal block and kit body could be spliced in
# the wrong place. Prints the 1-based line number, or nothing if absent.
marker_line_num() {
  awk -v marker="$MARKER" '
    { line = $0; sub(/[ \t]+$/, "", line)
      if (index(line, marker) == 1) { print NR; exit } }
  ' "$1" 2>/dev/null
}
if [ -f "$CONF" ]; then
  while IFS= read -r _line || [ -n "$_line" ]; do
    case "$_line" in
      ""|"#"*) continue ;;
    esac
    case "$_line" in
      [A-Za-z_]*=*) ;;
      *)
        printf '    ERROR: malformed line in %s (expected KEY=value): %s\n' "$CONF" "$_line" >&2
        exit 2
        ;;
    esac
    _key="${_line%%=*}"
    _val="${_line#*=}"
    # strip one layer of surrounding double quotes, if present
    _val="${_val%\"}"
    _val="${_val#\"}"
    case "$_key" in
      PROJECTS_DIR) CONF_PROJECTS_DIR="$_val" ;;
      SPELLING)
        case "$_val" in
          british|american) CONF_SPELLING="$_val" ;;
          *)
            printf '    ERROR: %s has SPELLING=%s (expected british or american)\n' "$CONF" "$_val" >&2
            exit 2
            ;;
        esac
        ;;
      GPT)
        case "$_val" in
          yes|no) CONF_GPT="$_val" ;;
          *)
            printf '    ERROR: %s has GPT=%s (expected yes or no)\n' "$CONF" "$_val" >&2
            exit 2
            ;;
        esac
        ;;
      KIT_VERSION) CONF_KIT_VERSION="$_val" ;;
      TIER_SOL)
        if [[ "$_val" =~ $TIER_SOL_RE ]]; then
          CONF_TIER_SOL="$_val"
        else
          printf '    ERROR: %s has TIER_SOL=%s (expected a slug shaped gpt-<major>[.<minor>]-sol)\n' "$CONF" "$_val" >&2
          exit 2
        fi
        ;;
      TIER_LUNA)
        if [[ "$_val" =~ $TIER_LUNA_RE ]]; then
          CONF_TIER_LUNA="$_val"
        else
          printf '    ERROR: %s has TIER_LUNA=%s (expected a slug shaped gpt-<major>[.<minor>]-luna)\n' "$CONF" "$_val" >&2
          exit 2
        fi
        ;;
      *) warn "ignoring unknown key '$_key' in $CONF" ;;
    esac
  done < "$CONF"
fi
unset _key _val _line

# --------------------------------------------------------------------------
# Migration from a v1.0.0 install: v1.0.0 predates this conf file, so someone
# updating straight from it has no conf — but their Phase 7 choices still
# exist, written straight into the files that install replaced by hand: a
# non-default projects folder baked into the installed wrapper's
# WRITE_PARENTS line, "American spelling" edited into the installed agent
# files and CLAUDE.md, and the GPT-not-set-up sentence written into the
# installed CLAUDE.md's kit body. Seed the conf from those before computing
# any default, so a v1.0.0 upgrade never silently resets them (e.g. losing a
# custom projects folder back to ~/developer). Only runs once — as soon as a
# conf exists, this block is skipped and the conf is the single source of
# truth from then on. Never creates the projects folder here; on a real
# migration it already exists.
# --------------------------------------------------------------------------
# --check must report this seeding too (so a v1.0.0 person can see what an
# update would do before agreeing to it) without claiming it already
# happened — everything below only sets in-memory CONF_* variables either
# way; the file writes that make it real happen only in a real install,
# further down.
_mig_verb="migrated"
[ "$CHECK_MODE" = 1 ] && _mig_verb="would migrate"
if [ ! -f "$CONF" ] && { [ -e "$CLAUDE_DIR/scripts/codex-agent.sh" ] || [ -f "$CLAUDE_DIR/CLAUDE.md" ]; }; then
  if [ -f "$CLAUDE_DIR/scripts/codex-agent.sh" ]; then
    _wp_line="$(grep -m1 '^WRITE_PARENTS=' "$CLAUDE_DIR/scripts/codex-agent.sh" 2>/dev/null)" || _wp_line=""
    # A shipped wrapper only ever has one WRITE_PARENTS entry (render_wrapper_to
    # writes exactly one); more than one means a hand edit this installer's
    # single-folder migration can't safely guess at — loud and fatal rather
    # than silently picking one or dropping the rest. Counted by quote pairs:
    # each entry is one quoted string, so more than one pair means more than
    # one entry.
    if [ -n "$_wp_line" ]; then
      _wp_quotes="$(printf '%s' "$_wp_line" | tr -cd '"' | wc -c | tr -d ' ')"
      if [ "$_wp_quotes" -gt 2 ]; then
        printf '    ERROR: the installed wrapper'"'"'s WRITE_PARENTS line has more than one entry (%s); this installer only understands a single projects folder. Fix ~/.claude/scripts/codex-agent.sh by hand (or ask for help) before re-running.\n' "$_wp_line" >&2
        exit 2
      fi
    fi
    _mig_rel="$(printf '%s\n' "$_wp_line" | sed -n 's/^WRITE_PARENTS=("\$REAL_HOME\/\(.*\)")$/\1/p')"
    if [ -n "$_mig_rel" ]; then
      CONF_PROJECTS_DIR="$_mig_rel"
      printf '    %s from your existing install: projects folder = %s\n' "$_mig_verb" "$_mig_rel"
    fi
    unset _wp_line _wp_quotes
  fi
  if grep -qF "American spelling" "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR"/agents/*.md 2>/dev/null; then
    CONF_SPELLING="american"
    printf '    %s from your existing install: spelling = american\n' "$_mig_verb"
  fi
  # v1.0.0 wrapped this sentence across two lines in some renders, so match
  # its fixed leading phrase rather than the sentence verbatim (which a
  # hard-wrapped copy would never equal line-for-line).
  if [ -f "$CLAUDE_DIR/CLAUDE.md" ] && grep -qF "GPT is not set up on this machine yet" "$CLAUDE_DIR/CLAUDE.md"; then
    CONF_GPT="no"
    printf '    %s from your existing install: GPT = not set up\n' "$_mig_verb"
  fi
  unset _mig_rel
fi
unset _mig_verb

SPELLING="${CONF_SPELLING:-british}"
GPT="${CONF_GPT:-yes}"
TIER_SOL="$CONF_TIER_SOL"
TIER_LUNA="$CONF_TIER_LUNA"

# Character whitelist, checked before a projects-dir value goes anywhere near
# the shell script we write out later (the codex wrapper's WRITE_PARENTS
# line) — no character that could break out of a quoted string is let
# through. Re-applied below to the resolved path too, since a symlink can
# turn an innocent-looking value into one that contains an unsafe character
# only after it is resolved.
check_whitelist() {
  case "$1" in
    *[!A-Za-z0-9._/\ -]*)
      warn "the projects folder path can only contain letters, numbers, spaces, and . _ - / (got $1)"
      exit 1
      ;;
  esac
}

# Resolve PROJECTS_DIR: an explicit env var on the command line wins over the
# conf file, which wins over the ~/developer default. In --check mode this
# never creates the folder — a read-only run must change nothing.
if [ -n "${PROJECTS_DIR:-}" ]; then
  RAW_PROJECTS_DIR="$PROJECTS_DIR"
elif [ -n "$CONF_PROJECTS_DIR" ]; then
  # The conf stores this relative to home (e.g. "developer", "code") so the
  # file never has to know which account it's read under; accept an
  # absolute or `~`-prefixed value too, for a conf written by an earlier
  # release (or by hand) before that was the convention.
  case "$CONF_PROJECTS_DIR" in
    /*|"~"|"~/"*) RAW_PROJECTS_DIR="$CONF_PROJECTS_DIR" ;;
    *) RAW_PROJECTS_DIR="$HOME/$CONF_PROJECTS_DIR" ;;
  esac
else
  RAW_PROJECTS_DIR="$HOME/developer"
fi
case "$RAW_PROJECTS_DIR" in
  "~") RAW_PROJECTS_DIR="$HOME" ;;
  "~/"*) RAW_PROJECTS_DIR="$HOME/${RAW_PROJECTS_DIR#"~/"}" ;;
esac
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

if [ "$CHECK_MODE" = 1 ]; then
  # Read-only: never create the folder. If it doesn't exist yet, compare
  # against the whitelisted, unresolved value — good enough for a report.
  if [ -d "$RAW_PROJECTS_DIR" ]; then
    PROJECTS_DIR="$(cd "$RAW_PROJECTS_DIR" && pwd -P)"
  else
    PROJECTS_DIR="$RAW_PROJECTS_DIR"
  fi
else
  if ! mkdir -p "$RAW_PROJECTS_DIR"; then
    warn "could not create the projects folder at $RAW_PROJECTS_DIR"
    exit 1
  fi
  if ! PROJECTS_DIR="$(cd "$RAW_PROJECTS_DIR" && pwd -P)"; then
    warn "could not resolve the projects folder at $RAW_PROJECTS_DIR"
    exit 1
  fi
fi
# Re-run the SAME character whitelist on the resolved (symlink-following)
# path: a symlink such as ~/developer -> a folder named
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

REL_PROJECTS="${PROJECTS_DIR#"$HOME"/}"
case "$REL_PROJECTS" in
  /*|"$PROJECTS_DIR")
    warn "could not compute a projects folder relative to your home folder (got $PROJECTS_DIR)"
    exit 1
    ;;
esac
check_whitelist "$REL_PROJECTS"

# --------------------------------------------------------------------------
# Rendering: what install.sh would write, computed from the kit files plus
# the conf — used by BOTH --check (to compare) and a real install (to
# write). Keeping one definition means the two can never quietly diverge.
# --------------------------------------------------------------------------

render_wrapper_to() {
  # $1 = output path. Also applies a per-user tier override for sol/luna
  # (TIER_SOL/TIER_LUNA in the conf) when the account's ChatGPT plan has
  # refused the kit's current pin — see MODELS.md's "Per-user tier
  # overrides" note. The wrapper's own family-suffix check still runs
  # against whatever this writes, so an override can never smuggle in a
  # slug of the wrong tier.
  python3 - "$KIT/claude/scripts/codex-agent.sh" "$1" "$REL_PROJECTS" "${TIER_SOL:-}" "${TIER_LUNA:-}" <<'PY'
import re, sys
src, dst, rel, tier_sol, tier_luna = sys.argv[1:]
with open(src) as f:
    s = f.read()
new_line = 'WRITE_PARENTS=("$REAL_HOME/' + rel + '")'
s, n = re.subn(r'^WRITE_PARENTS=\(.*\)$', lambda m: new_line, s, count=1, flags=re.M)
if n != 1:
    sys.exit("WRITE_PARENTS line not found in " + src)
for key, slug in (("SOL", tier_sol), ("LUNA", tier_luna)):
    if not slug:
        continue
    line = ('MODEL_TIER_%s="%s"  # per-user override (ai-starter-kit.conf: TIER_%s) '
            '- the kit-wide pin was refused on this account/plan' % (key, slug, key))
    s, n = re.subn(r'^MODEL_TIER_%s=.*$' % key, lambda m, line=line: line, s, count=1, flags=re.M)
    if n != 1:
        sys.exit("MODEL_TIER_%s line not found in %s" % (key, src))
with open(dst, "w") as f:
    f.write(s)
PY
}

render_gpt_to() {
  # $1 = output path
  sed "s|claude-__UID__|claude-$(id -u)|g" "$KIT/claude/commands/gpt.md" > "$1"
}

render_agent_to() {
  # $1 = source agent file in the kit, $2 = output path
  if [ "$SPELLING" = "american" ]; then
    sed 's/British\/Australian spelling/American spelling/' "$1" > "$2"
  else
    cp "$1" "$2"
  fi
}

render_kit_body_to() {
  # $1 = output path — claude/CLAUDE.md's kit body, spelling-rendered
  render_agent_to "$KIT/claude/CLAUDE.md" "$1"
}

# --check: report installed-vs-kit state and exit. Writes nothing under
# ~/.claude (it renders into a temporary directory to compare, then removes
# it) — safe to run any time, including against a machine you don't want to
# touch yet. Exits 1 if anything is out of date or missing, so a caller (the
# setup assistant, a script) can act on the exit code alone. Compares the
# INSTALLED files against the RENDERED files a real install would write (kit
# + conf) — not just a couple of version lines. A row can also read
# "CANNOT RENDER" instead of drift — that means the kit's own source moved
# under a render function's feet (e.g. a master's WRITE_PARENTS line was
# renamed) rather than the installed copy being out of date; the summary line
# at the end says which of the two happened.
if [ "$CHECK_MODE" = 1 ]; then
  DRIFT=0
  RENDER_FAILED=0
  TMPDIR_CHECK="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR_CHECK"' EXIT
  row() { printf '%-34s %-30s %-30s\n' "$1" "$2" "$3"; }
  row "ITEM" "INSTALLED" "KIT"

  kit_ver="$(cat "$KIT/KIT_VERSION" 2>/dev/null)" || kit_ver="missing"
  inst_ver="${CONF_KIT_VERSION:-missing}"
  [ "$inst_ver" = "$kit_ver" ] || DRIFT=1
  row "KIT_VERSION" "$inst_ver" "$kit_ver"

  check_rendered() {
    # $1 = label, $2 = installed path, $3 = rendered tmp path
    local label="$1" installed="$2" rendered="$3"
    if [ ! -e "$installed" ]; then
      row "$label" "MISSING" "-"
      DRIFT=1
    elif cmp -s "$installed" "$rendered"; then
      row "$label" "match" "-"
    else
      row "$label" "DIFFERS" "-"
      DRIFT=1
    fi
  }

  if render_wrapper_to "$TMPDIR_CHECK/wrapper"; then
    check_rendered "wrapper" "$CLAUDE_DIR/scripts/codex-agent.sh" "$TMPDIR_CHECK/wrapper"
  else
    row "wrapper" "CANNOT RENDER" "-"
    RENDER_FAILED=1
  fi

  render_gpt_to "$TMPDIR_CHECK/gpt.md"
  check_rendered "/gpt" "$CLAUDE_DIR/commands/gpt.md" "$TMPDIR_CHECK/gpt.md"

  for f in "$KIT"/claude/agents/*.md; do
    name="$(basename "$f")"
    render_agent_to "$f" "$TMPDIR_CHECK/$name"
    check_rendered "agent: $name" "$CLAUDE_DIR/agents/$name" "$TMPDIR_CHECK/$name"
  done

  CLAUDE_INSTALLED="$CLAUDE_DIR/CLAUDE.md"
  CLAUDE_MARKER_LINE=""
  [ -f "$CLAUDE_INSTALLED" ] && CLAUDE_MARKER_LINE="$(marker_line_num "$CLAUDE_INSTALLED")"
  if [ ! -f "$CLAUDE_INSTALLED" ]; then
    row "CLAUDE.md (kit body)" "MISSING" "-"
    DRIFT=1
  elif [ -z "$CLAUDE_MARKER_LINE" ]; then
    row "CLAUDE.md (kit body)" "DIFFERS (no marker)" "-"
    DRIFT=1
  else
    # The marker-detection read side is generous (trailing junk still
    # counts, install.sh's own comment above marker_line_num explains why) —
    # but a marker that isn't byte-exact is still something a real install
    # would rewrite, so --check must report it as drift rather than silently
    # accepting it as already-normalised.
    _marker_actual="$(sed -n "${CLAUDE_MARKER_LINE}p" "$CLAUDE_INSTALLED")"
    tail -n "+$((CLAUDE_MARKER_LINE + 1))" "$CLAUDE_INSTALLED" > "$TMPDIR_CHECK/installed-body"
    render_kit_body_to "$TMPDIR_CHECK/rendered-kit-body"
    { printf '\n'; cat "$TMPDIR_CHECK/rendered-kit-body"; } > "$TMPDIR_CHECK/rendered-body"
    if [ "$_marker_actual" != "$MARKER" ]; then
      row "CLAUDE.md (kit body)" "DIFFERS (marker not normalised)" "-"
      DRIFT=1
    elif cmp -s "$TMPDIR_CHECK/installed-body" "$TMPDIR_CHECK/rendered-body"; then
      row "CLAUDE.md (kit body)" "match" "-"
    else
      row "CLAUDE.md (kit body)" "DIFFERS" "-"
      DRIFT=1
    fi
    unset _marker_actual
  fi

  if [ -f "$CLAUDE_DIR/settings.json" ]; then
    ALLOW_STATE="$(python3 - "$CLAUDE_DIR/settings.json" "$HOME" <<'PY'
import json, sys
path, home = sys.argv[1:]
rule_abs = "Bash(" + home + "/.claude/scripts/codex-agent.sh:*)"
rule_tilde = "Bash(~/.claude/scripts/codex-agent.sh:*)"
try:
    with open(path) as f:
        data = json.load(f)
    allow = data.get("permissions", {}).get("allow", [])
    if rule_abs in allow and rule_tilde in allow:
        print("ok")
    else:
        print("DIFFERS")
except Exception:
    print("DIFFERS")
PY
)"
  else
    ALLOW_STATE="unreadable"
  fi
  [ "$ALLOW_STATE" = "ok" ] || DRIFT=1
  row "permissions.allow (both spellings)" "$ALLOW_STATE" "-"

  if [ -f "$CLAUDE_DIR/settings.json" ]; then
    ENV_CHECK="$(python3 - "$CLAUDE_DIR/settings.json" "$KIT/claude/settings-env.json" <<'PY'
import json, sys
inst_path, kit_path = sys.argv[1:]
try:
    with open(inst_path) as f:
        inst = json.load(f).get("env", {})
except Exception:
    print("unreadable|-")
    sys.exit()
with open(kit_path) as f:
    kit_env = json.load(f)["env"]
missing = [k for k in kit_env if k not in inst]
wrong = [k for k in kit_env if k in inst and inst[k] != kit_env[k]]
if not missing and not wrong:
    print("all present and equal|ok")
else:
    parts = []
    if missing:
        parts.append("missing: " + ",".join(missing))
    if wrong:
        parts.append("differs: " + ",".join(wrong))
    print("; ".join(parts) + "|drift")
PY
)"
    env_state="${ENV_CHECK%%|*}"
    env_flag="${ENV_CHECK##*|}"
    [ "$env_flag" = "ok" ] || DRIFT=1
  else
    env_state="settings.json missing"
    DRIFT=1
  fi
  row "env pins (4 keys)" "$env_state" "see MODELS.md"

  CODEX_BIN=""
  for c in /opt/homebrew/bin/codex /usr/local/bin/codex; do
    [ -x "$c" ] && CODEX_BIN="$c" && break
  done
  if [ -n "$CODEX_BIN" ]; then
    codex_ver="$("$CODEX_BIN" --version 2>/dev/null)" || codex_ver="found, version unknown"
    row "codex CLI" "$codex_ver ($CODEX_BIN)" "-"
  else
    row "codex CLI" "not found" "-"
  fi

  if command -v claude >/dev/null 2>&1; then
    claude_ver="$(claude --version 2>/dev/null)" || claude_ver="found, version unknown"
    row "Claude Code" "$claude_ver" "-"
  elif [ -x "$HOME/.local/bin/claude" ]; then
    claude_ver="$("$HOME/.local/bin/claude" --version 2>/dev/null)" || claude_ver="found, version unknown"
    row "Claude Code" "$claude_ver ($HOME/.local/bin/claude)" "-"
  else
    row "Claude Code" "not on PATH" "-"
  fi

  if [ -n "$TIER_SOL" ] || [ -n "$TIER_LUNA" ]; then
    row "per-user tier overrides" "sol=${TIER_SOL:-none} luna=${TIER_LUNA:-none}" "-"
  fi

  if [ "$RENDER_FAILED" = 1 ]; then
    printf '\nSUMMARY: could not render one or more expected files from the kit (see CANNOT RENDER above) — nothing was compared for those rows.\n'
    exit 1
  elif [ "$DRIFT" = 1 ]; then
    printf '\nSUMMARY: installed files differ from what the kit currently ships.\n'
    exit 1
  else
    printf '\nSUMMARY: everything installed matches the kit.\n'
    exit 0
  fi
fi

# --------------------------------------------------------------------------
# Real install from here on.
# --------------------------------------------------------------------------

ANY_BACKUP=0
BACKED_UP=""
NEWLY_CREATED=""
mark_created() { NEWLY_CREATED="$NEWLY_CREATED $1"; }
backup() {
  local src="$1" rel dst
  [ -e "$src" ] || return 0
  case " $NEWLY_CREATED " in *" $src "*) return 0 ;; esac
  case " $BACKED_UP " in *" $src "*) return 0 ;; esac
  rel="${src#"$CLAUDE_DIR"/}"
  dst="$BACKUP_DIR/$rel"
  if mkdir -p "$(dirname "$dst")" && cp -p "$src" "$dst"; then
    ANY_BACKUP=1
    BACKED_UP="$BACKED_UP $src"
    printf '    backed up %s\n' "$src"
  else
    printf '    WARNING: could not back up %s; stopping before changing anything\n' "$src"
    exit 1
  fi
}

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
  mark_created "$SETTINGS"
  printf '    created settings.json with the wrapper allow rule\n'
else
  backup "$SETTINGS"
  python3 - "$SETTINGS" "$RULE_ABS" "$RULE_TILDE" <<'PY'
import json, os, sys
path, *rules = sys.argv[1:]
path = os.path.realpath(path)  # write through a symlink, never replace the link itself
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
        mode = os.stat(path).st_mode & 0o777
        os.chmod(tmp, mode)  # keep the original file mode (e.g. 0600)
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
fi

# 2. Model tier pins — merge the env keys from claude/settings-env.json into
# settings.json's "env" block, the same careful way as the allow rule above:
# atomic write, original file mode preserved, existing unrelated keys left
# alone. (By this point settings.json exists either way — step 1 either
# created it fresh or merged into the existing one.) If this cannot be done,
# the keys printed below are exactly what the setup assistant needs to add
# by hand, and Phase 6 checks for them.
backup "$SETTINGS"
python3 - "$SETTINGS" "$KIT/claude/settings-env.json" <<'PY'
import json, os, sys
path, env_src = sys.argv[1:]
path = os.path.realpath(path)  # write through a symlink, never replace the link itself
with open(env_src) as f:
    new_env = json.load(f)["env"]
tmp = None
try:
    with open(path) as f:
        data = json.load(f)
    if not isinstance(data, dict):
        raise ValueError("settings.json is not a JSON object")
    env = data.setdefault("env", {})
    if not isinstance(env, dict):
        raise ValueError("env is not a JSON object")
    changed = False
    for k, v in new_env.items():
        if env.get(k) != v:
            env[k] = v
            changed = True
    if changed:
        # Atomic write, same recipe as the allow-rule merge above: build next
        # to the original, confirm it re-parses, then swap in with one rename.
        tmp = path + ".tmp"
        with open(tmp, "w") as f:
            json.dump(data, f, indent=2)
            f.write("\n")
        with open(tmp) as f:
            json.load(f)
        mode = os.stat(path).st_mode & 0o777
        os.chmod(tmp, mode)  # keep the original file mode (e.g. 0600)
        os.replace(tmp, path)
        print("    merged the model tier pins into settings.json's env block")
    else:
        print("    model tier pins already present in settings.json")
except Exception:
    if tmp and os.path.exists(tmp):
        try:
            os.remove(tmp)
        except Exception:
            pass
    print("    WARNING: ~/.claude/settings.json is not in a shape I can safely merge into (not valid JSON, or env isn't a JSON object), or the folder could not be written to; the original file is untouched. the setup assistant will add these keys to the env block for you (see claude/settings-env.json in the kit):")
    for k, v in new_env.items():
        print(f'      "{k}": "{v}"')
PY

# 3. Global CLAUDE.md — personal block on top (an existing "## About me"
# section, or everything above the managed-block marker), then the marker,
# then the kit body. Only the kit body below the marker is ever replaced;
# everything above it — the person's own edits, made through Phase 7 — is
# carried forward verbatim.
backup "$CLAUDE_DIR/CLAUDE.md"
PERSONAL_BLOCK=""
_claude_md_marker_line=""
[ -f "$CLAUDE_DIR/CLAUDE.md" ] && _claude_md_marker_line="$(marker_line_num "$CLAUDE_DIR/CLAUDE.md")"
if [ -n "$_claude_md_marker_line" ]; then
  # `head -n 0` is a macOS error (exit 1), not an empty read — a marker on
  # line 1 (nothing above it) would otherwise kill the whole install under
  # set -e before anything downstream had run. Nothing above line 1 to read
  # in that case anyway, so just leave PERSONAL_BLOCK empty.
  if [ "$_claude_md_marker_line" -gt 1 ]; then
    PERSONAL_BLOCK="$(head -n "$((_claude_md_marker_line - 1))" "$CLAUDE_DIR/CLAUDE.md")"
  fi
elif [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  # v1.0.0-shaped file: no marker yet. Keep the About me section (anything
  # before the first heading line - empty when there is none) the same way
  # this installer always has, then add the marker from here on.
  PERSONAL_BLOCK="$(awk '/^# / {exit} {print}' "$CLAUDE_DIR/CLAUDE.md")"
  # v1.0.0's Phase 7 also wrote other things straight into the kit body that
  # is about to be replaced below: the GPT-outstanding sentence (carried
  # forward separately via GPT=no, migrated above — never copied verbatim,
  # the render re-adds it whenever it's still needed) and, potentially, any
  # other free text an earlier Phase 7 run added anywhere in the file (a
  # check-in preference, or anything else the person asked for). Guessing at
  # a fixed phrase for that (the "before every change" heuristic this used
  # to be) only ever catches the one wording it was written for. Instead,
  # take every non-blank line from the first `# ` heading onward (the About
  # me section above is already carried, so skip it here) that does NOT
  # occur in the PREVIOUS release's own kit body — a plain set-difference
  # against claude/previous/CLAUDE-1.0.0.md, in file order, de-duplicated,
  # with the GPT sentence's own paragraph excluded outright (it is never
  # carried this way, wrapped over one line or two) and the previous body
  # compared after applying the SAME spelling substitution just detected, so
  # an "American spelling" edit reads as unchanged kit text rather than
  # something the person wrote.
  if [ -f "$KIT/claude/previous/CLAUDE-1.0.0.md" ]; then
    _mig_notes="$(python3 - "$CLAUDE_DIR/CLAUDE.md" "$KIT/claude/previous/CLAUDE-1.0.0.md" "$SPELLING" <<'PY'
import re, sys
installed_path, previous_path, spelling = sys.argv[1:]
with open(installed_path) as f:
    installed_lines = f.read().splitlines()
with open(previous_path) as f:
    previous_text = f.read()
previous_lines = set(previous_text.splitlines())
if spelling == "american":
    # Both ways the 1.0.0 runbook spelling edit could have been applied:
    # the whole phrase replaced, or only the word pair (a literal reading of
    # the 1.0.0 runbook step, which yields British/American spelling) -
    # neither is something the person wrote.
    for variant in (previous_text.replace("British/Australian spelling", "American spelling"),
                    previous_text.replace("Australian spelling", "American spelling")):
        previous_lines |= set(variant.splitlines())

GPT_PREFIX = "GPT is not set up on this machine yet"

# The About-me section (everything before the first "# " heading) is
# carried separately above; scan only from that heading onward so its
# lines are never duplicated here.
start = len(installed_lines)
for i, line in enumerate(installed_lines):
    if re.match(r'^# ', line):
        start = i
        break
remainder = installed_lines[start:]

# Group into blank-line-delimited paragraphs so a sentence hard-wrapped
# over two lines is recognised — and kept or dropped — as one unit, never
# split mid-sentence.
paragraphs = []
current = []
for line in remainder:
    if line.strip() == "":
        if current:
            paragraphs.append(current)
            current = []
    else:
        current.append(line)
if current:
    paragraphs.append(current)

# Paragraphs of the previous body, joined the same way, so a kit paragraph
# that had the GPT sentence appended to it is still recognised as kit text
# once the sentence is cut out.
previous_paragraphs = set()
_cur = []
for line in previous_text.splitlines():
    if line.strip() == "":
        if _cur:
            previous_paragraphs.add(" ".join(" ".join(_cur).split())); _cur = []
    else:
        _cur.append(line)
if _cur:
    previous_paragraphs.add(" ".join(" ".join(_cur).split()))

GPT_END = "has been run."
seen = set()
notes = []
for para in paragraphs:
    joined = " ".join(l.strip() for l in para)
    if GPT_PREFIX in joined:
        # Cut the sentence out wherever it sits in the paragraph (own
        # paragraph, glued under a heading, or appended to kit text); carry
        # only what is left, and only if that leftover is not kit text.
        i = joined.index(GPT_PREFIX)
        j = joined.find(GPT_END, i)
        leftover = " ".join((joined[:i] + (joined[j + len(GPT_END):] if j != -1 else "")).split())
        if leftover and leftover not in previous_paragraphs and leftover not in previous_lines and leftover not in seen:
            seen.add(leftover)
            notes.append(leftover)
        continue
    for line in para:
        if line not in previous_lines and line not in seen:
            seen.add(line)
            notes.append(line)

for line in notes:
    print(line)
PY
)"
    if [ -n "$_mig_notes" ]; then
      if [ -n "$(printf '%s' "$PERSONAL_BLOCK" | tr -d '[:space:]')" ]; then
        PERSONAL_BLOCK="$(printf '%s\n\n%s\n%s' "$PERSONAL_BLOCK" "## My notes (carried over from the previous version)" "$_mig_notes")"
      else
        PERSONAL_BLOCK="$(printf '%s\n%s' "## My notes (carried over from the previous version)" "$_mig_notes")"
      fi
    fi
    unset _mig_notes
  else
    warn "no claude/previous/CLAUDE-1.0.0.md in this kit copy; could not check for anything you wrote beyond the About me section"
  fi
fi
unset _claude_md_marker_line

# When GPT isn't set up, add the one sentence Phase 7 used to add by hand
# (once, if not already there); when it is, remove it if a previous run left
# it in. Both are idempotent so re-running this step never duplicates or
# strands the sentence.
if [ "$GPT" = "no" ]; then
  if ! printf '%s' "$PERSONAL_BLOCK" | grep -qF "$GPT_SENTENCE"; then
    if [ -n "$PERSONAL_BLOCK" ]; then
      PERSONAL_BLOCK="$(printf '%s\n\n%s' "$PERSONAL_BLOCK" "$GPT_SENTENCE")"
    else
      PERSONAL_BLOCK="$GPT_SENTENCE"
    fi
  fi
else
  if printf '%s' "$PERSONAL_BLOCK" | grep -qF "$GPT_SENTENCE"; then
    # grep -v exits 1 when every line matches (the sentence was the whole
    # block) — not a failure here, just "nothing left"; under set -e an
    # unguarded assignment would otherwise kill the whole install on exactly
    # that case, so the fallback to "" is explicit rather than left to the
    # command substitution's own exit status.
    PERSONAL_BLOCK="$(printf '%s\n' "$PERSONAL_BLOCK" | { grep -vF "$GPT_SENTENCE" || true; })"
  fi
fi

CLAUDE_BODY_TMP="$(mktemp)"
trap 'rm -f "$CLAUDE_BODY_TMP"' EXIT
render_kit_body_to "$CLAUDE_BODY_TMP"
{
  if [ -n "$PERSONAL_BLOCK" ]; then
    printf '%s\n\n' "$PERSONAL_BLOCK"
  fi
  printf '%s\n\n' "$MARKER"
  cat "$CLAUDE_BODY_TMP"
} > "$CLAUDE_DIR/CLAUDE.md.new"
rm -f "$CLAUDE_BODY_TMP"
mv "$CLAUDE_DIR/CLAUDE.md.new" "$CLAUDE_DIR/CLAUDE.md"
if [ -n "$PERSONAL_BLOCK" ]; then
  printf '    installed CLAUDE.md (kept your personal block above the marker)\n'
else
  printf '    installed CLAUDE.md\n'
fi

# 4. Agent role files
for f in "$KIT"/claude/agents/*.md; do
  backup "$CLAUDE_DIR/agents/$(basename "$f")"
  render_agent_to "$f" "$CLAUDE_DIR/agents/$(basename "$f")"
done
printf '    installed agents: %s\n' "$(ls "$KIT/claude/agents" | tr '\n' ' ')"

# 5. /gpt command
backup "$CLAUDE_DIR/commands/gpt.md"
render_gpt_to "$CLAUDE_DIR/commands/gpt.md"
printf '    installed /gpt command\n'

# 6. Codex wrapper, with the projects folder baked in.
backup "$CLAUDE_DIR/scripts/codex-agent.sh"
render_wrapper_to "$CLAUDE_DIR/scripts/codex-agent.sh"
chmod +x "$CLAUDE_DIR/scripts/codex-agent.sh"
bash -n "$CLAUDE_DIR/scripts/codex-agent.sh"
grep -qF "WRITE_PARENTS=(\"\$REAL_HOME/$REL_PROJECTS\")" "$CLAUDE_DIR/scripts/codex-agent.sh" \
  || warn "could not confirm the installed wrapper's WRITE_PARENTS line"
printf '    installed codex-agent.sh (repos may be edited by GPT only under %s)\n' "$PROJECTS_DIR"

# 7. Codex CLI check (for the GPT side) — trusted, absolute locations only;
# `command -v codex` would also accept a codex earlier on PATH that the
# wrapper itself would refuse to run. Skipped when GPT is recorded as not
# set up, so someone who said no to the GPT add-on doesn't see codex
# warnings about a thing they never asked for.
if [ "$GPT" = "no" ]; then
  printf '    GPT is not set up on this machine (skipping the codex check).\n'
  CODEX_BIN=""
else
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
fi

# 8. Persist the conf file — what this run actually used, so the next run
# (and Phase 9's update) starts from it rather than a hand-remembered value.
backup "$CONF"
{
  printf 'PROJECTS_DIR=%s\n' "$REL_PROJECTS"
  printf 'SPELLING=%s\n' "$SPELLING"
  printf 'GPT=%s\n' "$GPT"
  printf 'KIT_VERSION=%s\n' "$(cat "$KIT/KIT_VERSION")"
  if [ -n "$TIER_SOL" ]; then printf 'TIER_SOL=%s\n' "$TIER_SOL"; fi
  if [ -n "$TIER_LUNA" ]; then printf 'TIER_LUNA=%s\n' "$TIER_LUNA"; fi
} > "$CONF.tmp"
mv "$CONF.tmp" "$CONF"
printf '    saved settings to %s\n' "$CONF"

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

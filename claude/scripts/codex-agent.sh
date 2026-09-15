#!/bin/bash
# codex-agent.sh version: 2.7
#
# ^ THE wrapper version, and the only line the weekly drift lint reads. Keep it
# on line 2, keep the exact `codex-agent.sh version: N.N` form, and bump it in
# the same commit that changes behaviour.
#
# Why this line exists (added 2026-08-23, lint finding H6). The 2026-08-20
# maintenance run added a check comparing each machine's installed wrapper
# against "the header version in system/codex-agent-master.sh". No such header
# existed. The first version-shaped string in this file was the `(v2.4)` on the
# next line - a SUB-COMPONENT version for the startup sanitiser, not the
# wrapper - so anything reading the header mechanically got 2.4 for a v2.6
# wrapper and would have reported drift on every machine that was actually
# current, or none at all. A check that cannot fail is worse than no check.
# Windows installs are PORTS, so the comparison is this recorded version
# against the version recorded for that machine in memory/machines.md, never a
# byte comparison.
#
# NOTE: the sub-component tags further down (`startup sanitiser (v2.4)`, and
# the `v2.2`/`v2.3`/`v2.5` markers in the change notes) version individual
# pieces and their history. They are not the wrapper version. Only this line is.
#
# --- startup sanitiser (v2.4) ----------------------------------------------
# MUST stay first. bash runs $BASH_ENV and imports exported functions
# (BASH_FUNC_*) BEFORE line 1 of this script, so unsetting them below is far
# too late on its own: a caller can execute arbitrary code, or replace stat,
# before any hardening takes effect - silently falsifying every containment
# decision. SCOPE, precisely: this does NOT stop that code running. It runs
# once, in the outer shell, and no script can prevent that. What this does is
# QUARANTINE it, so nothing it changed survives into the process that makes
# the security decisions. The shebang is absolute so a caller PATH cannot
# choose the interpreter either.
#
# Two earlier attempts at this were wrong, both caught by review:
#   v2.3  skipped the re-exec whenever CODEX_AGENT_SANITISED was set, so a
#         caller could set it alongside a hostile BASH_ENV and walk past.
#   v2.3.1 replaced that with a "does the environment look clean?" test. That
#         test was a BLACKLIST of a few dangerous names plus a PATH compare,
#         so with PATH already pinned any unlisted variable survived and the
#         re-exec was skipped entirely - refuting the "only these survive"
#         claim right above it. It also kept the sentinel in the ENVIRONMENT,
#         which every descendant then inherited: a nested call with a
#         different PATH hit the fail-closed branch and died at exit 2.
#
# v2.5: v2.4 claimed the re-exec was "UNCONDITIONAL". It was not - it was
# skipped whenever argv[1] was the marker, and the allow-rule puts NO
# restriction on arguments, so a caller could pass the marker and skip it just
# as round 2's caller could set an environment variable and skip it. The bug
# was moved, not fixed. Both round-4 passes said so independently.
#
# So the marker no longer decides anything. VERIFICATION decides: if the
# environment is provably clean (allowlist + no shell functions at all) we
# proceed, no matter who claims what. If it is not clean we re-exec - unless
# we already did, in which case we refuse. The marker exists only to break
# that recursion, and its only possible effect is to turn a second failure
# into a refusal. Forging it can never buy a bypass, because a forged marker
# with a dirty environment simply fails the same verification.
# --- verification: this, not the marker, is what decides -------------------
# Nothing here refuses on its own. It only establishes whether the environment
# is provably clean; the decision (proceed / re-exec / refuse) is made once,
# below. v2.4 put hard refusals in here by accident, which fired on the very
# first pass and made the wrapper refuse every ordinary invocation.
_codex_unexpected=""
for _n in $(/usr/bin/env | cut -d= -f1); do
  case "$_n" in
    HOME|LANG|LC_ALL|OLDPWD|PATH|PWD|SHLVL|TERM|_) ;;
    *) _codex_unexpected="$_codex_unexpected $_n" ;;
  esac
done
# ANY function is disqualifying - not just exported ones. v2.4 used
# `declare -Fx`, reasoning only about exported BASH_FUNC_* entries. A hostile
# $BASH_ENV can define a NON-exported function and then unset BASH_ENV itself,
# so the variable scan above sees nothing and `-Fx` sees nothing, while the
# function still shadows the real binary (functions beat PATH). Every guard
# decision runs `stat`, so that is a total containment bypass. Both round-4
# passes found it. In a genuine run no function exists yet (die/need come
# later), so treating any function as dirty is safe.
_codex_clean=1
[ -z "$_codex_unexpected" ] || _codex_clean=0
[ -z "$(declare -F 2>/dev/null)" ] || _codex_clean=0

if [ "$_codex_clean" -ne 1 ]; then
  if [ "${1:-}" = "--__codex-agent-sanitised" ]; then
    # Already re-executed once and still not clean: refuse rather than loop.
    printf 'codex-agent: environment still unsafe after sanitising (%s); refusing
' "${_codex_unexpected:-shell functions present}" >&2
    exit 2
  fi
  exec /usr/bin/env -i \
  PATH=/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin \
  HOME="${HOME:-}" TERM="${TERM:-dumb}" LANG="${LANG:-}" LC_ALL="${LC_ALL:-}" \
  /bin/bash --noprofile --norc "$0" --__codex-agent-sanitised "$@"
fi
# Clean. Strip the marker if present - by this point it is inert.
[ "${1:-}" != "--__codex-agent-sanitised" ] || shift
unset _codex_unexpected _codex_clean _n
set -euo pipefail
unset CDPATH BASH_ENV ENV
PATH=/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin
export PATH
unset CODEX_HOME
# codex-agent-master.sh v2.7 (2026-09-15) — installed copy: ~/.claude/scripts/codex-agent.sh
# v2.7 (2026-09-15): --model allowlist adds gpt-6-astra (it was already the
#   config.toml default on one machine, so unflagged runs used it while an
#   explicit --model gpt-6-astra was refused). Effort help now says that not
#   every model accepts every level (gpt-5.6-sol rejects minimal - probed
#   2026-09-15, API unsupported_value). No other behaviour change.
#
#@help-start
# codex-agent.sh — run one GPT agent (OpenAI Codex CLI) non-interactively and
# capture its answer to a file.
#
# WHY THIS EXISTS AS A SCRIPT, NOT A RAW `codex exec` CALL:
# this is the only codex entry point allowlisted in ~/.claude/settings.json.
# Claude Code permission rules are prefix matches, so allowlisting `codex exec:*`
# would also silently allow --dangerously-bypass-approvals-and-sandbox. Routing
# through here makes those escape hatches unreachable by construction: the
# sandbox mode is validated against a fixed list below. v2.3 scope note: this
# holds only because the startup sanitiser above re-execs into a clean
# interpreter FIRST. Before v2.3 the claim was false - $BASH_ENV and imported
# functions ran ahead of every check here, which both adversarial passes on
# 2026-08-19 demonstrated. Add capability here,
# deliberately — never by widening the allowlist.
#
# PATH (v2.2 hardening): the very first thing this script does, right after
# `set -euo pipefail` and `unset CDPATH BASH_ENV ENV`, is pin its own PATH to
# /usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin. Without
# that, whatever PATH the caller's environment happens to carry decides
# which `id`, `stat`, `sed`, `date`, etc. this script runs - a caller (or a
# compromised earlier stage of a pipeline) that prepends a writable
# directory could shadow any of them. /opt/homebrew/bin and /usr/local/bin
# are kept (Homebrew utilities, and codex itself, live there) but nothing
# caller-supplied is trusted ahead of the system dirs. The two most
# structurally critical calls - `id` (decides REAL_HOME, and every
# account-home path depends on it) and `env` (the one call that actually
# launches codex) - are additionally hardened to their absolute /usr/bin
# path, since even this fixed PATH still includes two user-writable dirs.
#
# Usage:
#   codex-agent.sh --label NAME --outdir DIR [options] --prompt-file FILE
#   codex-agent.sh --label NAME --outdir DIR [options] -- "prompt text"
#   codex-agent.sh --resume SESSION_ID --label NAME --outdir DIR -- "follow-up"
#
# Options:
#   --label NAME        short slug for output filenames (default: agent)
#   --outdir DIR        where to write answer/log (required)
#   --cd DIR             agent's working root (default: current directory)
#   --sandbox MODE      read-only | workspace-write   (default: read-only)
#                       (v2.6: workspace-write additionally requires --cd to
#                        resolve at or inside one of this machine's fixed
#                        write parents - see WRITE_PARENTS in the script.
#                        Anything else is refused. This is an allowlist and
#                        fails closed: a false refusal is visible immediately,
#                        where the old protected-directory denylist failed
#                        open on every enumeration gap.)
#   --model NAME        override model (default: from account's config.toml)
#   --effort LEVEL      reasoning effort: none | minimal | low | medium | high |
#                       xhigh | max   (default: from account's config.toml;
#                        not every model accepts every level - gpt-5.6-sol
#                        rejects minimal - and the list is not exhaustive:
#                        `ultra` exists for some models but is not yet
#                        allowlisted here; probe before adding it)
#   --prompt-file FILE  read prompt from FILE instead of the trailing argument
#   --resume ID         continue a previous session instead of starting fresh
#                       (resume reads CURRENT config, not the session's - so
#                        --sandbox is re-enforced via -c sandbox_mode, default
#                        read-only; --cd is refused in this mode; resume stays
#                        pinned to the account that owns the session — see
#                        ACCOUNTS below, no failover on resume)
#   --schema FILE       JSON Schema file constraining the final response shape
#
# Writes:  $OUTDIR/$LABEL.answer.md   final answer only (what you want to read)
#          $OUTDIR/$LABEL.log         full transcript incl. session id
#          $OUTDIR/$LABEL.session     session id, for --resume
#          $OUTDIR/$LABEL.account     the account home that launched codex for
#                                     the last attempt. BEST-EFFORT (v2.6 doc
#                                     fix - this was previously documented as
#                                     guaranteed, but the write has always
#                                     been allowed to fail without discarding
#                                     the run): attempted whenever a codex
#                                     process actually ran, including a
#                                     failed/exhausted final attempt; absent
#                                     when no account was ever eligible to
#                                     try. The authoritative record is the
#                                     LOG's first line plus the stderr
#                                     `account:` line, which are always
#                                     written.
# Prints the final answer to stdout. Exit code: see "Exit codes" below.
#
# Exit codes
#   0   success - answer captured
#   1   codex run failed OR GPT is unavailable this session (every account
#       parked/exhausted on a fresh run, or --resume's owning account is
#       parked/exhausted - resume never fails over to another account).
#       These two cases deliberately share exit code 1: a plain codex
#       failure unrelated to usage limits (e.g. a bad --output-schema) can
#       itself exit 1, so the exit code alone cannot distinguish "codex
#       failed" from "GPT unavailable this session". If the caller needs to
#       tell them apart, read stderr: the fresh-run all-accounts path prints
#       the literal line "codex-agent: all accounts exhausted or parked:",
#       and the --resume path prints its own "... is parked until ..." /
#       "... exhausted (parked until ...)" lines naming the owning account -
#       don't infer either condition from the exit code by itself.
#   2   wrapper-level / caller error: bad arguments, validation failure, or
#       no Codex account is logged in at all (a setup problem, not a quota
#       one)
#   *   any other value is codex's own exit status, passed through unchanged
#       for a run that reached codex but failed for a reason other than the
#       usage-limit condition above
#
# ACCOUNTS (same-vendor account failover, added 2026-08-19)
# -----------------------------------------------------------------------
# Two fixed, same-vendor ChatGPT-plan account homes are tried in order:
# REAL_HOME/.codex, then REAL_HOME/.codex-b, where REAL_HOME comes from the
# password database for the real invoking user, not from the caller's $HOME
# env var (v2.1 hardening — see the derivation just below the option-parsing
# loop; v2.2 moved it there, after -h/--help handling, so --help works even
# when this derivation itself would die on a bad HOME or an unresolvable
# user). This list is NOT env-configurable on purpose — an env override here
# would reopen the same hole the 2026-08-13 hardening closed for `-c`. A
# home that doesn't exist or has no auth.json is skipped as "not logged in".
#
# On a fresh run, if an account's run log matches the Codex usage-limit
# error, that account is "parked" (a until-epoch is written to
# $ACCOUNT_HOME/.claude-wrapper-parked-until, best-effort parsed from the
# CLI's own "try again at ..." text, else 30 minutes) and the next account
# in the list is tried. A parked account is skipped without a codex call
# until its park time passes. If every account is unavailable, the wrapper
# reports each one's park file and until-time so it can be cleared with
# `rm $ACCOUNT_HOME/.claude-wrapper-parked-until` if the park looks wrong,
# then exits non-zero — GPT is unavailable for the session, nothing is
# silently substituted.
#
# --resume is pinned: a session belongs to exactly one account, found by
# searching each account's sessions/ tree for the session id, and that run
# never fails over — if that account is parked or exhausted, the wrapper
# says so and exits non-zero rather than continuing the session elsewhere.

die() { printf 'codex-agent: %s\n' "$1" >&2; exit 2; }

LABEL=agent
OUTDIR=""
WORKDIR="$PWD"
CD_SET=0
SANDBOX=read-only
MODEL=""
EFFORT=""
PROMPT_FILE=""
RESUME=""
SCHEMA=""
PROMPT=""

need() { [ "$2" -ge 2 ] || die "$1 requires a value"; }

# -h/--help is handled in this same pass, ahead of any REAL_HOME/HOME setup
# (v2.2: moved here from after it) - help must work even when that setup
# would itself die (bad HOME, id failing, no such user), since a caller
# asking for --help is not making an account-related request at all.
while [ $# -gt 0 ]; do
  case "$1" in
    --label)       need "$1" $#; LABEL="$2";       shift 2 ;;
    --outdir)      need "$1" $#; OUTDIR="$2";      shift 2 ;;
    --cd)          need "$1" $#; WORKDIR="$2"; CD_SET=1; shift 2 ;;
    --sandbox)     need "$1" $#; SANDBOX="$2";     shift 2 ;;
    --model)       need "$1" $#; MODEL="$2";       shift 2 ;;
    --effort)      need "$1" $#; EFFORT="$2";      shift 2 ;;
    --prompt-file) need "$1" $#; PROMPT_FILE="$2"; shift 2 ;;
    --resume)      need "$1" $#; RESUME="$2";      shift 2 ;;
    --schema)      need "$1" $#; SCHEMA="$2";      shift 2 ;;
    --)            shift; PROMPT="${1:-}"; shift || true ;;
    -h|--help)
      # Print the main header block and stop before die()'s definition.
      # v2.4: anchored on the dedicated "#@help-start" marker. v2.3 anchored
      # on "^# codex-agent", which ALSO matched the version banner above the
      # real title, so --help still leaked the platform preamble (caught in
      # cross-vendor review 2026-08-19). A marker that exists only for this
      # purpose cannot be matched by accident.
      awk '
        !started {
          if ($0 ~ /^#@help-start/) { started=1; next } else { next }
        }
        /^die\(\) \{/ { exit }
        { print }
      ' "$0"
      exit 0 ;;
    *)             die "unknown argument: $1" ;;
  esac
done

# Fixed ordered account list. Deliberately not overridable via environment
# or flag — see ACCOUNTS above. Built from the REAL home (password
# database), not the caller's $HOME - hardening 2026-08-19 v2.1: a caller
# who sets HOME=/tmp/attacker before invoking the wrapper would otherwise
# silently redirect every account-home path below to attacker-controlled
# state (a fake auth.json, a fake sessions/ tree, a config.toml with a
# hostile notify hook). `/usr/bin/id -un` output is validated against a
# safe username charset before it reaches `eval`, so a hostile value there
# can't become shell code. v2.2: `id` is called by its absolute path (the
# fixed PATH above already excludes caller-supplied dirs, but this specific
# call is structurally critical enough - it decides REAL_HOME, and every
# account-home path below depends on it - to also not trust /opt/homebrew
# or /usr/local, both user-writable).
_real_user="$(/usr/bin/id -un)" || die "cannot determine current user (id -un failed)"
case "$_real_user" in
  ''|*[!A-Za-z0-9._-]*) die "unexpected username from id -un: '$_real_user'" ;;
esac
# v2.2: first character must itself be alphanumeric. The charset check above
# alone would accept a leading '.', '_' or '-'; a leading '-' in particular
# means "~$_real_user" below can expand as a shell option rather than a
# username (e.g. a user actually named "-" would make `eval echo "~-"`
# expand to $OLDPWD, not a home directory).
case "$_real_user" in
  [A-Za-z0-9]*) ;;
  *) die "unexpected username from id -un: '$_real_user' (must start with a letter or digit)" ;;
esac
REAL_HOME="$(eval echo "~$_real_user")" || die "cannot resolve home directory for $_real_user"
case "$REAL_HOME" in /*) ;; *) die "resolved home is not an absolute path (got '$REAL_HOME')" ;; esac
[ -d "$REAL_HOME" ] || die "resolved home is not a directory: $REAL_HOME"
[ -n "${HOME:-}" ] || die "HOME is not set"
[ -d "$HOME" ] || die "HOME is not a directory: $HOME"
# v2.2: compared by device:inode, not string. macOS firmlinks give the same
# directory two valid spellings (/Users/foo vs /System/Volumes/Data/Users/foo)
# - a string compare would false-refuse a perfectly legitimate HOME spelled
# the other way. Still dies on any genuine mismatch, exactly as before.
_home_id="$(stat -f '%d:%i' "$HOME" 2>/dev/null)" || die "cannot stat HOME: $HOME"
_real_home_id="$(stat -f '%d:%i' "$REAL_HOME" 2>/dev/null)" || die "cannot stat resolved home: $REAL_HOME"
[ "$_home_id" = "$_real_home_id" ] || die "HOME ($HOME) does not match the account's home ($REAL_HOME); refusing"
ACCOUNT_HOMES=("$REAL_HOME/.codex" "$REAL_HOME/.codex-b")
# v2.6: fixed allowlist of parents a workspace-write root must resolve at or
# inside. INSTALL-TIME SETTING: edit this line to the parent folder(s) where
# your repos live (the kit's install.sh sets it for you). Deliberately not
# env- or flag-configurable, same reasoning as ACCOUNT_HOMES.
WRITE_PARENTS=("$REAL_HOME/projects")

# --- validation ------------------------------------------------------------
case "$SANDBOX" in
  read-only|workspace-write) ;;
  *) die "sandbox must be read-only or workspace-write (got '$SANDBOX'); full-access is deliberately not available here" ;;
esac

# Checked here rather than at the API, which only rejects a bad value after a
# full round trip. Enum per the Responses API's own error message.
case "$EFFORT" in
  ""|none|minimal|low|medium|high|xhigh|max) ;;
  *) die "effort must be one of: none minimal low medium high xhigh max (got '$EFFORT')" ;;
esac

# Fixed allowlist of literal slugs (the three 5.6 slugs probed end-to-end
# 2026-08-13). gpt-6-astra (v2.7) is a real slug that the account's desktop
# app serves, but the explicit --model probe through THIS wrapper on
# 2026-09-15 at codex-cli 0.149.1 was refused by the API - "requires a newer
# version of Codex" - so it stays unusable here until the CLI is upgraded and
# re-probed. Probe any new slug before adding it: a non-existent one fails at
# the API, not here.
case "$MODEL" in
  ""|gpt-5.6-sol|gpt-5.6-terra|gpt-5.6-luna|gpt-6-astra) ;;
  *) die "model must be one of: gpt-5.6-sol gpt-5.6-terra gpt-5.6-luna gpt-6-astra (got '$MODEL')" ;;
esac

# Shape check keeps the resume id out of option position: must start
# alphanumeric, then only [A-Za-z0-9._-] (the CLI accepts thread names, so
# UUID-only would be false precision).
if [ -n "$RESUME" ]; then
  case "$RESUME" in
    [A-Za-z0-9]*) ;;
    *) die "--resume id must start with a letter or digit (got '$RESUME')" ;;
  esac
  case "$RESUME" in
    *[!A-Za-z0-9._-]*) die "--resume id may contain only letters, digits, . _ -" ;;
  esac
  [ "$CD_SET" -eq 0 ] || die "--cd is not supported with --resume (resume keeps its own working root)"
  # v2.3: resume takes no --cd, so WORKDIR stayed $PWD - but the resumed
  # session keeps its OWN root, which this wrapper cannot see. The guard was
  # therefore evaluating the caller's current directory, not the directory the
  # agent would actually write to: a read-only session rooted somewhere
  # sensitive could be resumed with write access from a harmless cwd and pass
  # (cross-vendor review 2026-08-19). An unevaluable guard is not a passed
  # guard, so write access on resume is refused outright.
  [ "$SANDBOX" != "workspace-write" ] || die "--sandbox workspace-write is not supported with --resume (the session's real working root cannot be verified here); start a fresh run instead"
fi

[ -n "$OUTDIR" ] || die "--outdir is required"
case "$OUTDIR" in -*) die "--outdir may not start with a dash (got '$OUTDIR')" ;; esac
# A dash-leading directory name is an option to everything downstream; refuse
# it, then hand codex the resolved path so a retargeted symlink cannot move
# the workspace between check and launch. Unresolvable root fails closed.
# CDPATH is neutralised so the checked directory and the entered one match.
# /bin/pwd -P (not the builtin) also collapses macOS firmlink spellings.
case "$WORKDIR" in -*) die "--cd may not start with a dash (got '$WORKDIR')" ;; esac
[ -d "$WORKDIR" ] || die "--cd directory does not exist: $WORKDIR"
WORKDIR="$(CDPATH= cd -- "$WORKDIR" 2>/dev/null && /bin/pwd -P)" || die "cannot resolve --cd directory"
# v2.3: a newline in a resolved path would split every later comparison.
# Counted with wc rather than matched with a glob: a $(printf) newline
# pattern is stripped of its own trailing newline by command substitution,
# leaving the EMPTY pattern - which matches every path and refuses all of
# them. (That exact bug was written here first and caught by testing.)
[ "$(printf '%s' "$WORKDIR" | wc -l)" -eq 0 ] || die "--cd resolves to a path containing a newline; refusing"
[ -n "$WORKDIR" ] || die "cannot resolve --cd directory"
# --- containment (v2.6 restructure: allowlist, not denylist) ----------------
# Four consecutive review rounds each found real fail-OPEN defects in the old
# denylist here ("refuse a root at/above/inside these protected dirs"): a
# denylist is an enumeration, and every enumeration gap is a silent bypass -
# round 4's TEMP/TMP writable-root finding was exactly such a gap. Inverted:
# a workspace-write root must now resolve AT or INSIDE one of the fixed
# WRITE_PARENTS above. ~/.claude (this wrapper + the allowlist that makes it
# the only entry point), the codex
# binary and both account homes are out of reach BY CONSTRUCTION - none of
# them lives under a write parent - not by enumeration. A bug here fails
# closed: a false refusal someone notices immediately, instead of a silent
# grant a reviewer finds a round later.
#
# The account homes keep a small denylist walk of their own in EVERY sandbox
# mode: read-only cannot WRITE, but it can READ, and the account homes hold
# auth.json - live ChatGPT credentials (v2.3 finding). Read-only runs on
# arbitrary paths are legitimate (reviewing anything on disk), so read-only
# cannot be allowlisted; two fixed directories is the entire read surface
# worth guarding, and the walk fails closed (any stat failure refuses).
#
# Identity is compared by device:inode on resolved paths, never by string -
# macOS firmlinks (and, on the win port, /c/... vs C:/... spellings) give one
# directory several names, so string prefixes lie. Both sides go through
# `cd && /bin/pwd -P` first.
_root_id="$(stat -f '%d:%i' "$WORKDIR")" || die "cannot stat --cd directory: $WORKDIR"

# Account homes: refuse a root that IS, CONTAINS, or is INSIDE either one, in
# every sandbox mode.
for _g in "${ACCOUNT_HOMES[@]}"; do
  if [ ! -d "$_g" ]; then continue; fi
  # Resolve the guard like the root: a symlinked guard (dotfiles repo) would
  # otherwise carry the symlink's own inode and the guard would never bind.
  _g="$(CDPATH= cd -- "$_g" 2>/dev/null && /bin/pwd -P)" || die "cannot resolve account home"
  _gid="$(stat -f '%d:%i' "$_g")" || die "cannot stat $_g"
  # Refuse a root that IS or CONTAINS the account home: compare the root's
  # identity against every ancestor of the account home, walked in both
  # spellings (firmlinks).
  for _start in "$_g" "/System/Volumes/Data${_g}"; do
    if [ ! -d "$_start" ]; then continue; fi
    if [ "$(stat -f '%d:%i' "$_start")" != "$_gid" ]; then continue; fi
    _p="$_start"
    while :; do
      _pid="$(stat -f '%d:%i' "$_p")" || die "cannot stat $_p while checking containment"
      if [ "$_pid" = "$_root_id" ]; then
        die "--cd may not be at or above the account home $_g in any sandbox mode (resolved root: $WORKDIR)"
      fi
      _np="$(dirname -- "$_p")"
      # Fixed-point stop: "/" alone is not enough - on MSYS dirname // is
      # //, so a UNC root looped forever (cross-vendor review 2026-08-19).
      if [ "$_np" = "$_p" ]; then break; fi
      _p="$_np"
    done
  done
  # Refuse a root INSIDE the account home.
  _p="$WORKDIR"
  while :; do
    _pid="$(stat -f '%d:%i' "$_p")" || die "cannot stat $_p while checking containment"
    if [ "$_pid" = "$_gid" ]; then
      die "--cd may not be inside the account home $_g in any sandbox mode (resolved root: $WORKDIR)"
    fi
    _np="$(dirname -- "$_p")"
    if [ "$_np" = "$_p" ]; then break; fi
    _p="$_np"
  done
done

# Workspace-write: the root must resolve at or inside one write parent.
if [ "$SANDBOX" = "workspace-write" ]; then
  _real_home_chk="$(stat -f '%d:%i' "$REAL_HOME")" || die "cannot stat home while checking write parents"
  _fsroot_chk="$(stat -f '%d:%i' /)" || die "cannot stat / while checking write parents"
  _allowed=0
  for _wp in "${WRITE_PARENTS[@]}"; do
    if [ ! -d "$_wp" ]; then continue; fi
    _wp="$(CDPATH= cd -- "$_wp" 2>/dev/null && /bin/pwd -P)" || die "cannot resolve write parent $_wp"
    _wpid="$(stat -f '%d:%i' "$_wp")" || die "cannot stat write parent $_wp"
    # A parent that resolves to the home directory or the filesystem root
    # would allowlist everything. That is a misconfiguration (or a symlink
    # swap of the parent itself), and it becomes a hard error here instead of
    # a silent grant.
    [ "$_wpid" != "$_real_home_chk" ] || die "write parent $_wp resolves to the home directory; refusing"
    [ "$_wpid" != "$_fsroot_chk" ] || die "write parent $_wp resolves to the filesystem root; refusing"
    # v2.6 (round-5 review, MEDIUM 2): also refuse a parent that resolves to a
    # protected asset itself. The HOME/root checks above do NOT cover this -
    # a parent symlinked directly onto ~/.claude resolves
    # to neither HOME nor /, so without this it would allowlist that asset's
    # whole subtree. Account homes need no entry here: the account-home walk
    # above already refuses any WORKDIR at/above/inside them regardless of the
    # write-parent list. Defence-in-depth (it presupposes an attacker who can
    # already replace a parent under $HOME with a link), and strictly
    # fail-closed - it only ever adds refusals.
    for _prot in "$REAL_HOME/.claude"; do
      [ -d "$_prot" ] || continue
      _protr="$(CDPATH= cd -- "$_prot" 2>/dev/null && /bin/pwd -P)" || continue
      _protid="$(stat -f '%d:%i' "$_protr")" || continue
      [ "$_wpid" != "$_protid" ] || die "write parent $_wp resolves to a protected asset ($_prot); refusing"
    done
    # At or inside: walk the resolved root's ancestors (itself included)
    # looking for the parent's identity. Any stat failure refuses (fail
    # closed); note this is what still refuses a UNC root - //server is not
    # a stattable object - a recorded, accepted limitation.
    _p="$WORKDIR"
    while :; do
      _pid="$(stat -f '%d:%i' "$_p")" || die "cannot stat $_p while checking write-parent containment"
      if [ "$_pid" = "$_wpid" ]; then _allowed=1; break; fi
      _np="$(dirname -- "$_p")"
      if [ "$_np" = "$_p" ]; then break; fi
      _p="$_np"
    done
    if [ "$_allowed" -eq 1 ]; then break; fi
  done
  [ "$_allowed" -eq 1 ] || die "workspace-write requires --cd at or inside one of: ${WRITE_PARENTS[*]} (resolved root: $WORKDIR)"
fi
case "$LABEL" in
  ""|.|..) die "--label must be a plain non-empty slug (letters, digits, . _ -)" ;;
  *[!A-Za-z0-9._-]*) die "--label must be a plain slug (letters, digits, . _ -)" ;;
esac

if [ -n "$PROMPT_FILE" ]; then
  [ -f "$PROMPT_FILE" ] || die "prompt file not found: $PROMPT_FILE"
  PROMPT="$(cat "$PROMPT_FILE")"
fi
[ -n "$PROMPT" ] || die "no prompt given (use --prompt-file FILE or -- 'text')"
case "$SCHEMA" in -*) die "--schema path may not start with a dash (got '$SCHEMA')" ;; esac
[ -z "$SCHEMA" ] || [ -f "$SCHEMA" ] || die "schema file not found: $SCHEMA"

# Trusted-roots check (the owner's ruling 2026-08-13, ported from main PC): refuse
# a codex that resolves anywhere unexpected. HONEST SCOPE, and a deliberate
# divergence from the win port flagged in the 2026-08-19 round-5 cross-vendor
# review: this resolves codex via PATH (`command -v`) and trusts two fixed
# Homebrew dirs, whereas the win port ignores PATH entirely and takes only the
# Codex app's bundled binary. PATH here is already pinned by this script (see
# the PATH line up top) and the startup sanitiser re-execs into a clean
# environment first, so a CALLER cannot prepend a writable dir to steer
# `command -v`. The residual, stated plainly: /opt/homebrew/bin and
# /usr/local/bin are user-writable on a standard Homebrew install, so a codex
# PLANTED in one of them by something already able to write there would be
# trusted. That is the same "attacker who can already write our own trust
# anchors" case the wrapper does not defend against; it is change-detection
# against a codex arriving by ordinary means, not a containment control.
# Tightening this to the win port's app-dir-only model is a candidate for the
# next Mac touch (owner to confirm the Homebrew codex location at that time).
CODEX_BIN="$(command -v codex)" || die "codex CLI not on PATH"
case "$CODEX_BIN" in
  /opt/homebrew/bin/codex|/usr/local/bin/codex) ;;
  *) die "codex resolved to an untrusted location: $CODEX_BIN (trusted: /opt/homebrew/bin, /usr/local/bin)" ;;
esac

# --- account-failover helpers -----------------------------------------------
# Anchored to the CLI's own diagnostic line, and only ever scanned in the
# tail of the log - the log also contains the echoed prompt and the model's
# own answer, and an earlier unanchored whole-log grep parked an account for
# real (2026-08-19) because a review prompt merely quoted this phrase, which
# threw away a good answer along with it. Detection also requires codex's
# own exit status to be 1, the CLI's signal for this condition.
USAGE_LIMIT_ANCHOR_RE="^ERROR: You've hit your usage limit"

# v2.2 (round-2 review, BLOCKER): the anchored-tail check above still isn't
# enough on its own. Codex echoes the caller's own prompt back into the same
# log stream at column 0, so a prompt whose LAST line is a forged
# "ERROR: You've hit your usage limit ... try again at <date>." string, run
# alongside any unrelated exit-1 failure (a bad --output-schema, a codex bug,
# anything), would satisfy "status==1 and last-5-lines match" without codex
# ever having hit a real limit - and parks a good account for up to 8 days
# on the strength of text the caller itself supplied. Detection now requires
# ALL of:
#   (a) codex's own exit status is 1;
#   (b) --output-last-message ($ANSWER) is empty or absent - a genuine
#       usage-limit failure never produces an answer; a forged-line attack
#       riding on some other exit-1 failure typically won't either, but if
#       it somehow did, (b) alone would already be enough to refuse - see
#       the "genuine ERROR but non-empty answer" case below;
#   (c) the LAST anchored match within the tail of the log (still capped,
#       not the whole log - same reasoning as before);
#   (d) that matched line is NOT verbatim a line of $PROMPT - the one check
#       that specifically defeats the echoed-prompt attack, since codex's
#       own genuine error text is never something the caller typed.
# On a match, the matched line itself is echoed to stdout so the caller can
# hand that EXACT line to park_account() for date parsing, instead of
# park_account re-deriving it from the log a second time (two independent
# extractions of "the error line" could in principle disagree; passing the
# one already-verified line removes that possibility entirely).
usage_limit_hit() {
  local status="$1" log="$2" answer="$3"
  local line
  [ "$status" -eq 1 ] || return 1
  # (b) A genuine usage-limit failure never writes --output-last-message.
  # If the answer file has real content, treat this as NOT a usage-limit
  # condition, full stop - even if an anchored ERROR line is also present.
  # This is the deliberately safe direction: the cost of under-detecting a
  # real usage-limit hit is one wasted retry (codex gets tried again and
  # fails the same way, discovered on the next call); the cost of
  # over-detecting is discarding a paid-for, already-good answer and
  # parking a working account for up to 8 days. Given that asymmetry, an
  # inconsistent signal (error text alongside a real answer) should never
  # win over "there's a real answer sitting right here".
  if [ -s "$answer" ] && [ -n "$(tr -d '[:space:]' < "$answer" 2>/dev/null || true)" ]; then
    return 1
  fi
  # (c) last anchored match within the tail of the log.
  line="$(tail -5 "$log" 2>/dev/null | grep -E "$USAGE_LIMIT_ANCHOR_RE" | tail -1 || true)"
  [ -n "$line" ] || return 1
  # (d) refuse if that exact line is one the caller's own prompt contains -
  # the echoed-prompt forgery this whole rewrite exists to defeat.
  if printf '%s\n' "$PROMPT" | grep -qxF -- "$line"; then
    return 1
  fi
  printf '%s\n' "$line"
  return 0
}

# epoch, 0 if not parked / file missing / unreadable / non-numeric / a
# symlink (a planted symlink here is refused rather than followed - treated
# as "not parked", never as an arbitrary-file read).
# v2.6: anything present at the path that is NOT a regular file (a directory,
# a symlink) is still treated as "not parked", but now WARNS - previously a
# planted directory made parking silently succeed-and-do-nothing, so an
# exhausted account was retried every call with no visible signal (Sol's
# round-4 MEDIUM). The write side (write_line_safe below) now clears such an
# object; this warning covers the read side seeing one first.
account_parked_until() {
  local f="$1/.claude-wrapper-parked-until" v
  if [ -f "$f" ] && [ ! -L "$f" ]; then
    v="$(cat "$f" 2>/dev/null || true)"
    case "$v" in
      ''|*[!0-9]*) printf '0\n' ;;
      *) printf '%s\n' "$v" ;;
    esac
  else
    if [ -e "$f" ] || [ -L "$f" ]; then
      printf 'codex-agent: warning: unexpected object at %s (not a regular file); treating account as not parked\n' "$f" >&2
    fi
    printf '0\n'
  fi
}

# Best-effort epoch -> human string; BSD date first (macOS), then GNU.
human_date() {
  date -r "$1" 2>/dev/null || date -d "@$1" 2>/dev/null || printf '%s (epoch)' "$1"
}

# Symlink- and directory-safe single-line write (v2.6). One pattern for the
# park file AND the session/.account bookkeeping files, which shared the same
# time-of-check/time-of-use shape but previously used three different write
# idioms - Sol's round-4 HIGH (non-atomic session/.account writes) and MEDIUM
# (a DIRECTORY planted at the park-file path: `rm -f` failed quietly on it,
# `mv` then moved the temp file INSIDE the directory and reported success, so
# parking silently became a no-op and the exhausted account was retried every
# run). `rm -rf` clears a directory or symlink without following it; `set -C`
# (noclobber) refuses to write through anything re-planted in the race window
# between the rm and the write; the post-mv check catches an mv that nested
# into a re-planted directory. Any failure returns non-zero with nothing
# half-written at the target, never a false success.
write_line_safe() {
  local path="$1" content="$2"
  rm -rf -- "$path" "$path.tmp.$$" || return 1
  ( set -C; umask 077; printf '%s\n' "$content" > "$path.tmp.$$" ) || { rm -f -- "$path.tmp.$$"; return 1; }
  mv -f -- "$path.tmp.$$" "$path" || return 1
  [ -f "$path" ] && [ ! -L "$path" ]
}

# Parse the CLI's "... or try again at Aug 23rd, 2026 12:30 AM." tail out of
# the ONE matched line usage_limit_hit() already verified (v2.2 - no longer
# re-derives it from the whole log; that second, independent extraction is
# gone entirely, so there's nothing left to disagree with what
# usage_limit_hit() actually matched). Windows note: the wrapper is bash
# (Git Bash), so `date -j -f` (macOS/BSD) is tried first, then `date -d`
# (GNU, what Git Bash ships) as a portable fallback; if both fail, or the
# parsed time isn't a sane future date, park 30 minutes instead of trusting
# a bad parse.
park_account() {
  local home="$1" line="$2"
  local raw cleaned until_epoch now
  raw="$(printf '%s\n' "$line" | sed -n "s/^ERROR: You've hit your usage limit.*try again at \(.*\)\.\$/\1/p")"
  until_epoch=""
  if [ -n "$raw" ]; then
    # strip an ordinal suffix: "23rd" -> "23"
    cleaned="$(printf '%s' "$raw" | sed -E 's/([0-9]+)(st|nd|rd|th)/\1/')"
    # Shape-validate before it ever reaches `date`: "Aug 23, 2026 12:30 AM".
    # Anything that doesn't match this exact shape (CLI wording change, or a
    # hostile tail) falls through to the 30-minute fallback below instead of
    # being handed to `date`.
    if printf '%s\n' "$cleaned" | grep -qE '^[A-Za-z]{3} [0-9]{1,2}, [0-9]{4} [0-9]{1,2}:[0-9]{2} [AP]M$'; then
      until_epoch="$(date -j -f '%b %d, %Y %I:%M %p' "$cleaned" '+%s' 2>/dev/null || true)"
      if [ -z "$until_epoch" ]; then
        until_epoch="$(date -d "$cleaned" '+%s' 2>/dev/null || true)"
      fi
    fi
  fi
  now="$(date +%s)"
  if [ -z "$until_epoch" ] \
     || ! [ "$until_epoch" -gt "$now" ] 2>/dev/null \
     || [ $(( until_epoch - now )) -gt $(( 8 * 24 * 3600 )) ]; then
    until_epoch=$(( now + 1800 ))
  fi
  write_line_safe "$home/.claude-wrapper-parked-until" "$until_epoch"
}

# 0 = eligible, 1 = parked (adds to PARK_SUMMARY), 2 = not logged in / refused.
account_eligible() {
  local home="$1" until now
  # v2.2: refuse a symlinked account home (or a symlinked auth.json inside an
  # otherwise-real one) outright rather than following it. account homes are
  # meant to be real directories the wrapper itself manages the park-file
  # lifecycle for; a symlink here could point auth.json/config.toml/sessions
  # at attacker-controlled state while `$home` in every message and file
  # path still displays as the trusted-looking real path.
  if [ -L "$home" ]; then
    printf 'codex-agent: account %s: symlinked account home refused, skipping\n' "$home" >&2
    return 2
  fi
  if [ ! -d "$home" ] || [ ! -f "$home/auth.json" ]; then
    printf 'codex-agent: account %s not logged in, skipping\n' "$home" >&2
    return 2
  fi
  if [ -L "$home/auth.json" ]; then
    printf 'codex-agent: account %s: symlinked auth.json refused, skipping\n' "$home" >&2
    return 2
  fi
  until="$(account_parked_until "$home")"
  now="$(date +%s)"
  if [ "$until" -gt "$now" ]; then
    printf 'codex-agent: account %s parked until %s, skipping\n' "$home" "$(human_date "$until")" >&2
    PARK_SUMMARY+=("$home|$until")
    return 1
  fi
  return 0
}

mkdir -p -- "$OUTDIR"
ANSWER="$OUTDIR/$LABEL.answer.md"
LOG="$OUTDIR/$LABEL.log"
SESSION_FILE="$OUTDIR/$LABEL.session"
ACCOUNT_FILE="$OUTDIR/$LABEL.account"
# A planted symlink here would turn a later `>` write into an arbitrary-file
# overwrite; remove any existing paths before writing, and again immediately
# before each write below (a workspace-write attempt on a still-parked
# account could plant something in the window between attempts).
rm -rf -- "$ANSWER" "$LOG" "$SESSION_FILE" "$ACCOUNT_FILE"

# --- build + run one attempt on $CODEX_HOME ---------------------------------
# `exec` and `exec resume` take different flag sets: resume rejects
# --cd/--sandbox/--color, and resume reads CURRENT config, not the session's
# values - so the sandbox is re-enforced via -c sandbox_mode, which resume
# does accept. Options must precede the session id. Every positional sits
# behind `--`: codex parses a leading-dash positional as its own option, so
# without the separator a prompt of "--config=..." reaches codex as a flag,
# past the validated --sandbox.
run_codex_once() {
  rm -rf -- "$ANSWER" "$LOG" "$SESSION_FILE"

  if [ -n "$RESUME" ]; then
    set -- exec resume --skip-git-repo-check --output-last-message "$ANSWER" \
           -c "sandbox_mode=$SANDBOX"
  else
    set -- exec --cd "$WORKDIR" --sandbox "$SANDBOX" --skip-git-repo-check \
                --color never --output-last-message "$ANSWER"
  fi
  # v2.5: codex treats the temp-dir env var AND /tmp as writable roots under
  # workspace-write - its own config exposes exclude_tmpdir_env_var and
  # exclude_slash_tmp precisely to turn that off. That is a write root this
  # wrapper's containment guard never inspects: the guard only ever looked at
  # --cd, so a caller could pass a harmless --cd while pointing TEMP at
  # ~/.claude, an account home and write there anyway.
  # Found by the round-4 cross-vendor pass. Excluded unconditionally - this
  # wrapper never needs the agent writing outside its checked root.
  # v2.6: writable_roots pinned to empty for the same reason - an account
  # config.toml can ADD writable roots, and config.toml lives in the account
  # home, which is an asset this wrapper protects; a `-c` override beats the
  # file, so an edited config cannot quietly widen the write surface for the
  # next run. Same class as the TEMP/TMP fix above: codex's write surface is
  # set here, explicitly and completely, not inherited from mutable config.
  set -- "$@" -c sandbox_workspace_write.exclude_tmpdir_env_var=true \
              -c sandbox_workspace_write.exclude_slash_tmp=true \
              -c 'sandbox_workspace_write.writable_roots=[]'
  [ -z "$MODEL" ]  || set -- "$@" --model "$MODEL"
  [ -z "$SCHEMA" ] || set -- "$@" --output-schema "$SCHEMA"
  # Reasoning effort has no dedicated flag; it's a config override.
  [ -z "$EFFORT" ] || set -- "$@" -c "model_reasoning_effort=$EFFORT"
  if [ -n "$RESUME" ]; then
    set -- "$@" -- "$RESUME" "$PROMPT"
  else
    set -- "$@" -- "$PROMPT"
  fi

  # Provenance line first, so it precedes codex's own header and cannot be
  # mistaken for anything codex printed.
  printf 'account: %s\n' "$CODEX_HOME" > "$LOG"
  # </dev/null stops codex waiting on stdin. CODEX_HOME is passed to codex
  # explicitly via `env`, for exactly this one child process; the wrapper's
  # own process environment never carries CODEX_HOME at all (unset at the
  # top of the script), so an ambient or inherited value can never reach
  # codex except through this one explicit assignment. `env` is called by
  # its absolute /usr/bin path (v2.2) - the fixed PATH above already keeps a
  # caller from shadowing it via a prepended dir, but this is the one line
  # that actually launches codex, so it gets the same absolute-path
  # treatment as `id` above rather than relying on PATH alone.
  RUN_STATUS=0
  /usr/bin/env CODEX_HOME="$CODEX_HOME" "$CODEX_BIN" "$@" </dev/null >>"$LOG" 2>&1 || RUN_STATUS=$?

  # Session id is printed in the header; save it so the caller can --resume.
  # v2.6: written via write_line_safe - a workspace-write agent could have
  # planted a symlink or directory here DURING the run, and the old
  # rm-then-`>` pair left a race window between the two (Sol's round-4 HIGH).
  # Best-effort as before: a bookkeeping failure never discards a billed
  # run's answer.
  _sid="$(sed -n 's/^session id: *//p' "$LOG" 2>/dev/null | head -1 || true)"
  write_line_safe "$SESSION_FILE" "$_sid" || true
}

FINAL_STATUS=""

if [ -n "$RESUME" ]; then
  # A session belongs to exactly one account. Find it by session id under
  # each account's sessions/ tree (rollout files are named
  # rollout-<timestamp>-<session-id>.jsonl). No failover: a session cannot
  # move accounts.
  RESUME_HOME=""
  for _h in "${ACCOUNT_HOMES[@]}"; do
    if [ -d "$_h/sessions" ]; then
      _match="$(find "$_h/sessions" -type f -name "*-$RESUME.jsonl" 2>/dev/null | head -1 || true)"
      if [ -n "$_match" ]; then RESUME_HOME="$_h"; break; fi
    fi
  done
  [ -n "$RESUME_HOME" ] || die "session $RESUME not found under any account (checked: ${ACCOUNT_HOMES[*]})"


  _until="$(account_parked_until "$RESUME_HOME")"
  _now="$(date +%s)"
  if [ "$_until" -gt "$_now" ]; then
    # No codex process runs for this attempt, so no .account is written -
    # and this is a "GPT unavailable" outcome, not a wrapper/argument error,
    # so it exits 1 like the fresh-run all-parked/exhausted path, not 2.
    printf 'codex-agent: account %s (owns session %s) is parked until %s - resume cannot fail over to another account; if this looks wrong: rm %s/.claude-wrapper-parked-until\n' \
      "$RESUME_HOME" "$RESUME" "$(human_date "$_until")" "$RESUME_HOME" >&2
    exit 1
  fi

  # v2.3.1: this MUST stay after the parked check above. account_eligible()
  # also returns non-zero for a parked account, so calling it first made a
  # parked-owner resume die with exit 2 ("caller error") and left the
  # dedicated exit-1 "GPT unavailable" handler above unreachable, losing its
  # rm-the-park-file recovery hint. Ordering is the whole fix.
  # v2.6: return codes are now told apart. A park can land in the window
  # between the parked check above and this call (another process's run
  # finishing on this account) - that is the same "GPT unavailable" outcome
  # as the handler above and exits 1, not a caller-error 2 (the recorded
  # resume exit-code race). Any other refusal is a real setup problem.
  PARK_SUMMARY=()
  _elig=0
  account_eligible "$RESUME_HOME" || _elig=$?
  if [ "$_elig" -eq 1 ]; then
    printf 'codex-agent: account %s (owns session %s) was parked while this run was starting - resume cannot fail over to another account; if this looks wrong: rm %s/.claude-wrapper-parked-until\n' \
      "$RESUME_HOME" "$RESUME" "$RESUME_HOME" >&2
    exit 1
  elif [ "$_elig" -ne 0 ]; then
    die "account $RESUME_HOME (owns session $RESUME) failed the eligibility check; refusing to resume"
  fi

  CODEX_HOME="$RESUME_HOME"
  run_codex_once
  status=$RUN_STATUS
  # A codex process ran for this attempt - record which account, regardless
  # of outcome, so LOG line 1 and .account never disagree. `|| true`: a
  # billed run's answer (already on disk in $ANSWER) must never be discarded
  # just because this bookkeeping write failed. v2.6: via write_line_safe.
  write_line_safe "$ACCOUNT_FILE" "$CODEX_HOME" || true
  if MATCHED_LINE="$(usage_limit_hit "$status" "$LOG" "$ANSWER")"; then
    # v2.2: park_account can itself fail (the safe-write guard) - guarded by
    # `if` so a park-write failure logs a warning and moves on instead of
    # killing the whole script under `set -e`. v2.6: the exhausted message no
    # longer re-reads the park file after a FAILED park, which reported a
    # false "parked until 1970" (epoch 0) and a useless recovery hint.
    if park_account "$CODEX_HOME" "$MATCHED_LINE"; then
      _park_desc="parked until $(human_date "$(account_parked_until "$CODEX_HOME")")"
    else
      printf 'codex-agent: warning: could not write park file for %s, continuing without parking it\n' "$CODEX_HOME" >&2
      _park_desc="park-file write failed, so it may be retried before its real reset time"
    fi
    printf 'codex-agent: account %s exhausted (%s); --resume cannot fail over to another account\n' \
      "$CODEX_HOME" "$_park_desc" >&2
  fi
  printf 'codex-agent: account %s\n' "$CODEX_HOME" >&2
  FINAL_STATUS="$status"
else
  PARK_SUMMARY=()
  for CODEX_HOME in "${ACCOUNT_HOMES[@]}"; do
    account_eligible "$CODEX_HOME" || continue

    run_codex_once
    status=$RUN_STATUS
    # A codex process ran for this attempt - record which account, whether
    # or not it turns out to be exhausted, so LOG line 1 and .account never
    # disagree even for the final, failed attempt. `|| true` - see the
    # comment on the equivalent resume-path lines above. v2.6: via
    # write_line_safe.
    write_line_safe "$ACCOUNT_FILE" "$CODEX_HOME" || true

    if MATCHED_LINE="$(usage_limit_hit "$status" "$LOG" "$ANSWER")"; then
      # v2.2: see the equivalent resume-path comment above - park_account can
      # fail, and must not be allowed to abort the whole fan-out under set -e
      # when it does. v2.6: a failed park records epoch 0 in the summary,
      # which the all-exhausted report below renders honestly ("not parked,
      # will be retried") instead of the false "parked until 1970".
      if ! park_account "$CODEX_HOME" "$MATCHED_LINE"; then
        printf 'codex-agent: warning: could not write park file for %s, continuing without parking it\n' "$CODEX_HOME" >&2
      fi
      PARK_SUMMARY+=("$CODEX_HOME|$(account_parked_until "$CODEX_HOME")")
      printf 'codex-agent: account %s exhausted, trying next\n' "$CODEX_HOME" >&2
      # No explicit cleanup here: run_codex_once() already removes ANSWER/LOG/
      # SESSION_FILE as its first action, so they're cleared before the next
      # account's attempt writes new ones. If this was the LAST account, the
      # loop falls through to "all accounts exhausted" with nothing left to
      # try - deliberately leaving this final attempt's LOG (and .account, now
      # written above) on disk, since it's real diagnostic evidence at
      # exactly the point everything failed.
      continue
    fi

    printf 'codex-agent: account %s\n' "$CODEX_HOME" >&2
    FINAL_STATUS="$status"
    break
  done

  if [ -z "$FINAL_STATUS" ]; then
    if [ "${#PARK_SUMMARY[@]}" -eq 0 ]; then
      die "no logged-in Codex account found (checked: ${ACCOUNT_HOMES[*]})"
    fi
    {
      printf 'codex-agent: all accounts exhausted or parked:\n'
      for _s in "${PARK_SUMMARY[@]}"; do
        _h="${_s%%|*}"; _u="${_s##*|}"
        # v2.6: epoch 0 means this attempt hit the limit but the park-file
        # write failed - say that, rather than "parked until 1970".
        if [ "$_u" -gt 0 ] 2>/dev/null; then
          printf '  %s parked until %s (epoch %s) - clear with: rm %s/.claude-wrapper-parked-until\n' \
            "$_h" "$(human_date "$_u")" "$_u" "$_h"
        else
          printf '  %s exhausted this run but NOT parked (park-file write failed); it will be retried on the next call\n' "$_h"
        fi
      done
    } >&2
    exit 1
  fi
fi

status="$FINAL_STATUS"

if [ -s "$ANSWER" ] && [ -n "$(tr -d '[:space:]' < "$ANSWER")" ]; then
  # Only force status=1 on a read failure here if codex itself reported
  # success (status 0) - don't clobber an already-nonzero codex exit status
  # with a less informative 1.
  cat "$ANSWER" || { [ "$status" -ne 0 ] || status=1; }
else
  printf 'codex-agent: no answer captured (exit %s). Transcript: %s\n' "$status" "$LOG" >&2
  tail -20 "$LOG" >&2
  [ "$status" -ne 0 ] || status=1
fi

exit "$status"

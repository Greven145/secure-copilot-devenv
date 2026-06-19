#!/bin/bash
# preToolUse hook - the only permission mechanism that hard-blocks a tool
# call *before* it runs, deterministically (flags/prompts/settings.json are
# heuristic and can be bypassed). Known gap: not enforced on sub-agents
# spawned via the task tool - don't treat this as a complete boundary.
#
# Checks below are flag/token-aware rather than fixed-substring matches, so
# that reordering or respelling flags (e.g. `rm -fr`, `rm --force --recursive`)
# doesn't trivially slip past the denylist. This is still a heuristic, not a
# full shell parser - it won't catch obfuscation via variable expansion/eval.
set -euo pipefail

INPUT="${1:-}"
CMD="$(jq -r '.toolArgs.command // empty' <<<"$INPUT" 2>/dev/null || true)"

# Double as a redacted audit trail: same call site that can deny is the one
# best positioned to log every call before it executes.
LOG_DIR="${HOME}/.copilot/logs"
mkdir -p "$LOG_DIR"
REDACTED="$(sed -E \
  -e 's/gh[pous]_[A-Za-z0-9]+/[REDACTED-TOKEN]/g' \
  -e 's/(Bearer|--token)[= ][^ ]+/\1 [REDACTED]/g' \
  <<<"$CMD")"
printf '{"ts":"%s","command":"%s"}\n' "$(date -u +%FT%TZ)" "$REDACTED" >> "$LOG_DIR/audit.jsonl"

deny() {
  printf '{"permissionDecision":"deny","permissionDecisionReason":"blocked by .github/hooks/deny-risky.sh: %s"}\n' "$1"
  exit 0
}

# Word-split (not shell-parsed) tokens, used for flag-cluster checks below.
read -ra TOKENS <<<"$CMD"

has_token() {
  local needle="$1" tok
  for tok in "${TOKENS[@]}"; do
    [[ "$tok" == "$needle" ]] && return 0
  done
  return 1
}

# 1. Recursive + force delete, in any flag order/spelling: `-rf`, `-fr`,
#    `-Rf`, `-r -f`, `--recursive --force`, `--recursive -f`, etc.
HAS_RM=0 HAS_RECURSIVE=0 HAS_FORCE=0
for tok in "${TOKENS[@]}"; do
  case "$tok" in
    rm|*/rm) HAS_RM=1 ;;
    --recursive) HAS_RECURSIVE=1 ;;
    --force) HAS_FORCE=1 ;;
    -[a-zA-Z]*)
      flags="${tok#-}"
      [[ "$flags" == *[rR]* ]] && HAS_RECURSIVE=1
      [[ "$flags" == *f* ]] && HAS_FORCE=1
      ;;
  esac
done
if [[ "$HAS_RM" == 1 && "$HAS_RECURSIVE" == 1 && "$HAS_FORCE" == 1 ]]; then
  deny "recursive+force delete (rm with recursive and force flags, any order/spelling)"
fi

# 2. Bulk-delete equivalents to `rm -rf` in other tools/languages.
case "$CMD" in
  *"find "*"-delete"*)
    deny "find ... -delete (bulk delete equivalent to rm -rf)"
    ;;
esac
case "$CMD" in
  *"shutil.rmtree"*|*"os.removedirs"*)
    deny "scripting-language recursive delete (shutil.rmtree/os.removedirs)"
    ;;
esac

# 3. Piping or substituting remote/dynamic content into an interpreter -
#    not just `sh`, but any common shell/scripting interpreter.
case "$CMD" in
  *"| sh"*|*"|sh"*|*"| bash"*|*"|bash"*|*"| zsh"*|*"|zsh"*|*"| dash"*|*"|dash"*| \
  *"| ksh"*|*"|ksh"*|*"| python"*|*"|python"*|*"| python3"*|*"|python3"*| \
  *"| perl"*|*"|perl"*|*"| ruby"*|*"|ruby"*|*"| node"*|*"|node"*)
    deny "piping content into a shell/script interpreter"
    ;;
esac
case "$CMD" in
  *"<(curl"*|*"<(wget"*|*"source <("*|*"source /dev/stdin"*|*'eval "$('*|*'eval $('*)
    deny "process substitution / eval of dynamically fetched content"
    ;;
esac

# 4. git push force, including aliases and the config-based bypass.
if has_token "git" && has_token "push"; then
  for tok in "${TOKENS[@]}"; do
    case "$tok" in
      -f|--force|--force-with-lease|--force-with-lease=*)
        deny "git push --force/-f/--force-with-lease"
        ;;
    esac
  done
fi
case "$CMD" in
  *"push.force"*"true"*|*"push.force=true"*)
    deny "git config push.force true (force-push bypass)"
    ;;
esac

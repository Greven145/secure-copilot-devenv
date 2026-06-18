#!/bin/bash
# preToolUse hook - the only permission mechanism that hard-blocks a tool
# call *before* it runs, deterministically (flags/prompts/settings.json are
# heuristic and can be bypassed). Known gap: not enforced on sub-agents
# spawned via the task tool - don't treat this as a complete boundary.
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

case "$CMD" in
  *"rm -rf"*|*"| sh"*|*"|sh"*|*"git push -f"*|*"git push --force"*)
    echo '{"permissionDecision":"deny","permissionDecisionReason":"blocked by .github/hooks/deny-risky.sh: matches denylist pattern"}'
    ;;
esac

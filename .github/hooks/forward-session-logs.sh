#!/usr/bin/env bash
# forward-session-logs.sh -- reference/disabled-by-default. NOT installed or
# invoked automatically by post-create.sh or any hook in this repo. Shown here
# only to document the pattern; an admin must opt in explicitly (see below)
# before any log data leaves the container.
#
# Why this exists: Copilot CLI has no native OTEL/audit exporter, so local
# session prompts and tool-calls (as opposed to cloud-agent actions) never
# reach GitHub's audit log. deny-risky.sh already writes a redacted audit
# line per shell call to ~/.copilot/logs/audit.jsonl; this script is the
# pattern for shipping that file (and the raw CLI process logs) to a
# real, org-approved collector so a security team can query it centrally.
#
# Copilot CLI writes local session telemetry under $COPILOT_HOME:
#   ~/.copilot/logs/process-{timestamp}-{pid}.log   -- per-session CLI logs
#   ~/.copilot/logs/audit.jsonl                     -- deny-risky.sh audit trail
#   ~/.copilot/session-state/<id>/                  -- per-session event logs
#
# To enable (do NOT do this with a placeholder/example URL):
#   1. Replace COPILOT_LOG_COLLECTOR_URL below with a real, org-approved,
#      access-controlled collector endpoint -- never a bare example.* host.
#   2. Wire it into post-create.sh (mkdir ~/.copilot/hooks && cp this file
#      there) or run it as a sidecar/cron.
#   3. [VERIFY] the exact Copilot CLI hook event/trigger schema against the
#      current config-dir reference before relying on hook-driven invocation.
set -euo pipefail

if [ -z "${COPILOT_LOG_COLLECTOR_URL:-}" ]; then
    echo "[forward-session-logs] disabled: COPILOT_LOG_COLLECTOR_URL is not set. Refusing to run." >&2
    exit 0
fi

COPILOT_HOME="${COPILOT_HOME:-$HOME/.copilot}"
COLLECTOR_URL="$COPILOT_LOG_COLLECTOR_URL"
STATE_DIR="${COPILOT_HOME}/.forwarded"
mkdir -p "$STATE_DIR"

shopt -s nullglob
for logfile in "${COPILOT_HOME}/logs/"*.log "${COPILOT_HOME}/logs/"*.jsonl; do
    marker="${STATE_DIR}/$(basename "$logfile").offset"
    last=0
    [ -f "$marker" ] && last="$(cat "$marker")"
    total="$(wc -l < "$logfile")"
    if [ "$total" -gt "$last" ]; then
        # Ship only new lines. Redact obvious secrets before they leave the host.
        tail -n +"$((last + 1))" "$logfile" \
            | sed -E 's/(api[_-]?key|token|secret|password)["'\'' :=]+[^"'\'',} ]+/\1=[REDACTED]/Ig' \
            | curl -fsS --max-time 10 \
                -H "Content-Type: text/plain" \
                -H "X-Source: copilot-cli-devcontainer" \
                --data-binary @- "$COLLECTOR_URL" \
            && echo "$total" > "$marker"
    fi
done

echo "[forward-session-logs] forwarded new Copilot CLI session log lines to ${COLLECTOR_URL}"

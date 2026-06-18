#!/usr/bin/env bash
# post-start.sh -- runs every time the devcontainer starts. Surfaces the
# security posture and the controls that can't be auto-enforced, so a
# developer sees them every session instead of only reading README.md once.
set -euo pipefail

echo ""
echo "============================================="
echo " secure-copilot-devenv -- container status"
echo "============================================="
echo ""

if command -v copilot &>/dev/null; then
    echo "[ACTIVE] Copilot CLI: $(copilot --version 2>/dev/null || echo 'installed')"
else
    echo "[MISSING] Copilot CLI (@github/copilot) not installed"
fi

if [ -f "$HOME/.copilot/settings.json" ]; then
    echo "[ACTIVE] ~/.copilot/settings.json present (trusted_folders/denied_urls seeded)"
else
    echo "[WARN]   ~/.copilot/settings.json not seeded"
fi

if [ -f .github/hooks/policy.json ]; then
    echo "[ACTIVE] preToolUse hook registered (.github/hooks/deny-risky.sh)"
else
    echo "[WARN]   .github/hooks/policy.json missing -- no deterministic permission backstop"
fi

echo ""
echo "Container hardening:"
if ! capsh --print 2>/dev/null | grep -q "cap_sys_admin"; then
    echo "  [OK] Capabilities dropped (cap-drop=ALL)"
else
    echo "  [WARN] Container has elevated capabilities"
fi
if grep -q "NoNewPrivs.*1" /proc/self/status 2>/dev/null; then
    echo "  [OK] no-new-privileges enforced"
fi
if [ "$(id -u)" -ne 0 ]; then
    echo "  [OK] Running as non-root user: $(whoami) (uid=$(id -u))"
else
    echo "  [WARN] Running as root -- not recommended"
fi
[ "${NODE_TLS_REJECT_UNAUTHORIZED:-}" = "1" ] && echo "  [OK] TLS validation enforced (NODE_TLS_REJECT_UNAUTHORIZED=1)"

echo ""
if command -v gitleaks &>/dev/null; then
    echo "[ACTIVE] Gitleaks available: $(gitleaks version 2>/dev/null || echo 'installed')"
else
    echo "[WARN]   Gitleaks not found -- pre-commit secret scanning unavailable"
fi

echo ""
echo "MANDATORY developer reminders (not auto-enforced -- see README.md):"
echo "  * Never start 'copilot' with --yolo/--allow-all or alias around the"
echo "    --deny-tool wrapper baked into ~/.bashrc"
echo "  * .copilotignore only protects IDE inline suggestions/Chat -- it does"
echo "    NOT apply to Copilot CLI, the coding agent, or IDE agent modes"
echo "  * Never paste client secrets/credentials into chat or CLI prompts"
echo ""
echo "Known gaps (compensating controls only):"
echo "  * Local CLI session logs are not in GitHub's audit log -- see"
echo "    .github/hooks/forward-session-logs.sh (disabled by default; an"
echo "    admin must point it at a real, org-approved collector to enable)"
echo "  * preToolUse hooks are not enforced on sub-agents spawned via the"
echo "    task tool (deny-risky.sh known gap)"
echo ""
echo "============================================="
echo " Control details: README.md"
echo "============================================="
echo ""

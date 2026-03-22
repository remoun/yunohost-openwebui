#!/bin/bash
# Run ShellCheck on all YunoHost scripts with YunoHost variable stubs.
# Usage: ./tests/run_shellcheck.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STUB="$REPO_ROOT/tests/ynh_shellcheck_stub.sh"

SCRIPTS=(
    scripts/_common.sh
    scripts/install
    scripts/remove
    scripts/upgrade
    scripts/backup
    scripts/restore
    scripts/change_url
)

FAILED=0
for script in "${SCRIPTS[@]}"; do
    echo "--- $script ---"
    # Prepend the stub as a source so ShellCheck sees YunoHost vars as declared.
    # SC1091: can't follow sourced files (ynh helpers, _common.sh)
    # SC2034: variable appears unused (exported via source to other scripts)
    if shellcheck -s bash \
        -e SC1091 \
        -e SC2034 \
        --source-path="$REPO_ROOT/tests" \
        -P "$REPO_ROOT/scripts" \
        "$REPO_ROOT/$script" 2>&1; then
        echo "  OK"
    else
        FAILED=1
    fi
    echo
done

if [ "$FAILED" -eq 1 ]; then
    echo "FAIL: ShellCheck found issues"
    exit 1
else
    echo "PASS: All scripts clean"
fi

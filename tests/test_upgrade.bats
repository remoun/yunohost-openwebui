#!/usr/bin/env bats
# Tests for scripts/upgrade

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

run_upgrade() {
    source "$REPO_ROOT/tests/ynh_mock_helpers.sh"
    ynh_test_setup
    source "$REPO_ROOT/scripts/_common.sh"

    export llm_backend="${TEST_LLM_BACKEND:-none}"
    export ollama_connection="${TEST_OLLAMA_CONNECTION:-local}"
    export ollama_url="${TEST_OLLAMA_URL:-http://localhost:11434}"
    export enable_login_form="${TEST_LOGIN_FORM:-true}"

    eval "$(sed -n '/^#.*STOP SYSTEMD/,$ p' "$REPO_ROOT/scripts/upgrade")"
}

@test "upgrade: sets defaults for new settings" {
    run_upgrade
    track_contains settings_set_default "llm_backend=ollama"
    track_contains settings_set_default "ollama_connection=local"
    track_contains settings_set_default "enable_login_form=true"
}

@test "upgrade: stops service before upgrading" {
    run_upgrade
    head -1 "$YNH_TRACK_DIR/commands" | grep -q "stop"
}

@test "upgrade: starts service after upgrading" {
    run_upgrade
    tail -1 "$YNH_TRACK_DIR/commands" | grep -q "start"
}

@test "upgrade: regenerates .env" {
    run_upgrade
    track_contains commands "ynh_config_add"
}

teardown() {
    rm -rf /tmp/ynh_test
}

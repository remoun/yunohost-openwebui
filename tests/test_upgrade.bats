#!/usr/bin/env bats
# Tests for scripts/upgrade

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

run_upgrade() {
    source "$REPO_ROOT/tests/ynh_mock_helpers.sh"
    ynh_test_setup
    source "$REPO_ROOT/scripts/_common.sh"
    # Override wait_for_port after _common.sh defines it
    wait_for_port() { echo "wait_for_port $*" >> "$YNH_TRACK_DIR/commands"; return 0; }

    export auth_mode="${TEST_AUTH_MODE:-sso}"
    export enable_login_form="${TEST_LOGIN_FORM:-true}"

    eval "$(sed -n '/^#.*STOP SYSTEMD/,$ p' "$REPO_ROOT/scripts/upgrade")"
}

@test "upgrade: sets defaults for new settings" {
    run_upgrade
    track_contains settings_set_default "auth_mode=sso"
    track_contains settings_set_default "enable_login_form=true"
    track_contains settings_set_default "rag_embedding_engine=openai"
    track_contains settings_set_default "enable_signup=false"
    track_contains settings_set_default "enable_ldap=true"
}

@test "upgrade: stops service before upgrading" {
    run_upgrade
    head -1 "$YNH_TRACK_DIR/commands" | grep -q "stop"
}

@test "upgrade: starts service after upgrading" {
    run_upgrade
    track_contains commands "ynh_systemctl.*start"
}

@test "upgrade: regenerates .env" {
    run_upgrade
    track_contains commands "ynh_config_add"
}

teardown() {
    rm -rf /tmp/ynh_test
}

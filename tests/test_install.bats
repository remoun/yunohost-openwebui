#!/usr/bin/env bats
# Tests for scripts/install — validates logic with mocked YunoHost helpers.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

run_install() {
    source "$REPO_ROOT/tests/ynh_mock_helpers.sh"
    ynh_test_setup
    source "$REPO_ROOT/scripts/_common.sh"
    # Override wait_for_port after _common.sh defines it
    wait_for_port() { echo "wait_for_port $*" >> "$YNH_TRACK_DIR/commands"; return 0; }

    export auth_mode="${TEST_AUTH_MODE:-sso}"
    export admin="${TEST_ADMIN:-admin}"

    # Run the install script body (skip source lines and shebang)
    eval "$(sed -n '/^#.*CONFIGURE SETTINGS/,$ p' "$REPO_ROOT/scripts/install")"
}

# ─── Auth mode: SSO (default) ───

@test "install: sso mode disables signup" {
    TEST_AUTH_MODE="sso" run_install
    track_contains settings_set "enable_signup=false"
}

@test "install: sso mode enables login form" {
    TEST_AUTH_MODE="sso" run_install
    track_contains settings_set "enable_login_form=true"
}

@test "install: sso mode enables LDAP" {
    TEST_AUTH_MODE="sso" run_install
    track_contains settings_set "enable_ldap=true"
}

@test "install: sso mode sets trusted headers" {
    TEST_AUTH_MODE="sso" run_install
    track_contains settings_set "webui_auth_trusted_email_header=YNH_USER_EMAIL"
    track_contains settings_set "webui_auth_trusted_name_header=YNH_USER_FULLNAME"
}

# ─── Auth mode: open ───

@test "install: open mode enables signup" {
    TEST_AUTH_MODE="open" run_install
    track_contains settings_set "enable_signup=true"
}

@test "install: open mode disables LDAP" {
    TEST_AUTH_MODE="open" run_install
    track_contains settings_set "enable_ldap=false"
}

@test "install: open mode clears trusted headers" {
    TEST_AUTH_MODE="open" run_install
    track_contains settings_set "webui_auth_trusted_email_header=$"
    track_contains settings_set "webui_auth_trusted_name_header=$"
}

# ─── Common settings ───

@test "install: sets rag_embedding_engine to openai" {
    run_install
    track_contains settings_set "rag_embedding_engine=openai"
}

@test "install: saves admin_email setting" {
    run_install
    track_contains settings_set "admin_email=admin@example.com"
}

# ─── Ownership ───

@test "install: chowns both install_dir and data_dir" {
    run_install
    track_contains chown_calls "$install_dir" || fail "install_dir not chowned"
    track_contains chown_calls "$data_dir" || fail "data_dir not chowned"
}

@test "install: .env gets chmod 400" {
    run_install
    track_contains chmod_calls "400"
}

# ─── Service setup ───

@test "install: adds nginx, systemd, and service" {
    run_install
    track_contains commands "ynh_config_add_nginx"
    track_contains commands "ynh_config_add_systemd"
    track_contains commands "yunohost service"
}

@test "install: starts service and waits for port" {
    run_install
    track_contains commands "ynh_systemctl.*start"
}

teardown() {
    rm -rf /tmp/ynh_test
}

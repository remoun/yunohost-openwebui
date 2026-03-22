#!/usr/bin/env bats
# Tests for scripts/install — validates logic with mocked YunoHost helpers.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

run_install() {
    source "$REPO_ROOT/tests/ynh_mock_helpers.sh"
    ynh_test_setup
    source "$REPO_ROOT/scripts/_common.sh"

    export llm_backend="${TEST_LLM_BACKEND:-none}"
    export ollama_connection="${TEST_OLLAMA_CONNECTION:-local}"
    export ollama_url="${TEST_OLLAMA_URL:-http://localhost:11434}"
    export openai_api_key="${TEST_OPENAI_KEY:-sk-test123}"
    export openai_api_base_url="${TEST_OPENAI_URL:-https://api.openai.com/v1}"
    export admin="${TEST_ADMIN:-admin}"
    export init_main_permission="${TEST_INIT_PERM:-}"

    # Run the install script body (skip source lines and shebang)
    eval "$(sed -n '/^#.*CONFIGURE LLM BACKEND/,$ p' "$REPO_ROOT/scripts/install")"
}

# ─── LLM Backend: none ───

@test "install: llm_backend=none clears ollama settings" {
    TEST_LLM_BACKEND="none" run_install
    track_contains settings_set "ollama_url=$"
    track_contains settings_set "ollama_connection=none"
}

@test "install: llm_backend=none clears openai settings" {
    TEST_LLM_BACKEND="none" run_install
    track_contains settings_set "openai_api_key=$"
    track_contains settings_set "openai_api_base_url=$"
}

# ─── LLM Backend: ollama ───

@test "install: llm_backend=ollama sets ollama_url" {
    TEST_LLM_BACKEND="ollama" run_install
    track_contains settings_set "ollama_url=http://localhost:11434"
}

@test "install: llm_backend=ollama clears openai settings" {
    TEST_LLM_BACKEND="ollama" run_install
    track_contains settings_set "openai_api_key=$"
}

# ─── LLM Backend: openai ───

@test "install: llm_backend=openai clears ollama settings" {
    TEST_LLM_BACKEND="openai" run_install
    track_contains settings_set "ollama_url=$"
    track_contains settings_set "ollama_connection=none"
}

@test "install: llm_backend=openai keeps openai settings" {
    TEST_LLM_BACKEND="openai" TEST_OPENAI_KEY="sk-real" run_install
    ! track_contains settings_set "openai_api_key=$"
}

# ─── LLM Backend: both ───

@test "install: llm_backend=both sets ollama and keeps openai" {
    TEST_LLM_BACKEND="both" run_install
    track_contains settings_set "ollama_url=http://localhost:11434"
    ! track_contains settings_set "openai_api_key=$"
}

# ─── Login form / permission ───

@test "install: visitors permission enables login form" {
    TEST_INIT_PERM="visitors" run_install
    track_contains settings_set "enable_login_form=true"
}

@test "install: all_users permission disables login form" {
    TEST_INIT_PERM="all_users" run_install
    track_contains settings_set "enable_login_form=false"
}

@test "install: unset permission defaults to login form disabled" {
    TEST_INIT_PERM="" run_install
    track_contains settings_set "enable_login_form=false"
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

# ─── Admin email ───

@test "install: saves admin_email setting" {
    run_install
    track_contains settings_set "admin_email=admin@example.com"
}

# ─── Service setup ───

@test "install: adds nginx, systemd, and service" {
    run_install
    track_contains commands "ynh_config_add_nginx"
    track_contains commands "ynh_config_add_systemd"
    track_contains commands "yunohost service"
}

@test "install: starts service with Uvicorn wait" {
    run_install
    track_contains commands "Uvicorn running"
}

teardown() {
    rm -rf /tmp/ynh_test
}

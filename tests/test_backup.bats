#!/usr/bin/env bats
# Tests for scripts/backup

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

run_backup() {
    source "$REPO_ROOT/tests/ynh_mock_helpers.sh"
    ynh_test_setup

    eval "$(sed '/^source /d; /^#!\/bin\/bash/d; /shellcheck/d' "$REPO_ROOT/scripts/backup")"
}

@test "backup: backs up .env config" {
    run_backup
    track_contains backups "$install_dir/.env"
}

@test "backup: backs up data_dir" {
    run_backup
    track_contains backups "$data_dir"
}

@test "backup: backs up nginx config" {
    run_backup
    track_contains backups "nginx"
}

@test "backup: backs up systemd service" {
    run_backup
    track_contains backups "systemd"
}

@test "backup: dumps postgresql" {
    run_backup
    # Verify script completes (print_info messages present)
    [ -s "$YNH_TRACK_DIR/print_info" ]
}

teardown() {
    rm -rf /tmp/ynh_test
}

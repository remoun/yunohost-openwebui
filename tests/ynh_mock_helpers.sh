#!/bin/bash
# Mock YunoHost helpers for local testing (bash 3.2 compatible).
# Sources this instead of /usr/share/yunohost/helpers.

# --- Test tracking via temp files ---
YNH_TEST_DIR="/tmp/ynh_test"
YNH_TRACK_DIR="$YNH_TEST_DIR/_track"

# --- Simulated YunoHost environment variables ---
export app="openwebui"
export install_dir="$YNH_TEST_DIR/var/www/openwebui"
export data_dir="$YNH_TEST_DIR/home/yunohost.app/openwebui"
export domain="example.com"
export path="/"
export port="8080"
export db_name="openwebui"
export db_user="openwebui"
export db_pwd="testpassword123"

# --- Mock YunoHost helper functions ---

ynh_script_progression() { echo "$1" >> "$YNH_TRACK_DIR/progressions"; }
ynh_print_info() { echo "$1" >> "$YNH_TRACK_DIR/print_info"; }

ynh_app_setting_set() {
    local key="" value=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --key=*) key="${1#--key=}" ;;
            --value=*) value="${1#--value=}" ;;
        esac
        shift
    done
    echo "$key=$value" >> "$YNH_TRACK_DIR/settings_set"
    export "$key"="$value"
}

ynh_app_setting_set_default() {
    local key="" value=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --key=*) key="${1#--key=}" ;;
            --value=*) value="${1#--value=}" ;;
        esac
        shift
    done
    echo "$key=$value" >> "$YNH_TRACK_DIR/settings_set_default"
    if eval "[ -z \"\${${key}+x}\" ]"; then
        export "$key"="$value"
    fi
}

ynh_app_setting_get() {
    local app_name="" key=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --app=*) app_name="${1#--app=}" ;;
            --key=*) key="${1#--key=}" ;;
        esac
        shift
    done
    if [ -n "$app_name" ] && [ "$app_name" != "$app" ]; then
        return 1
    fi
    eval "echo \"\${${key}:-}\""
}

ynh_backup() { echo "$1" >> "$YNH_TRACK_DIR/backups"; }
ynh_restore() { echo "$1" >> "$YNH_TRACK_DIR/restores"; }

ynh_config_add() { echo "ynh_config_add $*" >> "$YNH_TRACK_DIR/commands"; }
ynh_config_add_nginx() { echo "ynh_config_add_nginx" >> "$YNH_TRACK_DIR/commands"; }
ynh_config_add_systemd() { echo "ynh_config_add_systemd" >> "$YNH_TRACK_DIR/commands"; }
ynh_config_remove_nginx() { echo "ynh_config_remove_nginx" >> "$YNH_TRACK_DIR/commands"; }
ynh_config_remove_systemd() { echo "ynh_config_remove_systemd" >> "$YNH_TRACK_DIR/commands"; }
ynh_config_change_url_nginx() { echo "ynh_config_change_url_nginx" >> "$YNH_TRACK_DIR/commands"; }

ynh_systemctl() { echo "ynh_systemctl $*" >> "$YNH_TRACK_DIR/commands"; }
ynh_psql_dump_db() { echo "-- mock SQL dump"; }
ynh_psql_db_shell() { echo "ynh_psql_db_shell" >> "$YNH_TRACK_DIR/commands"; cat > /dev/null; }
ynh_hide_warnings() { "$@" 2>/dev/null; }

yunohost() {
    local subcmd="$1"
    shift
    case "$subcmd" in
        service)
            echo "yunohost service $*" >> "$YNH_TRACK_DIR/commands"
            if [ "$1" = "status" ]; then return 0; fi
            ;;
        user)
            echo '{"mail": "admin@example.com"}'
            ;;
    esac
}

# Override chown/chmod to track calls without requiring root
chown() { echo "$*" >> "$YNH_TRACK_DIR/chown_calls"; }
chmod() { echo "$*" >> "$YNH_TRACK_DIR/chmod_calls"; }

# mkdir/touch for /var/log/$app fail in sandbox; no-op so install/upgrade/restore can run
mkdir() {
    if [ "$1" = "-p" ] && [ "${2:-}" = "/var/log/$app" ]; then return 0; fi
    /bin/mkdir "$@"
}
touch() {
    if [ "${1:-}" = "/var/log/$app/$app.log" ]; then return 0; fi
    /bin/touch "$@"
}

# Override commands that would actually install things
python3() {
    # Allow python3 -c (inline scripts like JSON parsing) to run for real
    if [ "$1" = "-c" ]; then
        /usr/bin/python3 "$@"
    else
        echo "python3 $*" >> "$YNH_TRACK_DIR/commands"
    fi
}
systemctl() { echo "systemctl $*" >> "$YNH_TRACK_DIR/commands"; }

# Create a fake pip binary so "$install_dir/venv/bin/pip" calls succeed
_create_mock_pip() {
    mkdir -p "$install_dir/venv/bin"
    cat > "$install_dir/venv/bin/pip" << 'MOCKPIP'
#!/bin/bash
echo "pip $*" >> "/tmp/ynh_test/_track/commands"
MOCKPIP
    /bin/chmod +x "$install_dir/venv/bin/pip"
}

# --- Test setup/teardown helpers ---

ynh_test_setup() {
    rm -rf "$YNH_TEST_DIR"
    mkdir -p "$install_dir" "$data_dir" "$YNH_TRACK_DIR"
    _create_mock_pip
    # Create empty tracking files
    touch "$YNH_TRACK_DIR/settings_set"
    touch "$YNH_TRACK_DIR/settings_set_default"
    touch "$YNH_TRACK_DIR/progressions"
    touch "$YNH_TRACK_DIR/print_info"
    touch "$YNH_TRACK_DIR/backups"
    touch "$YNH_TRACK_DIR/restores"
    touch "$YNH_TRACK_DIR/chown_calls"
    touch "$YNH_TRACK_DIR/chmod_calls"
    touch "$YNH_TRACK_DIR/commands"
}

ynh_test_teardown() {
    rm -rf "$YNH_TEST_DIR"
}

# Helper: check if a pattern exists in a tracking file
track_contains() {
    local file="$YNH_TRACK_DIR/$1"
    local pattern="$2"
    grep -q "$pattern" "$file" 2>/dev/null
}

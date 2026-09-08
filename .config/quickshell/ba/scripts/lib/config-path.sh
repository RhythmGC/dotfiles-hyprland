#!/usr/bin/env bash
# Shared BlueArchive paths. The user data directory is independent of the runtime.
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
ba_config_dir() {
    printf '%s/baOS\n' "$XDG_CONFIG_HOME"
}

ba_config_file() {
    printf '%s/config.json\n' "$(ba_config_dir)"
}

ba_version_file() {
    printf '%s/version.json\n' "$(ba_config_dir)"
}

ba_installed_marker_file() {
    printf '%s/installed_true\n' "$(ba_config_dir)"
}

ba_migrations_state_file() {
    printf '%s/migrations.json\n' "$(ba_config_dir)"
}

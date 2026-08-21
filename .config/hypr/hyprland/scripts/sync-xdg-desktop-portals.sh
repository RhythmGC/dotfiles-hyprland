#!/usr/bin/env bash
set -euo pipefail

# Quickshell can be started by systemd before the compositor environment has
# been imported. Resolve the active Wayland socket before (re)starting portal
# backends so GTK file choosers can connect to Hyprland and inherit GTK state.
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
wayland_display="${WAYLAND_DISPLAY:-}"

if [[ -z "$wayland_display" || ! -S "$runtime_dir/$wayland_display" ]]; then
    newest_socket=""
    for candidate in "$runtime_dir"/wayland-*; do
        [[ -S "$candidate" ]] || continue
        [[ "${candidate##*/}" =~ ^wayland-[0-9]+$ ]] || continue
        if [[ -z "$newest_socket" || "$candidate" -nt "$newest_socket" ]]; then
            newest_socket="$candidate"
        fi
    done
    wayland_display="${newest_socket##*/}"
fi

if [[ -z "$wayland_display" ]]; then
    printf '[portal-sync] No active Wayland socket found in %s\n' "$runtime_dir" >&2
    exit 1
fi

export WAYLAND_DISPLAY="$wayland_display"
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-Hyprland}"
export XDG_SESSION_DESKTOP="${XDG_SESSION_DESKTOP:-Hyprland}"
export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}"
export LC_TIME="${LC_TIME:-en_US.UTF-8}"

# Keep both activation environments aligned. Passing explicit assignments to
# dbus-update avoids replacing a valid value with an empty inherited variable.
dbus-update-activation-environment --systemd \
    "WAYLAND_DISPLAY=$WAYLAND_DISPLAY" \
    "XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP" \
    "XDG_SESSION_DESKTOP=$XDG_SESSION_DESKTOP" \
    "XDG_SESSION_TYPE=$XDG_SESSION_TYPE" \
    "LC_TIME=$LC_TIME"

systemctl --user reset-failed xdg-desktop-portal-hyprland.service 2>/dev/null || true
systemctl --user restart \
    xdg-desktop-portal-hyprland.service \
    xdg-desktop-portal-gtk.service \
    xdg-desktop-portal.service

printf '[portal-sync] Portals restarted with WAYLAND_DISPLAY=%s\n' "$WAYLAND_DISPLAY"

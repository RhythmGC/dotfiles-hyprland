#!/usr/bin/env bash
# game_focus_fix.sh
# Warp cursor to center of active game window and simulate a click
# to trigger XWayland pointer constraints (cursor grab/confinement).
# Called from Hyprland Lua window.active event listener.

sleep 0.2

window_info=$(hyprctl activewindow -j 2>/dev/null)
active_class=$(echo "$window_info" | jq -r '.class // empty')

# Only proceed if active window is a Steam game
if [[ ! "$active_class" =~ ^steam_app_ ]]; then
    exit 0
fi

x=$(echo "$window_info" | jq -r '.at[0]')
y=$(echo "$window_info" | jq -r '.at[1]')
w=$(echo "$window_info" | jq -r '.size[0]')
h=$(echo "$window_info" | jq -r '.size[1]')

center_x=$((x + w / 2))
center_y=$((y + h / 2))

# Warp cursor to the center of the game window
hyprctl dispatch movecursor "$center_x" "$center_y"

sleep 0.05

# Simulate a left mouse click to trigger XWayland pointer constraints
ydotool click 0x00

sleep 0.05

# Wiggle cursor slightly to make sure motion events are dispatched
hyprctl dispatch movecursor $((center_x + 2)) $((center_y + 2))
sleep 0.05
hyprctl dispatch movecursor "$center_x" "$center_y"

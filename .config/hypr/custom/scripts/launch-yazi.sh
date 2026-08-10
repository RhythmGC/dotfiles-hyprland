#!/usr/bin/env bash

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/yazi"
cwd_file="$state_dir/last-dir"
start_dir="$HOME"

mkdir -p "$state_dir"

if [[ -r "$cwd_file" ]]; then
    IFS= read -r saved_dir < "$cwd_file"
    if [[ -d "$saved_dir" ]]; then
        start_dir="$saved_dir"
    fi
fi

exec kitty -1 --directory "$start_dir" fish -c "yazi --cwd-file '$cwd_file'"

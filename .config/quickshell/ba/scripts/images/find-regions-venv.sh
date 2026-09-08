#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -n "${BA_VENV:-}" ]]; then
    _ba_venv="$(eval echo "$BA_VENV")"
elif [[ -n "${BA_VENV_COMPAT:-}" ]]; then
    _ba_venv="$(eval echo "$BA_VENV_COMPAT")"
else
    _ba_venv="$HOME/.local/state/quickshell/.venv"
fi
source "$_ba_venv/bin/activate" 2>/dev/null || true
"$_ba_venv/bin/python3" "$SCRIPT_DIR/find_regions.py" "$@"
deactivate 2>/dev/null || true

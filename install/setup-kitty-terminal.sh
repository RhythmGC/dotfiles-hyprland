#!/usr/bin/env bash
set -euo pipefail

if ! command -v kitty >/dev/null 2>&1; then
  echo "[ERROR] kitty is not installed." >&2
  exit 1
fi

if [ ! -f /usr/share/applications/kitty.desktop ] \
    && [ ! -f "${XDG_DATA_HOME:-$HOME/.local/share}/applications/kitty.desktop" ]; then
  echo "[ERROR] kitty.desktop was not found." >&2
  exit 1
fi

if ! command -v kwriteconfig6 >/dev/null 2>&1; then
  echo "[ERROR] kwriteconfig6 is required to configure KDE/Dolphin." >&2
  exit 1
fi

# KIO's terminal launcher reads both values. TerminalApplication is the
# executable fallback; TerminalService provides Kitty's desktop metadata,
# including its working-directory argument.
kwriteconfig6 --file kdeglobals --group General --key TerminalApplication --notify kitty
kwriteconfig6 --file kdeglobals --group General --key TerminalService --notify kitty.desktop

if command -v kreadconfig6 >/dev/null 2>&1; then
  terminal_application=$(kreadconfig6 --file kdeglobals --group General --key TerminalApplication)
  terminal_service=$(kreadconfig6 --file kdeglobals --group General --key TerminalService)
  if [ "$terminal_application" != "kitty" ] || [ "$terminal_service" != "kitty.desktop" ]; then
    echo "[ERROR] KDE terminal preference verification failed." >&2
    exit 1
  fi
fi

echo "[OK] KDE/Dolphin external terminal is now Kitty."
echo "[NOTE] Dolphin's embedded F4 panel still requires KonsolePart; use Open Terminal (Shift+F4) for Kitty."

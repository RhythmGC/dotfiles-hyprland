#!/usr/bin/env bash
# Install the bundled BlueArchive Neovim theme; no external theme plugin is needed.
set -euo pipefail
PALETTE_FILE="${1:?Usage: $0 <palette.json> <terminal.json> <plugin_dir>}"
TERMINAL_FILE="${2:?}"
NEOVIM_PLUGIN_DIR="${3:?}"
NEOVIM_CONFIG_DIR="$(dirname "$(dirname "$NEOVIM_PLUGIN_DIR")")"
THEME_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../assets/neovim" && pwd)"
mkdir -p "$NEOVIM_PLUGIN_DIR" "$NEOVIM_CONFIG_DIR/colors" "$NEOVIM_CONFIG_DIR/lua"
cp -r "$THEME_SOURCE/lua/." "$NEOVIM_CONFIG_DIR/lua/"
cp "$THEME_SOURCE/colors/ba.lua" "$NEOVIM_CONFIG_DIR/colors/ba.lua"
cp "$THEME_SOURCE/LICENSE" "$NEOVIM_CONFIG_DIR/lua/ba/LICENSE"
cat > "$NEOVIM_PLUGIN_DIR/neovim.lua" <<'PLUGEOF'
-- BlueArchive generated theme. Use 99-ba-user.lua for overrides.
return {
  { "LazyVim/LazyVim", opts = { colorscheme = "ba" } },
}
PLUGEOF

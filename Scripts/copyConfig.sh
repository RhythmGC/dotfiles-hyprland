#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
ITEMS_FILE="$SCRIPT_DIR/items.json"

SRC_CONFIG="$HOME/.config"
DST_CONFIG="$DOTFILES/.config"

if ! command -v jq >/dev/null 2>&1; then
  echo "Missing jq. Install using:"
  echo "sudo pacman -S jq"
  exit 1
fi

if [ ! -f "$ITEMS_FILE" ]; then
  echo "Not found: $ITEMS_FILE"
  exit 1
fi

mkdir -p "$DST_CONFIG"

copy_item() {
  local item="${1%/}"
  local src="$SRC_CONFIG/$item"
  local dst="$DST_CONFIG/$item"

  if [ ! -e "$src" ]; then
    echo "[skip] Does not exist: $src"
    return
  fi

  mkdir -p "$(dirname "$dst")"

  # If src and dst are the same file/folder due to symlink, skip
  if [ -e "$dst" ] && [ "$(readlink -f "$src")" = "$(readlink -f "$dst")" ]; then
    echo "[skip] Already linked correctly, skipping: $item"
    return
  fi

  if [ -d "$src" ]; then
    mkdir -p "$dst"
    rsync -a --delete "$src/" "$dst/"
  else
    cp -a "$src" "$dst"
  fi

  echo "[copied] $src -> $dst"
}

while IFS= read -r item; do
  copy_item "$item"
done < <(jq -r '.[]' "$ITEMS_FILE")

echo
echo "Finished copying config to: $DST_CONFIG"

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOTFILES="$HOME/dotfiles-hyprland"
ITEMS_FILE="$SCRIPT_DIR/items.json"

SRC_CONFIG="$DOTFILES/.config"
DST_CONFIG="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup-dotfiles-$(date +%Y%m%d-%H%M%S)"

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

backup_item() {
  local dst="$1"
  local item="$2"

  mkdir -p "$BACKUP_DIR/$(dirname "$item")"
  mv "$dst" "$BACKUP_DIR/$item"

  echo "[backup] $dst -> $BACKUP_DIR/$item"
}

link_item() {
  local item="${1%/}"
  local src="$SRC_CONFIG/$item"
  local dst="$DST_CONFIG/$item"

  if [ ! -e "$src" ]; then
    echo "[skip] Does not exist in dotfiles: $src"
    return
  fi

  if [ -L "$src" ]; then
    echo "[error] Source in dotfiles is a symlink, skipping to avoid loop: $src"
    return
  fi

  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    if [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
      echo "[skip] Already linked correctly: $dst -> $src"
      return
    fi
    rm "$dst"
    echo "[removed old symlink] $dst"
  elif [ -e "$dst" ]; then
    backup_item "$dst" "$item"
  fi

  ln -s "$src" "$dst"
  echo "[linked] $dst -> $src"
}

while IFS= read -r item; do
  echo "[item] $item"
  link_item "$item"
done < <(jq -r '.[]' "$ITEMS_FILE")

echo
echo "Finished creating symlinks."
echo "Backup if any is located at: $BACKUP_DIR"
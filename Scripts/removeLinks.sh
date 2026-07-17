#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ITEMS_FILE="$SCRIPT_DIR/items.json"

DST_CONFIG="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup-dotfiles-$(date +%Y%m%d-%H%M%S)"
backup_created=false

if ! command -v jq >/dev/null 2>&1; then
  echo "Missing jq. Install using:"
  echo "sudo pacman -S jq"
  exit 1
fi

if [ ! -f "$ITEMS_FILE" ]; then
  echo "Not found: $ITEMS_FILE"
  exit 1
fi

unlink_item() {
  local item="${1%/}"
  local dst="$DST_CONFIG/$item"

  echo "[item] $item"

  if [ -L "$dst" ]; then
    rm "$dst"
    echo "[unlinked symlink] $dst"
  elif [ -e "$dst" ]; then
    if [ "$backup_created" = false ]; then
      mkdir -p "$BACKUP_DIR"
      backup_created=true
    fi
    mkdir -p "$BACKUP_DIR/$(dirname "$item")"
    mv "$dst" "$BACKUP_DIR/$item"
    echo "[backed up physical config] $dst -> $BACKUP_DIR/$item"
  else
    echo "[skip] Does not exist: $dst"
  fi
}

while IFS= read -r item; do
  unlink_item "$item"
done < <(jq -r '.[]' "$ITEMS_FILE")

echo
echo "Finished removing/resetting configuration."
if [ "$backup_created" = true ]; then
  echo "Physical configs were preserved at: $BACKUP_DIR"
fi

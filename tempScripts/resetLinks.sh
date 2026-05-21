#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"
ITEMS_FILE="$HOME/dotfiles/tempScripts/items.json"

DST_CONFIG="$HOME/.config"

if ! command -v jq >/dev/null 2>&1; then
  echo "Thiếu jq. Cài bằng:"
  echo "sudo pacman -S jq"
  exit 1
fi

if [ ! -f "$ITEMS_FILE" ]; then
  echo "Không tìm thấy: $ITEMS_FILE"
  exit 1
fi

unlink_item() {
  local item="$1"
  local dst="$DST_CONFIG/$item"

  echo "[item] $item"

  if [ -L "$dst" ]; then
    rm "$dst"
    echo "[unlinked] $dst"
  elif [ -e "$dst" ]; then
    echo "[skip] Không phải symlink, giữ nguyên: $dst"
  else
    echo "[skip] Không tồn tại: $dst"
  fi
}

while IFS= read -r item; do
  unlink_item "$item"
done < <(jq -r '.[]' "$ITEMS_FILE")

echo
echo "Xong tắt symlink."


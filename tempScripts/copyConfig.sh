#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DOTFILES="$HOME/dotfiles"
ITEMS_FILE="$SCRIPT_DIR/items.json"

SRC_CONFIG="$HOME/.config"
DST_CONFIG="$DOTFILES/.config"

if ! command -v jq >/dev/null 2>&1; then
  echo "Thiếu jq. Cài bằng:"
  echo "sudo pacman -S jq"
  exit 1
fi

if [ ! -f "$ITEMS_FILE" ]; then
  echo "Không tìm thấy: $ITEMS_FILE"
  exit 1
fi

mkdir -p "$DST_CONFIG"

copy_item() {
  local item="$1"
  local src="$SRC_CONFIG/$item"
  local dst="$DST_CONFIG/$item"

  if [ ! -e "$src" ]; then
    echo "[skip] Không tồn tại: $src"
    return
  fi

  mkdir -p "$(dirname "$dst")"

  # Nếu src và dst đang là cùng một file/folder do symlink thì bỏ qua
  if [ -e "$dst" ] && [ "$(readlink -f "$src")" = "$(readlink -f "$dst")" ]; then
    echo "[skip] Đã link đúng, bỏ qua: $item"
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
echo "Xong copy config vào: $DST_CONFIG"

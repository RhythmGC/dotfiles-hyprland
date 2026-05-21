#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"
ITEMS_FILE="$HOME/dotfiles/tempScripts/items.json"

SRC_CONFIG="$DOTFILES/.config"
DST_CONFIG="$HOME/.config"

RESET_BACKUP="$HOME/.config-reset-before-relink-$(date +%Y%m%d-%H%M%S)"
LATEST_BACKUP="$(ls -dt "$HOME"/.config-backup-dotfiles-* 2>/dev/null | head -n 1 || true)"

if ! command -v jq >/dev/null 2>&1; then
  echo "Thiếu jq. Cài bằng:"
  echo "sudo pacman -S jq"
  exit 1
fi

if [ ! -f "$ITEMS_FILE" ]; then
  echo "Không tìm thấy: $ITEMS_FILE"
  exit 1
fi

mkdir -p "$SRC_CONFIG"
mkdir -p "$DST_CONFIG"

echo "[items] $ITEMS_FILE"
echo "[dotfiles] $SRC_CONFIG"
echo "[home config] $DST_CONFIG"
echo "[latest backup] ${LATEST_BACKUP:-không có}"
echo

repair_source_if_needed() {
  local item="$1"
  local src="$SRC_CONFIG/$item"
  local backup_src=""

  if [ -n "${LATEST_BACKUP:-}" ]; then
    backup_src="$LATEST_BACKUP/$item"
  fi

  if [ -L "$src" ] || [ ! -e "$src" ]; then
    echo "[repair] Source lỗi hoặc thiếu: $src"

    rm -rf "$src"
    mkdir -p "$(dirname "$src")"

    if [ -n "$backup_src" ] && [ -e "$backup_src" ]; then
      cp -a "$backup_src" "$src"
      echo "[restore source] $backup_src -> $src"
    elif [ -e "$RESET_BACKUP/$item" ]; then
      cp -a "$RESET_BACKUP/$item" "$src"
      echo "[restore source from reset backup] $RESET_BACKUP/$item -> $src"
    else
      echo "[error] Không có dữ liệu để restore cho: $item"
      return 1
    fi
  fi

  if [ -L "$src" ]; then
    echo "[error] Source vẫn là symlink, bỏ qua để tránh loop: $src"
    return 1
  fi

  return 0
}

reset_item() {
  local item="$1"
  local src="$SRC_CONFIG/$item"
  local dst="$DST_CONFIG/$item"

  echo
  echo "[item] $item"

  # 1. Gỡ symlink hiện tại trong ~/.config
  if [ -L "$dst" ]; then
    rm "$dst"
    echo "[removed symlink] $dst"
  elif [ -e "$dst" ]; then
    mkdir -p "$RESET_BACKUP/$(dirname "$item")"
    mv "$dst" "$RESET_BACKUP/$item"
    echo "[backup real config] $dst -> $RESET_BACKUP/$item"
  fi

  # 2. Sửa source trong ~/dotfiles/.config nếu bị symlink loop hoặc thiếu
  if ! repair_source_if_needed "$item"; then
    echo "[skip] Không link được: $item"
    return
  fi

  # 3. Tạo symlink lại đúng chiều
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "[linked] $dst -> $src"
}

while IFS= read -r item; do
  reset_item "$item"
done < <(jq -r '.[]' "$ITEMS_FILE")

echo
echo "Xong reset symlink."
echo "Backup config thật nếu có nằm ở: $RESET_BACKUP"


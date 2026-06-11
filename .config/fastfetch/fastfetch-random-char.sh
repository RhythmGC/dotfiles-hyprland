#!/bin/bash

IMG_DIR="$HOME/.config/fastfetch/Images"
CONFIG_DIR="$HOME/.config/fastfetch"
BASE_CONFIG="$CONFIG_DIR/config.jsonc"
TEMP_CONFIG="$CONFIG_DIR/temp-config.jsonc"
CHAR_COLOR_FILE="$CONFIG_DIR/characters.jsonc"

# Random folder
CHAR_FOLDER=$(find "$IMG_DIR" -mindepth 1 -maxdepth 1 -type d | shuf -n 1)
CHAR_NAME=$(basename "$CHAR_FOLDER")

# Random ảnh
CHAR_IMG=$(find "$CHAR_FOLDER" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.webp" \) | shuf -n 1)

# Lấy màu từ file jsonc, nếu không có thì default white (7)
CHAR_COLOR=$(jq -r --arg name "$CHAR_NAME" '.[$name] // "7"' "$CHAR_COLOR_FILE")

# Tạo config tạm bằng jq: set logo + thêm custom module với màu
jq --arg img "$CHAR_IMG" --arg char "$CHAR_NAME" --arg color "$CHAR_COLOR" '
  .logo.source = $img |
  .logo.type = "kitty-direct" |
  .logo.height = 13 |
  .logo.width = 27 |
  .modules += [
    {
      "type": "custom",
      "format": "\u001b[38;5;" + $color + "m󰮯 Waifu: " + $char + "\u001b[0m"
    }
  ]
' "$BASE_CONFIG" >"$TEMP_CONFIG"

# Chạy fastfetch
fastfetch -c "$TEMP_CONFIG"

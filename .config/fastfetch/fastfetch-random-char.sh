#!/usr/bin/env bash

set -u

CONFIG_DIR="$HOME/.config/fastfetch"
SOURCE_IMG_DIR="$CONFIG_DIR/Images"
IMG_DIR="$CONFIG_DIR/.icon"
BASE_CONFIG="$CONFIG_DIR/config.jsonc"
CHAR_COLOR_FILE="$CONFIG_DIR/characters.jsonc"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/fastfetch"
THUMBNAIL_DIR="$CONFIG_DIR/.icon"
TEMP_CONFIG="$CACHE_DIR/temp-config.jsonc"

LOGO_HEIGHT=13
LOGO_MIN_WIDTH=8
LOGO_MAX_WIDTH=40

# Fallback for Kitty with the configured 11 pt font. When run in a real TTY,
# these values are replaced with the current terminal cell geometry.
CELL_WIDTH=9
CELL_HEIGHT=20

mkdir -p "$CACHE_DIR" "$THUMBNAIL_DIR"

# Query the actual Kitty grid so a square image occupies a square pixel area.
# kitty-direct scales to terminal cells, whose height and width are different.
terminal_cells=$(stty size 2>/dev/null || true)
window_pixels=$(kitty +kitten icat --print-window-size 2>/dev/null || true)
if [[ "$terminal_cells" =~ ^([0-9]+)[[:space:]]+([0-9]+)$ ]]; then
  terminal_rows=${BASH_REMATCH[1]}
  terminal_columns=${BASH_REMATCH[2]}
else
  terminal_rows=0
  terminal_columns=0
fi
if [[ "$window_pixels" =~ ^([0-9]+)x([0-9]+)$ ]]; then
  window_width=${BASH_REMATCH[1]}
  window_height=${BASH_REMATCH[2]}
else
  window_width=0
  window_height=0
fi
if ((terminal_columns > 0 && terminal_rows > 0 && window_width > 0 && window_height > 0)); then
  CELL_WIDTH=$(((window_width + terminal_columns / 2) / terminal_columns))
  CELL_HEIGHT=$(((window_height + terminal_rows / 2) / terminal_rows))
fi

# Pre-render a thumbnail at the final cell rectangle. This avoids asking Kitty
# to downscale multi-megapixel artwork at draw time, which makes fine line art
# look soft or aliased. Mirror the Images directory structure under .icon so
# every processed image remains easy to identify.
sync_processed_image() {
  local source_image="$1"
  local source_geometry source_width source_height
  local width_numerator width_denominator logo_width
  local target_width target_height relative_image relative_directory
  local source_filename cached_directory cached_thumbnail cached_geometry
  local temporary_thumbnail

  source_geometry=$(magick identify -ping -format '%w %h' "$source_image" 2>/dev/null || true)
  if [[ "$source_geometry" =~ ^([0-9]+)[[:space:]]+([0-9]+)$ ]]; then
    source_width=${BASH_REMATCH[1]}
    source_height=${BASH_REMATCH[2]}

    width_numerator=$((source_width * LOGO_HEIGHT * CELL_HEIGHT))
    width_denominator=$((source_height * CELL_WIDTH))
    logo_width=$(((width_numerator + width_denominator / 2) / width_denominator))
    ((logo_width < LOGO_MIN_WIDTH)) && logo_width=$LOGO_MIN_WIDTH
    ((logo_width > LOGO_MAX_WIDTH)) && logo_width=$LOGO_MAX_WIDTH

    target_width=$((logo_width * CELL_WIDTH))
    target_height=$((LOGO_HEIGHT * CELL_HEIGHT))
    relative_image=${source_image#"$SOURCE_IMG_DIR"/}
    relative_directory=$(dirname -- "$relative_image")
    source_filename=$(basename -- "$relative_image")
    cached_directory="$THUMBNAIL_DIR/$relative_directory"
    cached_thumbnail="$cached_directory/${source_filename%.*}.png"
    mkdir -p "$cached_directory"

    cached_geometry=$(magick identify -ping -format '%w %h' "$cached_thumbnail" 2>/dev/null || true)
    if [[ ! -s "$cached_thumbnail" ||
      "$source_image" -nt "$cached_thumbnail" ||
      "$cached_geometry" != "$target_width $target_height" ]]; then
      temporary_thumbnail=$(mktemp --tmpdir="$CACHE_DIR" '.fastfetch-thumbnail.XXXXXX.png')
      if magick "$source_image" \
        -auto-orient \
        -filter Lanczos \
        -resize "${target_width}x${target_height}" \
        -background none \
        -gravity center \
        -extent "${target_width}x${target_height}" \
        -unsharp '0x0.65+0.65+0.015' \
        -depth 8 \
        "$temporary_thumbnail"; then
        mv -f -- "$temporary_thumbnail" "$cached_thumbnail"
      else
        rm -f -- "$temporary_thumbnail"
      fi
    fi
  fi
}

# Synchronize every new or changed source image before selecting a logo.
if command -v magick >/dev/null 2>&1 && [[ -d "$SOURCE_IMG_DIR" ]]; then
  while IFS= read -r -d '' source_image; do
    sync_processed_image "$source_image"
  done < <(find "$SOURCE_IMG_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.webp" \) -print0)
fi

# Fastfetch only displays processed images from .icon.
CHAR_FOLDER=$(find "$IMG_DIR" -mindepth 1 -maxdepth 1 -type d | shuf -n 1)
if [[ -z "$CHAR_FOLDER" ]]; then
  echo "[fastfetch] No processed character folders found in $IMG_DIR" >&2
  exit 1
fi
CHAR_NAME=$(basename "$CHAR_FOLDER")

CHAR_IMG=$(find "$CHAR_FOLDER" -type f -iname "*.png" | shuf -n 1)
if [[ -z "$CHAR_IMG" ]]; then
  echo "[fastfetch] No processed images found in $CHAR_FOLDER" >&2
  exit 1
fi

# Get color from jsonc file, defaults to white (7) if not found.
CHAR_COLOR=$(jq -r --arg name "$CHAR_NAME" '.[$name] // "7"' "$CHAR_COLOR_FILE")
DISPLAY_IMG="$CHAR_IMG"
LOGO_WIDTH=29
display_geometry=$(magick identify -ping -format '%w %h' "$DISPLAY_IMG" 2>/dev/null || true)
if [[ "$display_geometry" =~ ^([0-9]+)[[:space:]]+([0-9]+)$ ]]; then
  LOGO_WIDTH=$(((BASH_REMATCH[1] + CELL_WIDTH / 2) / CELL_WIDTH))
  ((LOGO_WIDTH < LOGO_MIN_WIDTH)) && LOGO_WIDTH=$LOGO_MIN_WIDTH
  ((LOGO_WIDTH > LOGO_MAX_WIDTH)) && LOGO_WIDTH=$LOGO_MAX_WIDTH
fi

# Create temporary config using jq: set logo + add custom module with color
jq --arg img "$DISPLAY_IMG" \
  --arg char "$CHAR_NAME" \
  --arg color "$CHAR_COLOR" \
  --argjson logoHeight "$LOGO_HEIGHT" \
  --argjson logoWidth "$LOGO_WIDTH" '
  .logo.source = $img |
  .logo.type = "kitty-direct" |
  .logo.height = $logoHeight |
  .logo.width = $logoWidth |
  .modules += [
    {
      "type": "custom",
      "format": "\u001b[38;5;" + $color + "m󰮯 Waifu: " + $char + "\u001b[0m"
    }
  ]
' "$BASE_CONFIG" >"$TEMP_CONFIG"

# Run fastfetch
fastfetch -c "$TEMP_CONFIG"

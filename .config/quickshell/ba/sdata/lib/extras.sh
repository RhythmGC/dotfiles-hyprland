# Optional extras helpers for setup/install flows
# shellcheck shell=bash

ba_get_user_wallpapers_dir() {
  local _xdg_pictures
  _xdg_pictures="$(xdg-user-dir PICTURES 2>/dev/null || true)"
  if [[ -z "$_xdg_pictures" || "$_xdg_pictures" != /* || "$_xdg_pictures" == "$HOME" ]]; then
    _xdg_pictures="$HOME/Pictures"
  fi
  printf '%s' "${_xdg_pictures}/Wallpapers"
}

# Install ba-pixel-sddm via the canonical installer script.
# Args:
#   $1 auto apply mode: ask|yes|no (default: ask)
extras_install_sddm_theme() {
  local auto_apply_mode="${1:-ask}"

  if ! command -v sddm &>/dev/null; then
    log_warning "SDDM not detected. Skipping ba-pixel-sddm setup."
    return 0
  fi

  local sddm_script="${REPO_ROOT}/scripts/sddm/install-pixel-sddm.sh"
  if [[ ! -f "$sddm_script" ]]; then
    log_warning "ba-pixel-sddm install script not found, skipping"
    return 0
  fi

  tui_info "Setting up ba-pixel-sddm login theme..."
  chmod +x "$sddm_script"
  if ! BA_SDDM_AUTO_APPLY="$auto_apply_mode" bash "$sddm_script"; then
    log_warning "ba-pixel-sddm setup failed — SDDM config may need manual update"
    log_warning "Try: sudo bash ${sddm_script}"
    return 1
  fi
}

# Copy bundled wallpaper assets without requiring an upstream wallpaper repository.
extras_install_ba_walls() {
  local destination wall target
  destination="$(ba_get_user_wallpapers_dir)"
  mkdir -p "$destination"
  EXTRAS_BA_WALLS_FIRST_IMAGE=""
  while IFS= read -r -d '' wall; do
    target="$destination/$(basename "$wall")"
    [[ -s "$target" ]] || cp "$wall" "$target"
    [[ -n "$EXTRAS_BA_WALLS_FIRST_IMAGE" ]] || EXTRAS_BA_WALLS_FIRST_IMAGE="$target"
  done < <(find "$REPO_ROOT/assets/wallpapers" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \) -print0)
  export EXTRAS_BA_WALLS_FIRST_IMAGE
}


# Install / update the "yet-another-monochrome-icon-set" (YAMIS) icon theme by
# dirn-typo. GPL-3, ~23 MiB. Lives in user-scope ($HOME/.local/share/icons) so
# it's available to GTK / Qt without root. Non-intrusive: only installs the
# theme files. The user's current icon theme is NOT touched — they can switch
# via BlueArchive Settings if they want.
#
# Idempotent: clones on first run, fast-forwards on subsequent runs.
extras_install_yamis_icons() {
  local repo_url="https://bitbucket.org/dirn-typo/yet-another-monochrome-icon-set.git"
  local theme_name="yet-another-monochrome-icon-set"
  local dest="${HOME}/.local/share/icons/${theme_name}"

  if ! command -v git >/dev/null 2>&1; then
    log_warning "Git is required to install YAMIS icons, skipping"
    return 0
  fi

  mkdir -p "${HOME}/.local/share/icons"

  if [[ ( -e "${dest}/.git" || -e "${dest}/../../../.git" ) ]]; then
    tui_info "Updating YAMIS monochrome icon theme..."
    if git -C "$dest" pull --ff-only --quiet 2>/dev/null; then
      log_success "YAMIS icons updated"
    else
      log_warning "YAMIS update had issues (non-fatal). Existing files kept."
    fi
    return 0
  fi

  if [[ -d "$dest" && ! ( -e "${dest}/.git" || -e "${dest}/../../../.git" ) ]]; then
    log_warning "YAMIS destination exists but is not a git checkout: ${dest}"
    log_warning "Skipping to avoid clobbering manual install"
    return 0
  fi

  tui_info "Installing YAMIS monochrome icon theme (~23 MiB, by dirn-typo)..."
  if git clone --depth 1 --quiet "$repo_url" "$dest"; then
    log_success "YAMIS icons installed at ${dest}"
    log_info  "Switch to it via BlueArchive Settings → Appearance → Icon theme"
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
      gtk-update-icon-cache -q "$dest" 2>/dev/null || true
    fi
  else
    log_warning "Failed to install YAMIS icons (network?), continuing"
    rm -rf "$dest"
  fi

  return 0
}

# Refresh YAMIS icons during `./setup update` — only acts if the user already
# has YAMIS installed. Never installs fresh on update; that's the install
# flow's or extras menu's responsibility.
extras_refresh_yamis_icons_on_update() {
  local dest="${HOME}/.local/share/icons/yet-another-monochrome-icon-set"
  if [[ ( -e "${dest}/.git" || -e "${dest}/../../../.git" ) ]]; then
    extras_install_yamis_icons
  fi
}

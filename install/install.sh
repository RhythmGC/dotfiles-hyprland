#!/usr/bin/env bash

# Arch Linux Dotfiles Installer
# Designed to install packages and safely link configurations.

set -euo pipefail

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0;37m' # No Color

# --- Logging Helpers ---
info()    { echo -e "${BLUE}${BOLD}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}${BOLD}[SUCCESS]${NC} $1"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARNING]${NC} $1"; }
error()   { echo -e "${RED}${BOLD}[ERROR]${NC} $1"; exit 1; }
ask()     { echo -ne "${CYAN}${BOLD}[?]${NC} $1 "; }

# --- Banner ---
clear
echo -e "${MAGENTA}${BOLD}"
echo "  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗"
echo "  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝"
echo "  ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗"
echo "  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║"
echo "  ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║"
echo "  ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝"
echo -e "${CYAN}             Arch Linux Installer & Config Linker${NC}"
echo -e "${BOLD}------------------------------------------------------------${NC}\n"

# --- Arch Linux Guard ---
if [ ! -f /etc/arch-release ]; then
  warn "This script is optimized and written specifically for Arch Linux."
  ask "Do you want to force continue anyway? (y/N): "
  read -r choice
  if [[ ! "$choice" =~ ^[Yy]$ ]]; then
    error "Installation cancelled."
  fi
fi

# --- Find Dotfiles Dir ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_CONFIG="$DOTFILES_DIR/.config"
DST_CONFIG="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup-dotfiles-$(date +%Y%m%d-%H%M%S)"

info "Dotfiles directory: $DOTFILES_DIR"

# --- Ensure Git is Configured ---
if ! command -v git >/dev/null 2>&1; then
  info "Installing git..."
  sudo pacman -S --noconfirm git
fi

# --- AUR Helper Detection/Setup ---
AUR_HELPER=""
if command -v yay >/dev/null 2>&1; then
  AUR_HELPER="yay"
elif command -v paru >/dev/null 2>&1; then
  AUR_HELPER="paru"
else
  warn "No AUR Helper (yay/paru) detected."
  ask "Would you like to install 'yay' now? (Y/n): "
  read -r install_aur
  if [[ "$install_aur" =~ ^[Nn]$ ]]; then
    info "Proceeding without an AUR helper. Some packages may be skipped."
  else
    info "Installing yay..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    (cd /tmp/yay-bin && makepkg -si --noconfirm)
    rm -rf /tmp/yay-bin
    AUR_HELPER="yay"
    success "yay installed successfully!"
  fi
fi

# --- Package Lists ---
# Standard Official Packages
core_packages=("jq" "rsync" "curl" "wget" "fastfetch" "fd" "ripgrep" "unzip")
shell_packages=("fish" "starship")
editor_packages=("neovim")
desktop_packages=("hyprland" "hyprpaper" "hyprlock" "hypridle" "kitty" "rofi-wayland" "waybar" "polkit-kde-agent")

# AUR Packages
aur_core=()
aur_shell=()
aur_editor=()
aur_desktop=("illogical-impulse-quickshell-git" "matugen-bin")

# Helper function to check if a package is satisfied
is_pkg_installed() {
  local pkg="$1"
  if pacman -T "$pkg" >/dev/null 2>&1; then
    return 0
  fi
  if [[ "$pkg" =~ -(bin|git)$ ]]; then
    local base_pkg="${pkg%-bin}"
    base_pkg="${base_pkg%-git}"
    if pacman -T "$base_pkg" >/dev/null 2>&1; then
      return 0
    fi
  fi
  return 1
}

# Helper function to install packages
install_packages() {
  local pkgs=("$@")
  local pacman_pkgs=()
  local aur_pkgs=()

  for pkg in "${pkgs[@]}"; do
    if is_pkg_installed "$pkg"; then
      info "Package $pkg is already satisfied -- skipping"
      continue
    fi

    # Check if package is AUR package (ends with -bin, -git, or matched)
    if [[ "$pkg" =~ -(bin|git)$ || "$pkg" == "matugen-bin" || "$pkg" == "vesktop-bin" ]]; then
      aur_pkgs+=("$pkg")
    else
      pacman_pkgs+=("$pkg")
    fi
  done

  # Install pacman packages
  if [ ${#pacman_pkgs[@]} -gt 0 ]; then
    info "Installing official packages: ${pacman_pkgs[*]}"
    sudo pacman -S --needed --noconfirm "${pacman_pkgs[@]}"
  fi

  # Install AUR packages
  if [ ${#aur_pkgs[@]} -gt 0 ]; then
    if [ -n "$AUR_HELPER" ]; then
      info "Installing AUR packages using $AUR_HELPER: ${aur_pkgs[*]}"
      $AUR_HELPER -S --needed --noconfirm "${aur_pkgs[@]}"
    else
      warn "Skipping AUR packages as no AUR helper is available: ${aur_pkgs[*]}"
    fi
  fi
}

# --- Category Selection ---
echo -e "\n${BOLD}=== Package Installation Categories ===${NC}"
ask "Install Core Utilities? (git, jq, rsync, curl, fastfetch, etc.) (Y/n): "
read -r sel_core
ask "Install Shell & Prompt? (fish, starship) (Y/n): "
read -r sel_shell
ask "Install Editors? (neovim) (Y/n): "
read -r sel_editor
ask "Install Desktop Environment & WM? (hyprland, kitty, quickshell, etc.) (Y/n): "
read -r sel_desktop

if command -v vesktop >/dev/null 2>&1; then
  info "Vesktop is already installed, skipping installation prompt."
  sel_vesktop="n"
else
  ask "Vesktop is not installed. Do you want to install it? (Y/n): "
  read -r sel_vesktop
fi

to_install=()

if [[ ! "$sel_core" =~ ^[Nn]$ ]]; then
  to_install+=("${core_packages[@]}" "${aur_core[@]}")
fi
if [[ ! "$sel_shell" =~ ^[Nn]$ ]]; then
  to_install+=("${shell_packages[@]}" "${aur_shell[@]}")
fi
if [[ ! "$sel_editor" =~ ^[Nn]$ ]]; then
  to_install+=("${editor_packages[@]}" "${aur_editor[@]}")
fi
if [[ ! "$sel_desktop" =~ ^[Nn]$ ]]; then
  to_install+=("${desktop_packages[@]}" "${aur_desktop[@]}")
fi
if [[ ! "$sel_vesktop" =~ ^[Nn]$ ]]; then
  to_install+=("vesktop-bin")
fi

if [ ${#to_install[@]} -gt 0 ]; then
  info "Starting package installation..."
  install_packages "${to_install[@]}"
  success "Package installation complete!"
else
  info "No packages selected for installation."
fi

# --- Configuration Symlinking ---
echo -e "\n${BOLD}=== Configuration Setup (Symlinking) ===${NC}"
ask "Do you want to symlink your configurations to ~/.config/? (Y/n): "
read -r setup_config

if [[ ! "$setup_config" =~ ^[Nn]$ ]]; then
  info "Setting up configurations..."
  mkdir -p "$DST_CONFIG"

  # Define standard configuration files/folders to link
  config_items=(
    "hypr"
    "fish"
    "kitty"
    "nvim"
    "fastfetch"
    "quickshell"
    "starship.toml"
    "vesktop/settings"
    "illogical-impulse"
  )

  backup_created=false

  for item in "${config_items[@]}"; do
    local_src="$SRC_CONFIG/$item"
    local_dst="$DST_CONFIG/$item"

    # Skip files or folders that aren't actually in source (safety guard)
    if [ ! -e "$local_src" ]; then
      continue
    fi

    info "Processing: $item"

    # Check if target destination already exists
    if [ -e "$local_dst" ] || [ -L "$local_dst" ]; then
      # If it's already a symlink pointing to our dotfiles, skip it
      if [ -L "$local_dst" ] && [ "$(readlink -f "$local_dst")" = "$(readlink -f "$local_src")" ]; then
        success "Already linked correctly: $item"
        continue
      fi

      # Otherwise, back it up if it's a real file/directory
      if [ ! -L "$local_dst" ]; then
        if [ "$backup_created" = false ]; then
          mkdir -p "$BACKUP_DIR"
          info "Creating backup directory for existing configs: $BACKUP_DIR"
          backup_created=true
        fi
        mkdir -p "$BACKUP_DIR/$(dirname "$item")"
        mv "$local_dst" "$BACKUP_DIR/$item"
        success "Backed up existing config: ~/.config/$item -> backup/$item"
      else
        # If it's an old/broken symlink, just remove it
        rm "$local_dst"
        info "Removed existing old symlink: ~/.config/$item"
      fi
    fi

    # Create parent folder if nested
    mkdir -p "$(dirname "$local_dst")"

    # Create the symlink
    ln -s "$local_src" "$local_dst"
    success "Linked: ~/.config/$item -> $local_src"
  done

  if [ "$backup_created" = true ]; then
    success "All existing configuration backups are stored at: $BACKUP_DIR"
  fi
  success "Configurations linked successfully!"1

  # Restart Vesktop to apply new settings
  if command -v vesktop >/dev/null 2>&1; then
    info "Restarting Vesktop to apply new configurations..."
    pkill -f vesktop || killall vesktop || true
    sleep 1.5
    if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
      vesktop >/dev/null 2>&1 &
      disown
      success "Vesktop restarted successfully!"
    else
      info "No display server detected. Vesktop will launch upon next desktop environment startup."
    fi
  fi
fi

# --- Default Shell Verification ---
if command -v fish >/dev/null 2>&1; then
  current_shell=$(basename "$SHELL")
  if [ "$current_shell" != "fish" ]; then
    echo -e "\n${BOLD}=== Shell Setup ===${NC}"
    ask "Would you like to set Fish as your default shell? (y/N): "
    read -r change_shell
    if [[ "$change_shell" =~ ^[Yy]$ ]]; then
      info "Changing default shell to fish..."
      if ! grep -q "$(which fish)" /etc/shells; then
        echo "$(which fish)" | sudo tee -a /etc/shells
      fi
      chsh -s "$(which fish)"
      success "Default shell changed to Fish. Please log out and back in to apply."
    fi
  fi
fi

echo -e "\n${GREEN}${BOLD}=== Setup Process Completed Successfully! ===${NC}"
echo -e "Enjoy your personalized, premium desktop environment! 🚀\n"

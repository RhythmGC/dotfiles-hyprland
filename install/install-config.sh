# Arch Linux Dotfiles Installer
# Designed to install packages and safely copy configurations.

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
info() { echo -e "${BLUE}${BOLD}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}${BOLD}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}${BOLD}[WARNING]${NC} $1"; }
error() {
  echo -e "${RED}${BOLD}[ERROR]${NC} $1"
  exit 1
}
ask() { echo -ne "${CYAN}${BOLD}[?]${NC} $1 "; }

# --- Banner ---
clear
echo -e "${MAGENTA}${BOLD}"
echo "  ██████╗ ██╗  ██╗██╗   ██╗████████╗██╗  ██╗███╗   ███╗ ██████╗  ██████╗"
echo "  ██╔══██╗██║  ██║╚██╗ ██╔╝╚══██╔══╝██║  ██║████╗ ████║██╔════╝ ██╔════╝"
echo "  ██████╔╝███████║ ╚████╔╝    ██║   ███████║██╔████╔██║██║  ███╗██║     "
echo "  ██╔══██╗██╔══██║  ╚██╔╝     ██║   ██╔══██║██║╚██╔╝██║██║   ██║██║     "
echo "  ██║  ██║██║  ██║   ██║      ██║   ██║  ██║██║ ╚═╝ ██║╚██████╔╝╚██████╗"
echo "  ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝"
echo -e "${CYAN}                 Arch Linux Installer & Config Copier${NC}"
echo -e "${BOLD}--------------------------------------------------------------------------${NC}\n"

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

# Get selected packages from packages.jsonl
get_selected_packages() {
  local source_type="$1"
  local cats=","
  if [[ ! "${sel_core:-y}" =~ ^[Nn]$ ]]; then cats+="core,"; fi
  if [[ ! "${sel_shell:-y}" =~ ^[Nn]$ ]]; then cats+="shell,"; fi
  if [[ ! "${sel_editor:-y}" =~ ^[Nn]$ ]]; then cats+="editor,"; fi
  if [[ ! "${sel_desktop:-y}" =~ ^[Nn]$ ]]; then cats+="desktop,"; fi
  if [[ ! "${sel_vesktop:-y}" =~ ^[Nn]$ ]]; then cats+="vesktop,"; fi

  if [ -f "$DOTFILES_DIR/packages.jsonl" ]; then
    jq -r --arg src "$source_type" --arg cats "$cats" \
      'select(.source == $src and ($cats | contains("," + .category + ","))) | .name' \
      "$DOTFILES_DIR/packages.jsonl"
  fi
}

# --- Category Selection ---
echo -e "\n${BOLD}=== Package Installation Categories ===${NC}"
ask "Install Core Utilities? (git, jq, rsync, curl, fastfetch, fnm, pyenv etc.) (Y/n): "
read -r sel_core
ask "Install Extra Utilities? (bun, pnpm, etc.) (Y/n): "
read -r sel_extra
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

# Query packages to install
pacman_pkgs=()
while IFS= read -r pkg; do
  if [ -n "$pkg" ]; then
    if is_pkg_installed "$pkg"; then
      info "Package $pkg is already satisfied -- skipping"
    else
      pacman_pkgs+=("$pkg")
    fi
  fi
done < <(get_selected_packages "pacman")

aur_pkgs=()
while IFS= read -r pkg; do
  if [ -n "$pkg" ]; then
    if is_pkg_installed "$pkg"; then
      info "Package $pkg is already satisfied -- skipping"
    else
      aur_pkgs+=("$pkg")
    fi
  fi
done < <(get_selected_packages "yay")

if [ ${#pacman_pkgs[@]} -gt 0 ] || [ ${#aur_pkgs[@]} -gt 0 ]; then
  info "Starting package installation..."
  
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

  if [[ ! "$sel_extra" =~ ^[Nn]$ ]]; then
    curl -fsSL https://bun.sh/install | bash
    curl -fsSL https://get.pnpm.io/install.sh | sh -
  fi
  success "Package installation complete!"
else
  info "No packages selected or all selected packages are already satisfied."
  if [[ ! "$sel_extra" =~ ^[Nn]$ ]]; then
    curl -fsSL https://bun.sh/install | bash
    curl -fsSL https://get.pnpm.io/install.sh | sh -
    success "Extra utilities installation complete!"
  fi
fi

# --- Ask for using my SDDM THEME ---
ask "Do you want to use my custom SDDM theme (I just support for Yuuka Hayase right now, you want to custom your theme then clone my repo https://github.com/RhythmGC/BlueArchive-SDDM-theme.git and follow my instruct to set your custom theme)? (Y/n): "
read -r use_sddm_theme

# --- Install SDDM Theme if user agrees ---
if [[ ! "$use_sddm_theme" =~ ^[Nn]$ ]]; then
  git clone https://github.com/RhythmGC/BlueArchive-SDDM-theme.git
  cd BlueArchive-SDDM-theme
  chmod +x ./setup.sh
  ./setup.sh
fi

# --- Configuration Copying ---
echo -e "\n${BOLD}=== Configuration Setup (Copying) ===${NC}"
ask "Do you want to copy your configurations to ~/.config/? (Y/n): "
read -r setup_config

if [[ ! "$setup_config" =~ ^[Nn]$ ]]; then
  info "Setting up configurations..."
  mkdir -p "$DST_CONFIG"

  # Load configuration files/folders to link from items.json
  json_file="$DOTFILES_DIR/Scripts/items.json"
  if [ ! -f "$json_file" ]; then
    error "Configuration items file not found: $json_file"
  fi

  if ! command -v jq >/dev/null 2>&1; then
    if command -v pacman >/dev/null 2>&1; then
      info "Installing jq to parse configuration items..."
      sudo pacman -S --needed --noconfirm jq
    else
      error "jq is not installed and package manager (pacman) was not found. Please install jq manually."
    fi
  fi

  mapfile -t config_items < <(jq -r '.[]' "$json_file")

  backup_created=false

  for item in "${config_items[@]}"; do
    item="${item%/}"
    local_src="$SRC_CONFIG/$item"
    local_dst="$DST_CONFIG/$item"

    # Skip files or folders that aren't actually in source (safety guard)
    if [ ! -e "$local_src" ]; then
      continue
    fi

    info "Processing: $item"

    # Check if target destination already exists
    if [ -e "$local_dst" ] || [ -L "$local_dst" ]; then
      # If it's a symlink, remove it (since we want a real copy now)
      if [ -L "$local_dst" ]; then
        rm "$local_dst"
        info "Removed existing symlink: ~/.config/$item"
      else
        # Otherwise, back it up if it's a real file/directory
        if [ "$backup_created" = false ]; then
          mkdir -p "$BACKUP_DIR"
          info "Creating backup directory for existing configs: $BACKUP_DIR"
          backup_created=true
        fi
        mkdir -p "$BACKUP_DIR/$(dirname "$item")"
        mv "$local_dst" "$BACKUP_DIR/$item"
        success "Backed up existing config: ~/.config/$item -> backup/$item"
      fi
    fi

    # Create parent folder if nested
    mkdir -p "$(dirname "$local_dst")"

    # Copy the item
    cp -a "$local_src" "$local_dst"
    success "Copied: ~/.config/$item <- $local_src"
  done

  if [ "$backup_created" = true ]; then
    success "All existing configuration backups are stored at: $BACKUP_DIR"
  fi
  success "Configurations copied successfully!"

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

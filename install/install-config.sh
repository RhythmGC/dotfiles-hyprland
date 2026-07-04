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

# --- Prevent Running as Root ---
if [ "$EUID" -eq 0 ]; then
  echo -e "\033[0;31m\033[1m[ERROR]\033[0;37m Please do NOT run this script as root or with sudo. The installer will prompt for privilege escalation (sudo) when executing commands that require it."
  exit 1
fi


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

# --- Ensure jq is Configured ---
if ! command -v jq >/dev/null 2>&1; then
  info "Installing jq..."
  sudo pacman -S --noconfirm jq
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
      '.category as $cat | select(.source == $src and ($cats | contains("," + $cat + ","))) | .name' \
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
  if [ -d "$DOTFILES_DIR/BlueArchive-SDDM-theme" ]; then
    info "Installing SDDM Theme from local folder..."
    (
      cd "$DOTFILES_DIR/BlueArchive-SDDM-theme"
      chmod +x ./setup.sh
      ./setup.sh
    )
  else
    info "Cloning and installing SDDM Theme..."
    (
      git clone https://github.com/RhythmGC/BlueArchive-SDDM-theme.git /tmp/BlueArchive-SDDM-theme
      cd /tmp/BlueArchive-SDDM-theme
      chmod +x ./setup.sh
      ./setup.sh
      cd ..
      rm -rf /tmp/BlueArchive-SDDM-theme
    )

  fi
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

  # --- KDE/Qt Theming Setup ---
  echo -e "\n${BOLD}=== KDE/Qt Theming Setup ===${NC}"

  # Install papirus-folders script (for dynamic folder icon recoloring)
  if ! command -v papirus-folders > /dev/null 2>&1; then
    info "Installing papirus-folders script (folder icon recoloring)..."
    sudo curl -fsSL https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders \
      -o /usr/local/bin/papirus-folders && sudo chmod +x /usr/local/bin/papirus-folders
    success "papirus-folders installed!"
  else
    info "papirus-folders already installed — skipping."
  fi

  # Add sudoers rule so papirus-folders can recolor icons without a password prompt
  if [ ! -f /etc/sudoers.d/papirus-folders ]; then
    info "Adding sudoers rule for papirus-folders (passwordless icon recoloring)..."
    echo "$USER ALL=(ALL) NOPASSWD: /usr/local/bin/papirus-folders" | sudo tee /etc/sudoers.d/papirus-folders > /dev/null
    sudo chmod 440 /etc/sudoers.d/papirus-folders
    success "Sudoers rule added: /etc/sudoers.d/papirus-folders"
  else
    info "Sudoers rule for papirus-folders already exists — skipping."
  fi

  # Set initial KDE theming: Papirus-Dark icon theme, Darkly widget style & color scheme
  if command -v kwriteconfig6 > /dev/null 2>&1; then
    info "Configuring initial KDE theming (Papirus-Dark icons, Darkly colors)..."
    kwriteconfig6 --file kdeglobals --group Icons   --key Theme       Papirus-Dark 2>/dev/null || true
    kwriteconfig6 --file kdeglobals --group KDE     --key widgetStyle Darkly       2>/dev/null || true
    kwriteconfig6 --file kdeglobals --group General --key ColorScheme Darkly        2>/dev/null || true
    success "KDE theming configured!"
  fi

  # Apply initial wallpaper-based colors (generates Darkly.colors + recolors Papirus folders)
  theme_script="$DST_CONFIG/quickshell/ii/scripts/colors/apply-gtk-theme.sh"
  if [ -f "$theme_script" ]; then
    info "Applying initial wallpaper-based theme colors..."
    bash "$theme_script" 2>/dev/null || true
    success "Initial theme applied!"
  fi

  # Initialize Quickshell virtual environment and Python dependencies
  venv_dir="$HOME/.local/state/quickshell/.venv"
  req_file="$DST_CONFIG/quickshell/ii/sdata/uv/requirements.txt"
  if [ -f "$req_file" ] && command -v uv > /dev/null 2>&1; then
    info "Setting up Quickshell Python virtual environment and dependencies..."
    mkdir -p "$(dirname "$venv_dir")"
    uv venv --prompt ii-venv "$venv_dir"
    uv pip install --python "$venv_dir" -r "$req_file"
    success "Quickshell virtual environment and Python dependencies initialized successfully!"
  fi

  # --- Clipboard: ensure wl-clipboard + cliphist are installed ---
  clipboard_pkgs=()
  if ! command -v wl-copy > /dev/null 2>&1; then
    clipboard_pkgs+=(wl-clipboard)
  fi
  if ! command -v cliphist > /dev/null 2>&1; then
    clipboard_pkgs+=(cliphist)
  fi
  if [ ${#clipboard_pkgs[@]} -gt 0 ]; then
    info "Installing clipboard tools: ${clipboard_pkgs[*]}"
    sudo pacman -S --needed --noconfirm "${clipboard_pkgs[@]}"
    success "Clipboard tools installed!"
  else
    info "Clipboard tools already installed — skipping."
  fi

  # --- Clipboard: set up systemd user services for cliphist daemons ---
  info "Setting up cliphist systemd user services..."
  mkdir -p "$HOME/.config/systemd/user"

  cat > "$HOME/.config/systemd/user/cliphist-text.service" << 'SVCEOF'
[Unit]
Description=Clipboard history manager (text) - cliphist
After=graphical-session.target

[Service]
ExecStart=/usr/bin/bash -c 'wl-paste --type text --watch bash -c "cliphist store && qs -c ii ipc call cliphistService update"'
Restart=on-failure
RestartSec=2s

[Install]
WantedBy=graphical-session.target
SVCEOF

  cat > "$HOME/.config/systemd/user/cliphist-image.service" << 'SVCEOF'
[Unit]
Description=Clipboard history manager (image) - cliphist
After=graphical-session.target

[Service]
ExecStart=/usr/bin/bash -c 'wl-paste --type image --watch bash -c "cliphist store && qs -c ii ipc call cliphistService update"'
Restart=on-failure
RestartSec=2s

[Install]
WantedBy=graphical-session.target
SVCEOF

  systemctl --user daemon-reload
  systemctl --user enable cliphist-text.service cliphist-image.service

  # --- ydotool: needed for clipboard paste-on-select feature ---
  if ! command -v ydotool > /dev/null 2>&1; then
    info "Installing ydotool (required for clipboard paste)..."
    sudo pacman -S --needed --noconfirm ydotool
    success "ydotool installed!"
  else
    info "ydotool already installed — skipping."
  fi

  # Add user to input group (required for ydotool to work)
  if ! groups | grep -q "\binput\b"; then
    info "Adding $USER to the 'input' group for ydotool..."
    sudo usermod -aG input "$USER"
    warn "Group change takes effect on next login."
  fi

  uid=$(id -u)
  cat > "$HOME/.config/systemd/user/ydotoold.service" << SVCEOF
[Unit]
Description=ydotoold - ydotool daemon
After=graphical-session.target

[Service]
ExecStart=/usr/bin/ydotoold --socket-path /run/user/${uid}/.ydotool_socket --socket-perm 0660
Restart=on-failure
RestartSec=2s

[Install]
WantedBy=graphical-session.target
SVCEOF

  systemctl --user daemon-reload
  systemctl --user enable ydotoold.service

  # Start daemons immediately if a Wayland session is active
  if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${XDG_RUNTIME_DIR:-}" ]; then
    systemctl --user restart cliphist-text.service cliphist-image.service ydotoold.service || true
    success "Clipboard history daemons started! Press Super+V to view history."
  else
    info "Clipboard daemons will auto-start on next graphical login (Super+V to open history)."
  fi

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

  # Copy Zen Browser extensions
  if [ -d "$HOME/.config/zen" ] && [ -d "$DOTFILES_DIR/install/zen-extensions" ]; then
    info "Installing Zen Browser extensions..."
    shopt -s nullglob
    for profile_dir in "$HOME/.config/zen/"*Default*/; do
      if [ -d "$profile_dir" ]; then
        mkdir -p "${profile_dir}extensions"
        cp "$DOTFILES_DIR/install/zen-extensions/"*.xpi "${profile_dir}extensions/"
        success "Copied extensions to profile: $(basename "$profile_dir")"
      fi
    done
    shopt -u nullglob
  fi

  # Create system CLI wrapper for ba
  info "Creating system CLI wrapper for 'ba'..."

  mkdir -p "$HOME/.local/bin"
  
  cat << 'EOF' > "$HOME/.local/bin/ba"
#!/usr/bin/env bash
export INIR_CMD=ba
exec "$HOME/.config/quickshell/ii/scripts/ba" "$@"
EOF
  chmod +x "$HOME/.local/bin/ba"

  success "CLI wrapper created: ~/.local/bin/ba"

  # --- Plasma Browser Integration: fix Wayland hangs outside Plasma ---
  if pacman -Qs plasma-browser-integration > /dev/null 2>&1; then
    info "Configuring plasma-browser-integration XCB wrapper..."
    mkdir -p "$HOME/.local/bin"
    cat << 'EOF' > "$HOME/.local/bin/plasma-browser-integration-host-wrapper"
#!/bin/bash
export QT_QPA_PLATFORM=xcb
exec /usr/bin/plasma-browser-integration-host "$@"
EOF
    chmod +x "$HOME/.local/bin/plasma-browser-integration-host-wrapper"

    # Setup user-level manifest
    mkdir -p "$HOME/.mozilla/native-messaging-hosts"
    cat << 'EOF' > "$HOME/.mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json"
{
    "name": "org.kde.plasma.browser_integration",
    "description": "Native connector for KDE Plasma",
    "path": "$HOME/.local/bin/plasma-browser-integration-host-wrapper",
    "type": "stdio",
    "allowed_extensions": [
        "plasma-browser-integration@kde.org"
    ]
}
EOF
    # Expand $HOME inside path
    sed -i "s|\$HOME|$HOME|g" "$HOME/.mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json"

    # Setup Zen Browser-specific manifest if installed
    if [ -d "/opt/zen-browser-bin" ]; then
      sudo mkdir -p /opt/zen-browser-bin/native-messaging-hosts
      sudo cp "$HOME/.mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json" \
        /opt/zen-browser-bin/native-messaging-hosts/org.kde.plasma.browser_integration.json
    fi
    success "plasma-browser-integration configured successfully!"
  fi

  # --- Brave Browser Policy Directory ---
  if command -v brave > /dev/null 2>&1 || pacman -Qs brave-bin > /dev/null 2>&1; then
    info "Setting up Brave browser policy directory..."
    sudo mkdir -p /etc/brave/policies/managed
    sudo chmod a+rw /etc/brave/policies/managed
    success "Brave policy directory configured: /etc/brave/policies/managed"
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

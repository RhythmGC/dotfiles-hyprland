# RhythmGC's Dotfiles

Welcome to my personal, premium **Arch Linux** dotfiles repository. This setup is crafted for maximum productivity, sleek aesthetics, and visual comfort, featuring a fluid tiling window manager, modern shells, highly optimized editors, and material-you styling.

---

## System Configuration Stack

This repository centralizes and tracks configurations for the following stack:

| Component | Software | Description |
| :--- | :--- | :--- |
| **Window Manager** | [Hyprland](https://hyprland.org/) | Dynamic tiling Wayland compositor with smooth physics-based animations. |
| **Shell & Prompt** | [Fish](https://fishshell.com/) + [Starship](https://starship.rs/) | Fast shell with smart auto-suggestions, paired with a custom prompt. |
| **Terminal Emulator** | [Kitty](https://sw.kovidgoyal.net/kitty/) | Fast, GPU-accelerated terminal emulator. |
| **Code Editor** | [Neovim](https://neovim.io/) | Premium, lightweight modal editor optimized for speed and coding. |
| **Widget & Panel** | [Quickshell](https://quickshell.uxam.org/) | Advanced, highly custom desktop widgets and bar layout using QML. |
| **Theme Manager** | [Matugen](https://github.com/InSyncWithYou/matugen) | Material-you color palette generator from wallpaper assets. |
| **Desktop Theme** | Illogical-Impulse | Personalized theme integration engine including KDE & GTK colors. |
| **Discord Client** | [Vesktop](https://github.com/Vencord/Vesktop) | Wayland-native Discord wrapper with Vencord plugin integration. |

---

## Repository Layout

```text
dotfiles/
├── .config/               # Tracked dotfiles synced across environments
│   ├── fastfetch/         # Fastfetch system info layout
│   ├── fish/              # Fish shell configuration files & aliases
│   ├── hypr/              # Hyprland window rules, binds, and variables
│   ├── illogical-impulse/ # Illogical-impulse theme system configuration
│   ├── kitty/             # Kitty terminal configuration & styling
│   ├── nvim/              # Neovim code editor configurations
│   ├── quickshell/        # Custom widgets, status bars, and applet QMLs
│   ├── starship.toml      # Universal Starship cross-shell prompt config
│   └── vesktop/           # Vesktop settings & Vencord styling
│
├── install/               # Arch Linux bootstrap and config installer
│   └── install-config.sh  # Interactive package installer and config copier
│
└── Scripts/
    ├── items.json         # Config paths managed by the helper scripts
    ├── link.sh            # Deploy configs as symlinks
    ├── removeLinks.sh     # Remove links and back up physical configs
    └── copyConfig.sh      # Sync local configs back to this repository
```

---

## Quick Start Guide

Ready to install this desktop environment on a new machine? The `install/` module handles package installation and safely copies the selected configs automatically.

### 1. Clone the Repository

```bash
git clone https://github.com/RhythmGC/dotfiles-hyprland.git ~/dotfiles-hyprland
```

### 2. Run the Installer

```bash
cd ~/dotfiles-hyprland
./install/install-config.sh
```

The installer targets Arch-based distributions. Existing configuration entries are moved to a timestamped backup directory before the repository copies are installed.

---

## Visual Aesthetics & Styling

This system utilizes **Matugen** to read colors from your active desktop wallpaper and dynamically compile theme definitions. These themes are subsequently applied to:

- Hyprland borders and active frame shadows.
- Custom QML quickshell panel widgets (battery, CPU, memory, clock, calendar, todo applet, etc.).
- GTK and KDE applications via custom Material-You CSS scripts in `illogical-impulse`.

---

## License & Acknowledgment

All configurations and scripts are open-source. Feel free to fork, modify, and integrate elements of these dotfiles into your own setup.

This dotfiles setup is currently based on [End-4's dots-hyprland](https://github.com/end-4/dots-hyprland) and [iNiR](https://github.com/snowarch/iNiR). If you find this setup useful, consider visiting the original repository and giving End-4 and Snowarch a star.

*Elevate your Linux desktop experience!*

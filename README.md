# BlueArchive — RhythmGC's Dotfiles

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
| **Desktop Theme** | BlueArchive | Personalized theme integration engine including KDE & GTK colors. |
| **Discord Client** | [Vesktop](https://github.com/Vencord/Vesktop) | Wayland-native Discord wrapper with Vencord plugin integration. |

---

## Repository Layout

```text
dotfiles/
├── .config/               # Tracked dotfiles synced across environments
│   ├── fastfetch/         # Fastfetch system info layout
│   ├── fish/              # Fish shell configuration files & aliases
│   ├── hypr/              # Hyprland window rules, binds, and variables
│   ├── baOS/              # BlueArchive user settings
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

For an existing desktop, preview and activate the renamed runtime with:

```bash
python3 install/activate-bluearchive.py
python3 install/activate-bluearchive.py --apply
```

Activation backs up existing files under `~/.local/state/ba/migration-backups/`,
preserves user settings, installs the `ba` launcher and Fish completions, and
restarts the shell using its current launch method. The runtime is `~/.config/quickshell/ba`, the shell ID is
`ba`, and settings live in `~/.config/baOS/config.json`. In an already open Fish
terminal, run `source ~/.config/fish/config.fish` to refresh its aliases.

Useful commands: `ba help`, `ba path`, `ba status`, `ba restart`,
`ba audio --help`, `ba theme list-targets`, and `ba completions fish`.
The Neovim `ba` colorscheme is bundled locally and follows generated wallpaper
colors. Old names remain only in migration inputs and historical/license records.

To reapply Kitty as KDE/Dolphin's external terminal without running the full
installer:

```bash
./install/setup-kitty-terminal.sh
```

This affects Dolphin's **Open Terminal** action (`Shift+F4`). The embedded `F4`
terminal panel is a KonsolePart feature and is separate from the default terminal.

---

## Visual Aesthetics & Styling

This system utilizes **Matugen** to read colors from your active desktop wallpaper and dynamically compile theme definitions. These themes are subsequently applied to:

- Hyprland borders and active frame shadows.
- Custom QML quickshell panel widgets (battery, CPU, memory, clock, calendar, todo applet, etc.).
- GTK and KDE applications via custom Material-You CSS scripts in `baOS`.

---

## License & Acknowledgment

All configurations and scripts are open-source. Feel free to fork, modify, and integrate elements of these dotfiles into your own setup.

BlueArchive is maintained by **RhythmGC**. Original third-party licenses and historical credits are preserved in the shell and bundled assets.

*Elevate your Linux desktop experience!*

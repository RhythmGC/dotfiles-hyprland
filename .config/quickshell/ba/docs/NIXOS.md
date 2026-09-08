# NixOS

> Experimental. The Arch installer is still the primary supported path.

BlueArchive provides a flake with:

| Output | Purpose |
|---|---|
| `packages.<system>.default` | Packaged BlueArchive runtime and `ba` launcher |
| `nixosModules.ba` | NixOS module for system package + user service |
| `homeModules.ba` | Home Manager module for user package + user service |

The module does not run `./setup install` or `./setup update`. Nix owns the installed files, and BlueArchive runs from the package store path.

## With niri-flake

Add both flakes:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    niri.url = "github:sodiboo/niri-flake";
    ba.url = "github:RhythmGC/dotfiles-hyprland";
  };
}
```

Then import both modules in your NixOS configuration:

```nix
{ config, inputs, ... }: {
  imports = [
    inputs.niri.nixosModules.niri
    inputs.ba.nixosModules.ba
  ];

  programs.niri.enable = true;

  programs.ba = {
    enable = true;
    service.compositor = "niri";
    extraPackages = [ config.programs.niri.package ];
  };
}
```

`programs.ba.service.compositor = "niri"` creates the user unit wiring under `niri.service.wants/ba.service`. It does not wire BlueArchive to `graphical-session.target`, so it will not auto-start under KDE, GNOME, or other desktop sessions.

`extraPackages = [ config.programs.niri.package ];` puts the same `niri` client binary used by your compositor on BlueArchive's runtime `PATH`, so features that call `niri msg` use the matching package.

For useful default shortcuts, merge BlueArchive actions into `programs.niri.settings.binds`:

```nix
{
  programs.niri.settings.binds = {
    "Mod+Space" = {
      repeat = false;
      action.spawn = [ "ba" "overview" "toggle" ];
    };

    "Mod+V".action.spawn = [ "ba" "clipboard" "toggle" ];
    "Mod+Comma".action.spawn = [ "ba" "settings" ];
    "Mod+Slash".action.spawn = [ "ba" "cheatsheet" "toggle" ];
    "Mod+Shift+W".action.spawn = [ "ba" "panelFamily" "cycle" ];

    "Mod+Alt+L" = {
      allow-when-locked = true;
      action.spawn = [ "ba" "lock" "activate" ];
    };

    "Mod+Shift+S".action.spawn = [ "ba" "region" "screenshot" ];
    "Mod+Shift+X".action.spawn = [ "ba" "region" "ocr" ];
    "Mod+Shift+A".action.spawn = [ "ba" "region" "search" ];
  };
}
```

## Home Manager

If you manage your user session with Home Manager, import the Home Manager module instead:

```nix
{ inputs, ... }: {
  imports = [
    inputs.ba.homeModules.ba
  ];

  programs.ba = {
    enable = true;
    service.compositor = "niri";
  };
}
```

The Home Manager module can also expose the packaged runtime at:

```text
~/.config/quickshell/ba
```

That symlink keeps tools that expect the traditional config path working, but it is opt-in because it will conflict with an existing repo checkout at the same path. Enable it with:

```nix
programs.ba.configSymlink.enable = true;
```

## Hyprland

Hyprland users can wire the service to the UWSM unit:

```nix
programs.ba.service.compositor = "hyprland";
```

This creates `wayland-wm@Hyprland.service.wants/ba.service`.

## Manual service wiring

To create the service but avoid auto-start wiring:

```nix
programs.ba.service.compositor = null;
```

Then start it manually:

```bash
systemctl --user start ba.service
```

## Notes

- Use `ba logs --full` for runtime errors.
- The packaged `ba` launcher wraps Quickshell and runtime tools in `PATH`.
- User preferences still live in BlueArchive's normal config/state files; the packaged QML source itself is immutable.
- `ba update` is not the right update path for a Nix install. Update through your flake inputs and rebuild.

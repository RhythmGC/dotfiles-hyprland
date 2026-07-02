-- Environment variables for Hyprland (Lua version)
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")
end)

-- NVIDIA Explicit Sync crash workarounds (prevents eglDupNativeFenceFDANDROID crash on Aquamarine)
hl.env("AQ_MGPU_NO_EXPLICIT", "1")
hl.env("AQ_NO_MODIFIERS", "1")

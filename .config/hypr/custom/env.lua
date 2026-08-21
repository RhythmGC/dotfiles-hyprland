-- Environment variables for Hyprland (Lua version)
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Keep Vietnamese regional settings, but render weekday/month names in English.
hl.env("LC_TIME", "en_US.UTF-8")

hl.on("hyprland.start", function ()
    hl.exec_cmd("$HOME/.config/hypr/hyprland/scripts/sync-xdg-desktop-portals.sh")
end)

-- NVIDIA Explicit Sync crash workarounds (prevents eglDupNativeFenceFDANDROID crash on Aquamarine)
-- hl.env("AQ_MGPU_NO_EXPLICIT", "1")
-- hl.env("AQ_NO_MODIFIERS", "1")

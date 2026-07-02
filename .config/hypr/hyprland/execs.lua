-- put former exec-once commands inside the func and former exec commands outside
local function exec_once(cmd, check_proc, use_full_cmdline)
    check_proc = check_proc or cmd:match("^([^ ]+)")
    local pgrep_opt = use_full_cmdline and "-f" or "-x"
    local handle = io.popen("pgrep " .. pgrep_opt .. " " .. check_proc .. " >/dev/null && echo 'running' || echo ''")
    local result = handle:read("*a")
    handle:close()
    if not result:find("running") then
        hl.exec_cmd(cmd)
    end
end

-- Bar, wallpaper
hl.exec_cmd("$HOME/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")
exec_once("qs -c ii", "qs")
hl.exec_cmd("$HOME/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")

-- Core components (authentication, lock screen, notification daemon)
exec_once("gnome-keyring-daemon --start --components=secrets", "gnome-keyring-daemon")
exec_once("hypridle", "hypridle")
hl.exec_cmd("dbus-update-activation-environment --all")
hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user restart xdg-desktop-portal")

-- Audio
exec_once("easyeffects --hide-window --service-mode", "easyeffects")

-- Clipboard: history
exec_once("wl-paste --type text --watch bash -c 'cliphist store && qs -c ii ipc call cliphistService update'", "\"[w]l-paste --type text\"", true)
exec_once("wl-paste --type image --watch bash -c 'cliphist store && qs -c ii ipc call cliphistService update'", "\"[w]l-paste --type image\"", true)

-- Cursor
hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")

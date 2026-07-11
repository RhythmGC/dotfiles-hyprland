hl.window_rule({ match = { class = ".*[Ss]potify.*" }, no_initial_focus = true })
hl.window_rule({ match = { class = ".*com\\.spotify\\.Client.*" }, no_initial_focus = true })

-- Custom opacity settings for Kitty terminal (Values: 0.0 to 1.0)
local kitty_active_opacity = 1.0      -- Opacity of Kitty when focused
local kitty_inactive_opacity = 0.8    -- Opacity of Kitty when unfocused

hl.window_rule({ match = { class = "^(kitty)$" }, opacity = kitty_active_opacity .. " " .. kitty_inactive_opacity })

hl.window_rule({ match = { class = "^(steam_app).*" }, tile = true })

hl.on("window.active", function(w)
    if w ~= nil and w.class ~= nil and string.match(w.class, "^steam_app_") then
        hl.exec_cmd("bash ~/.config/hypr/custom/scripts/game_focus_fix.sh &")
    end
end)




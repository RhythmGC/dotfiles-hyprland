hl.window_rule({ match = { class = ".*[Ss]potify.*" }, no_initial_focus = true })
hl.window_rule({ match = { class = ".*com\\.spotify\\.Client.*" }, no_initial_focus = true })

-- Custom opacity settings for Kitty terminal (Values: 0.0 to 1.0)
local kitty_active_opacity = 1.0      -- Opacity of Kitty when focused
local kitty_inactive_opacity = 0.8    -- Opacity of Kitty when unfocused

hl.window_rule({ match = { class = "^(kitty)$" }, opacity = kitty_active_opacity .. " " .. kitty_inactive_opacity })

hl.window_rule({ match = { class = "^(steam_app).*" }, tile = true })

-- Keep the Arknights game rendering when its workspace is not visible.
-- Matching initial_title excludes the launcher, whose class is identical.
hl.window_rule({
	match = {
		class = "^steam_app_3417883729$",
		initial_title = "^Arknights$",
	},
	render_unfocused = true,
})

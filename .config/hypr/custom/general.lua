-- Global opacity settings (Values: 0.0 to 1.0)
local opt_active_opacity = 1.0 -- Opacity of the focused window
local opt_inactive_opacity = 1.0 -- Opacity of unfocused windows (1.0 = fully opaque)
local opt_fullscreen_opacity = 1.1 -- Opacity of fullscreen windows

-- Mouse sensitivity settings (Values: -1.0 to 1.0)
local mouse_sensitivity = -0.3 -- Speed of the mouse cursor (0.0 = default)
local mouse_force_no_accel = false -- Disable mouse acceleration (true/false)
local mouse_accel_profile = "flat" -- Acceleration profile ("flat" or "adaptive")

hl.config({
	input = {
		accel_profile = mouse_accel_profile,
		force_no_accel = mouse_force_no_accel,
		sensitivity = mouse_sensitivity,
	},
	general = {
		border_size = 2,
		col = {
			active_border = {
				colors = { "rgba(0DB7D4ff)", "rgba(50E3C2ff)" },
				angle = 45,
			},
			inactive_border = "rgba(31313600)",
		},
	},
	decoration = {
		active_opacity = opt_active_opacity,
		inactive_opacity = opt_inactive_opacity,
		fullscreen_opacity = opt_fullscreen_opacity,
		blur = {
			enabled = false,
			size = 0,
			passes = 1,
			new_optimizations = true,
			xray = false,
			noise = 0.01,
			contrast = 1.15,
			brightness = 1,
			special = false,
			popups = true,
		},
		dim_inactive = true,
		dim_strength = 0.1,
	},
	misc = {
		focus_on_activate = false,
	},
})

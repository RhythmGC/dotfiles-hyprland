hl.config({
    input = {
        accel_profile = "flat",
        force_no_accel = false,
        sensitivity = -0.6,
    },
    general = {
        border_size = 2,
        col = {
            active_border = {
                colors = { "rgba(0DB7D4ff)", "rgba(50E3C2ff)" },
                angle = 45
            },
            inactive_border = "rgba(31313600)"
        }
    },
    decoration = {
        active_opacity = 1.0,
        inactive_opacity = 0.9,
        blur = {
            enabled = true,
            size = 8,
            passes = 4,
            popups = true,
        },
        dim_inactive = true,
        dim_strength = 0.1,
    }
})

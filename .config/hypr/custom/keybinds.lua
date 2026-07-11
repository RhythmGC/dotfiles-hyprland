hl.bind(
	"CTRL+SUPER+ALT+Slash",
	hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"),
	{ description = "Edit user keybinds" }
)
hl.bind("SUPER+x", hl.dsp.exec_cmd("vesktop"), { description = "Open Vesktop" })

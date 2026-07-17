hl.on("hyprland.start", function()
	local function exec_once(cmd, check_proc)
		check_proc = check_proc or cmd:match("^([^ ]+)")
		local handle = io.popen("/usr/bin/pgrep -x " .. check_proc .. " >/dev/null && echo 'running' || echo ''")
		local result = handle:read("*a")
		handle:close()
		local is_running = result:find("running") ~= nil
		if not is_running then
			hl.exec_cmd(cmd)
		end
	end

	exec_once("sleep 2 && ba run", "qs")

	-- Start clipboard and ydotool services
	hl.exec_cmd("systemctl --user start cliphist-text.service cliphist-image.service ydotoold.service")

	-- Custom auto-start apps
	exec_once("9router -d", "9router")
	exec_once("fcitx5 -d", "fcitx5")
	exec_once("spotify --minimized", "spotify")
	exec_once("sleep 5 && env XDG_CURRENT_DESKTOP=Unity vesktop", "vesktop")
	exec_once("steam -silent", "steam")
end)

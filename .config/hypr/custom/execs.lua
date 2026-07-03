local function exec_once(cmd, check_proc)
	check_proc = check_proc or cmd:match("^([^ ]+)")
	local handle = io.popen("pgrep -f " .. check_proc .. " >/dev/null && echo 'running' || echo ''")
	local result = handle:read("*a")
	handle:close()
	if not result:find("running") then
		hl.exec_cmd(cmd)
	end
end

exec_once("9router -d", "9router")

-- Custom auto-start apps
exec_once("fcitx5 -d", "fcitx5")
exec_once("com.spotify.Client --minimized", "spotify")
exec_once("sleep 5 && vesktop", "vesktop")
exec_once("steam -silent", "steam")

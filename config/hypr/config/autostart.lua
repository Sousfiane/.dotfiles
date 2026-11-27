-- Each in uwsm's slice for what it is: -s s (session) for the shell, which the session needs (bar, lock
-- screen); -s b (background) for daemons. Apps opened later go to the default app slice.
-- hypridle and the polkit agent are user services (install/steps/services.sh).
-- On NVIDIA, Quickshell is shown only NVIDIA's EGL driver: otherwise it also loads Mesa's (and LLVM),
-- unused (~10 MB)
local function shell_cmd()
	local nvidia = "/usr/share/glvnd/egl_vendor.d/10_nvidia.json"
	local f = io.open(nvidia)
	local loaded = io.open("/proc/driver/nvidia/version")
	if f and loaded then
		f:close()
		loaded:close()
		return "uwsm-app -s s -- env __EGL_VENDOR_LIBRARY_FILENAMES=" .. nvidia .. " qs"
	end
	if f then
		f:close()
	end
	if loaded then
		loaded:close()
	end
	return "uwsm-app -s s -- qs"
end

hl.on("hyprland.start", function()
	hl.exec_cmd(shell_cmd())
	hl.exec_cmd("uwsm-app -s b -- wl-paste --watch clipvault store")
	hl.exec_cmd("uwsm-app -s b -- bt-agent")
	hl.exec_cmd("uwsm-app -s b -- easyeffects --service-mode -w")

	-- the plugins (plugins.lua), once hyprpm has them; at the first login it doesn't yet, since hyprpm builds
	-- them for the running Hyprland: a terminal runs install.sh's plugins step (it asks for sudo)
	local user = os.getenv("USER") or ""
	local state = io.open("/var/cache/hyprpm/" .. user .. "/hyprland-plugins/state.toml")
	if state then
		state:close()
		hl.exec_cmd("hyprpm reload -n") -- -n: a notification when a plugin fails to load
	else
		hl.exec_cmd("uwsm-app -- kitty --hold -e " .. os.getenv("HOME") .. "/.dotfiles/install/install.sh plugins")
	end
end)

-- The login screen's compositor: greetd runs this Hyprland as the `greeter` user (config.toml), with the
-- desktop's monitors and keyboard (monitors.lua and input.lua, copies install/steps/greeter.sh puts next to
-- this file) and the Quickshell greeter (../quickshell/shell.qml). Once the greeter has handed the session
-- to greetd it quits, and this Hyprland exits with it, so greetd can start the session.

-- this file's folder (/etc/greetd/hypr), so the copies are found wherever it is installed or tested
local here = debug.getinfo(1, "S").source:match("^@(.*/)") or "/etc/greetd/hypr/"
package.path = here .. "?.lua;" .. package.path

require("monitors")
require("input")

hl.config({
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
	},

	animations = {
		enabled = false,
	},
})

hl.on("hyprland.start", function()
	hl.exec_cmd("qs -p " .. here .. "../quickshell/shell.qml; hyprctl dispatch 'hl.dsp.exit()'")
end)

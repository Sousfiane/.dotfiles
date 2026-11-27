-- The login screen's compositor: greetd runs this Hyprland as the `greeter` user (/etc/greetd/config.toml,
-- written by install/steps/greeter.sh), with the desktop's own monitors and keyboard (config/monitors.lua and
-- config/input.lua) and the Quickshell greeter (~/.config/quickshell/greeter.qml). Once the greeter has handed
-- the session to greetd it quits, and this Hyprland exits with it, so greetd can start the session.
--
-- $HOME here is the greeter's: the user's home is QS_GREETER_HOME, which greetd's config sets.

local home = os.getenv("QS_GREETER_HOME") or os.getenv("HOME")
package.path = home .. "/.config/hypr/?.lua;" .. package.path

require("config.monitors")
require("config.input")

hl.config({
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
	},

	animations = {
		enabled = false,
	},
})

-- the home's owner logs in
local owner = io.popen("stat -c %U '" .. home .. "'")
local user = owner and owner:read("*l") or ""
if owner then
	owner:close()
end

-- The greeter quits cleanly only once someone has logged in: that's marked for greetd's login-screen script
-- (/etc/greetd/login-screen, written by install/steps/greeter.sh), which counts anything else as a failure and
-- falls back to a text login after a few in a row
hl.on("hyprland.start", function()
	hl.exec_cmd(
		"QS_GREETER_HOME='" .. home .. "' QS_GREETER_USER='" .. user .. "' qs -p '" .. home
			.. "/.config/quickshell/greeter.qml' && touch /tmp/qs-greeter-ok; hyprctl dispatch 'hl.dsp.exit()'"
	)
end)

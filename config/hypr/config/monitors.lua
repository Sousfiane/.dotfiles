-- The screens, matched by their name (make, model, serial: `hyprctl monitors all`), not by the port they're
-- on: a cable moved to another port keeps its settings. The greeter uses this file too (greeter.lua).
--
-- The TV is off unless turned on: SUPER + T (bindings.lua) or the hub's TV toggle, both toggle_tv() below.
-- On, it's left of the ASUS, in the room kept for it. Whether it's on is kept in
-- ~/.local/state/hypr/tv ("on" or "off"), so a reload (a theme change runs one) leaves it as it was; the
-- hub's toggle reads the same file. The greeter's home has none: at the login screen the TV is off.

local M = {}

local TV = "desc:Technical Concepts Ltd Beyond TV 0x00010000"
local ASUS = "desc:ASUSTek COMPUTER INC VG259QR M5LMQS094202"
local IIYAMA = "desc:iiyama Corporation PL2488H 0"

local STATE = os.getenv("HOME") .. "/.local/state/hypr/tv"

local function tv_wanted()
	local file = io.open(STATE, "r")
	if file == nil then
		return false
	end
	local value = file:read("*l")
	file:close()
	return value == "on"
end

local function save(on)
	local file = io.open(STATE, "w")
	if file == nil then
		os.execute("mkdir -p '" .. STATE:match("(.*)/") .. "'")
		file = io.open(STATE, "w")
	end
	if file ~= nil then
		file:write(on and "on\n" or "off\n")
		file:close()
	end
end

-- The TV's rule, on or off. Only the TV's: the other screens keep their place either way (the TV's room on
-- the left is left empty while it's off), since a screen whose rule changes is set up again, and blinks.
-- The TV at scale 2 takes the room of a 1080p screen.
local function apply_tv(tv)
	if tv then
		-- disabled = false said outright: a rule leaves out what it doesn't set, and the TV's off rule set it.
		-- Its preferred mode is 4K at 60 Hz. It lists 4K at 120 Hz too, but its EDID's range limits (75 Hz,
		-- 600 MHz) contradict it, so the NVIDIA driver leaves that mode out; a mode not offered is forced by
		-- Hyprland, and the TV stays black. "3840x2160@120" here once the driver offers it.
		hl.monitor({ output = TV, mode = "preferred", position = "0x0", scale = 2, disabled = false })
	else
		-- without this, Hyprland would turn it on like any other screen plugged in
		hl.monitor({ output = TV, disabled = true })
	end
end

function M.toggle_tv()
	local on = not tv_wanted()
	save(on)
	apply_tv(on)
	hl.dispatch(hl.dsp.exec_cmd(on and "notify-send -a Display 'TV on'" or "notify-send -a Display 'TV off'"))
end

-- any screen not named here (another machine's, a new one): its preferred mode, placed and scaled by
-- Hyprland, as in Hyprland's own default config
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.monitor({ output = ASUS, mode = "1920x1080@165", position = "1920x0", scale = 1 })
hl.monitor({ output = IIYAMA, mode = "1920x1080@60", position = "3840x0", scale = 1 })
apply_tv(tv_wanted())

return M

-- The screens, matched by their name (make, model, serial: `hyprctl monitors all`), not by the port they're
-- on: a cable moved to another port keeps its settings. The greeter uses this file too (greeter.lua).
--
-- The TV is off unless turned on: SUPER + T (bindings.lua) or the hub's TV toggle, both toggle_tv() below.
-- On, it's left of the ASUS, which moves right to make room. Whether it's on is kept in
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

-- the TV's fastest 4K mode, up to 120 Hz, among those it offers. Asked for a mode it doesn't offer, Hyprland
-- would force it and the TV would stay black: 4K at 120 Hz is only offered once the TV's HDMI input is in
-- its HDMI 2.1 mode (60 Hz before). Its preferred mode when it isn't plugged in, or not seen yet.
local function tv_mode()
	local best
	for _, m in ipairs(hl.get_monitors({ all = true })) do
		if "desc:" .. m.description == TV then
			for _, mode in ipairs(m.available_modes) do
				if mode.width == 3840 and mode.height == 2160 and mode.refresh_rate <= 120.5 then
					if best == nil or mode.refresh_rate > best then
						best = mode.refresh_rate
					end
				end
			end
		end
	end
	return best and ("3840x2160@%.2f"):format(best) or "preferred"
end

-- every screen's rule, with the TV on or off. The TV at scale 2 takes the room of a 1080p screen
local function apply(tv)
	local x = tv and 1920 or 0
	hl.monitor({ output = ASUS, mode = "1920x1080@165", position = x .. "x0", scale = 1 })
	hl.monitor({ output = IIYAMA, mode = "1920x1080@60", position = (x + 1920) .. "x0", scale = 1 })
	if tv then
		-- disabled = false said outright: a rule leaves out what it doesn't set, and the TV's off rule set it
		hl.monitor({ output = TV, mode = tv_mode(), position = "0x0", scale = 2, disabled = false })
	else
		-- without this, Hyprland would turn it on like any other screen plugged in
		hl.monitor({ output = TV, disabled = true })
	end
end

function M.toggle_tv()
	local on = not tv_wanted()
	save(on)
	apply(on)
	hl.dispatch(hl.dsp.exec_cmd(on and "notify-send -a Display 'TV on'" or "notify-send -a Display 'TV off'"))
end

-- any screen not named here (another machine's, a new one): its preferred mode, placed and scaled by
-- Hyprland, as in Hyprland's own default config
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

apply(tv_wanted())

return M

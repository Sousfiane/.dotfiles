-- The system theme, from the merged theme (~/.local/state/theme/current.json: theme.json in config/theme,
-- the fonts picked and the current palette, put together by merge.sh), which quickshell, kitty, Neovim and
-- tmux read too. Hyprland reads it on start and on `hyprctl reload`.
--
--   local theme = require("config.theme")
--   theme.colors.muted              "#6e6a86"
--   theme.rgb("muted")              "rgb(6e6a86)"
--   theme.rgba("base", 0.8)         "rgba(191724cc)"
--   theme.radius.medium, theme.font.mono, theme.opacity.terminal

local json = require("config.json")

local dir = os.getenv("HOME") .. "/.config/theme"
local current = os.getenv("HOME") .. "/.local/state/theme/current.json"

local function read(path)
	local file = assert(io.open(path, "r"), "theme: can't open " .. path)
	local value = json.decode(file:read("*a"))
	file:close()
	return value
end

-- the merged theme: written first by merge.sh if it isn't there yet (a new machine)
do
	local file = io.open(current, "r")
	if file then
		file:close()
	else
		os.execute("'" .. dir .. "/merge.sh'")
	end
end
local theme = read(current)

-- a palette colour's hex digits, without the "#"
local function hex(name)
	local value = theme.colors[name]
	if not value then
		error("theme: no colour named '" .. tostring(name) .. "'", 3)
	end
	return value:sub(2)
end

function theme.rgb(name)
	return "rgb(" .. hex(name) .. ")"
end

-- `name` with opacity `alpha` (0..1)
function theme.rgba(name, alpha)
	return ("rgba(%s%02x)"):format(hex(name), math.floor(alpha * 255 + 0.5))
end

return theme

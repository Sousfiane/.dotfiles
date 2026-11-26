-- The system theme, read from ~/.config/theme/theme.json and the current palette (config/theme in the
-- dotfiles; the current one is named in ~/.local/state/theme/palette, the fonts picked in fonts.json next to it), which quickshell, kitty, Neovim and tmux read too. Hyprland reads it on start and on `hyprctl reload`.
--
--   local theme = require("config.theme")
--   theme.colors.muted              "#6e6a86"
--   theme.rgb("muted")              "rgb(6e6a86)"
--   theme.rgba("base", 0.8)         "rgba(191724cc)"
--   theme.radius.medium, theme.font.mono, theme.opacity.terminal

local json = require("config.json")

local dir = os.getenv("HOME") .. "/.config/theme"

local function read(path)
	local file = assert(io.open(path, "r"), "theme: can't open " .. path)
	local value = json.decode(file:read("*a"))
	file:close()
	return value
end

-- the current palette: ~/.local/state/theme/palette (out of the repo, written by `theme`), or the settings'
-- default
local function current_palette(default)
	local file = io.open(os.getenv("HOME") .. "/.local/state/theme/palette", "r")
	if not file then
		return default
	end
	local name = (file:read("*l") or ""):match("^%s*(.-)%s*$")
	file:close()
	return name ~= "" and name or default
end

-- the settings, with the current palette on top (its colors, name, dark, gtk...)
local theme = read(dir .. "/theme.json")

-- the fonts picked in the theme picker (~/.local/state/theme/fonts.json, written by `theme font`) over the
-- settings' (one that doesn't parse is ignored)
do
	local file = io.open(os.getenv("HOME") .. "/.local/state/theme/fonts.json", "r")
	if file then
		local ok, fonts = pcall(json.decode, file:read("*a"))
		file:close()
		if ok and type(fonts) == "table" then
			for key, value in pairs(fonts) do
				theme.font[key] = value
			end
		end
	end
end
theme.palette = current_palette(theme.palette)
for key, value in pairs(read(dir .. "/palettes/" .. theme.palette .. ".json")) do
	theme[key] = value
end

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

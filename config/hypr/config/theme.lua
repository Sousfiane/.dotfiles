-- The system theme, read from ~/.config/theme/theme.json (config/theme/theme.json in the dotfiles), which
-- quickshell and kitty read too. Hyprland reads it on start and on `hyprctl reload`.
--
--   local theme = require("config.theme")
--   theme.colors.muted              "#6e6a86"
--   theme.rgb("muted")              "rgb(6e6a86)"
--   theme.rgba("base", 0.8)         "rgba(191724cc)"
--   theme.radius.medium, theme.font.mono, theme.opacity.terminal

local json = require("config.json")

local path = os.getenv("HOME") .. "/.config/theme/theme.json"
local file = assert(io.open(path, "r"), "theme: can't open " .. path)
local theme = json.decode(file:read("*a"))
file:close()

-- a palette colour's hex digits, without the "#"
local function hex(name)
	local value = theme.colors[name]
	if not value then error("theme: no colour named '" .. tostring(name) .. "'", 3) end
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

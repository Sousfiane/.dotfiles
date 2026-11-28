-- An app opening again where it was, without a sound: while held, a rule sends the windows of `class` to
-- workspace `ws`, silently (the workspace shown stays as it is) and without the focus. The theme's restarts
-- use it (config/theme/reopen.sh: Zen, Spotify, Nautilus closed and opened again for a new palette), through
--   hyprctl dispatch 'function() require("config.reopen").hold("zen", 2) end'
-- and release it once the app is back. A config reload drops every rule held.
local M = {}

M.rules = {}

-- a class as a regex matching it alone (org.gnome.Nautilus: its dots taken as dots)
local function exactly(class)
	return "^(" .. class:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?%{%}|\\]", "\\%0") .. ")$"
end

function M.hold(class, ws)
	M.release(class)
	M.rules[class] = hl.window_rule({
		name = "reopen-" .. class,
		match = { class = exactly(class) },
		workspace = tostring(ws) .. " silent",
		no_initial_focus = true,
	})
end

function M.release(class)
	local rule = M.rules[class]
	if rule then
		rule:set_enabled(false)
		M.rules[class] = nil
	end
end

return M

-- Floating: toggles the active window between tiled and floating; a window that floats is sized 875x600 and centred.
-- Toggled from SUPER + SHIFT + F (bindings.lua) and the foam dot on the title bar (plugins.lua); float() is also what
-- Quickshell's fullscreen title bar runs to take a window out of fullscreen into a floating one. The size is also
-- what the windows that always float open at (rules.lua).
local M = {}

M.size = { x = 875, y = 600 }

-- sized and centred, once it floats
local function place(w)
	hl.dispatch(hl.dsp.window.resize({ x = M.size.x, y = M.size.y, window = w }))
	hl.dispatch(hl.dsp.window.center({ window = w }))
end

-- makes `w` float (whatever it was), sized and centred
function M.float(w)
	hl.dispatch(hl.dsp.window.float({ window = w, action = "enable" }))
	place(w)
end

function M.toggle()
	local active = hl.get_active_window()
	if active == nil then
		return
	end
	hl.dispatch(hl.dsp.window.float({ window = active }))
	if active.floating then
		place(active)
	end
end

return M

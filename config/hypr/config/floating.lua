-- Floating: toggles the active window between tiled and floating; a window that floats is sized 875x600 and centred.
-- Toggled from SUPER + SHIFT + F (bindings.lua) and the foam dot on the title bar (plugins.lua).
local M = {}

function M.toggle()
	local active = hl.get_active_window()
	if active == nil then
		return
	end
	hl.dispatch(hl.dsp.window.float({ window = active }))
	if active.floating then
		hl.dispatch(hl.dsp.window.resize({ x = 875, y = 600, window = active }))
		hl.dispatch(hl.dsp.window.center({ window = active }))
	end
end

return M

-- Popout (picture-in-picture): a small floating window, pinned on every workspace, on top.
-- Toggled from SUPER + P (bindings.lua) and the iris dot on the title bar (plugins.lua).
local M = {}

function M.toggle()
	local active = hl.get_active_window()
	if active == nil then
		return
	end
	if active.pinned then
		hl.dispatch(hl.dsp.window.pin({ window = active }))
		hl.dispatch(hl.dsp.window.float({ window = active }))
		hl.dispatch(hl.dsp.window.clear_tags({ window = active }))
	else
		hl.dispatch(hl.dsp.window.float({ window = active }))
		hl.dispatch(hl.dsp.window.resize({ x = 640, y = 360, window = active }))
		hl.dispatch(hl.dsp.window.center({ window = active }))
		hl.dispatch(hl.dsp.window.pin({ window = active }))
		hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = active }))
		hl.dispatch(hl.dsp.window.tag({ tag = "pop", window = active }))
	end
end

return M

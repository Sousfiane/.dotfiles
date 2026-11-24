import Quickshell
import qs.config
import qs.services
import qs.components.ui

// Mouse way out of fullscreen: the window's title bar is hidden then, but touching the top edge
// still slides this bar down. Only exists while this monitor shows a fullscreen window.
BarButton {
    visible: Fullscreen.on(screenName)
    icon: Icons.fullscreenExit

    // the fullscreen window of this monitor, not the focused one (focus may be on another monitor)
    onClicked: Quickshell.execDetached(["hyprctl", "eval",
        `local ws = hl.get_active_workspace("${screenName}")
         if ws ~= nil and ws.fullscreen_window ~= nil then
             hl.dispatch(hl.dsp.window.fullscreen({ window = ws.fullscreen_window }))
         end`])
}

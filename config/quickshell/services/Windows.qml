pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.config

// Hyprland windows: what app a window is, and acting on one (the dock, the workspace cards, the
// notifications going to their app).
Singleton {
    // a window's app id (Wayland) or class (XWayland), "" when unknown
    function windowClass(w) {
        return w.wayland?.appId || w.lastIpcObject?.class || "";
    }

    // the class a window is shown as: floating terminals carry a custom class so Hyprland floats
    // them, they are the terminal
    function appClass(w) {
        const c = windowClass(w);
        return c === Config.floatingClass ? Config.terminal : c;
    }

    // the "0x..." address Hyprland's selectors take
    function address(w) {
        return "0x" + String(w.address).replace(/^0x/, "");
    }

    function focus(w) {
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${address(w)}" })`);
    }

    function close(w) {
        Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${address(w)}" })`);
    }
}

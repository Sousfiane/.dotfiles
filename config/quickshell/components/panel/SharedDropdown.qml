import Quickshell
import QtQuick
import qs.services

// The one window the right edge's dropdowns share (DropdownPanel's `shared`): it shows whichever of them is
// open, and going from one to another swaps the content inside the same card, which grows or shrinks to the
// new one, as the hub does between its tabs. Instantiated once, in shell.qml.
Scope {
    id: root

    // the shared panel that is open, or null
    readonly property var target: Panels.panels[Panels.current] ?? null

    // the one on show: the last one stays while the card slides out after closing
    property var shown: null
    onTargetChanged: {
        if (target)
            shown = target;
    }

    DropdownWindow {
        panel: root.shown
        open: !!root.target
    }
}

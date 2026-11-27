import Quickshell
import Quickshell.Io
import QtQuick
import qs.services

// What every dropdown panel is: a name, an edge, a size and its content, opened and closed through Panels
// and an IPC target (`qs ipc call <name> toggle`). A DropdownWindow shows it: its own, or for a panel on
// the right edge the one they all share (SharedDropdown in shell.qml), so going from one to another grows
// or shrinks the same card around the new content, as the hub does between its tabs.
Scope {
    id: root

    // ---------- what a panel provides ----------

    required property string name             // key in Panels.current, and the IPC target
    property bool open: Panels.isOpen(name)   // hover panels override this
    property string edge: "center"            // "left" | "right" | "center"
    property real cardWidth: 460
    property real cardHeight: 0               // 0 = fit the content
    property real padding: 16
    property string namespace: "qs-" + name   // what Hyprland layer rules match on
    property bool autoFocus: true             // false when the content has its own text input
    property bool ipc: true                   // false when the panel registers its own IPC target
    // the card animates its own height changes; false when the content already animates its size
    // (then the card just follows it, frame by frame, instead of chasing it with a second animation)
    property bool animateHeight: true

    // fully slid in and staying: content can start its own size animations from here
    property bool settled: false

    // hover panels: no keyboard focus, no click-outside, and a window only as big as the card,
    // so the rest of the screen stays clickable
    property bool compact: false
    property var targetScreen: null           // a specific monitor; null = the focused one

    // the panel's content: exactly one item, usually a ColumnLayout
    default property Component content

    signal cardHoverChanged(bool hovered)

    // shown in the window the right edge's panels share, rather than its own
    readonly property bool shared: edge === "right" && !compact && targetScreen === null

    // which edge it hangs from, so the bar item above it can light up; a shared one also tells the shared
    // window it exists
    function register() {
        if (root.compact)
            return;
        Panels.setEdge(root.name, edge);
        Panels.setPanel(root.name, root.shared ? root : null);
    }
    onSharedChanged: register()
    onEdgeChanged: register()
    Component.onCompleted: register()
    // (Panels may already be gone: the whole shell reloading)
    Component.onDestruction: {
        const panels = Panels.panels;
        if (panels && panels[root.name] === root)
            Panels.setPanel(root.name, null);
    }

    function close() {
        Panels.hide(name);
    }

    function toggle() {
        Panels.toggle(name);
    }

    IpcHandler {
        enabled: root.ipc
        target: root.name

        function toggle(): void {
            root.toggle();
        }
        function close(): void {
            root.close();
        }
    }

    // its own window, unless it is shown in the shared one
    DropdownWindow {
        panel: root
        open: root.open && !root.shared
    }
}

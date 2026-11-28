import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services
import qs.components.ui

// The app switcher, as macOS's Cmd + Tab, with ALT (SUPER + Tab switches workspaces):
//
//   ALT + Tab        the apps, most recently used first, the previous one chosen; Tab again goes on,
//                    SHIFT + Tab back. Letting go of ALT goes to the app's last window (the strip
//                    scrolls to it); a quick ALT + Tab goes straight back to the previous app
//   ALT + ²          the same for the windows of the app in front, shown as live previews (macOS's Cmd + `)
//   while it shows   h l / arrows choose, Enter goes, Esc cancels, Q quits the chosen app; a click goes
//
// Hyprland binds the keys (bindings.lua) and calls this through IPC: `qs ipc call switcher next apps`,
// `prev`, and `commit` when ALT is let go. It shows on the focused monitor, after a short moment so a quick
// tap doesn't flash it.
Scope {
    id: root

    property bool open: false
    property string mode: "apps"          // "apps" or "windows"
    property int index: 0
    property string screenName: ""
    property bool uiShown: false          // drawn: a moment after opening

    // ---------- what it lists ----------

    // the windows, most recently focused first
    readonly property var recent: {
        if (!open)
            return [];
        return Hyprland.toplevels.values.filter(t => {
            const o = t.lastIpcObject;
            return o && o.mapped && !o.hidden && o.workspace?.id > 0;
        }).sort((a, b) => (a.lastIpcObject.focusHistoryID ?? 99) - (b.lastIpcObject.focusHistoryID ?? 99));
    }

    // the apps, in the order their last window was used: { cls, name, icon, windows }
    readonly property var apps: {
        const byClass = {}, out = [];
        for (const t of recent) {
            const cls = Windows.appClass(t);
            if (!byClass[cls]) {
                const entry = Apps.entryForWindow(t);
                byClass[cls] = {
                    cls: cls,
                    name: entry?.name ?? cls,
                    icon: Icons.source(entry?.icon ?? cls.toLowerCase(), "application-x-executable"),
                    windows: []
                };
                out.push(byClass[cls]);
            }
            byClass[cls].windows.push(t);
        }
        return out;
    }

    // the windows of the app in front
    readonly property var appWindows: {
        const front = recent[0];
        return front ? recent.filter(t => Windows.appClass(t) === Windows.appClass(front)) : [];
    }

    readonly property int count: mode === "apps" ? apps.length : appWindows.length

    // ---------- moving through it ----------

    function start(m, dir) {
        if (open && mode === m) {
            if (count > 0)
                index = (index + dir + count) % count;
            return;
        }
        Panels.closeAll();
        Hyprland.refreshToplevels();
        mode = m;
        screenName = Hyprland.focusedMonitor?.name ?? "";
        index = -1;                       // set once the list is read (below)
        pendingDir = dir;
        open = true;
        showTimer.restart();
    }

    // the first choice waits for the fresh list: the previous one going forward, the last one going back
    property int pendingDir: 1
    onCountChanged: if (open && index < 0 && count > 0)
        index = count === 1 ? 0 : (pendingDir > 0 ? 1 : count - 1)
    onOpenChanged: if (open && count > 0 && index < 0)
        index = count === 1 ? 0 : (pendingDir > 0 ? 1 : count - 1)

    function commit() {
        if (!open)
            return;
        const i = index < 0 ? (count > 1 ? 1 : 0) : index;
        const target = mode === "apps" ? apps[i]?.windows[0] : appWindows[i];
        close();
        if (target)
            Windows.focus(target);
    }

    function close() {
        open = false;
        uiShown = false;
        showTimer.stop();
    }

    // quits the chosen app: every window of it closed, the list stays open
    function quitChosen() {
        if (mode !== "apps" || !apps[index])
            return;
        for (const t of apps[index].windows)
            Windows.close(t);
        Qt.callLater(Hyprland.refreshToplevels);
    }

    Timer {
        id: showTimer
        interval: 110
        onTriggered: root.uiShown = root.open
    }

    IpcHandler {
        target: "switcher"

        function next(mode: string): void {
            root.start(mode === "windows" ? "windows" : "apps", 1);
        }
        function prev(mode: string): void {
            root.start(mode === "windows" ? "windows" : "apps", -1);
        }
        function commit(): void {
            root.commit();
        }
        function cancel(): void {
            root.close();
        }
    }

    // ---------- drawing, on the focused monitor ----------

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: win

            required property ShellScreen modelData
            readonly property bool here: root.open && root.screenName === modelData.name

            screen: modelData
            visible: here
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-switcher"
            WlrLayershell.keyboardFocus: here ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            implicitWidth: Math.min(modelData.width - 80, card.implicitWidth)
            implicitHeight: card.implicitHeight

            onHereChanged: if (here)
                keys.forceActiveFocus()

            Item {
                id: keys
                focus: true
                Keys.onPressed: event => {
                    const k = event.key;
                    if (k === Qt.Key_Escape)
                        root.close();
                    else if (k === Qt.Key_Return || k === Qt.Key_Enter)
                        root.commit();
                    else if (k === Qt.Key_L || k === Qt.Key_Right)
                        root.index = (root.index + 1) % Math.max(1, root.count);
                    else if (k === Qt.Key_H || k === Qt.Key_Left)
                        root.index = (root.index - 1 + root.count) % Math.max(1, root.count);
                    else if (k === Qt.Key_Q)
                        root.quitChosen();
                    else
                        return;
                    event.accepted = true;
                }
                // ALT let go while the keyboard is here (Hyprland's release bind does it too)
                Keys.onReleased: event => {
                    if (event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr)
                        root.commit();
                }
            }

            Rectangle {
                id: card

                readonly property int pad: 14

                anchors.centerIn: parent
                implicitWidth: (root.mode === "apps" ? appRow.implicitWidth : winRow.implicitWidth) + 2 * pad
                implicitHeight: (root.mode === "apps" ? appRow.implicitHeight : winRow.implicitHeight) + label.implicitHeight + 3 * pad
                radius: Theme.radiusLarge + 6
                color: Theme.bg
                border.width: 1
                border.color: Theme.border
                opacity: root.uiShown ? 1 : 0
                scale: root.uiShown ? 1 : 0.96

                Behavior on opacity {
                    Anim {
                        duration: Motion.fast
                    }
                }
                Behavior on scale {
                    Anim {
                        curve: Motion.enter
                        duration: Motion.fast
                    }
                }

                // the apps: their icons, the chosen one on a plate
                Row {
                    id: appRow

                    visible: root.mode === "apps"
                    x: card.pad
                    y: card.pad
                    spacing: 6

                    Repeater {
                        model: root.mode === "apps" ? root.apps : []

                        delegate: Item {
                            id: app

                            required property var modelData
                            required property int index
                            readonly property bool chosen: index === root.index

                            width: 92
                            height: 92

                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.radiusLarge + 2
                                color: app.chosen ? Theme.surface : "transparent"
                                border.width: app.chosen ? 1 : 0
                                border.color: Theme.withAlpha(Theme.fg, 0.12)
                            }

                            AppIcon {
                                anchors.centerIn: parent
                                implicitSize: 64
                                source: app.modelData.icon
                            }

                            // how many windows it has, when more than one
                            Rectangle {
                                visible: app.modelData.windows.length > 1
                                anchors {
                                    right: parent.right
                                    top: parent.top
                                    margins: 6
                                }
                                width: Math.max(height, n.implicitWidth + 8)
                                height: 18
                                radius: height / 2
                                color: Theme.accent

                                Txt {
                                    id: n
                                    anchors.centerIn: parent
                                    variant: "small"
                                    font.bold: true
                                    color: Theme.bgSolid
                                    text: app.modelData.windows.length
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.index = app.index
                                onClicked: root.commit()
                            }
                        }
                    }
                }

                // the windows of the app in front: live previews
                Row {
                    id: winRow

                    readonly property int tileH: 150

                    visible: root.mode === "windows"
                    x: card.pad
                    y: card.pad
                    spacing: 10

                    Repeater {
                        model: root.mode === "windows" ? root.appWindows : []

                        delegate: Item {
                            id: tile

                            required property var modelData
                            required property int index
                            readonly property bool chosen: index === root.index
                            readonly property var size: modelData.lastIpcObject?.size ?? [16, 9]

                            height: winRow.tileH
                            width: Math.max(100, Math.min(300, height * size[0] / Math.max(1, size[1])))

                            ClippingRectangle {
                                anchors.fill: parent
                                radius: Theme.radiusLarge
                                color: Theme.surface

                                ScreencopyView {
                                    anchors.fill: parent
                                    captureSource: win.here ? (tile.modelData.wayland ?? null) : null
                                    live: true
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.radiusLarge
                                color: "transparent"
                                border.width: tile.chosen ? 2 : 1
                                border.color: tile.chosen ? Theme.accent : Theme.withAlpha(Theme.fg, 0.12)
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: root.index = tile.index
                                onClicked: root.commit()
                            }
                        }
                    }
                }

                // the chosen one's name (an app) or title (a window)
                Txt {
                    id: label
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: card.pad
                    }
                    width: card.width - 2 * card.pad
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    variant: "body"
                    text: root.mode === "apps" ? (root.apps[root.index]?.name ?? "") : (root.appWindows[root.index]?.title ?? "")
                }
            }
        }
    }
}

import Quickshell.Hyprland
import QtQuick
import qs.config
import qs.services
import qs.components.ui

// An icon's right-click menu: its windows (click one to go to it), pin / unpin, a new window, close.
// Shown while dock.menuItem is set; AppDock places it above the icon.
Rectangle {
    id: menu

    required property var dock         // the AppDock window: which icon's menu is open
    readonly property var item: dock.menuItem
    readonly property var windows: item ? (Dock.windowsByApp[item.key] ?? []) : []

    visible: opacity > 0
    opacity: item ? 1 : 0
    width: 220
    height: col.implicitHeight + 12
    radius: Theme.radiusLarge
    color: Theme.bg
    border.width: 1
    border.color: Theme.line

    Behavior on opacity {
        Anim {
            duration: Motion.fast
        }
    }

    // keeps showing the last app while fading out
    property var shownItem: null
    onItemChanged: if (item)
        shownItem = item

    Column {
        id: col
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 6
        }
        spacing: 2

        Txt {
            x: 8
            width: parent.width - 16
            height: 26
            verticalAlignment: Text.AlignVCenter
            variant: "dim"
            text: Dock.nameFor(menu.shownItem)
            elide: Text.ElideRight
        }

        // its windows: click one to go to it
        Repeater {
            model: menu.windows.slice(0, 8)

            delegate: DockMenuRow {
                required property var modelData
                width: col.width
                text: modelData.title || modelData.lastIpcObject?.title || "Window"
                active: modelData === Hyprland.activeToplevel
                onClicked: {
                    Windows.focus(modelData);
                    dock.menuItem = null;
                }
            }
        }

        Rectangle {
            visible: menu.windows.length > 0
            width: parent.width
            height: 1
            color: Theme.line
        }

        DockMenuRow {
            width: col.width
            visible: menu.shownItem?.entry != null
            text: menu.shownItem && Dock.isPinned(menu.shownItem.key) ? "Unpin from dock" : "Pin to dock"
            onClicked: {
                Dock.togglePin(menu.shownItem.key);
                dock.menuItem = null;
            }
        }

        DockMenuRow {
            width: col.width
            visible: menu.shownItem?.entry != null
            text: "New window"
            onClicked: {
                Dock.launch(menu.shownItem);
                dock.menuItem = null;
            }
        }

        DockMenuRow {
            width: col.width
            visible: menu.windows.length > 0
            text: menu.windows.length > 1 ? "Close " + menu.windows.length + " windows" : "Close"
            danger: true
            onClicked: {
                Dock.closeAll(menu.shownItem);
                dock.menuItem = null;
            }
        }
    }
}

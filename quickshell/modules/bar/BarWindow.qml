import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services

PanelWindow {
    id: win

    // true for the temporary copy that sits above fullscreen apps
    property bool overlay: false

    WlrLayershell.layer: overlay ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.namespace: overlay ? "bar-overlay" : "quickshell"

    // the copy must never reserve space, only the real bar does
    exclusionMode: overlay ? ExclusionMode.Ignore : ExclusionMode.Auto

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: Theme.bg

    Workspaces {
        screen: win.screen
        anchors {
            left: parent.left
            leftMargin: 8
            verticalCenter: parent.verticalCenter
        }
    }

    Clock {
        anchors.centerIn: parent
    }

    PowerIcon {
        id: power
        anchors {
            right: parent.right
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
    }

    BellIcon {
        id: bell
        anchors {
            right: power.left
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
    }

    Volume {
        id: volume
        anchors {
            right: bell.left
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
    }

    BtIcon {
        id: bt
        anchors {
            right: volume.left
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
    }

    UpdatesIcon {
        id: updates
        anchors {
            right: bt.left
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
    }

    DotIcon {
        anchors {
            right: updates.left
            rightMargin: 12
            verticalCenter: parent.verticalCenter
        }
    }
}

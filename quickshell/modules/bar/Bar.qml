import Quickshell
import QtQuick
import qs.config
import qs.services

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: Theme.barHeight
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.80)

        Workspaces {
            screen: win.modelData
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
}

import Quickshell
import QtQuick

// Mission Control on screen (services/Overview.qml: whether it's open, and where): one OverviewWindow on
// every monitor, each showing that monitor's workspaces.
Scope {
    Variants {
        model: Quickshell.screens

        delegate: OverviewWindow {
            required property ShellScreen modelData
            screen: modelData
        }
    }
}

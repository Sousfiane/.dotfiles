import Quickshell
import QtQuick
import qs.services

Variants {
    model: Quickshell.screens

    Scope {
        id: scope
        required property var modelData

        // the permanent bar
        BarWindow {
            screen: scope.modelData
        }

        // copy above fullscreen apps, only while a dropdown is open
        LazyLoader {
            active: Panels.raised

            BarWindow {
                screen: scope.modelData
                overlay: true
            }
        }
    }
}

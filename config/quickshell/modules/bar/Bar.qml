import Quickshell

// One bar on every monitor.
Variants {
    model: Quickshell.screens

    BarWindow {
        required property var modelData
        screen: modelData
    }
}

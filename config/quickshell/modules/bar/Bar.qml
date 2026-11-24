import Quickshell

Variants {
    model: Quickshell.screens

    BarWindow {
        required property var modelData
        screen: modelData
    }
}

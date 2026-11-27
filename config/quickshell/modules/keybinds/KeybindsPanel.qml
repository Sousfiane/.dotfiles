import qs.services
import qs.components.panel

// The keybinds list's own panel: its content is KeybindsView, which the hub also shows as a tab.
DropdownPanel {
    name: "keybinds"
    edge: "center"
    cardWidth: Panels.pickerSizes.keybinds[0]
    cardHeight: Panels.pickerSizes.keybinds[1]
    autoFocus: false            // the search box takes the focus itself

    KeybindsView {}
}

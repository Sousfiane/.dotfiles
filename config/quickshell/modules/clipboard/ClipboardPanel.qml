import qs.services
import qs.components.panel

// The clipboard history's own panel: its content is ClipboardView, which the hub also shows as a tab.
DropdownPanel {
    name: "clipboard"
    edge: "center"
    cardWidth: Panels.pickerSizes.clipboard[0]
    cardHeight: Panels.pickerSizes.clipboard[1]
    padding: 20
    autoFocus: false            // the search box takes the focus itself

    ClipboardView {}
}

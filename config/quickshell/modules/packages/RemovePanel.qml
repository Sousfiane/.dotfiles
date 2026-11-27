import qs.services
import qs.components.panel

// The package remover's own panel: its content is RemoveView, which the hub also shows as a tab.
DropdownPanel {
    name: "remove"
    edge: "center"
    cardWidth: Panels.pickerSizes.remove[0]
    cardHeight: Panels.pickerSizes.remove[1]
    autoFocus: false            // the search box takes the focus itself

    RemoveView {}
}

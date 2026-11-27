import qs.services
import qs.components.panel

// The package installer's own panel: its content is InstallView, which the hub also shows as a tab.
DropdownPanel {
    name: "install"
    edge: "center"
    cardWidth: Panels.pickerSizes.install[0]
    cardHeight: Panels.pickerSizes.install[1]
    autoFocus: false            // the search box takes the focus itself

    InstallView {}
}

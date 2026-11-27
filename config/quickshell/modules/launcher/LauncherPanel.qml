import qs.services
import qs.components.panel

// The app launcher's own panel: its content is LauncherView, which the hub also shows as a tab.
DropdownPanel {
    name: "launcher"
    edge: "center"
    cardWidth: Panels.pickerSizes.launcher[0]
    cardHeight: Panels.pickerSizes.launcher[1]
    autoFocus: false            // the search box takes the focus itself

    LauncherView {}
}

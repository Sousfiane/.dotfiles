import qs.services
import qs.components.panel

// The theme picker's own panel: its content is ThemeView, which the hub also shows as a tab.
DropdownPanel {
    name: "theme"
    edge: "center"
    cardWidth: Panels.pickerSizes.theme[0]

    ThemeView {}
}

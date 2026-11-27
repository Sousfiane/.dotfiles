import qs.services
import qs.components.panel

// The wallpaper picker's own panel: its content is WallpaperView, which the hub also shows as a tab.
DropdownPanel {
    name: "wallpaper"
    edge: "center"
    cardWidth: Panels.pickerSizes.wallpaper[0]
    cardHeight: Panels.pickerSizes.wallpaper[1]
    padding: 20
    autoFocus: false

    WallpaperView {}
}

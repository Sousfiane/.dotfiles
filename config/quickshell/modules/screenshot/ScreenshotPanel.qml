import qs.services
import qs.components.panel

// The screenshot menu's own panel: its content is ScreenshotView, which the hub also shows as a tab.
DropdownPanel {
    name: "screenshot"
    edge: "center"
    cardWidth: Panels.pickerSizes.screenshot[0]

    ScreenshotView {}
}

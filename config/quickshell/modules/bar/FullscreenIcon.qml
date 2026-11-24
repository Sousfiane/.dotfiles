import qs.config
import qs.services
import qs.components.ui

// Mouse way out of fullscreen: the window's title bar is hidden then, but touching the top edge
// still slides this bar down. Only exists while this monitor shows a fullscreen window.
BarButton {
    visible: Fullscreen.on(screenName)
    icon: Icons.fullscreenExit

    onClicked: Fullscreen.exit(screenName)
}

import qs.config
import qs.services
import qs.components.ui

// The notifications in the bar: unread count, click for the center, right click for do not disturb.
BarButton {
    iconSize: Theme.fontSize + 2
    icon: Notifs.dnd ? Icons.bellOff : Notifs.unread > 0 ? Icons.bellRing : Icons.bell
    glyphs: [Icons.bell, Icons.bellRing, Icons.bellOff]
    label: Notifs.unread > 0 && !Notifs.dnd ? String(Notifs.unread) : ""
    open: Notifs.open
    off: Notifs.dnd

    onClicked: Notifs.toggle()
    onRightClicked: Notifs.dnd = !Notifs.dnd
}

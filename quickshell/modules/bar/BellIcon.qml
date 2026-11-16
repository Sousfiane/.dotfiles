import qs.config
import qs.services
import qs.components.ui

BarButton {
    iconSize: Theme.fontSize + 2
    icon: Notifs.dnd ? Icons.bellOff : Notifs.unread > 0 ? Icons.bellRing : Icons.bell
    label: Notifs.unread > 0 && !Notifs.dnd ? String(Notifs.unread) : ""
    open: Notifs.open
    off: Notifs.dnd

    onClicked: Notifs.toggle()
    onRightClicked: Notifs.dnd = !Notifs.dnd
}

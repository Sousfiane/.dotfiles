import qs.config
import qs.services
import qs.components

BarButton {
    icon: Notifs.dnd ? Icons.bellOff : Notifs.unread > 0 ? Icons.bellRing : Icons.bell
    iconColor: Notifs.dnd ? Theme.dim : Notifs.unread > 0 ? Theme.accent : Theme.fg
    label: Notifs.unread > 0 && !Notifs.dnd ? String(Notifs.unread) : ""

    onClicked: Notifs.toggle()
    onRightClicked: Notifs.dnd = !Notifs.dnd
}

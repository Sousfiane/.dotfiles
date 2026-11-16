import qs.config
import qs.services
import qs.components

BarButton {
    icon: Icons.git
    iconColor: Dotfiles.failed ? Theme.urgent : Dotfiles.open ? Theme.accent : Theme.fg
    label: Dotfiles.count > 0 ? String(Dotfiles.count) : ""

    onClicked: Dotfiles.toggle()
}

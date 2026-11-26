import qs.config
import qs.services
import qs.components.ui

BarButton {
    icon: Icons.git
    label: Dotfiles.count > 0 ? String(Dotfiles.count) : ""
    alert: Dotfiles.failed
    open: Dotfiles.open

    onClicked: Dotfiles.toggle()
}

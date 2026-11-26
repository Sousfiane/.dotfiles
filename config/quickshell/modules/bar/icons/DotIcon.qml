import qs.config
import qs.services
import qs.components.ui

// The dotfiles repo in the bar: number of uncommitted changes, click for the panel.
BarButton {
    icon: Icons.git
    label: Dotfiles.count > 0 ? String(Dotfiles.count) : ""
    alert: Dotfiles.failed
    open: Dotfiles.open

    onClicked: Dotfiles.toggle()
}

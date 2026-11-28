import Quickshell
import qs.modules.background
import qs.modules.bar
import qs.modules.launcher
import qs.modules.osd
import qs.modules.notifications
import qs.modules.clipboard
import qs.modules.mixer
import qs.modules.bluetooth
import qs.modules.power
import qs.modules.updates
import qs.modules.dotfiles
import qs.modules.workspaces
import qs.modules.wallpaper
import qs.modules.theme
import qs.modules.hub
import qs.modules.network
import qs.modules.screenshot
import qs.modules.share
import qs.modules.lock
import qs.modules.tray
import qs.modules.dock
import qs.modules.packages
import qs.modules.keybinds
import qs.modules.polkit
import qs.modules.overview
import qs.modules.switcher
import qs.services
import qs.components.panel

// The shell: the bar, the wallpaper, the dock, the toasts and every panel, each on the monitors it
// needs.
ShellRoot {
    // singletons are created on first use: these must exist from the start (the media keys' and the
    // screen sharing picker's IPC targets, the polkit agent)
    readonly property var startServices: [Media, Share, Polkit]

    Background {}
    Bar {}
    LauncherPanel {}
    Osd {}
    NotifPopups {}
    NotifPanel {}
    ClipboardPanel {}
    MixerPanel {}
    BtPanel {}
    PowerPanel {}
    UpdatesPanel {}
    DotfilesPanel {}
    WsPanel {}
    WsDragChip {}
    WallpaperPanel {}
    ThemePanel {}
    HubPanel {}
    NetPanel {}
    ScreenshotPanel {}
    SharePanel {}
    InstallPanel {}
    RemovePanel {}
    KeybindsPanel {}
    PolkitPanel {}
    LockScreen {}
    TrayPanel {}
    AppDock {}
    OverviewPanel {}
    SwitcherPanel {}

    // the window the right edge's dropdowns share: one card, growing or shrinking from one to another
    SharedDropdown {}
}

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
import qs.modules.lock
import qs.modules.tray
import qs.modules.dock
import qs.modules.packages
import qs.modules.keybinds
import qs.services

ShellRoot {
    // singletons are created on first use: these hold IPC targets (media keys) that must exist from the start
    readonly property var ipcServices: [Media]

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
    InstallPanel {}
    RemovePanel {}
    KeybindsPanel {}
    LockScreen {}
    TrayPanel {}
    AppDock {}
}

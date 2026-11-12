import Quickshell
import qs.modules.bar
import qs.modules.launcher
import qs.modules.osd
import qs.modules.notifications
import qs.modules.wallpaper
import qs.modules.clipboard
import qs.modules.power
import qs.modules.mixer
import qs.modules.bluetooth

ShellRoot {
    Bar {}
    Launcher {}
    Osd {}
    NotifPopups {}
    NotifCenter {}
    WallpaperPicker {}
    Clipboard {}
    PowerMenu {}
    MixerPanel {}
    BtPanel {}
}

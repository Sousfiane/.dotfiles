pragma Singleton
import Quickshell
import QtQuick

// The shell's settings that aren't the theme: terminal, weather place, calendar colours, dock pins, paths.
Singleton {
    readonly property string home: Quickshell.env("HOME")

    // the terminal xdg-terminal-exec opens (pinned in config/xdg-terminals.list), used here only for the
    // icon of its floating windows in the dock and the workspace cards
    property string terminal: "kitty"
    // app id that Hyprland's "tag-floating-windows" rule floats
    property string floatingClass: "FloatingTerm"

    // command line that runs `cmd` in a floating terminal window: the same as SUPER + SHIFT + Return
    function floatingTerm(cmd) {
        return ["xdg-terminal-exec", "--app-id=" + floatingClass, "--", ...cmd];
    }

    // the launcher's web search ("? query"): the query goes at the end, URL-encoded
    property string searchUrl: "https://duckduckgo.com/?q="

    // weather in the hub: a city ("Paris", "Lyon"...), or "" to locate by IP address
    property string weatherLocation: "Lille"

    // calendar in the hub (CalDAV). Server, user and app password live in the keyring, not here:
    // `~/.dotfiles/install/install.sh calendar` asks for them and stores them
    // color per calendar name; unlisted calendars use Theme.accent. Nextcloud's own colors are ignored.
    //   e.g. ({ "Personal": Theme.foam, "Work": Theme.gold })
    property var calendarColors: ({})

    // the dock's pins before you change them (right-click an icon, or an app in the launcher, to pin/unpin).
    // Desktop entry ids: the .desktop file name without the extension. Your changes are kept in
    // ~/.local/state/quickshell/.../dock-pins.json; delete it to come back to this list.
    property var dockPins: ["kitty", "zen", "org.gnome.Nautilus", "vesktop", "spotify-launcher"]

    property string dotfilesRepo: home + "/.dotfiles"
    property string wallpaperDir: home + "/.wallpapers"
    property string wallpaperDefault: wallpaperDir + "/Mountain.jpg"     // until one is picked (a new machine)
    property string wallpaperState: Quickshell.statePath("wallpaper")    // the wallpaper picked, next to the dock pins
}

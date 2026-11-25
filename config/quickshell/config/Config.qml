pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property string home: Quickshell.env("HOME")

    property string terminal: "kitty"                  // change to foot, alacritty, ghostty...
    // class that Hyprland's "tag-floating-windows" rule floats (foot uses --app-id instead)
    property string floatingClass: "FloatingTerm"

    // command line that runs `cmd` in a floating terminal window
    function floatingTerm(cmd) {
        return [terminal, "--class", floatingClass, "-e", ...cmd];
    }

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
    property string wallpaperState: home + "/.swaybg"
}

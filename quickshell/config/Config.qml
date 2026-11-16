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

    property string dotfilesRepo: home + "/.dotfiles"
    property string wallpaperDir: home + "/.wallpapers"
    property string wallpaperState: home + "/.swaybg"
}

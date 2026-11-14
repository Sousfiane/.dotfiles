pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property string home: Quickshell.env("HOME")

    property string terminal: "kitty"                  // change to foot, alacritty, ghostty...
    property string dotfilesRepo: home + "/.dotfiles"
    property string wallpaperDir: home + "/.wallpapers"
    property string wallpaperState: home + "/.swaybg"
}

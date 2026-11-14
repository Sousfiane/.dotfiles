pragma Singleton
import Quickshell
import QtQuick

Singleton {
    function glyph(cp) {
        return String.fromCodePoint(cp);
    }

    // system
    readonly property string power: glyph(0xF0425)
    readonly property string lock: glyph(0xF033E)
    readonly property string suspend: glyph(0xF0904)
    readonly property string logout: glyph(0xF0343)
    readonly property string reboot: glyph(0xF0709)
    readonly property string shutdown: power

    // bluetooth
    readonly property string bluetooth: glyph(0xF00AF)
    readonly property string bluetoothConnected: glyph(0xF00B1)
    readonly property string bluetoothOff: glyph(0xF00B2)

    // audio
    readonly property string volumeHigh: glyph(0xF057E)
    readonly property string volumeMedium: glyph(0xF0580)
    readonly property string volumeLow: glyph(0xF057F)
    readonly property string volumeOff: glyph(0xF0581)
    readonly property string mic: glyph(0xF036C)
    readonly property string micOff: glyph(0xF036D)
    readonly property string speaker: glyph(0xF04C3)
    readonly property string chip: glyph(0xF061A)

    // bar and hub
    readonly property string update: glyph(0xF06B0)
    readonly property string git: glyph(0xF02A2)
    readonly property string bell: glyph(0xF009C)
    readonly property string bellRing: glyph(0xF009D)
    readonly property string bellOff: glyph(0xF009B)
    readonly property string apps: glyph(0xF003B)
    readonly property string wallpaper: glyph(0xF02E9)
    readonly property string clipboard: glyph(0xF0147)
    readonly property string capsLock: "⇪"
}

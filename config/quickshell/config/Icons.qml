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
    readonly property string volumeHigh: glyph(0xF028)     // fa-volume_up, 3 waves
    readonly property string volumeMedium: glyph(0xEFCF)   // fa-volume, 2 waves
    readonly property string volumeLow: glyph(0xF027)      // fa-volume_low, 1 wave
    readonly property string volumeZero: glyph(0xF026)     // fa-volume_off, no waves
    readonly property string volumeOff: glyph(0xEEE8)      // fa-volume_xmark, muted
    readonly property string mic: glyph(0xF036C)
    readonly property string micOff: glyph(0xF036D)
    readonly property string capsLock: glyph(0xF0632)     // md-apple_keyboard_caps
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
    readonly property string screenshot: glyph(0xF0100)
    readonly property string palette: glyph(0xF03D8)
    readonly property string check: glyph(0xF012C)

    // media
    readonly property string music: glyph(0xF075A)
    readonly property string play: glyph(0xF040A)
    readonly property string pause: glyph(0xF03E4)
    readonly property string next: glyph(0xF04AD)
    readonly property string previous: glyph(0xF04AE)

    // weather
    readonly property string weatherSunny: glyph(0xF0599)
    readonly property string weatherNight: glyph(0xF0594)
    readonly property string weatherPartly: glyph(0xF0595)
    readonly property string weatherNightPartly: glyph(0xF0F31)
    readonly property string weatherCloudy: glyph(0xF0590)
    readonly property string weatherFog: glyph(0xF0591)
    readonly property string weatherRain: glyph(0xF0597)
    readonly property string weatherPouring: glyph(0xF0596)
    readonly property string weatherSleet: glyph(0xF067F)
    readonly property string weatherSnow: glyph(0xF0598)
    readonly property string weatherSnowHeavy: glyph(0xF0F36)
    readonly property string weatherThunder: glyph(0xF0593)
    readonly property string weatherThunderRain: glyph(0xF067E)

    // screenshot modes
    readonly property string shotRegion: glyph(0xF019E)
    readonly property string shotWindow: glyph(0xF0614)
    readonly property string shotMonitor: glyph(0xF0379)
    readonly property string shotActiveWindow: glyph(0xF08C6)
    readonly property string shotActiveMonitor: glyph(0xF1265)

    // network
    readonly property string wifi1: glyph(0xF091F)
    readonly property string wifi2: glyph(0xF0922)
    readonly property string wifi3: glyph(0xF0925)
    readonly property string wifi4: glyph(0xF0928)
    readonly property string wifiOff: glyph(0xF05AA)
    readonly property string ethernet: glyph(0xF0200)
    readonly property string ethernetOff: glyph(0xF0202)

    // tray
    readonly property string dots: glyph(0xF01D8)            // md-dots_horizontal, the drawer
    readonly property string chevronLeft: glyph(0xF0141)
    readonly property string chevronRight: glyph(0xF0142)
    readonly property string checkboxOn: glyph(0xF0132)
    readonly property string checkboxOff: glyph(0xF0131)
    readonly property string radioOn: glyph(0xF043E)
    readonly property string radioOff: glyph(0xF043D)
}

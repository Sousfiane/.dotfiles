import qs.config
import qs.services
import qs.components.ui

BarButton {
    iconSize: Theme.fontSize + 1
    readonly property int pct: Math.round(Audio.volume * 100)

    icon: Audio.muted ? Icons.volumeOff : pct === 0 ? Icons.volumeZero : pct < 34 ? Icons.volumeLow : pct < 67 ? Icons.volumeMedium : Icons.volumeHigh
    glyphs: [Icons.volumeOff, Icons.volumeZero, Icons.volumeLow, Icons.volumeMedium, Icons.volumeHigh]
    inkAlign: "left"                      // the speaker stays put, only the waves grow
    open: Mixer.open
    off: Audio.muted

    onClicked: Mixer.toggle()
    onRightClicked: Mixer.toggleMute(Audio.sink)
    onScrolled: delta => Mixer.adjust(Audio.sink, delta > 0 ? 0.05 : -0.05)
}

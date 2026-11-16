import qs.config
import qs.services
import qs.components.ui

BarButton {
    readonly property int pct: Math.round(Audio.volume * 100)

    icon: (Audio.muted || pct === 0) ? Icons.volumeOff : pct < 34 ? Icons.volumeLow : pct < 67 ? Icons.volumeMedium : Icons.volumeHigh
    open: Mixer.open
    off: Audio.muted

    onClicked: Mixer.toggle()
    onRightClicked: Mixer.toggleMute(Audio.sink)
    onScrolled: delta => Mixer.adjust(Audio.sink, delta > 0 ? 0.05 : -0.05)
}

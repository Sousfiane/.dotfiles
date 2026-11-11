pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    // The OSD listens to this
    signal changed()
    onVolumeChanged: changed()
    onMutedChanged: changed()

    PwObjectTracker { objects: [root.sink] }
}

pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// The default output and input (PipeWire): their volume and mute, for the bar, the OSD and the volume keys.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false

    // the OSD listens to these
    signal changed
    signal micChanged

    onVolumeChanged: changed()
    onMutedChanged: changed()
    onMicMutedChanged: micChanged()

    // ---------- the volume keys ----------

    readonly property real step: 0.05

    // up to 100%: the mixer can push past it, the keys never do (nor pull a boosted volume back down)
    function up() {
        if (!sink?.audio)
            return;
        sink.audio.muted = false;
        if (sink.audio.volume < 1)
            sink.audio.volume = Math.min(1, Math.round((sink.audio.volume + step) * 100) / 100);
    }

    function down() {
        if (sink?.audio)
            sink.audio.volume = Math.max(0, Math.round((sink.audio.volume - step) * 100) / 100);
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleMicMute() {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    // hypr/config/bindings.lua: `qs ipc call audio up` and so on
    IpcHandler {
        target: "audio"

        function up(): void {
            root.up();
        }
        function down(): void {
            root.down();
        }
        function mute(): void {
            root.toggleMute();
        }
        function micMute(): void {
            root.toggleMicMute();
        }
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}

pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

// the MPRIS player worth showing: the one playing, else the last one that played, else the first one
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property MprisPlayer lastActive: null

    readonly property MprisPlayer player: players.find(p => p.isPlaying) ?? (players.includes(lastActive) ? lastActive : null) ?? players[0] ?? null
    readonly property bool active: player !== null && (player.trackTitle ?? "") !== ""

    onPlayerChanged: {
        if (player?.isPlaying)
            lastActive = player;
        rememberLength();
    }

    // The track's length in seconds, 0 if unknown. Firefox re-sends its metadata without mpris:length after
    // a seek (until the next pause or play), so the last length seen for the same track stands in for it.
    readonly property string trackKey: player ? [player.dbusName, player.trackTitle, player.trackArtist].join("\n") : ""
    property var lastLength: ({
            key: "",
            length: 0
        })
    // (without mpris:length, Quickshell's length falls back to the position, so lengthSupported decides)
    // A live stream (Twitch) has an infinite duration, which the browser sends as the largest 64-bit
    // length: anything past 100 days is that, not a track. It has no length to show, only "live".
    readonly property real liveLength: 100 * 24 * 3600
    readonly property bool live: (player?.lengthSupported ?? false) && player.length >= liveLength
    readonly property bool playerHasLength: (player?.lengthSupported ?? false) && player.length > 0 && !live
    readonly property real length: live ? 0 : playerHasLength ? player.length : (lastLength.key === trackKey ? lastLength.length : 0)

    function rememberLength() {
        if (playerHasLength)
            lastLength = {
                key: trackKey,
                length: player.length
            };
    }
    onTrackKeyChanged: rememberLength()
    Connections {
        target: root.player
        function onLengthChanged() {
            root.rememberLength();
        }
        function onLengthSupportedChanged() {
            root.rememberLength();
        }
    }

    function toggle() {
        if (player?.canTogglePlaying)
            player.togglePlaying();
    }
    function next() {
        if (player?.canGoNext)
            player.next();
    }
    function previous() {
        if (player?.canGoPrevious)
            player.previous();
    }

    // the media keys (hypr/config/bindings.lua): `qs ipc call media toggle` and so on
    IpcHandler {
        target: "media"

        function toggle(): void {
            root.toggle();
        }
        function next(): void {
            root.next();
        }
        function previous(): void {
            root.previous();
        }
    }

    // seconds -> "m:ss"
    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    // MPRIS does not push position updates: ask for them while something plays
    Timer {
        running: root.player?.isPlaying ?? false
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }
}

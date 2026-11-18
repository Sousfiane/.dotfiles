pragma Singleton
import Quickshell
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

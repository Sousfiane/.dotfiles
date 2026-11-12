pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    property bool open: false
    property int tab: 0                      // 0 playback, 1 recording, 2 output, 3 input
    readonly property real maxVolume: 1.5    // slider goes to 150% like wiremix

    readonly property var tabLabels: ["Playback", "Recording", "Output", "Input", "Config"]

    function toggle() {
        open = !open;
    }

    function mediaClass(n) {
        return (n.properties || ({}))["media.class"] || "";
    }
    function isRecordingStream(n) {
        return mediaClass(n) === "Stream/Input/Audio";
    }

    // every audio node, once PipeWire has bound it
    readonly property var allNodes: Pipewire.nodes.values.filter(n => n.ready && n.audio)

    readonly property var playback: allNodes.filter(n => n.isStream && mediaClass(n) === "Stream/Output/Audio")
    readonly property var recording: allNodes.filter(n => n.isStream && mediaClass(n) === "Stream/Input/Audio")
    readonly property var outputs: allNodes.filter(n => !n.isStream && n.isSink)
    readonly property var inputs: allNodes.filter(n => !n.isStream && !n.isSink)

    function listFor(i) {
        return [playback, recording, outputs, inputs, cards][i];
    }
    readonly property var current: listFor(tab)

    function setVolume(n, v) {
        if (n && n.audio)
            n.audio.volume = Math.max(0, Math.min(maxVolume, Math.round(v * 100) / 100));
    }
    function adjust(n, delta) {
        if (n && n.audio)
            setVolume(n, n.audio.volume + delta);
    }
    function toggleMute(n) {
        if (n && n.audio)
            n.audio.muted = !n.audio.muted;
    }
    function isDefault(n) {
        return n === Pipewire.defaultAudioSink || n === Pipewire.defaultAudioSource;
    }
    function makeDefault(n) {
        if (!n)
            return;
        if (n.isSink)
            Pipewire.preferredDefaultAudioSink = n;
        else
            Pipewire.preferredDefaultAudioSource = n;
    }

    // ---------- per-app routing ----------

    // devices an app can be moved to
    function targets(node) {
        return isRecordingStream(node) ? inputs : outputs;
    }

    // the device an app is currently connected to (or null)
    function currentTarget(node) {
        const rec = isRecordingStream(node);
        for (const g of Pipewire.linkGroups.values) {
            if (!rec && g.source === node)
                return g.target;
            if (rec && g.target === node)
                return g.source;
        }
        return null;
    }

    property var pending: null

    function moveStream(node, target) {
        if (!node || !target)
            return;
        const rec = isRecordingStream(node);
        pending = {
            serial: String((node.properties || ({}))["object.serial"] ?? ""),
            id: String(node.id),
            target: target.name,
            rec: rec
        };
        lister.command = ["pactl", "-f", "json", "list", rec ? "source-outputs" : "sink-inputs"];
        lister.running = true;
    }

    // pactl numbers streams differently from PipeWire, so look the stream up
    // by its object.serial, then move it by pactl's own index
    function finishMove(text) {
        const p = pending;
        pending = null;
        if (!p)
            return;

        let list = [];
        try {
            list = JSON.parse(text);
        } catch (e) {
            console.log("mixer: could not parse pactl output", e);
            return;
        }

        const hit = list.find(x => String(x.properties?.["object.serial"]) === p.serial) ?? list.find(x => String(x.index) === p.id);

        if (!hit) {
            console.log("mixer: stream not found in pactl output, serial", p.serial);
            return;
        }

        Quickshell.execDetached(["pactl", p.rec ? "move-source-output" : "move-sink-input", String(hit.index), p.target]);
    }

    Process {
        id: lister
        stdout: StdioCollector {
            onStreamFinished: root.finishMove(text)
        }
    }

    // ---------- sound card profiles ----------

    // [{ name, description, active, profiles: [{ name, description, available }] }]
    property var cards: []

    function refreshCards() {
        cardLister.running = false;
        cardLister.running = true;
    }

    function parseCards(text) {
        let raw = [];
        try {
            raw = JSON.parse(text);
        } catch (e) {
            console.log("mixer: could not parse pactl cards", e);
            return;
        }

        cards = raw.map(c => {
            const props = c.properties || ({});
            const profiles = Object.keys(c.profiles || ({})).map(k => {
                const p = c.profiles[k];
                return {
                    name: k,
                    description: p.description || k,
                    available: p.available !== false && p.available !== "no",
                    priority: p.priority || 0
                };
            }).sort((a, b) => b.priority - a.priority);

            return {
                name: c.name,
                description: props["device.description"] || props["device.nick"] || c.name,
                active: c.active_profile,
                profiles: profiles
            };
        }).filter(c => c.profiles.length > 0);
    }

    function setProfile(card, profile) {
        if (!card || !profile)
            return;
        Quickshell.execDetached(["pactl", "set-card-profile", card.name, profile.name]);
        refreshTimer.restart();           // re-read once the change has settled
    }

    Process {
        id: cardLister
        command: ["pactl", "-f", "json", "list", "cards"]
        stdout: StdioCollector {
            onStreamFinished: root.parseCards(text)
        }
    }

    Timer {
        id: refreshTimer
        interval: 500
        onTriggered: root.refreshCards()
    }

    onTabChanged: if (tab === 4)
        refreshCards()
    onOpenChanged: if (open && tab === 4)
        refreshCards()

    // nodes and links must be tracked, otherwise properties stay unavailable
    PwObjectTracker {
        objects: Pipewire.nodes.values
    }
    PwObjectTracker {
        objects: Pipewire.linkGroups.values
    }
}

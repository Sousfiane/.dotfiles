pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// The installed games of Steam and Heroic and their cover art (scripts/games.py), so a game's window
// shows its cover in the dock and the workspace panel without a desktop entry. A window is matched by
// its class for a Proton game (steam_app_<id>), else by its title, which starts with the game's name:
// a Heroic game runs as steam_app_default, a native one picks its own class (cs2).
Singleton {
    id: root

    // [{ name, key (name normalized), art, steam (app id or null) }]
    property var games: []

    // a letter (accented ones too) or a digit: "" past the end of a string is not
    function isWordChar(c) {
        return c !== "" && (c.toLowerCase() !== c.toUpperCase() || (c >= "0" && c <= "9"));
    }

    // lower case, every run of punctuation and symbols one space: "Street Fighter™ 6" and
    // "Kingdom Come: Deliverance II" read like their window titles
    function normalize(s) {
        return (s ?? "").toLowerCase().split("").map(c => isWordChar(c) ? c : " ").join("").replace(/ +/g, " ").trim();
    }

    // whether a title starts with a name, ending at a word boundary
    // ("Cyberpunk 2077 (C) 2020 by CD Projekt RED" starts with "Cyberpunk 2077")
    function titleStartsWith(title, name) {
        const t = normalize(title), n = normalize(name);
        return n !== "" && (t === n || t.startsWith(n + " "));
    }

    // the game a window is, or null; cached by class and title
    property var cache: ({})
    onGamesChanged: cache = ({})

    function gameFor(cls, title) {
        const key = cls + "\n" + title;
        if (key in cache)
            return cache[key];
        const id = (cls.match(/^steam_app_(\d+)$/) ?? [])[1];
        let game = id ? games.find(g => g.steam === id) ?? null : null;
        if (!game) {
            const t = normalize(title);
            for (const g of games)
                if (g.key !== "" && (t === g.key || t.startsWith(g.key + " ")) && (!game || g.key.length > game.key.length))
                    game = g;
        }
        return cache[key] = game;
    }

    // the last output: a rescan that finds the same games changes nothing
    property string lastText: ""

    function parse(text) {
        if (text === lastText)
            return;
        lastText = text;
        try {
            games = JSON.parse(text).map(g => Object.assign(g, { key: normalize(g.name) }));
        } catch (e) {
            console.warn("Games: bad output from games.py:", e);
        }
    }

    Process {
        id: scan
        running: true
        command: ["python3", "-I", Quickshell.shellDir + "/scripts/games.py"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }

    // a game installed since the last scan is found once its window opens
    Timer {
        id: rescan
        interval: 1500
        onTriggered: scan.running = true
    }

    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (ev.name === "openwindow" && !scan.running)
                rescan.restart();
        }
    }
}

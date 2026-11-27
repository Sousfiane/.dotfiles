pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.config
import qs.services.launcher

// The app launcher's search: the desktop entries and their actions, ranked by the query and by use, and
// starting the one picked through uwsm-app. A first character switches to another mode:
//   = a calculation (plain math like "12*4" also shows its result above the apps), Enter copies it
//   : an emoji by name, Enter copies it
//   > a shell command, run in a terminal or in the background
//   ? a web search (or the address typed, opened)
//   / a file or folder in your home, opened with its default app (right click: the folder it's in)
Singleton {
    id: root

    property string query: ""

    readonly property bool open: Panels.isShown("launcher")      // its panel, or the hub's tab

    function toggle() {
        Panels.toggle("launcher");
    }

    // start fresh on every open
    onOpenChanged: if (open)
        query = ""

    // ---------- what the list shows ----------

    // One row per app, plus one per desktop action ("New Private Window"...) that the query names:
    //   { entry, action (null for the app itself), name, detail, icon }
    // Rows are made once and reused, so the list diffs them by identity and never reloads an icon.
    property var rowCache: ({})

    function rowFor(entry, action, index) {
        const key = action ? entry.id + "#" + index : entry.id;
        return rowCache[key] ?? (rowCache[key] = {
                entry,
                action,
                name: action ? action.name : entry.name,
                // an action shows the app it belongs to ("Settings" alone could be anyone's)
                detail: action ? entry.name : "",
                icon: (action?.icon || entry.icon) ?? ""
            });
    }

    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)
    onAppsChanged: rowCache = ({})          // an app was installed or removed: entries are new objects

    // ---------- modes ----------

    readonly property var modes: ({
            "=": "calc",
            ":": "emoji",
            ">": "run",
            "?": "web",
            "/": "files"
        })
    readonly property string mode: modes[query.charAt(0)] ?? "apps"
    readonly property string arg: query.slice(1).trim()          // what follows a mode's character

    // what the list shows: a mode's rows, or the apps (under the result of plain math)
    readonly property var results: {
        switch (mode) {
        case "calc":
            return calcRows(arg);
        case "emoji":
            return emojiRows(arg);
        case "run":
            return runRows(arg);
        case "web":
            return webRows(arg);
        case "files":
            return fileRows(arg);
        }
        return Calc.looksLikeMath(query) ? calcRows(query).concat(appResults) : appResults;
    }

    // the line of help under the list
    readonly property string hint: ({
            apps: "= calculate • : emoji • > run a command • ? search the web • / find a file",
            calc: "Enter copies the result • sqrt, sin, log, ln, pi, ^ …",
            emoji: "Enter copies the emoji",
            run: "Enter runs it in a terminal, or pick the background row",
            web: "Enter opens it in the browser",
            files: "Enter opens it with its default app • right click opens its folder"
        })[mode]

    // a row that only explains: Enter does nothing on it
    function note(glyph, text) {
        return {
            glyph,
            name: text,
            detail: "",
            run: null
        };
    }

    function copy(text) {
        Quickshell.execDetached(["wl-copy", "--", text]);
    }

    // ---------- calculator ----------

    function calcRows(text) {
        if (text === "")
            return [note(Icons.calculator, "Type a calculation")];
        const v = Calc.evaluate(text);
        if (v === null)
            return [note(Icons.calculator, "Not a calculation yet")];
        const result = Calc.format(v);
        return [
            {
                glyph: Icons.calculator,
                name: "= " + result,
                detail: "copy",
                run: () => copy(result)
            }
        ];
    }

    // ---------- emoji ----------

    // the list is read the first time ":" is typed
    Emojis {
        id: emojis
    }
    onModeChanged: if (mode === "emoji")
        emojis.wanted = true

    property var emojiRowCache: ({})

    function emojiRows(text) {
        if (emojis.missing)
            return [note(Icons.emoji, "Emoji need the unicode-emoji package")];
        return emojis.find(text, 80).map(e => emojiRowCache[e.char] ?? (emojiRowCache[e.char] = {
                    glyph: e.char,
                    emoji: true,
                    name: e.name.charAt(0).toUpperCase() + e.name.slice(1),
                    detail: "",
                    run: () => copy(e.char)
                }));
    }

    // ---------- commands ----------

    function runRows(cmd) {
        if (cmd === "")
            return [note(Icons.terminal, "Type a command")];
        return [
            {
                glyph: Icons.terminal,
                name: cmd,
                detail: "in a terminal",
                // the window stays until a key, so the output can be read
                run: () => Quickshell.execDetached(["uwsm-app", "--", ...Config.floatingTerm(["bash", "-c", cmd + "\nprintf '\\n[exit %d: press a key]' $?; read -rsn1"])])
            },
            {
                glyph: Icons.terminal,
                name: cmd,
                detail: "in the background",
                run: () => Quickshell.execDetached(["uwsm-app", "--", "bash", "-c", cmd])
            }
        ];
    }

    // ---------- web ----------

    function webRows(text) {
        if (text === "")
            return [note(Icons.web, "Type a search, or an address")];
        const rows = [];
        // one word with a dot ("archlinux.org", "https://…"): open it as an address too
        if (/^\S+\.\S+$/.test(text)) {
            const url = /^[a-z]+:\/\//i.test(text) ? text : "https://" + text;
            rows.push({
                glyph: Icons.web,
                name: url,
                detail: "open",
                run: () => Quickshell.execDetached(["xdg-open", url])
            });
        }
        rows.push({
            glyph: Icons.web,
            name: text,
            detail: "search the web",
            run: () => Quickshell.execDetached(["xdg-open", Config.searchUrl + encodeURIComponent(text)])
        });
        return rows;
    }

    // ---------- files ----------

    // fd runs only while "/" is typed
    FileSearch {
        id: fileSearch
        query: root.mode === "files" ? root.arg : ""
    }

    function fileRows(text) {
        if (text === "")
            return [note(Icons.folder, "Type a file or folder name")];
        if (fileSearch.paths.length === 0)
            return [note(Icons.folder, fileSearch.searching || fileSearch.foundFor !== text ? "Searching…" : "No file or folder called that")];
        const found = fileSearch.find(text, 60);
        if (found.length === 0)
            return [note(Icons.folder, "No file or folder called that")];
        return found.map(f => ({
                    glyph: f.glyph,
                    name: f.name,
                    detail: f.folder,
                    run: () => Quickshell.execDetached(["uwsm-app", "--", "xdg-open", f.path]),
                    alt: () => Quickshell.execDetached(["uwsm-app", "--", "xdg-open", f.dir])
                }));
    }

    // ---------- apps ----------

    readonly property var appResults: {
        if (mode !== "apps")
            return [];
        const q = query.toLowerCase().trim();

        // nothing typed: the apps you use, most first, then the rest alphabetically
        if (q === "")
            return apps.slice().sort((a, b) => LauncherHistory.frecency(b.id) - LauncherHistory.frecency(a.id) || a.name.localeCompare(b.name)).map(a => rowFor(a, null, 0));

        const words = q.split(/\s+/);
        const scored = [];
        for (const a of apps) {
            const frecency = LauncherHistory.frecency(a.id);
            // a small push for what you launch often: it orders matches of the same kind, never beats a better match
            const bonus = Math.min(90, 30 * Math.log2(1 + frecency));

            const s = Match.app(a, words);
            if (s > 0)
                scored.push({
                    row: rowFor(a, null, 0),
                    score: s + bonus
                });

            const actions = a.actions ?? [];
            for (let i = 0; i < actions.length; i++) {
                const t = Match.action(a, actions[i], words);
                if (t > 0)
                    scored.push({
                        row: rowFor(a, actions[i], i),
                        score: t + bonus
                    });
            }
        }
        scored.sort((x, y) => y.score - x.score || x.row.name.localeCompare(y.row.name));
        return scored.map(x => x.row);
    }

    // ---------- launching ----------

    // starts a desktop entry (also used by the notification center), or one of its actions
    function run(entry, action) {
        const command = action ? action.command : entry.command;
        const cmd = entry.runInTerminal ? Config.floatingTerm(command) : command;

        Quickshell.execDetached({
            command: ["uwsm-app", "--", ...cmd],
            workingDirectory: entry.workingDirectory
        });
    }

    // picked from the launcher: an app counts towards the ranking (an action counts for its app), a mode's
    // row does its thing; then it closes. A row that only explains does nothing and leaves it open
    function launch(row) {
        if (row?.entry) {
            LauncherHistory.record(row.entry.id);
            run(row.entry, row.action);
        } else if (row?.run) {
            row.run();
        } else if (row) {
            return;
        }
        Panels.hide("launcher");
    }

    // a row's other action (a file's folder), then it closes
    function launchAlt(row) {
        row.alt();
        Panels.hide("launcher");
    }
}

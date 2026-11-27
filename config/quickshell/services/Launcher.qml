pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

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

    readonly property bool open: Panels.isOpen("launcher")

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
        return looksLikeMath(query) ? calcRows(query).concat(appResults) : appResults;
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

    // the names a calculation may use; anything else and it isn't one (so nothing else can run)
    readonly property var mathNames: ({
            sqrt: "Math.sqrt",
            cbrt: "Math.cbrt",
            abs: "Math.abs",
            round: "Math.round",
            floor: "Math.floor",
            ceil: "Math.ceil",
            sin: "Math.sin",
            cos: "Math.cos",
            tan: "Math.tan",
            asin: "Math.asin",
            acos: "Math.acos",
            atan: "Math.atan",
            ln: "Math.log",
            log: "Math.log10",
            exp: "Math.exp",
            min: "Math.min",
            max: "Math.max",
            pi: "Math.PI",
            e: "Math.E"
        })

    // the value of a calculation, or null when it isn't one
    function evaluate(text) {
        let s = text.toLowerCase().replace(/\s+/g, "").replace(/×/g, "*").replace(/÷/g, "/").replace(/π/g, "pi").replace(/\^/g, "**");
        if (s === "")
            return null;
        // "3,5" is a decimal comma, unless a function is used (then a comma separates its arguments)
        if (!/[a-z]/.test(s))
            s = s.replace(/,/g, ".");
        if (!/^[0-9a-z.+\-*\/%(),]+$/.test(s))
            return null;
        let unknown = false;
        s = s.replace(/[a-z]+/g, w => mathNames[w] ?? (unknown = true, ""));
        if (unknown)
            return null;
        try {
            const v = Function('"use strict"; return (' + s + ");")();
            return typeof v === "number" && isFinite(v) ? v : null;
        } catch (e) {
            return null;
        }
    }

    // 0.1 + 0.2 shows 0.3: twelve significant digits, trailing zeros dropped
    function formatNumber(v) {
        return Number.isInteger(v) ? String(v) : String(parseFloat(v.toPrecision(12)));
    }

    // only digits and operators, with an operator: worth a result row above the apps
    function looksLikeMath(q) {
        return /^[\d\s.,+\-*\/%^()×÷]+$/.test(q) && /\d/.test(q) && /[+\-*\/%^×÷]/.test(q) && evaluate(q) !== null;
    }

    function calcRows(text) {
        if (text === "")
            return [note(Icons.calculator, "Type a calculation")];
        const v = evaluate(text);
        if (v === null)
            return [note(Icons.calculator, "Not a calculation yet")];
        const result = formatNumber(v);
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

    // Unicode's list (the unicode-emoji package), read the first time ":" is typed
    property bool emojiWanted: false
    property bool emojiMissing: false
    property var emojis: []                 // [{ char, name, words }]
    property var emojiRowCache: ({})

    onModeChanged: if (mode === "emoji")
        emojiWanted = true

    FileView {
        path: root.emojiWanted ? "/usr/share/unicode/emoji/emoji-test.txt" : ""
        printErrors: false
        onLoaded: root.emojis = root.parseEmoji(text())
        onLoadFailed: root.emojiMissing = true
    }

    // "1F600 ; fully-qualified # 😀 E1.0 grinning face", under "# subgroup: face-smiling". The skin tone
    // variants are left out: the list would be five times as long
    function parseEmoji(text) {
        const out = [];
        let subgroup = "";
        for (const line of text.split("\n")) {
            if (line.startsWith("# subgroup:")) {
                subgroup = line.slice(11).trim().replace(/-/g, " ");
                continue;
            }
            const m = line.match(/; fully-qualified\s+#\s+(\S+)\s+E[\d.]+\s+(.+)$/);
            if (m && !m[2].includes("skin tone"))
                out.push({
                    char: m[1],
                    name: m[2],
                    words: (m[2] + " " + subgroup).toLowerCase()
                });
        }
        return out;
    }

    function emojiRows(text) {
        if (emojiMissing)
            return [note(Icons.emoji, "Emoji need the unicode-emoji package")];
        const words = text.toLowerCase().split(/\s+/).filter(w => w !== "");
        // every word in the name or its subgroup; names that start with the first word first
        const found = words.length === 0 ? emojis : emojis.filter(e => words.every(w => e.words.includes(w)));
        const ranked = words.length === 0 ? found : found.map((e, i) => ({
                    e,
                    i,
                    rank: e.name.startsWith(words[0]) ? 0 : e.name.includes(" " + words[0]) ? 1 : 2
                })).sort((a, b) => a.rank - b.rank || a.i - b.i).map(x => x.e);
        return ranked.slice(0, 80).map(e => emojiRowCache[e.char] ?? (emojiRowCache[e.char] = {
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

    // fd over the home folder, run again as the query settles; only while "/" is typed, so it costs
    // nothing otherwise. Hidden files and what .gitignore files leave out aren't searched
    readonly property string home: Quickshell.env("HOME")
    property var files: []              // the paths fd found for the last query
    property string filesQuery: ""      // the query those are for
    property bool filesSearching: false

    onArgChanged: if (mode === "files")
        fileDebounce.restart()

    Timer {
        id: fileDebounce
        interval: 150
        onTriggered: root.searchFiles()
    }

    function searchFiles() {
        const words = arg.split(/\s+/).filter(w => w !== "");
        if (words.length === 0) {
            files = [];
            filesQuery = "";
            return;
        }
        // fd matches the first word on names; the others narrow its results down below, on the whole path
        fileSearch.running = false;
        fileSearch.wanted = arg;
        fileSearch.command = ["fd", "--fixed-strings", "--ignore-case", "--max-results", "400", "--exclude", "node_modules", "--", words[0], home];
        filesSearching = true;
        fileSearch.running = true;
    }

    Process {
        id: fileSearch
        property string wanted: ""
        stdout: StdioCollector {
            onStreamFinished: {
                root.files = text.split("\n").filter(l => l !== "");
                root.filesQuery = fileSearch.wanted;
                root.filesSearching = false;
            }
        }
    }

    // a glyph for what a path holds, from its extension
    function fileGlyph(path) {
        if (path.endsWith("/"))
            return Icons.folder;
        const ext = path.slice(path.lastIndexOf(".") + 1).toLowerCase();
        if (["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "avif", "heic"].includes(ext))
            return Icons.fileImage;
        if (["mp4", "mkv", "webm", "mov", "avi"].includes(ext))
            return Icons.fileVideo;
        if (["mp3", "flac", "ogg", "opus", "wav", "m4a"].includes(ext))
            return Icons.fileMusic;
        if (ext === "pdf")
            return Icons.filePdf;
        if (["txt", "md", "odt", "doc", "docx", "rtf", "ods", "xls", "xlsx", "odp", "ppt", "pptx", "csv"].includes(ext))
            return Icons.fileDocument;
        return Icons.file;
    }

    function fileRows(text) {
        if (text === "")
            return [note(Icons.folder, "Type a file or folder name")];
        if (files.length === 0)
            return [note(Icons.folder, filesSearching || filesQuery !== text ? "Searching…" : "No file or folder called that")];

        const words = text.toLowerCase().split(/\s+/).filter(w => w !== "");
        const rows = [];
        for (const path of files) {
            const rel = path.startsWith(home + "/") ? path.slice(home.length + 1) : path;
            const low = rel.toLowerCase();
            if (!words.every(w => low.includes(w)))
                continue;
            const trimmed = rel.endsWith("/") ? rel.slice(0, -1) : rel;
            const name = trimmed.slice(trimmed.lastIndexOf("/") + 1);
            const lowName = name.toLowerCase();
            // the name itself first, then names that start with the word, then shallow paths
            const rank = (lowName === words[0] ? 0 : lowName.startsWith(words[0]) ? 1 : 2) * 1000 + trimmed.split("/").length * 10 + Math.min(9, name.length / 8);
            const dir = path.slice(0, path.length - (rel.endsWith("/") ? 1 : 0) - name.length);
            rows.push({
                rank,
                row: {
                    glyph: fileGlyph(rel),
                    name,
                    detail: "~/" + trimmed.slice(0, trimmed.length - name.length),
                    run: () => Quickshell.execDetached(["uwsm-app", "--", "xdg-open", path]),
                    alt: () => Quickshell.execDetached(["uwsm-app", "--", "xdg-open", dir])
                }
            });
        }
        if (rows.length === 0)
            return [note(Icons.folder, "No file or folder called that")];
        rows.sort((a, b) => a.rank - b.rank || a.row.name.localeCompare(b.row.name));
        return rows.slice(0, 60).map(r => r.row);
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

            const s = scoreApp(a, words);
            if (s > 0)
                scored.push({
                    row: rowFor(a, null, 0),
                    score: s + bonus
                });

            const actions = a.actions ?? [];
            for (let i = 0; i < actions.length; i++) {
                const t = scoreAction(a, actions[i], words);
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

    // ---------- matching ----------

    // how well `word` matches `text`, 0..100: whole > start > start of a word > anywhere > (fuzzy) in order
    function match(text, word, fuzzy) {
        const t = (text ?? "").toLowerCase();
        if (t === "")
            return 0;
        if (t === word)
            return 100;
        if (t.startsWith(word))
            return 90;
        const at = t.indexOf(word);
        if (at > 0 && /[^a-z0-9]/.test(t[at - 1]))
            return 80;
        if (at > 0)
            return 70;
        return fuzzy ? subsequence(t, word) : 0;
    }

    // "lbo" in "libreoffice": every letter in order, scored by how close together they are (10..40)
    function subsequence(t, word) {
        let i = 0, first = -1, last = -1;
        for (const ch of word) {
            i = t.indexOf(ch, i);
            if (i < 0)
                return 0;
            if (first < 0)
                first = i;
            last = i++;
        }
        const spread = last - first + 1 - word.length;      // letters skipped in between
        return Math.max(10, 40 - 3 * spread);
    }

    // the name counts most; what kind of app it is and its keywords next; its description last.
    // Every word of the query must match somewhere; the weakest one sets the score
    function scoreApp(a, words) {
        const keywords = [].concat(a.keywords ?? []);
        let total = Infinity;
        for (const w of words) {
            const s = Math.max(match(a.name, w, true) * 10, match(a.genericName, w, false) * 6, Math.max(0, ...keywords.map(k => match(k, w, false))) * 6, match(a.comment, w, false) * 3);
            if (s === 0)
                return 0;
            total = Math.min(total, s);
        }
        return total;
    }

    // an action shows when the query names it ("private"), alone or with its app ("zen private").
    // Below the apps: typing "zen" lists Zen first, its actions only when asked for
    function scoreAction(a, action, words) {
        let named = false;
        let total = Infinity;
        for (const w of words) {
            const onAction = match(action.name, w, false);
            const onApp = match(a.name, w, false);
            if (onAction === 0 && onApp === 0)
                return 0;
            named = named || onAction > 0;
            total = Math.min(total, Math.max(onAction, onApp) * 5);
        }
        return named ? total : 0;
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

pragma Singleton
import Quickshell
import QtQuick
import qs.config

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

    readonly property var results: {
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

    // picked from the launcher: counts towards the ranking (an action counts for its app), then closes it
    function launch(row) {
        if (row) {
            LauncherHistory.record(row.entry.id);
            run(row.entry, row.action);
        }
        Panels.hide("launcher");
    }
}

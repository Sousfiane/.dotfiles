pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// Installing and removing packages, for the Install and Remove panels.
//
//   install   searches the official repos (pacman -Ss) and the AUR (yay -Ssa) as you type; the repos answer
//             at once, the AUR (over the network) joins in when it answers
//   remove    the packages installed on purpose (pacman -Qe), the AUR ones marked, with the dotfiles' package
//             list each is in (install/packages/*.txt), since removing one there doesn't take it off the list
//
// Either runs yay in a floating terminal, like the updates panel: sudo's password, AUR build files and
// pacman's [Y/n] are all answered there, and the lists are read again when it closes.
Singleton {
    id: root

    readonly property string listsDir: Quickshell.env("HOME") + "/.dotfiles/install/packages"

    // ---------- install: search ----------

    property string query: ""
    // [{ name, repo, version, description, installed, votes }], best matches first
    property var repoResults: []
    property var aurResults: []
    readonly property var results: sortResults(repoResults.concat(aurResults))
    readonly property bool searching: repoSearch.running || aurSearch.running

    onQueryChanged: searchDelay.restart()

    // wait for a pause in the typing: each search is a process, and the AUR's a request over the network
    Timer {
        id: searchDelay
        interval: 300
        onTriggered: root.search()
    }

    function search() {
        const q = query.trim();
        repoSearch.running = false;
        aurSearch.running = false;
        if (q.length < 2) {
            repoResults = [];
            aurResults = [];
            return;
        }
        // pacman reads a regular expression: the text is matched as typed
        repoSearch.command = ["pacman", "-Ss", "--color", "never", "--", q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")];
        aurSearch.command = ["yay", "-Ssa", "--color", "never", "--", q];
        repoSearch.running = true;
        aurSearch.running = true;
    }

    // "repo/name version [installed]" (the AUR adds "(+votes popularity) [age]"), then the description
    // indented on the next line
    function parseSearch(text) {
        const out = [];
        const lines = text.split("\n");
        for (let i = 0; i < lines.length; i++) {
            const m = lines[i].match(/^(\S+)\/(\S+) (\S+)(.*)$/);
            if (!m)
                continue;
            const votes = m[4].match(/\(\+(\d+)/);
            out.push({
                repo: m[1],
                name: m[2],
                version: m[3],
                installed: /[\[(]installed/i.test(m[4]),
                votes: votes ? parseInt(votes[1]) : 0,
                description: (lines[i + 1] ?? "").match(/^\s/) ? lines[i + 1].trim() : ""
            });
        }
        return out;
    }

    // the name typed first, then names that start with it, then the repos before the AUR (the AUR by votes)
    function sortResults(list) {
        const q = query.trim().toLowerCase();
        const rank = p => p.name === q ? 0 : p.name.startsWith(q) ? 1 : 2;
        return list.slice().sort((a, b) => rank(a) - rank(b) || (a.repo === "aur") - (b.repo === "aur") || b.votes - a.votes || a.name.localeCompare(b.name)).slice(0, 200);
    }

    Process {
        id: repoSearch
        stdout: StdioCollector {
            onStreamFinished: root.repoResults = root.parseSearch(text)
        }
    }

    Process {
        id: aurSearch
        stdout: StdioCollector {
            onStreamFinished: root.aurResults = root.parseSearch(text)
        }
    }

    // ---------- remove: what's installed ----------

    // [{ name, version, aur, list }], by name; `list` is the dotfiles list it's in ("desktop.txt"), or ""
    property var installed: []
    readonly property bool loading: lister.running

    function refresh() {
        lister.running = true;
    }

    Process {
        id: lister

        // "e name version" for each package installed on purpose, "m name" for the AUR ones (foreign), and
        // "l name file" for each package the dotfiles' lists name
        command: ["sh", "-c", `
            pacman -Qe | sed 's/^/e /'
            pacman -Qqem | sed 's/^/m /'
            for f in "$1"/*.txt; do
                [ "$(basename "$f")" = remove.txt ] && continue
                sed 's/#.*//' "$f" | awk -v f="$(basename "$f")" 'NF { print "l " $1 " " f }'
            done`, "sh", root.listsDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const pkgs = [], aur = new Set(), lists = {};
                for (const line of text.split("\n")) {
                    const [kind, name, extra] = line.split(" ");
                    if (kind === "e")
                        pkgs.push({ name, version: extra });
                    else if (kind === "m")
                        aur.add(name);
                    else if (kind === "l")
                        lists[name] = extra;
                }
                root.installed = pkgs.map(p => Object.assign(p, {
                    aur: aur.has(p.name),
                    list: lists[p.name] ?? ""
                }));
            }
        }
    }

    // ---------- running yay ----------

    readonly property bool busy: runner.running

    // a repo package as "extra/name", an AUR one as "aur/name", so yay installs that one and doesn't ask
    function install(pkg) {
        run("install", ["yay", "-S", "--", pkg.repo + "/" + pkg.name]);
    }

    function remove(pkg) {
        run("remove", ["yay", "-Rns", "--", pkg.name]);
    }

    function run(panel, cmd) {
        if (runner.running)
            return;
        Panels.hide(panel);
        // the command as arguments of bash, never in its script: a package name is only ever an argument
        runner.command = ["uwsm", "app", "--", ...Config.floatingTerm(["bash", "-c", '"$@"; echo; read -rp "Press Enter to close..."', "bash", ...cmd])];
        runner.running = true;
    }

    // `uwsm app` returns when the terminal closes: what's installed (and the search's marks) changed
    Process {
        id: runner
        onExited: {
            root.refresh();
            root.search();
            Updates.refresh();
        }
    }
}

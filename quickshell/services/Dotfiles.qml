pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// The dotfiles repository: its status, and the few git actions the panel needs to replace lazygit
// (stage, discard, diff, commit, pull, push).
Singleton {
    id: root

    readonly property string repoPath: Config.dotfilesRepo

    // ---------- state ----------

    // one entry per changed path, in git's order:
    //   { path, orig, x, y, staged, unstaged, untracked }
    // x / y are git's index / worktree letters; `orig` is the old path of a rename
    property var files: []
    readonly property int count: files.length
    readonly property int stagedCount: files.filter(f => f.staged).length

    property string branch: ""
    property string upstream: ""
    property int ahead: 0
    property int behind: 0

    property bool failed: false
    readonly property bool checking: statusProc.running

    // the action being run ("push", "pull"...), "" when idle
    property string busy: ""
    // the last action's outcome, shown under the list
    property string message: ""
    property bool messageError: false

    // the commit message being written, kept until a commit succeeds
    property string draft: ""

    // ---------- panel ----------

    readonly property bool open: Panels.isOpen("dotfiles")

    function toggle() {
        Panels.toggle("dotfiles");
    }

    // opening the panel is when the numbers matter: look again, and ask the remote what's new
    onOpenChanged: {
        if (open) {
            refresh();
            fetch(true);
        }
    }

    // ---------- git status ----------

    function refresh() {
        if (statusProc.running)
            statusProc.again = true;
        else
            statusProc.running = true;
    }

    // "## main...origin/main [ahead 1, behind 2]", "## No commits yet on main", "## HEAD (no branch)"
    function parseBranch(line) {
        const head = line.replace(/^## /, "");
        const m = head.match(/^(?:No commits yet on |Initial commit on )?(.+?)(?:\.\.\.(\S+))?(?: \[(.*)\])?$/);
        branch = m ? m[1] : head;
        upstream = m?.[2] ?? "";
        const info = m?.[3] ?? "";
        ahead = Number(info.match(/ahead (\d+)/)?.[1] ?? 0);
        behind = Number(info.match(/behind (\d+)/)?.[1] ?? 0);
    }

    function parseStatus(text) {
        // fields come NUL-separated (turned into newlines): "XY path", then the old path after a rename
        const fields = text.split("\n");
        const list = [];
        for (let i = 0; i < fields.length; i++) {
            const f = fields[i];
            if (f === "")
                continue;
            if (f.startsWith("## ")) {
                parseBranch(f);
                continue;
            }
            const x = f.charAt(0), y = f.charAt(1);
            const entry = {
                path: f.slice(3),
                orig: "",
                x: x,
                y: y,
                untracked: x === "?",
                staged: x !== " " && x !== "?" && x !== "!",
                unstaged: y !== " "
            };
            if (x === "R" || x === "C")
                entry.orig = fields[++i] ?? "";
            list.push(entry);
        }
        files = list;
    }

    Process {
        id: statusProc

        property bool again: false     // asked while running: look once more when done

        command: ["bash", "-c", "set -o pipefail; git -C \"$0\" status --porcelain=v1 -z -b --untracked-files=all | tr '\\0' '\\n'", root.repoPath]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.parseStatus(text)
        }

        onExited: (code, status) => {
            root.failed = code !== 0;
            if (again) {
                again = false;
                running = true;
            }
        }
    }

    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    // ---------- actions ----------

    // git commands run one after the other, so quick key presses never race each other.
    // Each job: { args, label, quiet, done }. `label` names it in the panel while it runs and in
    // the message after; quiet jobs only speak up when they fail. `done(ok)` runs after it.
    property var queue: []

    function run(args, label, quiet, done) {
        queue = queue.concat([
            {
                args: args,
                label: label ?? "",
                quiet: !!quiet,
                done: done ?? null,
                remote: ["pull", "push", "fetch"].includes(args[0])
            }
        ]);
        next();
    }

    function needsAuth(lines) {
        return lines.some(l => /Permission denied|Could not read from remote|passphrase|terminal prompts disabled|could not read (Username|Password)/i.test(l));
    }

    // ---------- SSH passphrase ----------

    // No SSH agent holds the key, so a remote command that needs it fails. The panel then asks for the
    // passphrase and runs the command again with scripts/askpass.sh answering ssh's prompt. The passphrase
    // only lives in that one command's environment; nothing keeps it afterwards.
    property var authJob: null
    readonly property bool askingPass: authJob !== null
    readonly property string askpass: Quickshell.shellDir + "/scripts/askpass.sh"

    function submitPass(pass) {
        const j = authJob;
        authJob = null;
        if (!j || pass === "")
            return;
        queue = [Object.assign({}, j, {
                pass: pass
            })].concat(queue);
        next();
    }

    function cancelPass() {
        authJob = null;
        message = "";
    }

    function next() {
        if (job.running || queue.length === 0)
            return;
        job.current = queue[0];
        queue = queue.slice(1);
        if (!job.current.quiet)
            busy = job.current.label;
        job.environment = Object.assign({
            GIT_TERMINAL_PROMPT: "0",
            GIT_EDITOR: "true",
            SSH_ASKPASS_REQUIRE: job.current.pass ? "force" : "never"
        }, job.current.pass ? {
            SSH_ASKPASS: root.askpass,
            QS_SSH_PASS: job.current.pass
        } : {});
        job.command = ["sh", "-c", "git -C \"$0\" \"$@\" 2>&1; printf '\\n%s' \"$?\"", root.repoPath, ...job.current.args];
        job.running = true;
    }

    function finished(output) {
        const lines = output.replace(/\s+$/, "").split("\n");
        const code = Number(lines.pop());
        const ok = code === 0;
        const j = job.current;
        const said = lines.filter(l => l.trim() !== "");

        if (!ok && j.remote && needsAuth(said)) {
            // the key needs its passphrase: ask for it in the panel. Background fetches just give up
            if (!j.quiet) {
                authJob = {
                    args: j.args,
                    label: j.label,
                    quiet: false,
                    done: j.done,
                    remote: true
                };
                message = j.pass ? "Wrong passphrase" : "";
                messageError = !!j.pass;
            }
        } else if (!ok) {
            // git puts the reason last ("fatal: ...", "error: ..."), after hints
            const reason = said.filter(l => /^(fatal|error):/.test(l)).pop() ?? said.pop() ?? "exit code " + code;
            message = (j.label !== "" ? j.label + " failed: " : "") + reason.replace(/^(fatal|error):\s*/, "");
            messageError = true;
        } else if (!j.quiet && j.label !== "") {
            message = j.label + " done";
            messageError = false;
        }

        busy = "";
        // forget the passphrase as soon as its command is over
        job.current = null;
        job.environment = {};
        if (j.done)
            j.done(ok);
        if (queue.length === 0)
            refresh();
        next();
    }

    Process {
        id: job

        property var current: null

        // set for each command in next(): no terminal to answer a prompt, so fail instead of hanging,
        // unless a passphrase was typed in the panel for this command

        stdout: StdioCollector {
            onStreamFinished: root.finished(text)
        }
    }

    function stage(f) {
        if (f)
            run(["add", "-A", "--", f.path]);
    }

    function unstage(f) {
        if (!f)
            return;
        const paths = f.orig !== "" ? [f.orig, f.path] : [f.path];
        run(["reset", "-q", "--", ...paths]);
    }

    // fully staged files get unstaged; anything with work left in the tree gets staged
    function toggleStage(f) {
        if (!f)
            return;
        if (f.staged && !f.unstaged)
            unstage(f);
        else
            stage(f);
    }

    // everything staged already: unstage all. Otherwise stage all
    function toggleStageAll() {
        if (count > 0 && files.every(f => f.staged && !f.unstaged))
            run(["reset", "-q"]);
        else
            run(["add", "-A"]);
    }

    // throws the file's changes away: back to HEAD, or deleted if git never knew it
    function discard(f) {
        if (!f)
            return;
        if (f.untracked)
            run(["clean", "-fq", "--", f.path], "Discard");
        else if (f.x === "A")
            run(["rm", "-fq", "--", f.path], "Discard");
        else if (f.orig !== "")
            run(["reset", "-q", "--", f.orig, f.path], "", true, () => {
                run(["checkout", "HEAD", "--", f.orig], "Discard");
                run(["clean", "-fq", "--", f.path], "", true);
            });
        else
            run(["checkout", "HEAD", "--", f.path], "Discard");
    }

    // commits what's staged, or everything when nothing is
    function commit(msg) {
        const text = msg.trim();
        if (text === "") {
            message = "Write a commit message first";
            messageError = true;
            return;
        }
        if (count === 0) {
            message = "Nothing to commit";
            messageError = true;
            return;
        }
        if (stagedCount === 0)
            run(["add", "-A"], "", true);
        run(["commit", "-q", "-m", text], "Commit", false, ok => {
            if (ok)
                root.draft = "";
        });
    }

    function pull() {
        run(["pull", "--ff-only", "-q"], "Pull");
    }

    function push() {
        run(upstream === "" ? ["push", "-q", "-u", "origin", "HEAD"] : ["push", "-q"], "Push");
    }

    // quiet when the panel fetches on its own: no passphrase prompt, no error
    function fetch(quiet) {
        run(["fetch", "-q"], "Fetch", quiet ?? false);
    }

    // ---------- diff ----------

    property string diffPath: ""
    property var diffLines: []
    readonly property bool diffLoading: diffProc.running
    readonly property int maxDiffLines: 3000

    // the file's changes against HEAD (staged and not), or its whole content when it's new
    function loadDiff(f) {
        diffLines = [];
        diffPath = f ? f.path : "";
        if (!f) {
            diffProc.pending = null;
            return;
        }
        let args;
        if (f.untracked)
            args = ["diff", "--no-color", "--no-ext-diff", "--no-index", "--", "/dev/null", f.path];
        else if (f.orig !== "")
            args = ["diff", "--no-color", "--no-ext-diff", "-M", "HEAD", "--", f.orig, f.path];
        else
            args = ["diff", "--no-color", "--no-ext-diff", "HEAD", "--", f.path];
        // one diff at a time: a newer request waits for the running one, whose output is then dropped
        diffProc.pending = ["git", "-C", root.repoPath, ...args];
        if (!diffProc.running)
            diffProc.start();
    }

    Process {
        id: diffProc

        property var pending: null

        function start() {
            command = pending;
            pending = null;
            running = true;
        }

        onExited: if (pending)
            start()

        stdout: StdioCollector {
            onStreamFinished: {
                if (diffProc.pending)
                    return;
                // the header lines say nothing the panel doesn't already show; start at the first hunk
                const all = text.replace(/\n$/, "").split("\n");
                const first = all.findIndex(l => l.startsWith("@@") || l.startsWith("Binary"));
                let lines = first >= 0 ? all.slice(first) : all.filter(l => l !== "");
                if (lines.length > root.maxDiffLines)
                    lines = lines.slice(0, root.maxDiffLines).concat(["… " + (lines.length - root.maxDiffLines) + " more lines"]);
                root.diffLines = lines;
            }
        }
    }
}

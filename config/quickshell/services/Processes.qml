pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Every process, busiest first, and ending one: for the hub's System tab (modules/hub/ProcessList.qml).
// Read by scripts/procs.py, which reads /proc itself, only while a view uses it: use() when it appears,
// release() when it goes.
Singleton {
    id: root

    property int users: 0
    readonly property bool active: users > 0
    readonly property int interval: 1500

    function use() {
        users++;
    }
    function release() {
        users = Math.max(0, users - 1);
        if (users === 0)
            held = false;
    }

    // { pid, name, user, cpu (0..1 of the whole CPU), rss (bytes) }, busiest first. A ListModel updated in
    // place, so a view scrolled down stays where it is and its rows are reused, not rebuilt
    property alias processes: procModel
    property bool read: false
    // while held (the pointer on the list), the rows keep their order: only their figures change, gone
    // ones leave and new ones come last, so a row doesn't slide away just as it is clicked
    property bool held: false

    ListModel {
        id: procModel
    }

    function apply(list) {
        if (held && procModel.count) {
            const byPid = {};
            for (const p of list)
                byPid[p.pid] = p;
            for (let i = procModel.count - 1; i >= 0; i--) {
                const pid = procModel.get(i).pid;
                if (byPid[pid]) {
                    procModel.set(i, byPid[pid]);
                    delete byPid[pid];
                } else {
                    procModel.remove(i);
                }
            }
            for (const p of list)
                if (byPid[p.pid])
                    procModel.append(p);
        } else {
            for (let i = 0; i < list.length; i++) {
                if (i < procModel.count)
                    procModel.set(i, list[i]);
                else
                    procModel.append(list[i]);
            }
            if (procModel.count > list.length)
                procModel.remove(list.length, procModel.count - list.length);
        }
        read = true;
    }

    // ---------- ending a process: TERM asks it to quit, KILL (force) ends it at once ----------

    property string killMessage: ""
    property bool killFailed: false

    function kill(pid, name, force) {
        if (killer.running)
            return;
        killer.name = name;
        killer.what = (force ? "Killed " : "Asked to quit: ") + name + " (" + pid + ")";
        killer.force = force;
        killer.pid = pid;
        killer.command = ["kill", "-s", force ? "KILL" : "TERM", String(pid)];
        killer.running = true;
    }

    Process {
        id: killer

        property string name
        property string what
        property bool force
        property int pid

        stderr: StdioCollector {
            id: killErr
        }
        onExited: code => {
            root.killFailed = code !== 0;
            root.killMessage = code === 0 ? what : "Couldn't end " + name + ": " + (killErr.text.trim().split(": ").pop() || "kill failed");
            killMessageTimer.restart();
            // a killed process is gone: off the list now rather than at the next frame
            if (code === 0 && force)
                for (let i = 0; i < procModel.count; i++)
                    if (procModel.get(i).pid === pid) {
                        procModel.remove(i);
                        break;
                    }
        }
    }
    Timer {
        id: killMessageTimer
        interval: 4000
        onTriggered: root.killMessage = ""
    }

    // the list (scripts/procs.py): one JSON line per frame
    Process {
        running: root.active
        command: ["python3", "-I", Quickshell.shellDir + "/scripts/procs.py", String(root.interval / 1000)]
        stdout: SplitParser {
            onRead: line => {
                let frame;
                try {
                    frame = JSON.parse(line);
                } catch (e) {
                    console.warn("Processes: bad output from procs.py:", e);
                    return;
                }
                root.apply(frame.procs);
            }
        }
    }
}

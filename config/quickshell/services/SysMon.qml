pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// System figures for the hub: CPU, memory and GPU (its Home row), plus per core, frequency, load,
// network and disks (its System tab; the processes are services/Processes.qml). Nothing is read unless
// something on screen uses it: a view calls use() when it appears and release() when it goes, and detail
// views useDetail()/releaseDetail() for the costlier parts (frequency, load, network, disks).
Singleton {
    id: root

    property int users: 0
    property int detailUsers: 0
    readonly property bool active: users > 0
    readonly property bool detailed: detailUsers > 0

    function use() {
        users++;
    }
    function release() {
        users = Math.max(0, users - 1);
    }
    function useDetail() {
        detailUsers++;
        users++;
    }
    function releaseDetail() {
        detailUsers = Math.max(0, detailUsers - 1);
        release();
    }

    readonly property int interval: 1500
    readonly property int historyLength: 60          // samples kept for the graphs: 90 s

    // a graph's history starts empty every time the figures start being read again, so it never joins two
    // moments with a line across the time nothing was read
    onActiveChanged: if (active) {
        ticks = 0;
        cpuHistory = [];
        memHistory = [];
        gpuHistory = [];
        lastCpu = null;
    }
    onDetailedChanged: if (detailed) {
        downHistory = [];
        upHistory = [];
        lastNet = null;
        df.running = true;
    }

    function pushed(list, v) {
        const out = list.concat([v]);
        return out.length > historyLength ? out.slice(out.length - historyLength) : out;
    }

    // ---------- CPU: the time spent busy since the last reading, overall and per core ----------

    property var lastCpu: null           // [[busy, total], ...]: overall first, then each core
    property real cpu: -1                // 0..1, -1 until two readings exist
    property var cores: []               // 0..1 each
    property var cpuHistory: []
    property real cpuTemp: -1            // °C
    property real cpuGhz: 0              // the cores' average clock
    property string load: ""             // "0.19 0.22 0.91"

    function readStat(text) {
        const now = [];
        for (const line of text.split("\n")) {
            if (!line.startsWith("cpu"))
                break;
            const f = line.trim().split(/\s+/).slice(1, 9).map(Number);
            const idle = f[3] + f[4];                        // idle + iowait
            const total = f.reduce((a, b) => a + b, 0);
            now.push([total - idle, total]);
        }
        if (lastCpu && lastCpu.length === now.length) {
            const use = now.map((n, i) => {
                const dt = n[1] - lastCpu[i][1];
                return dt > 0 ? Math.max(0, Math.min(1, (n[0] - lastCpu[i][0]) / dt)) : 0;
            });
            cpu = use[0];
            cores = use.slice(1);
            cpuHistory = pushed(cpuHistory, cpu);
        }
        lastCpu = now;
    }

    // ---------- memory ----------

    property real memTotal: 0            // GiB
    property real memUsed: -1            // what apps hold (total - available)
    property real memCached: 0           // page cache, given back when needed
    property real swapTotal: 0
    property real swapUsed: 0
    property var memHistory: []

    function readMeminfo(text) {
        const kb = key => Number((text.match(new RegExp("^" + key + ":\\s+(\\d+)", "m")) ?? [0, 0])[1]) / 1048576;
        memTotal = kb("MemTotal");
        memUsed = memTotal - kb("MemAvailable");
        memCached = kb("Cached") + kb("SReclaimable");
        swapTotal = kb("SwapTotal");
        swapUsed = swapTotal - kb("SwapFree");
        if (memTotal > 0)
            memHistory = pushed(memHistory, memUsed / memTotal);
    }

    // ---------- GPU (NVIDIA: one nvidia-smi in its own loop mode) ----------

    property bool hasGpu: false
    property real gpu: -1
    property real gpuTemp: -1
    property real vramUsed: 0            // GiB
    property real vramTotal: 0
    property real gpuWatts: -1
    property var gpuHistory: []

    // ---------- network: bytes per second over every real interface ----------

    property var lastNet: null           // [rx, tx, ms]
    property real down: 0                // bytes/s
    property real up: 0
    property var downHistory: []         // bytes/s
    property var upHistory: []

    function readNetDev(text) {
        let rx = 0, tx = 0;
        for (const line of text.split("\n").slice(2)) {
            const [name, rest] = line.split(":");
            if (!rest || /^(lo|veth|docker|br-|virbr|tun|tap)/.test(name.trim()))
                continue;
            const f = rest.trim().split(/\s+/).map(Number);
            rx += f[0];
            tx += f[8];
        }
        const ms = Date.now();
        if (lastNet && ms > lastNet[2]) {
            down = Math.max(0, (rx - lastNet[0]) * 1000 / (ms - lastNet[2]));
            up = Math.max(0, (tx - lastNet[1]) * 1000 / (ms - lastNet[2]));
            downHistory = pushed(downHistory, down);
            upHistory = pushed(upHistory, up);
        }
        lastNet = [rx, tx, ms];
    }

    // ---------- disks ----------

    property var disks: []               // [{ mount, size, used }] in bytes

    // ---------- reading ----------

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: root.readStat(text())
    }
    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: root.readMeminfo(text())
    }
    FileView {
        id: loadavg
        path: "/proc/loadavg"
        onLoaded: root.load = text().split(" ").slice(0, 3).join(" ")
    }
    FileView {
        id: netdev
        path: "/proc/net/dev"
        onLoaded: root.readNetDev(text())
    }

    // the CPU's temperature file: AMD's k10temp / zenpower, or Intel's coretemp (its package sensor).
    // Its hwmon number changes between boots, so it is looked up by name, once
    property string tempPath: ""
    FileView {
        id: temp
        path: root.tempPath.startsWith("/") ? root.tempPath : ""
        printErrors: false
        onLoaded: root.cpuTemp = Number(text().trim()) / 1000
    }
    Process {
        running: root.active && root.tempPath === ""
        command: ["bash", "-c", `for h in /sys/class/hwmon/hwmon*; do
    case $(cat "$h/name") in k10temp|zenpower|coretemp) echo "$h/temp1_input"; exit ;; esac
done; echo none`]
        stdout: StdioCollector {
            onStreamFinished: root.tempPath = text.trim() === "none" ? "-" : text.trim()
        }
    }

    // the first two readings close together, so the figures (a difference between two) show at once
    property int ticks: 0
    Timer {
        running: root.active
        interval: root.ticks < 2 ? 250 : root.interval
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.ticks++;
            stat.reload();
            meminfo.reload();
            if (root.tempPath.startsWith("/"))
                temp.reload();
            if (root.detailed) {
                loadavg.reload();
                netdev.reload();
                for (let i = 0; i < freqFiles.count; i++)
                    freqFiles.objectAt(i)?.reload();
            }
        }
    }

    Process {
        running: root.active
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw", "--format=csv,noheader,nounits", "-lms", String(root.interval)]
        stdout: SplitParser {
            onRead: line => {
                const f = line.split(",").map(s => Number(s.trim()));
                if (isNaN(f[0]))
                    return;
                root.hasGpu = true;
                root.gpu = f[0] / 100;
                root.gpuTemp = f[1];
                root.vramUsed = f[2] / 1024;
                root.vramTotal = f[3] / 1024;
                root.gpuWatts = isNaN(f[4]) ? -1 : f[4];
                root.gpuHistory = root.pushed(root.gpuHistory, root.gpu);
            }
        }
    }

    // local disks, and network ones that answer within 3 s (a NAS that is down must not hang this)
    Process {
        id: df
        command: ["timeout", "3", "df", "-B1", "--output=target,size,used", "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs", "-x", "overlay", "-x", "squashfs"]
        environment: ({
                LC_ALL: "C"
            })
        stdout: StdioCollector {
            onStreamFinished: root.disks = text.trim().split("\n").slice(1).map(l => {
                    const f = l.trim().split(/\s+/);
                    return {
                        mount: f[0],
                        size: Number(f[1]),
                        used: Number(f[2])
                    };
                }).filter(d => d.size > 4e9 && d.mount !== "/boot")
        }
    }
    Timer {
        running: root.detailed
        interval: 30000                      // disks fill slowly
        repeat: true
        onTriggered: df.running = true
    }

    // the cores' clock: each core's own file, read with the rest while a detail view shows (the cores are
    // known once /proc/stat was read)
    Instantiator {
        id: freqFiles
        model: root.detailed ? root.cores.length : 0

        delegate: FileView {
            required property int index
            path: `/sys/devices/system/cpu/cpu${index}/cpufreq/scaling_cur_freq`
            printErrors: false
            onLoaded: root.setFreq(index, Number(text().trim()))
        }
    }
    readonly property var freqs: []          // kHz, by core: changed in place, cpuGhz set from it
    function setFreq(i, khz) {
        freqs[i] = khz;
        const known = freqs.filter(f => f > 0);
        cpuGhz = known.length ? known.reduce((a, b) => a + b, 0) / known.length / 1e6 : 0;
    }

    // ---------- formatting, for the views ----------

    function pct(f) {
        return f < 0 ? "…" : Math.round(f * 100) + "%";
    }

    function deg(t) {
        return t < 0 ? "" : Math.round(t) + "°";
    }

    function gib(v) {
        return v.toFixed(1) + " GB";
    }

    // bytes, or bytes/s with a "/s"
    function bytes(b, perSecond) {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        while (b >= 1000 && i < units.length - 1) {
            b /= 1000;
            i++;
        }
        return (i === 0 ? Math.round(b) : b.toFixed(b < 10 ? 1 : 0)) + " " + units[i] + (perSecond ? "/s" : "");
    }
}

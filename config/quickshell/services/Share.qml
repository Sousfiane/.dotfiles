pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.config

// Screen sharing's picker. When an app asks to share the screen, xdg-desktop-portal-hyprland runs
// ~/.local/bin/share-picker, which calls `qs ipc call share pick <pipe> <windows> <workspaces> <remember>`
// and waits on the pipe. The share panel opens; what's picked (a monitor, a window, a workspace, a region
// drawn with slurp) is written back as XDPH reads it, and closing the panel any other way cancels the share.
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("share")

    // the pipe share-picker waits on: "" when no app is asking
    property string reply: ""
    readonly property bool pending: reply !== ""

    // whether the app may share the same thing again later without asking (XDPH's restore token)
    property bool remember: false

    // the windows XDPH can share: { handle, cls, title, toplevel } (toplevel: Hyprland's, for the preview)
    property var windows: []
    // the workspaces: { id (XDPH's, not Hyprland's), name, outputs }
    property var workspaces: []

    // the panel's tab: 0 screens, 1 windows, 2 workspaces, 3 region. Each request starts on the screens
    readonly property var tabs: ["Screens", "Windows", "Workspaces", "Region"]
    property int tab: 0

    // drawing a region: the panel is closed meanwhile, without that cancelling the share
    property bool drawing: false

    IpcHandler {
        target: "share"

        function pick(reply: string, windows: string, workspaces: string, allowToken: bool): void {
            if (root.pending)
                root.send("");              // an older request still waiting: that one is cancelled
            root.windows = root.parseWindows(windows);
            root.workspaces = root.parseWorkspaces(workspaces);
            root.tab = 0;
            root.remember = allowToken;
            root.reply = reply;
            Panels.show("share");
        }
    }

    // XDPH's list: "<handle>[HC>]<class>[HT>]<title>[HE>]<hyprland address>[HA>]" for each window. Its
    // names never hold a marker (XDPH blanks a "]" after a ">"), and the address is in decimal, 0 if unknown
    function parseWindows(list) {
        const toplevels = Hyprland.toplevels.values;
        return list.split("[HA>]").map(e => /^(\d+)\[HC>\]([\s\S]*)\[HT>\]([\s\S]*)\[HE>\](\d+)$/.exec(e)).filter(m => m !== null).map(m => ({
                    handle: m[1],
                    cls: m[2],
                    title: m[3],
                    toplevel: m[4] === "0" ? null : (toplevels.find(t => parseInt(t.address, 16) === Number(m[4])) ?? null)
                })).sort((a, b) => (a.toplevel?.workspace?.id ?? 1e9) - (b.toplevel?.workspace?.id ?? 1e9));
    }

    // XDPH's list: "<id>[HN>]<name>[HM>]<count>:<output>...[HE>]" for each workspace, where the name and
    // each output are "<length>:<text>", the length in bytes of UTF-8 (a name may hold anything)
    function parseWorkspaces(list) {
        let pos = 0;
        // the next `n` bytes of the list, or null when it ends sooner
        function takeBytes(n) {
            let bytes = 0, end = pos;
            while (bytes < n && end < list.length) {
                const c = list.codePointAt(end);
                bytes += c < 0x80 ? 1 : c < 0x800 ? 2 : c < 0x10000 ? 3 : 4;
                end += c >= 0x10000 ? 2 : 1;
            }
            const text = list.slice(pos, end);
            pos = end;
            return bytes === n ? text : null;
        }
        function takeUntil(mark) {
            const at = list.indexOf(mark, pos);
            if (at < 0)
                return null;
            const text = list.slice(pos, at);
            pos = at + mark.length;
            return text;
        }
        function takePrefixed() {
            const n = takeUntil(":");
            return n !== null && /^\d+$/.test(n) ? takeBytes(Number(n)) : null;
        }
        function expect(mark) {
            if (!list.startsWith(mark, pos))
                return false;
            pos += mark.length;
            return true;
        }

        const result = [];
        while (pos < list.length) {
            const id = takeUntil("[HN>]");
            const name = id !== null && /^\d+$/.test(id) ? takePrefixed() : null;
            const count = name !== null && expect("[HM>]") ? takeUntil(":") : null;
            if (count === null || !/^\d+$/.test(count))
                break;
            const outputs = [];
            for (let i = 0; i < Number(count); i++) {
                const output = takePrefixed();
                if (output === null)
                    return result;
                outputs.push(output);
            }
            if (!expect("[HE>]"))
                break;
            result.push({
                id: id,
                name: name,
                outputs: outputs
            });
        }
        // numbered ones in order, named ones after
        return result.sort((a, b) => (Number(a.name) || 1e9) - (Number(b.name) || 1e9) || a.name.localeCompare(b.name));
    }

    // ---------- the answer ----------

    function shareScreen(name) {
        send("screen:" + name);
    }

    function shareWindow(handle) {
        send("window:" + handle);
    }

    function shareWorkspace(id) {
        send("workspace-id:" + id);
    }

    // the panel goes away first, so the region is drawn over what will be shared
    function shareRegion() {
        drawing = true;
        Panels.closeThen(() => slurp.running = true);
    }

    // "" cancels. The line goes in the pipe in one write, so share-picker reads it whole
    function send(selection) {
        if (!pending)
            return;
        const line = selection === "" ? "" : (remember ? "r" : "") + "/" + selection;
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" > "$2"', "sh", line, reply]);
        reply = "";
        drawing = false;
        Panels.hide("share");
    }

    // closed by Esc, a click outside or another panel opening: the share is cancelled
    Connections {
        target: Panels

        function onCurrentChanged() {
            if (root.pending && !root.drawing && Panels.current !== "share")
                root.send("");
        }
    }

    // slurp prints the region on its monitor, in that monitor's own coordinates, as XDPH takes it. Esc in
    // slurp brings the panel back, to pick something else
    Process {
        id: slurp

        command: ["slurp", "-f", "%o %X %Y %W %H"]
        stdout: StdioCollector {
            id: region
        }
        onExited: code => {
            const m = /^(\S+) (\d+) (\d+) (\d+) (\d+)$/.exec(region.text.trim());
            if (code === 0 && m && Number(m[4]) > 0 && Number(m[5]) > 0) {
                root.send(`region:${m[1]}@${m[2]},${m[3]},${m[4]},${m[5]}`);
                return;
            }
            root.drawing = false;
            if (root.pending)
                Panels.show("share");
        }
    }
}

pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The Hyprland shortcuts, for the Keybinds panel.
//
// The binds come from Hyprland itself (hyprctl binds -j), so the list is what's really bound, read again each
// time the panel opens. Their sections are the headers of hypr/config/bindings.lua ("-- 🪟 Window
// management"): each bind goes under the header its description follows in that file.
//
// Binds that only differ by a number (workspaces 1-9) become one row, and binds with the same description
// (play and pause keys) one row with both keys.
Singleton {
    id: root

    readonly property string bindingsFile: Quickshell.env("HOME") + "/.config/hypr/config/bindings.lua"

    // [{ section, description, keys: [[ "SUPER", "SHIFT", "F" ], ...] }], in the file's order
    property var binds: []
    property string error: ""
    readonly property bool loading: proc.running

    function refresh() {
        file.reload();
        proc.running = true;
    }

    // ---------- the sections, from bindings.lua ----------

    // [{ section, description }]: each description in the file (or its start, for one built with ..), under
    // the header above it
    function readSections() {
        const out = [];
        let section = "Other";
        const lines = file.text().split("\n");
        for (let i = 0; i < lines.length; i++) {
            // a header is a comment between two lines of dashes
            const header = lines[i].match(/^-- (.+)$/);
            if (header && /^-{10,}$/.test(lines[i - 1] ?? "") && /^-{10,}$/.test(lines[i + 1] ?? "")) {
                // drop the emoji (and what joins it) before the words
                section = header[1].replace(/^[^A-Za-z0-9]+/, "").replace(/\s*\(.*\)$/, "");
                continue;
            }
            const re = /description = "([^"]*)"/g;
            let m;
            while ((m = re.exec(lines[i])) !== null)
                out.push({ section: section, description: m[1] });
        }
        return out;
    }

    function sectionOf(sections, description) {
        const exact = sections.find(s => s.description === description);
        if (exact)
            return exact.section;
        const prefix = sections.find(s => s.description !== "" && description.startsWith(s.description));
        return prefix ? prefix.section : "Other";
    }

    // ---------- reading the binds ----------

    readonly property var modNames: [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"]]

    // a key's name as it's printed on the keyboard
    function keyName(b) {
        if (b.mouse)
            return { "mouse:272": "Left click", "mouse:273": "Right click", "mouse:274": "Middle click" }[b.key] ?? b.key;
        if (b.key === "" && b.keycode >= 10 && b.keycode <= 19)
            return String((b.keycode - 9) % 10);          // the number row, bound by keycode
        if (b.key === "")
            return "code " + b.keycode;
        const named = {
            "TAB": "Tab",
            "Return": "Enter",
            "Escape": "Esc",
            "Caps_Lock": "Caps Lock",
            "XF86AudioRaiseVolume": "Volume up",
            "XF86AudioLowerVolume": "Volume down",
            "XF86AudioMute": "Mute",
            "XF86AudioMicMute": "Mic mute",
            "XF86AudioNext": "Next",
            "XF86AudioPrev": "Previous",
            "XF86AudioPlay": "Play",
            "XF86AudioPause": "Pause",
            "XF86KbdBrightnessUp": "Backlight up",
            "XF86KbdBrightnessDown": "Backlight down"
        };
        if (named[b.key])
            return named[b.key];
        // other media keys: XF86MonBrightnessUp -> Mon Brightness Up
        if (b.key.startsWith("XF86"))
            return b.key.slice(4).replace(/([a-z])([A-Z])/g, "$1 $2");
        return b.key.length === 1 ? b.key.toUpperCase() : b.key;
    }

    function combo(b) {
        const keys = modNames.filter(([bit]) => b.modmask & bit).map(([, name]) => name);
        keys.push(keyName(b));
        return keys;
    }

    function parse(text) {
        const list = JSON.parse(text).filter(b => b.description !== "" && b.submap === "");
        const sections = readSections();
        const rows = [];

        for (const b of list) {
            const keys = combo(b);
            const description = b.description;

            // "Switch to workspace 4" when "Switch to workspace 1–3" is there with the same mods: one row, "1–4"
            const numbered = description.match(/^(.*\D)(\d+)$/);
            const mods = keys.slice(0, -1).join("+");
            const run = numbered && rows.find(r => r.base === numbered[1] && r.mods === mods && parseInt(r.to) + 1 === parseInt(numbered[2]));
            if (run) {
                run.to = numbered[2];
                run.description = numbered[1] + run.from + "–" + run.to;
                run.keys[0][run.keys[0].length - 1] = run.fromKey + "–" + keys[keys.length - 1];
                continue;
            }

            // the same description again (play and pause): another key on that row
            const same = rows.find(r => r.full === description);
            if (same) {
                same.keys.push(keys);
                continue;
            }

            // "Menu: Apps" under Menus, "OBS: Cam Scene" under OBS Studio: the section already says it
            const section = sectionOf(sections, description);
            const prefix = description.match(/^([^:]+): (.+)$/);
            const shownAs = prefix && section.toLowerCase().startsWith(prefix[1].toLowerCase()) ? prefix[2] : description;

            rows.push({
                section: section,
                description: shownAs,
                full: description,
                keys: [keys],
                // for joining the numbered binds that follow
                base: numbered ? numbered[1] : null,
                from: numbered ? numbered[2] : null,
                to: numbered ? numbered[2] : null,
                fromKey: keys[keys.length - 1],
                mods: mods
            });
        }

        // grouped by section, in the order the sections first come up
        const order = [];
        for (const r of rows)
            if (!order.includes(r.section))
                order.push(r.section);
        const out = [];
        for (const s of order)
            for (const r of rows)
                if (r.section === s)
                    out.push({
                        section: r.section,
                        description: r.description,
                        keys: r.keys
                    });
        return out;
    }

    FileView {
        id: file
        path: root.bindingsFile
        blockLoading: true
    }

    Process {
        id: proc
        command: ["hyprctl", "binds", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.binds = root.parse(text);
                    root.error = "";
                } catch (e) {
                    root.error = "couldn't read hyprctl's answer: " + e;
                }
            }
        }

        onExited: code => {
            if (code !== 0)
                root.error = "hyprctl binds failed (" + code + ")";
        }
    }
}

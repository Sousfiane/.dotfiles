import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd
import QtQuick
import qs.modules.lock

// The login screen: greetd runs it as the `greeter` user, in a small Hyprland (config/hypr/greeter.lua). What
// it shows is the lock screen's own LockFace, so the two always match; restart and shut down are added in the
// corner. Enter logs in to the same session as before, uwsm's Hyprland.
//
// It reads everything where it is, in the user's home: the greeter user may cross the home (an ACL that
// install/steps/greeter.sh sets: `x` only, it can't list it), and what's under it is readable. The theme is
// ~/.config/theme's (theme.json, the current palette, the fonts picked), the wallpaper the shell's current
// one. The home is QS_GREETER_HOME (greeter.lua passes it), the user its owner, QS_GREETER_USER.
//
// Outside greetd (as the user: `qs -p ~/.config/quickshell/greeter.qml`) it runs in test mode: any password
// works, Esc quits, and it quits by itself after QS_GREETER_TEST_SECONDS (20 by default).
ShellRoot {
    id: root

    // ---------- the theme, as config/Theme.qml reads it ----------

    readonly property string home: Quickshell.env("QS_GREETER_HOME") || Quickshell.env("HOME")

    function parse(file) {
        try {
            return JSON.parse(file.text());
        } catch (e) {
            return {};
        }
    }

    FileView {
        id: settingsFile
        path: root.home + "/.config/theme/theme.json"
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: fontsFile
        path: root.home + "/.local/state/theme/fonts.json"
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: paletteName
        path: root.home + "/.local/state/theme/palette"
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: paletteFile
        path: root.home + "/.config/theme/palettes/" + (paletteName.text().trim() || root.settings.palette || "rose-pine") + ".json"
        blockLoading: true
        printErrors: false
    }

    readonly property var settings: parse(settingsFile)
    readonly property var fonts: Object.assign({}, settings.font ?? {}, parse(fontsFile))
    readonly property var palette: parse(paletteFile)

    // Rosé Pine Moon, for a missing or broken palette
    readonly property var colors: Object.assign({
        base: "#232136",
        surface: "#2a273f",
        overlay: "#393552",
        muted: "#6e6a86",
        subtle: "#908caa",
        text: "#e0def4",
        love: "#eb6f92",
        gold: "#f6c177",
        rose: "#ea9a97",
        pine: "#3e8fb0",
        foam: "#9ccfd8",
        iris: "#c4a7e7",
        highlightLow: "#2a283e",
        highlightMed: "#44415a",
        highlightHigh: "#56526e"
    }, palette.colors ?? {})
    readonly property string font: fonts.ui ?? "JetBrainsMono Nerd Font"
    readonly property int fontSize: fonts.uiPixelSize ?? 13
    readonly property int radius: settings.radius?.large ?? 6
    readonly property real panelAlpha: settings.opacity?.panel ?? 0.95
    readonly property real controlAlpha: settings.opacity?.control ?? 0.75

    // the shell's current wallpaper: its state file (services/Wallpapers.qml), the newest if there are several
    property string wallpaper: ""
    Process {
        running: true
        command: ["sh", "-c", 'f=$(ls -t "$1"/.local/state/quickshell/by-shell/*/wallpaper 2>/dev/null | head -n 1) && head -n 1 "$f"', "sh", root.home]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                if (path !== "")
                    root.wallpaper = "file://" + path;
            }
        }
    }

    // the palette's colours are hex strings: made a colour first (a string has no r, g, b: black)
    function alpha(c, a) {
        const k = Qt.tint(c, "transparent");
        return Qt.rgba(k.r, k.g, k.b, a);
    }

    // ---------- logging in ----------

    readonly property bool testing: !Greetd.available
    // Started through the user's login shell, as a display manager does: its profile (~/.zprofile: ~/.local/bin
    // in PATH, DOTFILES, the theme's colours) runs first, and uwsm hands that environment to the whole session.
    // Its output would print on the console while Hyprland comes up (a few seconds): the console is cleared,
    // its cursor hidden, and the output dropped (uwsm and Hyprland log to the journal anyway)
    readonly property var session: ["sh", "-c", "printf '\\033[2J\\033[3J\\033[H\\033[?25l'; login=$(getent passwd \"$(id -un)\" | cut -d: -f7); exec \"${login:-/bin/sh}\" -l -c 'exec uwsm start -e -D Hyprland hyprland.desktop' >/dev/null 2>&1"]

    property string user: (testing ? Quickshell.env("USER") : Quickshell.env("QS_GREETER_USER")) ?? ""
    property string password: ""
    property string message: ""
    property bool busy: false
    property bool leaving: false            // fading out, the session starts right after
    signal failed                           // shakes the field

    function submit() {
        if (busy || leaving || password === "")
            return;
        if (user === "") {
            // no user known: what was typed is the user name, the password comes next
            user = password.trim();
            password = "";
            return;
        }
        busy = true;
        message = "";
        if (testing)
            fakeCheck.restart();
        else
            Greetd.createSession(user);
    }

    function fail(text) {
        busy = false;
        password = "";
        message = text;
        failed();
        if (!testing && Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession();
    }

    function start() {
        busy = false;
        leaving = true;
        launchAfterFade.restart();
    }

    Connections {
        target: Greetd

        function onAuthMessage(text, error, responseRequired, echoResponse) {
            if (responseRequired)
                Greetd.respond(root.password);
            else if (error)
                root.message = text;
        }

        function onAuthFailure(text) {
            root.fail("Wrong password");
        }

        function onReadyToLaunch() {
            root.start();
        }

        function onError(text) {
            root.fail(text);
        }
    }

    // the screen fades out, then the session starts (the greeter quits, and Hyprland with it)
    Timer {
        id: launchAfterFade
        interval: 300
        onTriggered: root.testing ? Qt.quit() : Greetd.launch(root.session)
    }

    // test mode: "checking" a moment, then in
    Timer {
        id: fakeCheck
        interval: 600
        onTriggered: root.start()
    }

    Timer {
        running: root.testing
        interval: 1000 * Number(Quickshell.env("QS_GREETER_TEST_SECONDS") || 20)
        onTriggered: Qt.quit()
    }

    // ---------- every screen ----------

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            // the login itself on the first screen; the others only show the wallpaper and the time
            readonly property bool main: modelData === Quickshell.screens[0]

            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-greeter"
            WlrLayershell.keyboardFocus: main ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: root.colors.base

            LockFace {
                id: face
                anchors.fill: parent

                colors: root.colors
                font: root.font
                fontSize: root.fontSize
                radius: root.radius
                panelAlpha: root.panelAlpha

                wallpaper: root.wallpaper
                interactive: win.main
                user: root.user
                password: root.password
                busy: root.busy
                message: root.message
                note: root.testing ? "Test mode: any password works, Esc quits" : ""
                hint: "Enter log in • Esc clear"
                reveal: root.user === ""                   // no user known: the user name is typed first
                placeholder: root.busy ? "Checking…" : root.user === "" ? "User name" : "Password"
                leaving: root.leaving

                onEdited: text => {
                    root.password = text;
                    root.message = "";
                }
                onSubmitted: root.submit()
                onEscaped: if (root.testing)
                    Qt.quit()

                Connections {
                    target: root
                    function onFailed() {
                        face.shake();
                    }
                }

                // ---------- restart and shut down ----------
                Row {
                    visible: win.main
                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                        margins: 32
                    }
                    spacing: 10

                    Repeater {
                        model: [
                            {
                                glyph: "\u{F0709}",            // md-restart
                                label: "Restart",
                                command: ["systemctl", "reboot"]
                            },
                            {
                                glyph: "\u{F0425}",            // md-power
                                label: "Shut down",
                                command: ["systemctl", "poweroff"]
                            }
                        ]

                        delegate: Rectangle {
                            id: power
                            required property var modelData

                            implicitWidth: row.implicitWidth + 28
                            implicitHeight: 40
                            radius: height / 2
                            // the bar's fill, and its rows' on hover
                            color: mouse.containsMouse ? root.alpha(root.colors.overlay, root.controlAlpha) : root.alpha(root.colors.base, root.panelAlpha)
                            border.width: 1
                            border.color: mouse.containsMouse ? root.colors.iris : root.alpha(root.colors.text, 0.12)

                            Row {
                                id: row
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: power.modelData.glyph
                                    color: root.colors.text
                                    font.family: root.font
                                    font.pixelSize: root.fontSize + 3
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: power.modelData.label
                                    color: root.colors.text
                                    font.family: root.font
                                    font.pixelSize: root.fontSize
                                }
                            }

                            MouseArea {
                                id: mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.testing ? Qt.quit() : Quickshell.execDetached(power.modelData.command)
                            }
                        }
                    }
                }
            }
        }
    }
}

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd
import QtQuick

// The login screen: greetd runs it as the `greeter` user, in a small Hyprland (/etc/greetd/hypr). What it
// shows is LockFace.qml, the lock screen's own file (a link to config/quickshell/modules/lock, copied next to
// this one when installed), so the two always match; restart and shut down are added in the corner. Enter
// logs in to the same session as before, uwsm's Hyprland.
//
// It can't read the user's home (private), so the theme comes from /var/lib/qs-greeter, a folder the user
// owns: theme.json (palette, fonts, user name), written by ~/.config/theme/files.sh on every theme change,
// and the wallpaper, copied by Quickshell's wallpaper service. Without them, Rosé Pine Moon and no picture.
//
// Outside greetd (QS_GREETER_DIR points at another folder to test with) it runs in test mode: any password
// works, Esc quits, and it quits by itself after QS_GREETER_TEST_SECONDS (20 by default).
ShellRoot {
    id: root

    // ---------- the theme, from the user's last export ----------

    readonly property string dir: Quickshell.env("QS_GREETER_DIR") || "/var/lib/qs-greeter"

    FileView {
        id: themeFile
        path: root.dir + "/theme.json"
        blockLoading: true
        printErrors: false
    }

    readonly property var theme: {
        try {
            return JSON.parse(themeFile.text());
        } catch (e) {
            return {};
        }
    }

    // Rosé Pine Moon, for a missing or broken export
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
    }, theme.colors ?? {})
    readonly property string font: theme.font ?? "JetBrainsMono Nerd Font"
    readonly property int fontSize: theme.fontSize ?? 13
    readonly property int radius: theme.radius ?? 12
    readonly property real panelAlpha: theme.panelAlpha ?? 0.95
    readonly property string wallpaper: "file://" + dir + "/wallpaper"

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // ---------- logging in ----------

    readonly property bool testing: !Greetd.available
    readonly property var session: ["uwsm", "start", "-e", "-D", "Hyprland", "hyprland.desktop"]

    property string user: theme.user ?? ""
    property string password: ""
    property string message: ""
    property bool busy: false
    property bool leaving: false            // fading out, the session starts right after
    signal failed                           // shakes the field

    function submit() {
        if (busy || leaving || password === "")
            return;
        if (user === "") {
            // no export yet: what was typed is the user name, the password comes next
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
                reveal: root.user === ""                   // no export yet: the user name is typed first
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
                            radius: 20
                            color: mouse.containsMouse ? root.alpha(root.colors.overlay, 0.95) : root.alpha(root.colors.base, 0.7)
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

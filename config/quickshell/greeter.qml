import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.modules.lock
import qs.modules.greeter

// The login screen: greetd runs it as the `greeter` user, in a small Hyprland (config/hypr/greeter.lua). What
// it shows is the lock screen's own LockFace, so the two always match; restart and shut down are added in the
// corner. Enter logs in to the same session as before, uwsm's Hyprland. The parts are in modules/greeter:
// the theme (GreeterTheme), logging in (GreeterLogin), the buttons (PowerButtons).
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

    readonly property string home: Quickshell.env("QS_GREETER_HOME") || Quickshell.env("HOME")

    GreeterTheme {
        id: greeterTheme
        home: root.home
    }

    GreeterLogin {
        id: login
        home: root.home
    }

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
            color: greeterTheme.colors.base

            LockFace {
                id: face
                anchors.fill: parent

                colors: greeterTheme.colors
                font: greeterTheme.font
                fontSize: greeterTheme.fontSize
                radius: greeterTheme.radius
                panelAlpha: greeterTheme.panelAlpha

                wallpaper: greeterTheme.wallpaper
                interactive: win.main
                user: login.user
                password: login.password
                busy: login.busy
                message: login.message
                note: login.testing ? "Test mode: any password works, Esc quits" : ""
                hint: "Enter log in • Esc clear"
                reveal: login.user === ""                   // no user known: the user name is typed first
                placeholder: login.busy ? "Checking…" : login.user === "" ? "User name" : "Password"
                leaving: login.leaving

                onEdited: text => login.edit(text)
                onSubmitted: login.submit()
                onEscaped: if (login.testing)
                    Qt.quit()

                Connections {
                    target: login
                    function onFailed() {
                        face.shake();
                    }
                }

                PowerButtons {
                    visible: win.main
                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                        margins: 32
                    }
                    theme: greeterTheme
                    testing: login.testing
                }
            }
        }
    }
}

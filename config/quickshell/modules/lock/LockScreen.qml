import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import qs.config
import qs.services
import qs.components.ui

// Session lock: LockFace (the wallpaper blurred, the clock, the password field: the same as the login
// screen's), with the weather from the hub.
// The password is shared by every screen, so typing works on whichever monitor has focus.
Scope {
    id: root

    property string password: ""
    property string message: ""                 // error shown under the field
    property string pamError: ""                // what else PAM said during this attempt (faillock: "account locked...")
    property bool unlocking: false              // fading out, the lock is released right after
    readonly property bool busy: pam.active

    signal failed                               // shakes the field

    function submit() {
        if (busy || password === "")
            return;
        message = "";
        pamError = "";
        pam.start();
    }

    // fresh weather and a clean field every time the screen locks
    Connections {
        target: Lock
        function onLockedChanged() {
            if (!Lock.locked)
                return;
            root.unlocking = false;
            root.password = "";
            root.message = "";
            Weather.refreshIfStale();
        }
    }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellDir + "/config/pam"
        config: "password.conf"

        // the password prompt is answered; what PAM says besides replaces "Wrong password". faillock, while
        // the account is locked (the right password fails too), says it in two lines: "The account is locked
        // due to 3 failed logins." and "(9 minutes left to unlock)"
        onPamMessage: {
            if (responseRequired)
                respond(root.password);
            else
                root.pamError = (root.pamError + " " + message).trim();
        }

        onCompleted: result => {
            root.password = "";
            if (result === PamResult.Success) {
                root.unlocking = true;
                release.restart();
                return;
            }
            root.message = root.pamError || (result === PamResult.MaxTries ? "Too many attempts" : "Wrong password");
            root.failed();
        }

        onError: err => {
            root.password = "";
            root.message = "Authentication error: " + PamError.toString(err);
            root.failed();
        }
    }

    readonly property int fadeMs: Motion.slow

    Timer {
        id: release
        interval: root.fadeMs
        onTriggered: Lock.locked = false
    }

    WlSessionLock {
        locked: Lock.locked

        WlSessionLockSurface {
            id: surface
            color: Theme.base

            // the desktop as it was when locking: what the lockscreen fades in from and back out to
            Image {
                anchors.fill: parent
                source: surface.screen ? "file://" + Lock.shotPath(surface.screen.name) : ""
                fillMode: Image.PreserveAspectCrop
                cache: false
                visible: content.opacity < 1      // fully covered once faded in: don't draw it every frame
            }

            LockFace {
                id: content
                anchors.fill: parent

                colors: Theme.colors
                font: Theme.font
                fontSize: Theme.fontSize
                radius: Theme.radiusLarge
                panelAlpha: Theme.alpha

                wallpaper: Wallpapers.currentUrl
                user: Quickshell.env("USER") ?? ""
                password: root.password
                busy: root.busy
                message: root.message
                leaving: root.unlocking

                onEdited: text => {
                    root.password = text;
                    root.message = "";
                }
                onSubmitted: root.submit()

                Connections {
                    target: root
                    function onFailed() {
                        content.shake();
                    }
                }

                // ---------- weather, top right like in the hub ----------
                WeatherBlock {
                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: 40
                    }
                    iconSize: Theme.fontSize + 26
                    tempSize: Theme.fontSize + 20
                    descSize: Theme.fontSize + 2
                    smallSize: Theme.fontSize
                    descWidth: 260
                }
            }
        }
    }
}

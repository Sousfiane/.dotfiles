import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// Session lock: blurred wallpaper, clock and weather from the hub, password field.
// The password is shared by every screen, so typing works on whichever monitor has focus.
Scope {
    id: root

    property string password: ""
    property string message: ""                 // error shown under the field
    property bool unlocking: false              // fading out, the lock is released right after
    readonly property bool busy: pam.active

    signal failed                               // shakes the field

    // one entry per typed character: adding or removing one leaves the other dots alone
    // (a plain number as the Repeater model would rebuild, and re-animate, every dot)
    ListModel {
        id: dots
    }

    onPasswordChanged: {
        const n = password.length;
        if (dots.count > n)
            dots.remove(n, dots.count - n);
        while (dots.count < n)
            dots.append({ c: 0 });
    }

    function submit() {
        if (busy || password === "")
            return;
        message = "";
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

        onPamMessage: {
            if (responseRequired)
                respond(root.password);
        }

        onCompleted: result => {
            root.password = "";
            if (result === PamResult.Success) {
                root.unlocking = true;
                release.restart();
                return;
            }
            root.message = result === PamResult.MaxTries ? "Too many attempts" : "Wrong password";
            root.failed();
        }

        onError: err => {
            root.password = "";
            root.message = "Authentication error: " + PamError.toString(err);
            root.failed();
        }
    }

    readonly property int fadeMs: 350

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

            Item {
                id: content
                anchors.fill: parent

                // wait for the wallpaper so the fade does not start on an empty background
                readonly property bool shown: wall.status !== Image.Loading && !root.unlocking

                opacity: shown ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: root.fadeMs
                        easing.type: Easing.InOutQuad
                    }
                }

                // ---------- background: the wallpaper, blurred and darkened ----------
                // drawn larger than the screen: the blur fades the image's borders, keep them off-screen
                Image {
                    id: wall
                    anchors.fill: parent
                    anchors.margins: -80
                    source: Wallpapers.currentUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(width / 2, height / 2)   // blurred anyway
                    visible: false
                }

                MultiEffect {
                    anchors.fill: wall
                    source: wall
                    autoPaddingEnabled: false
                    visible: wall.status === Image.Ready
                    blurEnabled: true
                    blur: 1
                    blurMax: 64
                    saturation: -0.1
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.withAlpha(Theme.base, 0.45)
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

                // ---------- clock and password ----------
                ColumnLayout {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -40
                    spacing: 40

                    scale: content.shown ? 1 : 0.96
                    Behavior on scale {
                        NumberAnimation {
                            duration: root.fadeMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    DateTimeBlock {
                        Layout.alignment: Qt.AlignHCenter
                        align: Qt.AlignHCenter
                        timeSize: 120
                        dateSize: Theme.fontSize + 9
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 10

                        Rectangle {
                            id: field
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 320
                            implicitHeight: 52
                            radius: Theme.radius * 2
                            color: Theme.bg
                            border.width: 2
                            border.color: root.message !== "" ? Theme.urgent : root.busy ? Theme.gold : input.activeFocus ? Theme.accent : Theme.highlightMed

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            // shake on a wrong password
                            transform: Translate {
                                id: shift
                            }
                            SequentialAnimation {
                                id: shake
                                NumberAnimation {
                                    target: shift
                                    property: "x"
                                    to: -12
                                    duration: 50
                                }
                                NumberAnimation {
                                    target: shift
                                    property: "x"
                                    to: 12
                                    duration: 80
                                }
                                NumberAnimation {
                                    target: shift
                                    property: "x"
                                    to: -8
                                    duration: 70
                                }
                                NumberAnimation {
                                    target: shift
                                    property: "x"
                                    to: 6
                                    duration: 60
                                }
                                NumberAnimation {
                                    target: shift
                                    property: "x"
                                    to: 0
                                    duration: 50
                                }
                            }
                            Connections {
                                target: root
                                function onFailed() {
                                    shake.restart();
                                }
                            }

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 18
                                    rightMargin: 18
                                }
                                spacing: 12

                                Txt {
                                    text: Icons.lock
                                    color: field.border.color
                                    font.pixelSize: Theme.fontSize + 6
                                }

                                // one dot per character, or the placeholder
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true

                                    Txt {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: root.password === ""
                                        variant: "dim"
                                        font.pixelSize: Theme.fontSize
                                        text: root.busy ? "Checking…" : "Password"
                                    }

                                    Row {
                                        anchors.verticalCenter: parent.verticalCenter
                                        // keep the newest dots visible when they overflow
                                        x: Math.min(0, parent.width - width)
                                        spacing: 6

                                        Repeater {
                                            model: dots

                                            delegate: Rectangle {
                                                width: 8
                                                height: 8
                                                radius: 4
                                                color: Theme.fg
                                                opacity: 0
                                                Component.onCompleted: opacity = 1
                                                Behavior on opacity {
                                                    NumberAnimation {
                                                        duration: 90
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // takes the keyboard; the text itself lives in root.password
                            Item {
                                id: input
                                anchors.fill: parent
                                focus: true

                                Keys.onPressed: event => {
                                    if (root.busy || root.unlocking) {
                                        event.accepted = true;
                                        return;
                                    }
                                    const ctrl = event.modifiers & Qt.ControlModifier;
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        root.submit();
                                    } else if (event.key === Qt.Key_Escape || (ctrl && event.key === Qt.Key_U)) {
                                        root.password = "";
                                    } else if (event.key === Qt.Key_Backspace) {
                                        root.password = ctrl ? "" : root.password.slice(0, -1);
                                    } else if (event.text.length > 0 && !ctrl && event.text.charCodeAt(0) >= 0x20) {
                                        root.password += event.text;
                                        root.message = "";
                                    } else {
                                        return;
                                    }
                                    event.accepted = true;
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.IBeamCursor
                                onClicked: input.forceActiveFocus()
                            }
                        }

                        Txt {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredHeight: Theme.fontSize + 6
                            variant: "dim"
                            color: Theme.urgent
                            text: root.message
                        }
                    }
                }

                // ---------- bottom hint ----------
                Hint {
                    anchors {
                        bottom: parent.bottom
                        horizontalCenter: parent.horizontalCenter
                        bottomMargin: 30
                    }
                    text: "Enter unlock • Esc clear"
                }
            }
        }
    }
}

import Quickshell
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts

// What the lock screen and the login screen both show: the wallpaper blurred and darkened, the clock, the
// user, the password field and the line under it. The same file is used by both, so they always match: the
// lock screen (LockScreen.qml) and the greeter (greeter.qml, run as another user before logging in). That's
// why it imports nothing from the shell (Theme reads the running user's home): the theme comes in as
// properties, and typing goes out as signals, the host owns the password.
//
// Whatever is declared inside a LockFace { } goes over it and fades with it (the weather, the power buttons).
Item {
    id: root

    // ---------- the theme ----------
    required property var colors            // the palette: base, text, subtle, iris, love, gold, highlightMed
    required property string font
    required property int fontSize
    required property int radius            // the field's: the theme's large radius
    property real panelAlpha: 0.95          // the field's background, like the panels

    // ---------- what it shows ----------
    property url wallpaper
    property string user: ""                // the name and its initial over the field; none, no row
    property string password: ""
    property bool busy: false               // being checked: the field turns gold and takes no keys
    property string message: ""             // an error, in red under the field
    property string note: ""                // shown there when there's no error
    property string hint: "Enter unlock • Esc clear"
    property bool reveal: false             // the field shows what's typed (a user name), not dots
    property string placeholder: busy ? "Checking…" : "Password"
    property bool interactive: true         // the field and the keyboard (false: the clock only)
    property bool leaving: false            // fades out (unlocked, logged in)

    // ---------- typing ----------
    signal edited(string text)              // the field's new text: the host stores it in `password`
    signal submitted
    signal escaped                          // Esc on an empty field

    function shake() {
        shakeAnim.restart();
    }

    // shown once the wallpaper is in, so the fade never starts on an empty background
    readonly property bool wallReady: wall.status !== Image.Loading
    readonly property bool shown: wallReady && !leaving

    // the shell's motion (config/Motion.qml), copied since this file can't import it
    readonly property int slowMs: 350
    readonly property int fastMs: 120
    readonly property var enterCurve: [0.16, 1, 0.3, 1, 1, 1]

    // the palette's colours are hex strings: made a colour first (a string has no r, g, b: black)
    function alpha(c, a) {
        const k = Qt.tint(c, "transparent");
        return Qt.rgba(k.r, k.g, k.b, a);
    }

    opacity: shown ? 1 : 0
    Behavior on opacity {
        NumberAnimation {
            duration: root.slowMs
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.77, 0, 0.175, 1, 1, 1]
        }
    }

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
            dots.append({
                c: 0
            });
    }

    // ---------- background: the wallpaper, blurred and darkened ----------
    // drawn larger than the screen: the blur fades the image's borders, keep them off-screen
    Image {
        id: wall
        anchors.fill: parent
        anchors.margins: -80
        source: root.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
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
        color: root.alpha(root.colors.base, 0.45)
    }

    // ---------- clock, user and password ----------
    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        spacing: 40

        scale: root.shown ? 1 : 0.96
        Behavior on scale {
            NumberAnimation {
                duration: root.slowMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.enterCurve
            }
        }

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: root.colors.text
                font.family: root.font
                font.pixelSize: 120
                font.bold: true
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "dddd d MMMM")
                color: root.colors.subtle
                font.family: root.font
                font.pixelSize: root.fontSize + 9
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            visible: root.interactive
            spacing: 10

            // ---------- who ----------
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 4
                visible: root.user !== ""
                spacing: 12

                Rectangle {
                    implicitWidth: 40
                    implicitHeight: 40
                    radius: 20
                    color: root.colors.iris

                    Text {
                        anchors.centerIn: parent
                        text: root.user.charAt(0).toUpperCase()
                        color: root.colors.base
                        font.family: root.font
                        font.pixelSize: root.fontSize + 6
                        font.bold: true
                    }
                }

                Text {
                    text: root.user
                    color: root.colors.text
                    font.family: root.font
                    font.pixelSize: root.fontSize + 4
                }
            }

            // ---------- the field ----------
            Rectangle {
                id: field
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 320
                implicitHeight: 52
                radius: root.radius
                color: root.alpha(root.colors.base, root.panelAlpha)
                border.width: 2
                border.color: root.message !== "" ? root.colors.love : root.busy ? root.colors.gold : input.activeFocus ? root.colors.iris : root.colors.highlightMed

                Behavior on border.color {
                    ColorAnimation {
                        duration: root.fastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.enterCurve
                    }
                }

                // shake on a wrong password
                transform: Translate {
                    id: shift
                }
                SequentialAnimation {
                    id: shakeAnim
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

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 18
                        rightMargin: 18
                    }
                    spacing: 12

                    Text {
                        text: "\u{F033E}"               // md-lock
                        color: field.border.color
                        font.family: root.font
                        font.pixelSize: root.fontSize + 6
                    }

                    // one dot per character, or the placeholder (or the text itself, revealed)
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.min(0, parent.width - width)
                            visible: root.password === "" || root.reveal
                            text: root.password !== "" ? root.password : root.placeholder
                            color: root.password !== "" ? root.colors.text : root.colors.subtle
                            font.family: root.font
                            font.pixelSize: root.fontSize
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !root.reveal
                            // keep the newest dots visible when they overflow
                            x: Math.min(0, parent.width - width)
                            spacing: 6

                            Repeater {
                                model: dots

                                delegate: Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: root.colors.text
                                    opacity: 0
                                    Component.onCompleted: opacity = 1
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: root.fastMs
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: root.enterCurve
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // takes the keyboard; the text itself lives in the host's password
                Item {
                    id: input
                    anchors.fill: parent
                    focus: root.interactive

                    Keys.onPressed: event => {
                        event.accepted = true;
                        const ctrl = event.modifiers & Qt.ControlModifier;
                        if (event.key === Qt.Key_Escape && root.password === "") {
                            root.escaped();
                        } else if (root.busy || root.leaving) {
                        // no keys while checking or leaving
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.submitted();
                        } else if (event.key === Qt.Key_Escape || (ctrl && event.key === Qt.Key_U)) {
                            root.edited("");
                        } else if (event.key === Qt.Key_Backspace) {
                            root.edited(ctrl ? "" : root.password.slice(0, -1));
                        } else if (event.text.length > 0 && !ctrl && event.text.charCodeAt(0) >= 0x20) {
                            root.edited(root.password + event.text);
                        } else {
                            event.accepted = false;
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onClicked: input.forceActiveFocus()
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredHeight: root.fontSize + 6
                text: root.message !== "" ? root.message : root.note
                color: root.message !== "" ? root.colors.love : root.colors.subtle
                font.family: root.font
                font.pixelSize: root.fontSize - 2
            }
        }
    }

    // ---------- bottom hint ----------
    Text {
        visible: root.interactive && root.hint !== ""
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 30
        }
        text: root.hint
        color: root.colors.subtle
        font.family: root.font
        font.pixelSize: root.fontSize - 3
    }
}

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

Scope {
    id: root

    // `qs ipc call hub toggle|close`
    IpcHandler {
        target: "hub"
        function toggle(): void {
            Hub.toggle();
        }
        function close(): void {
            Hub.open = false;
        }
    }

    function focusedScreen() {
        const name = Hyprland.focusedMonitor?.name;
        for (let i = 0; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i].name === name)
                return Quickshell.screens[i];
        return Quickshell.screens[0];
    }

    SlideLoader {
        open: Hub.open

        PanelWindow {
            screen: root.focusedScreen()
            margins.top: Theme.barHeight
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "hub-menu"

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            Item {
                id: content
                anchors.fill: parent
                focus: true
                Component.onCompleted: forceActiveFocus()

                // month being displayed (starts on the current month)
                property int viewYear: new Date().getFullYear()
                property int viewMonth: new Date().getMonth()

                readonly property date today: clock.date

                function shiftMonth(d) {
                    const next = new Date(viewYear, viewMonth + d, 1);
                    viewYear = next.getFullYear();
                    viewMonth = next.getMonth();
                }

                function goToday() {
                    viewYear = today.getFullYear();
                    viewMonth = today.getMonth();
                }

                // 6 weeks of days, starting on Monday
                readonly property var cells: {
                    const y = viewYear;
                    const m = viewMonth;
                    const first = new Date(y, m, 1);
                    const offset = (first.getDay() + 6) % 7;
                    const out = [];
                    for (let i = 0; i < 42; i++) {
                        const d = new Date(y, m, 1 - offset + i);
                        out.push({
                            day: d.getDate(),
                            month: d.getMonth(),
                            year: d.getFullYear()
                        });
                    }
                    return out;
                }

                Keys.onEscapePressed: Hub.open = false
                Keys.onLeftPressed: shiftMonth(-1)
                Keys.onRightPressed: shiftMonth(1)

                Keys.onPressed: event => {
                    let handled = true;
                    switch (event.text) {
                    case "h":
                        shiftMonth(-1);
                        break;
                    case "l":
                        shiftMonth(1);
                        break;
                    case "t":
                        goToday();
                        break;
                    case "a":
                        Hub.openPicker("launcher");
                        break;
                    case "w":
                        Hub.openPicker("wallpaper");
                        break;
                    case "c":
                        Hub.openPicker("clipboard");
                        break;
                    case "q":
                        Hub.open = false;
                        break;
                    default:
                        handled = false;
                    }
                    if (handled)
                        event.accepted = true;
                }

                // click outside to close
                MouseArea {
                    anchors.fill: parent
                    onClicked: Hub.open = false
                }

                SlideArea {
                    open: Hub.open

                    DropCard {
                        id: card
                        edge: "center"
                        anchors {
                            top: parent.top
                            horizontalCenter: parent.horizontalCenter
                        }
                        width: 350
                        height: col.implicitHeight + 32

                        // swallow clicks on the card
                        MouseArea {
                            anchors.fill: parent
                        }

                        ColumnLayout {
                            id: col
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 16
                            }
                            spacing: 12

                            // ---------- time and date ----------
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: Qt.formatDateTime(clock.date, "HH:mm")
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize + 18
                                    font.bold: true
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: Qt.formatDateTime(clock.date, "dddd d MMMM yyyy")
                                    color: Theme.dim
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 1
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: Theme.border
                            }

                            // ---------- calendar header ----------
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: 14
                                    color: prevMouse.containsMouse ? Theme.surface : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "‹"
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize + 6
                                    }
                                    MouseArea {
                                        id: prevMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: content.shiftMonth(-1)
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: Qt.formatDate(new Date(content.viewYear, content.viewMonth, 1), "MMMM yyyy")
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize + 1
                                    font.bold: true

                                    // click the title to jump back to today
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: content.goToday()
                                    }
                                }

                                Rectangle {
                                    implicitWidth: 28
                                    implicitHeight: 28
                                    radius: 14
                                    color: nextMouse.containsMouse ? Theme.surface : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "›"
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize + 6
                                    }
                                    MouseArea {
                                        id: nextMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: content.shiftMonth(1)
                                    }
                                }
                            }

                            // ---------- calendar grid ----------
                            Grid {
                                id: calendar
                                Layout.alignment: Qt.AlignHCenter
                                columns: 7
                                columnSpacing: 4
                                rowSpacing: 2

                                // weekday names
                                Repeater {
                                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                                    delegate: Text {
                                        required property string modelData

                                        width: 42
                                        height: 22
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        text: modelData
                                        color: Theme.dim
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 3
                                        font.bold: true
                                    }
                                }

                                // days
                                Repeater {
                                    model: content.cells

                                    delegate: Rectangle {
                                        id: dayCell
                                        required property var modelData

                                        readonly property bool inMonth: modelData.month === content.viewMonth
                                        readonly property bool isToday: modelData.day === content.today.getDate() && modelData.month === content.today.getMonth() && modelData.year === content.today.getFullYear()

                                        width: 42
                                        height: 30
                                        radius: 8
                                        color: isToday ? Theme.accent : dayMouse.containsMouse ? Theme.surface : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: dayCell.modelData.day
                                            color: dayCell.isToday ? Theme.bg : dayCell.inMonth ? Theme.fg : Theme.dim
                                            opacity: dayCell.inMonth || dayCell.isToday ? 1 : 0.5
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize - 1
                                            font.bold: dayCell.isToday
                                        }

                                        MouseArea {
                                            id: dayMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                        }
                                    }
                                }

                                // scroll over the calendar to change month
                                WheelHandler {
                                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                                    onWheel: event => content.shiftMonth(event.angleDelta.y > 0 ? -1 : 1)
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: Theme.border
                            }

                            // ---------- picker buttons ----------
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: [
                                        {
                                            label: "Apps",
                                            key: "A",
                                            icon: 0xF003B,
                                            target: "launcher"
                                        },
                                        {
                                            label: "Wallpapers",
                                            key: "W",
                                            icon: 0xF02E9,
                                            target: "wallpaper"
                                        },
                                        {
                                            label: "Clipboard",
                                            key: "C",
                                            icon: 0xF0147,
                                            target: "clipboard"
                                        }
                                    ]

                                    delegate: Rectangle {
                                        id: btn
                                        required property var modelData

                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        implicitHeight: 70
                                        radius: Theme.radius
                                        color: btnMouse.containsMouse ? Theme.surface : "transparent"
                                        border.width: 1
                                        border.color: btnMouse.containsMouse ? Theme.accent : Theme.border

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: String.fromCodePoint(btn.modelData.icon)
                                                color: btnMouse.containsMouse ? Theme.accent : Theme.fg
                                                font.family: Theme.font
                                                font.pixelSize: Theme.fontSize + 8
                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: btn.modelData.label
                                                color: Theme.fg
                                                font.family: Theme.font
                                                font.pixelSize: Theme.fontSize - 2
                                            }
                                        }

                                        // shortcut key, top right
                                        Text {
                                            anchors {
                                                top: parent.top
                                                right: parent.right
                                                margins: 6
                                            }
                                            text: btn.modelData.key
                                            color: Theme.dim
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize - 4
                                        }

                                        MouseArea {
                                            id: btnMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Hub.openPicker(btn.modelData.target)
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                                text: "h l month • t today • a w c open • Esc close"
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 3
                            }
                        }
                    }
                }
            }
        }
    }
}

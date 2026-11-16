import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

DropdownPanel {
    id: panel
    name: "hub"
    edge: "center"
    cardWidth: 350

    ColumnLayout {
        id: hub
        spacing: 12

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        // month being displayed (starts on the current month)
        property int viewYear: new Date().getFullYear()
        property int viewMonth: new Date().getMonth()

        readonly property date today: clock.date

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

        function shiftMonth(d) {
            const next = new Date(viewYear, viewMonth + d, 1);
            viewYear = next.getFullYear();
            viewMonth = next.getMonth();
        }

        function goToday() {
            viewYear = today.getFullYear();
            viewMonth = today.getMonth();
        }

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Left:
            case Qt.Key_H:
                shiftMonth(-1);
                break;
            case Qt.Key_Right:
            case Qt.Key_L:
                shiftMonth(1);
                break;
            case Qt.Key_T:
                goToday();
                break;
            case Qt.Key_A:
                Hub.openPicker("launcher");
                break;
            case Qt.Key_W:
                Hub.openPicker("wallpaper");
                break;
            case Qt.Key_C:
                Hub.openPicker("clipboard");
                break;
            case Qt.Key_S:
                Hub.openPicker("screenshot");
                break;
            case Qt.Key_Q:
                panel.close();
                break;
            default:
                return;
            }
            event.accepted = true;
        }

        // ---------- time and date, weather next to them ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // fresh weather whenever the hub opens (the service also refreshes every 30 minutes)
            Component.onCompleted: Weather.refreshIfStale(10)

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Txt {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    font.pixelSize: Theme.fontSize + 18
                    font.bold: true
                }

                Txt {
                    variant: "dim"
                    text: Qt.formatDateTime(clock.date, "dddd d MMMM")
                }
            }

            // the columns hold only fixed-size text, so this is what lets the row span the card
            Item {
                Layout.fillWidth: true
            }

            ColumnLayout {
                visible: Weather.ready
                Layout.fillWidth: false             // nested layouts fill by default: stay against the right edge
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                spacing: 0

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 6

                    Txt {
                        text: Weather.icon
                        font.pixelSize: Theme.fontSize + 14
                    }

                    Txt {
                        text: Weather.temp + "°"
                        font.pixelSize: Theme.fontSize + 10
                        font.bold: true
                    }
                }

                Txt {
                    Layout.alignment: Qt.AlignRight
                    Layout.maximumWidth: 150
                    variant: "dim"
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    text: Weather.desc
                }

                Txt {
                    Layout.alignment: Qt.AlignRight
                    variant: "small"
                    text: "↑" + Weather.high + "° ↓" + Weather.low + "°  " + Weather.area
                }
            }
        }

        Divider {}

        // ---------- calendar header ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                color: prevMouse.containsMouse ? Theme.surface : "transparent"

                Txt {
                    anchors.centerIn: parent
                    text: "‹"
                    font.pixelSize: Theme.fontSize + 6
                }
                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: hub.shiftMonth(-1)
                }
            }

            Txt {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                variant: "heading"
                text: Qt.formatDate(new Date(hub.viewYear, hub.viewMonth, 1), "MMMM yyyy")

                // click the title to jump back to today
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: hub.goToday()
                }
            }

            Rectangle {
                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                color: nextMouse.containsMouse ? Theme.surface : "transparent"

                Txt {
                    anchors.centerIn: parent
                    text: "›"
                    font.pixelSize: Theme.fontSize + 6
                }
                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: hub.shiftMonth(1)
                }
            }
        }

        // ---------- calendar grid ----------
        Grid {
            Layout.alignment: Qt.AlignHCenter
            columns: 7
            columnSpacing: 4
            rowSpacing: 2

            // weekday names
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                delegate: Txt {
                    required property string modelData

                    width: 42
                    height: 22
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    variant: "small"
                    font.bold: true
                    text: modelData
                }
            }

            // days
            Repeater {
                model: hub.cells

                delegate: Rectangle {
                    id: dayCell
                    required property var modelData

                    readonly property bool inMonth: modelData.month === hub.viewMonth
                    readonly property bool isToday: modelData.day === hub.today.getDate() && modelData.month === hub.today.getMonth() && modelData.year === hub.today.getFullYear()

                    width: 42
                    height: 30
                    radius: 8
                    color: isToday ? Theme.accent : "transparent"

                    Txt {
                        anchors.centerIn: parent
                        variant: "row"
                        text: dayCell.modelData.day
                        color: dayCell.isToday ? Theme.bgSolid : dayCell.inMonth ? Theme.fg : Theme.dim
                        opacity: dayCell.inMonth || dayCell.isToday ? 1 : 0.5
                        font.bold: dayCell.isToday
                    }
                }
            }

            // scroll over the calendar to change month
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => hub.shiftMonth(event.angleDelta.y > 0 ? -1 : 1)
            }
        }

        Divider {}

        // ---------- picker buttons ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    {
                        label: "Apps",
                        key: "A",
                        icon: Icons.apps,
                        target: "launcher"
                    },
                    {
                        label: "Wallpapers",
                        key: "W",
                        icon: Icons.wallpaper,
                        target: "wallpaper"
                    },
                    {
                        label: "Clipboard",
                        key: "C",
                        icon: Icons.clipboard,
                        target: "clipboard"
                    },
                    {
                        label: "Screenshot",
                        key: "S",
                        icon: Icons.screenshot,
                        target: "screenshot"
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

                        Txt {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: btn.modelData.icon
                            color: btnMouse.containsMouse ? Theme.accent : Theme.fg
                            font.pixelSize: Theme.fontSize + 8
                        }

                        Txt {
                            anchors.horizontalCenter: parent.horizontalCenter
                            variant: "dim"
                            color: Theme.fg
                            text: btn.modelData.label
                        }
                    }

                    // shortcut key, top right
                    Txt {
                        anchors {
                            top: parent.top
                            right: parent.right
                            margins: 6
                        }
                        variant: "small"
                        text: btn.modelData.key
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

        Hint {
            text: "h l month • t today • a w c s open • Esc close"
        }
    }
}

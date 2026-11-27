import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// The hub (SUPER + ALT + Space, or the clock), in three tabs:
//   Home    date and weather, the calendar with the selected day's events on the left; what's playing,
//           quick toggles, CPU/RAM/GPU and shortcuts to the other pickers on the right
//   System  btop-like: graphs, each core, memory, GPU, network, disks, the busiest processes
//   About   neofetch-like, for fun
// System and About exist only while showing, so they read nothing otherwise. It always opens on Home.
DropdownPanel {
    id: panel
    name: "hub"
    edge: "center"
    cardWidth: 720

    ColumnLayout {
        id: hub
        spacing: 12

        property int tab: 0
        readonly property var tabs: ["Home", "System", "About"]

        Keys.onPressed: event => {
            // the tabs: Tab / Shift+Tab, or the number row's 1 2 3 (by keycode, so AZERTY needs no Shift)
            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                hub.tab = (hub.tab + (event.key === Qt.Key_Tab ? 1 : hub.tabs.length - 1)) % hub.tabs.length;
                event.accepted = true;
                return;
            }
            const numberRow = [10, 11, 12].indexOf(event.nativeScanCode);
            if (numberRow >= 0) {
                hub.tab = numberRow;
                event.accepted = true;
                return;
            }
            // the calendar's keys only mean something on Home
            const calendarKeys = [Qt.Key_Left, Qt.Key_H, Qt.Key_Right, Qt.Key_L, Qt.Key_J, Qt.Key_Down, Qt.Key_K, Qt.Key_Up, Qt.Key_T];
            if (hub.tab !== 0 && calendarKeys.includes(event.key))
                return;

            switch (event.key) {
            case Qt.Key_Left:
            case Qt.Key_H:
                calendar.shiftMonth(-1);
                break;
            case Qt.Key_Right:
            case Qt.Key_L:
                calendar.shiftMonth(1);
                break;
            case Qt.Key_J:
            case Qt.Key_Down:
                calendar.moveDay(1);
                break;
            case Qt.Key_K:
            case Qt.Key_Up:
                calendar.moveDay(-1);
                break;
            case Qt.Key_T:
                calendar.goToday();
                break;
            case Qt.Key_A:
                Hub.openPicker("launcher");
                break;
            case Qt.Key_W:
                Hub.openPicker("wallpaper");
                break;
            case Qt.Key_E:
                Hub.openPicker("theme");
                break;
            case Qt.Key_C:
                Hub.openPicker("clipboard");
                break;
            case Qt.Key_S:
                Hub.openPicker("screenshot");
                break;
            case Qt.Key_I:
                Hub.openPicker("install");
                break;
            case Qt.Key_R:
                Hub.openPicker("remove");
                break;
            case Qt.Key_Question:
                Hub.openPicker("keybinds");
                break;
            case Qt.Key_P:
            case Qt.Key_Space:
                Media.toggle();
                break;
            case Qt.Key_N:
                Media.next();
                break;
            case Qt.Key_B:
                Media.previous();
                break;
            case Qt.Key_Q:
                panel.close();
                break;
            default:
                return;
            }
            event.accepted = true;
        }

        // ---------- the tabs ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: hub.tabs

                delegate: Pill {
                    required property string modelData
                    required property int index

                    text: modelData
                    active: hub.tab === index
                    minWidth: 80
                    onClicked: hub.tab = index
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        // the three tabs share one height: Home's, with room enough for System
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(home.implicitHeight, 520)

            // the calendar's side on the left, the player and shortcuts on the right
            RowLayout {
                id: home
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                // hidden, not removed, while another tab shows: its height stays the tabs' height
                opacity: hub.tab === 0 ? 1 : 0
                enabled: hub.tab === 0
                spacing: 20

                ColumnLayout {
                    Layout.preferredWidth: 318        // the calendar grid's width
                    Layout.maximumWidth: 318
                    Layout.alignment: Qt.AlignTop
                    spacing: 12

                    // ---------- time and date, weather next to them ----------
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // fresh weather whenever the hub opens (the service also refreshes every 30 minutes)
                        Component.onCompleted: Weather.refreshIfStale()

                        DateTimeBlock {
                            Layout.fillWidth: true
                        }

                        // the columns hold only fixed-size text, so this is what lets the row span the card
                        Item {
                            Layout.fillWidth: true
                        }

                        WeatherBlock {
                            Layout.fillWidth: false             // nested layouts fill by default: stay against the right edge
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        }
                    }

                    Divider {}

                    // ---------- calendar ----------
                    HubCalendar {
                        id: calendar
                        Layout.fillWidth: true
                    }

                    Divider {}

                    // ---------- events of the selected day ----------
                    HubEvents {
                        Layout.fillWidth: true
                        day: calendar.selected
                        today: calendar.today
                    }
                }

                Rectangle {
                    Layout.fillHeight: true
                    implicitWidth: 1
                    color: Theme.border
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 12

                    // ---------- now playing (only while a player has a track) ----------
                    NowPlaying {
                        Layout.fillWidth: true
                    }

                    Divider {
                        visible: Media.active
                    }

                    // ---------- quick toggles ----------
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        QuickToggle {
                            icon: Net.wifiOn ? Icons.wifi4 : Icons.wifiOff
                            label: "Wi-Fi"
                            active: Net.wifiOn && Net.wifiDevice !== null
                            available: Net.wifiDevice !== null
                            onClicked: Net.toggleWifi()
                        }

                        QuickToggle {
                            icon: Bt.connected ? Icons.bluetoothConnected : Bt.powered ? Icons.bluetooth : Icons.bluetoothOff
                            label: "Bluetooth"
                            active: Bt.powered
                            available: Bt.adapter !== null
                            onClicked: Bt.togglePower()
                        }

                        QuickToggle {
                            icon: Notifs.dnd ? Icons.bellOff : Icons.bell
                            label: "Silent"
                            active: Notifs.dnd
                            onClicked: Notifs.dnd = !Notifs.dnd
                        }

                        QuickToggle {
                            icon: Icons.keepAwake
                            label: "Awake"
                            active: Toggles.keepAwake
                            onClicked: Toggles.keepAwake = !Toggles.keepAwake
                        }
                    }

                    // ---------- CPU, RAM and GPU (read only while the hub is open) ----------
                    HubStats {
                        Layout.fillWidth: true
                        active: hub.tab === 0
                    }

                    Divider {}

                    // ---------- shortcuts: the pickers, and the packages ----------
                    Txt {
                        variant: "heading"
                        text: "Open"
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8

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
                                    label: "Theme",
                                    key: "E",
                                    icon: Icons.palette,
                                    target: "theme"
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
                                },
                                {
                                    label: "Keybinds",
                                    key: "?",
                                    icon: Icons.keyboard,
                                    target: "keybinds"
                                },
                                {
                                    label: "Install",
                                    key: "I",
                                    icon: Icons.packageInstall,
                                    target: "install"
                                },
                                {
                                    label: "Remove",
                                    key: "R",
                                    icon: Icons.packageRemove,
                                    target: "remove"
                                }
                            ]

                            delegate: ShortcutTile {
                                onActivated: target => Hub.openPicker(target)
                            }
                        }
                    }
                }
            }

            Loader {
                anchors.fill: parent
                active: hub.tab === 1
                sourceComponent: HubSystem {}
            }

            Loader {
                anchors.fill: parent
                active: hub.tab === 2
                sourceComponent: HubAbout {}
            }
        }

        Hint {
            readonly property string media: Media.active ? " • p/b/n media" : ""
            text: hub.tab === 0 ? "Tab or 1 2 3 tabs • h l month • j k day • t today" + media + " • a w e c s ? i r open • Esc" : "Tab or 1 2 3 tabs" + media + " • a w e c s ? i r open • Esc close"
        }
    }
}

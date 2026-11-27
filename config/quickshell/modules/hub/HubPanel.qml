import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// The hub (SUPER + ALT + Space, or the clock): date and weather, the calendar with the selected day's
// events on the left; what's playing and shortcuts to the other pickers on the right.
DropdownPanel {
    id: panel
    name: "hub"
    edge: "center"
    cardWidth: 720

    ColumnLayout {
        id: hub
        spacing: 12

        Keys.onPressed: event => {
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

        // the calendar's side on the left, the player and shortcuts on the right
        RowLayout {
            Layout.fillWidth: true
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

        Hint {
            text: Media.active ? "h l month • j k day • t today • p/b/n media • a w e c s ? i r open • Esc" : "h l month • j k day • t today • a w e c s ? i r open • Esc close"
        }
    }
}

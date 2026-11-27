import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui
import qs.modules.launcher
import qs.modules.wallpaper
import qs.modules.theme
import qs.modules.clipboard
import qs.modules.screenshot
import qs.modules.keybinds
import qs.modules.packages

// The hub (SUPER + ALT + Space, or the clock), in tabs:
//   Home    one column: date and weather, what's playing, the quick toggles, the calendar and the selected
//           day's events
//   System  btop-like: graphs, each core, memory, GPU, network, disks, the busiest processes
//   About   neofetch-like, for fun
//   then the pickers, each its own view as in its panel: apps, wallpapers, theme, clipboard, screenshot,
//   keybinds, install, remove
// A tab other than Home exists only while showing, so it reads nothing otherwise. It always opens on
// Home. Panels.hubTab says which tab shows, so a picker's service knows it is on screen (Panels.isShown).
// The hub takes each picker's own size (Panels.pickerSizes), growing or shrinking to it as tabs change,
// so a picker looks the same here as in its panel.
DropdownPanel {
    id: panel
    name: "hub"
    edge: "center"
    cardWidth: (Panels.pickerSizes[Panels.hubTab] ?? [Panels.hubTab === "home" ? 420 : 720])[0]

    ColumnLayout {
        id: hub
        spacing: 12

        readonly property var tabs: [
            {
                id: "home",
                label: "Home",
                icon: Icons.home
            },
            {
                id: "system",
                label: "System",
                icon: Icons.system
            },
            {
                id: "about",
                label: "About",
                icon: Icons.about
            },
            {
                id: "launcher",
                label: "Apps",
                icon: Icons.apps,
                key: "a"
            },
            {
                id: "wallpaper",
                label: "Wallpapers",
                icon: Icons.wallpaper,
                key: "w"
            },
            {
                id: "theme",
                label: "Theme",
                icon: Icons.palette,
                key: "e",
                takesKeys: true            // no search box: the view itself takes the keyboard
            },
            {
                id: "clipboard",
                label: "Clipboard",
                icon: Icons.clipboard,
                key: "c"
            },
            {
                id: "screenshot",
                label: "Screenshot",
                icon: Icons.screenshot,
                key: "s",
                takesKeys: true
            },
            {
                id: "keybinds",
                label: "Keybinds",
                icon: Icons.keyboard,
                key: "?"
            },
            {
                id: "install",
                label: "Install",
                icon: Icons.packageInstall,
                key: "i"
            },
            {
                id: "remove",
                label: "Remove",
                icon: Icons.packageRemove,
                key: "r"
            }
        ]
        readonly property int tab: Math.max(0, tabs.findIndex(t => t.id === Panels.hubTab))
        readonly property var current: tabs[tab]

        function show(i) {
            Panels.hubTab = tabs[(i + tabs.length) % tabs.length].id;
        }

        // a new hub starts on Home, and a closed one leaves no picker "shown"
        Component.onCompleted: Panels.hubTab = "home"
        Component.onDestruction: Panels.hubTab = "home"

        // back on a tab without its own keyboard handling: the hub takes the keys again
        onTabChanged: if (!current.takesKeys)
            Qt.callLater(() => {
                if (hub)               // gone already when the change came from closing
                    hub.forceActiveFocus();
            })

        Keys.onPressed: event => {
            // the tabs, everywhere: Tab / Shift+Tab, or the number row's 1 2 3 (by keycode, so AZERTY needs
            // no Shift). A tab's own keys come first (a search box, the screenshot menu's numbers)
            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                hub.show(hub.tab + (event.key === Qt.Key_Tab ? 1 : -1));
                event.accepted = true;
                return;
            }
            const numberRow = [10, 11, 12].indexOf(event.nativeScanCode);
            if (numberRow >= 0) {
                hub.show(numberRow);
                event.accepted = true;
                return;
            }
            // the rest only on Home
            if (hub.tab !== 0)
                return;

            const picker = hub.tabs.findIndex(t => t.key && t.key === event.text.toLowerCase());
            if (picker >= 0) {
                hub.show(picker);
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Q)
                panel.close();
            else if (!home.handleKey(event.key))
                return;
            event.accepted = true;
        }

        // ---------- the tabs, by icon (the narrowest picker is 420 wide); the name is in the hint ----------
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            Repeater {
                model: hub.tabs

                delegate: IconPill {
                    required property var modelData
                    required property int index

                    // a gap between the hub's own tabs and the pickers
                    Layout.leftMargin: index === 3 ? 8 : 0
                    icon: modelData.icon
                    active: hub.tab === index
                    onClicked: hub.show(index)
                }
            }
        }

        // the tab's own height: Home's and a picker's are their content's, a fixed-size picker's its card's
        // inside (as in its panel), System's and About's room enough for them
        Item {
            readonly property var size: Panels.pickerSizes[hub.current.id] ?? null

            Layout.fillWidth: true
            Layout.preferredHeight: hub.tab === 0 ? home.implicitHeight : !size ? 560 : size[1] > 0 ? size[1] - 2 * panel.padding : (picker.item?.implicitHeight ?? 0)
            clip: true

            HubHome {
                id: home
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                // hidden, not removed, while another tab shows: the calendar keeps its month and day
                opacity: hub.tab === 0 ? 1 : 0
                enabled: hub.tab === 0
            }

            Loader {
                anchors.fill: parent
                active: hub.current.id === "system"
                sourceComponent: HubSystem {}
            }

            Loader {
                anchors.fill: parent
                active: hub.current.id === "about"
                sourceComponent: HubAbout {}
            }

            // ---------- the picker on show: the same view as in its own panel ----------
            Component {
                id: launcherView
                LauncherView {}
            }
            Component {
                id: wallpaperView
                WallpaperView {}
            }
            Component {
                id: themeView
                ThemeView {}
            }
            Component {
                id: clipboardView
                ClipboardView {}
            }
            Component {
                id: screenshotView
                ScreenshotView {}
            }
            Component {
                id: keybindsView
                KeybindsView {}
            }
            Component {
                id: installView
                InstallView {}
            }
            Component {
                id: removeView
                RemoveView {}
            }

            Loader {
                id: picker
                anchors.fill: parent
                active: hub.tab >= 3
                sourceComponent: ({
                        launcher: launcherView,
                        wallpaper: wallpaperView,
                        theme: themeView,
                        clipboard: clipboardView,
                        screenshot: screenshotView,
                        keybinds: keybindsView,
                        install: installView,
                        remove: removeView
                    })[hub.current.id] ?? null
                onLoaded: if (hub.current.takesKeys)
                    item.forceActiveFocus()
            }
        }

        Hint {
            readonly property string media: Media.active ? " • p/b/n media" : ""
            text: hub.tab === 0 ? "Home • Tab or 1 2 3 tabs • h l month • j k day • t today" + media + " • a w e c s ? i r pickers • Esc" : hub.current.label + " • Tab / Shift+Tab or 1 2 3 tabs • Esc close"
        }
    }
}

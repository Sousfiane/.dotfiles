import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import qs.config
import Quickshell.Hyprland
import qs.components

Scope {
    id: root

    property bool open: false
    readonly property string wallpaperDir: Quickshell.env("HOME") + "/.wallpapers"
    property string query: ""
    onOpenChanged: {
        query = "";                 // start fresh on every open
        Panels.wallpaperOpen = open;
    }

    readonly property var extensions: ["png", "jpg", "jpeg", "webp", "bmp", "gif"]
    readonly property var filters: {
        // strip characters that would act as wildcards in the filter
        const q = query.trim().replace(/[\[\]\\?*]/g, "");
        return extensions.map(e => "*" + q + "*." + e);
    }

    IpcHandler {
        target: "wallpaper"

        function toggle(): void {
            root.open = !root.open;
        }

        function close(): void {
            root.open = false;
        }
    }

    FileView {
        id: currentWallpaperFile
        path: Quickshell.env("HOME") + "/.swaybg"
        blockLoading: true
    }

    FolderListModel {
        id: wallpapers

        folder: "file://" + root.wallpaperDir
        showDirs: false
        showFiles: true
        sortField: FolderListModel.Name

        caseSensitive: false
        nameFilters: root.filters
    }

    function applyWallpaper(path) {
        currentWallpaperFile.setText(path + "\n");

        Quickshell.execDetached(["bash", "-c", "pkill -x swaybg 2>/dev/null || true; " + "setsid uwsm-app -- swaybg -i \"$1\" >/dev/null 2>&1 &", "wallpaper-picker", path]);

        root.open = false;
    }

    function focusedScreen() {
        const name = Hyprland.focusedMonitor?.name;
        for (let i = 0; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i].name === name)
                return Quickshell.screens[i];
        return Quickshell.screens[0];
    }

    SlideLoader {
        open: root.open

        PanelWindow {
            id: panel

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
            WlrLayershell.namespace: "wallpaper-picker"

            Item {
                id: content
                anchors.fill: parent

                function applyCurrent() {
                    const item = grid.itemAtIndex(grid.currentIndex);
                    if (item)
                        root.applyWallpaper(item.filePath);
                }

                Keys.onEscapePressed: root.open = false

                // click outside to close
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.open = false
                }

                SlideArea {
                    open: root.open

                    DropCard {
                        id: card
                        edge: "center"
                        anchors {
                            top: parent.top
                            horizontalCenter: parent.horizontalCenter
                        }
                        width: Math.min(1000, parent.width - 64)
                        height: Math.min(760, parent.height - 16)

                        // swallow clicks on the card
                        MouseArea {
                            anchors.fill: parent
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 16

                            // Header
                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Wallpapers"
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize + 6
                                    font.bold: true
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: wallpapers.count + " images"
                                    color: Theme.dim
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize
                                }

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: Theme.radius
                                    color: closeMouse.containsMouse ? Theme.surface : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "×"
                                        color: Theme.fg
                                        font.pixelSize: 20
                                    }

                                    MouseArea {
                                        id: closeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.open = false
                                    }
                                }
                            }

                            // Search
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40

                                radius: Theme.radius
                                color: Theme.surface

                                TextInput {
                                    id: search

                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12

                                    verticalAlignment: TextInput.AlignVCenter

                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize

                                    clip: true
                                    selectByMouse: true

                                    focus: true
                                    Component.onCompleted: forceActiveFocus()

                                    onTextChanged: root.query = text

                                    Keys.onEscapePressed: root.open = false
                                    Keys.onUpPressed: grid.moveCurrentIndexUp()
                                    Keys.onDownPressed: grid.moveCurrentIndexDown()
                                    Keys.onLeftPressed: grid.moveCurrentIndexLeft()
                                    Keys.onRightPressed: grid.moveCurrentIndexRight()
                                    Keys.onReturnPressed: content.applyCurrent()
                                    Keys.onEnterPressed: content.applyCurrent()

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Search wallpapers..."
                                        color: Theme.dim
                                        visible: search.text.length === 0
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize
                                    }
                                }
                            }

                            // Wallpaper grid

                            GridView {
                                id: grid

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                clip: true
                                cellWidth: 220
                                cellHeight: 166
                                model: wallpapers

                                focus: true
                                keyNavigationEnabled: true
                                currentIndex: wallpapers.count > 0 ? 0 : -1

                                Component.onCompleted: forceActiveFocus()

                                Keys.onReturnPressed: {
                                    const item = grid.itemAtIndex(grid.currentIndex);
                                    if (item)
                                        root.applyWallpaper(item.filePath);
                                }

                                Keys.onEnterPressed: {
                                    const item = grid.itemAtIndex(grid.currentIndex);
                                    if (item)
                                        root.applyWallpaper(item.filePath);
                                }

                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AsNeeded
                                }

                                delegate: Item {
                                    id: tile

                                    required property string fileName
                                    required property url fileUrl
                                    required property string filePath
                                    required property int index

                                    width: grid.cellWidth
                                    height: grid.cellHeight

                                    property bool hovered: false
                                    property bool selected: currentWallpaperFile.text().trim() === filePath
                                    property bool highlighted: hovered || grid.currentIndex === index

                                    Rectangle {
                                        id: tileBackground

                                        anchors.fill: parent
                                        anchors.margins: 6

                                        radius: Theme.radius
                                        color: Theme.surface
                                        clip: true

                                        // Image frame, clipped to rounded corners
                                        Rectangle {
                                            id: imageFrame

                                            anchors {
                                                top: parent.top
                                                left: parent.left
                                                right: parent.right
                                            }

                                            height: 116
                                            radius: Theme.radius
                                            clip: true
                                            color: Theme.bg

                                            // Rounded mask, rendered as a texture
                                            Rectangle {
                                                id: previewMask

                                                anchors.fill: parent
                                                radius: imageFrame.radius
                                                color: Theme.bg
                                                antialiasing: true

                                                layer.enabled: true
                                                layer.smooth: true

                                                z: -1
                                            }

                                            Image {
                                                id: preview

                                                anchors.fill: parent

                                                source: tile.fileUrl
                                                asynchronous: true
                                                cache: true
                                                fillMode: Image.PreserveAspectCrop

                                                layer.enabled: true
                                                layer.smooth: true

                                                layer.effect: MultiEffect {
                                                    maskEnabled: true
                                                    maskSource: previewMask
                                                }
                                            }
                                            Text {
                                                anchors.centerIn: parent
                                                visible: preview.status === Image.Loading
                                                text: "Loading..."
                                                color: Theme.dim
                                                font.family: Theme.font
                                            }
                                        }

                                        Text {
                                            anchors {
                                                left: parent.left
                                                right: parent.right
                                                bottom: parent.bottom
                                                margins: 8
                                            }

                                            text: tile.fileName
                                            color: Theme.fg
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize - 1
                                            elide: Text.ElideMiddle
                                        }

                                        // Current wallpaper indicator
                                        Rectangle {
                                            anchors {
                                                top: parent.top
                                                right: parent.right
                                                margins: 8
                                            }

                                            visible: tile.selected
                                            width: 22
                                            height: 22
                                            radius: 11
                                            color: Theme.accent

                                            Text {
                                                anchors.centerIn: parent
                                                text: "✓"
                                                color: Theme.bg
                                                font.bold: true
                                            }
                                        }

                                        // Draw the border ABOVE the image and content
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: Theme.radius
                                            color: "transparent"

                                            border.width: tile.highlighted ? 2 : 0
                                            border.color: Theme.accent

                                            Behavior on border.width {
                                                NumberAnimation {
                                                    duration: 100
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor

                                            onEntered: {
                                                tile.hovered = true;
                                                grid.currentIndex = tile.index;
                                            }

                                            onExited: tile.hovered = false

                                            onClicked: {
                                                grid.currentIndex = tile.index;
                                                root.applyWallpaper(tile.filePath);
                                            }
                                        }
                                    }
                                }
                            }

                            // Empty state
                            Text {
                                Layout.fillWidth: true
                                visible: wallpapers.count === 0
                                horizontalAlignment: Text.AlignHCenter

                                text: "No wallpapers found in " + root.wallpaperDir
                                color: Theme.dim
                                font.family: Theme.font
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Select a wallpaper to apply • Esc to close"
                                horizontalAlignment: Text.AlignHCenter
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 2
                            }
                        }
                    }
                }
            }
        }
    }
}

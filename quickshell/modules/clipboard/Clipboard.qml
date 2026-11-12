import Quickshell
import QtQuick.Effects
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services

Scope {
    // `qs ipc call clipboard toggle|close|refresh`
    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            ClipHistory.toggle();
        }

        function close(): void {
            ClipHistory.open = false;
        }

        function refresh(): void {
            ClipHistory.refresh();
        }
    }

    LazyLoader {
        active: ClipHistory.open

        PanelWindow {
            id: panel

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
            WlrLayershell.namespace: "clipboard-picker"

            Item {
                id: content
                anchors.fill: parent

                function copyCurrent() {
                    const item = ClipHistory.entries.get(grid.currentIndex);
                    if (item)
                        ClipHistory.copy(item.clipId);
                }

                Keys.onEscapePressed: ClipHistory.open = false

                Shortcut {
                    sequence: "Ctrl+R"
                    onActivated: ClipHistory.refresh()
                }

                // Click outside to close
                MouseArea {
                    anchors.fill: parent
                    onClicked: ClipHistory.open = false
                }

                // Main card
                Rectangle {
                    id: card

                    anchors.centerIn: parent

                    width: Math.min(1000, parent.width - 48)
                    height: Math.min(760, parent.height - 48)

                    radius: Theme.radius + 4
                    color: Theme.bg

                    border.color: Theme.border
                    border.width: 2

                    // Consume clicks inside the card
                    MouseArea {
                        anchors.fill: parent
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16

                        // ------------------------------
                        // Header
                        // ------------------------------
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Clipboard"
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize + 6
                                font.bold: true
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: ClipHistory.entries.count + " entries"
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
                                    onClicked: ClipHistory.open = false
                                }
                            }
                        }

                        // ------------------------------
                        // Search
                        // ------------------------------
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

                                onTextChanged: ClipHistory.query = text

                                // navigate the grid while typing
                                Keys.onEscapePressed: ClipHistory.open = false
                                Keys.onUpPressed: grid.moveCurrentIndexUp()
                                Keys.onDownPressed: grid.moveCurrentIndexDown()
                                Keys.onLeftPressed: grid.moveCurrentIndexLeft()
                                Keys.onRightPressed: grid.moveCurrentIndexRight()
                                Keys.onReturnPressed: content.copyCurrent()
                                Keys.onEnterPressed: content.copyCurrent()

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Search clipboard..."
                                    color: Theme.dim
                                    visible: search.text.length === 0
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize
                                }
                            }
                        }

                        // ------------------------------
                        // History grid
                        // ------------------------------
                        GridView {
                            id: grid

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            clip: true
                            cellWidth: 220
                            cellHeight: 166

                            model: ClipHistory.entries
                            currentIndex: 0

                            // reset the selection whenever the results change
                            Connections {
                                target: ClipHistory.entries

                                function onCountChanged() {
                                    grid.currentIndex = ClipHistory.entries.count > 0 ? 0 : -1;
                                }
                            }

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                            }

                            delegate: Item {
                                id: tile

                                required property string clipId
                                required property string kind
                                required property string imageExt
                                required property string preview
                                required property int index

                                width: grid.cellWidth
                                height: grid.cellHeight

                                property bool hovered: false
                                property bool imageReady: false
                                property bool imageFailed: false

                                property string thumbnailPath: ClipHistory.cacheDir + "/" + clipId + ".thumb." + imageExt

                                property bool highlighted: hovered || grid.currentIndex === index

                                // Image thumbnail generation
                                Process {
                                    id: thumbnailProcess

                                    command: ["bash", "-c", ['set -e', 'cache="$1"', 'id="$2"', 'ext="$3"', 'mkdir -p "$cache"', 'original="$cache/$id.$ext"', 'thumb="$cache/$id.thumb.$ext"', 'if [ ! -s "$original" ]; then', '  clipvault get "$id" > "$original.tmp"', '  mv "$original.tmp" "$original"', 'fi', 'if [ ! -s "$thumb" ]; then', '  if command -v magick >/dev/null 2>&1; then', '    magick "$original" -thumbnail "256x256>" "$thumb" 2>/dev/null || cp -f "$original" "$thumb"', '  else', '    cp -f "$original" "$thumb"', '  fi', 'fi'].join("\n"), "clipboard-thumbnail", ClipHistory.cacheDir, tile.clipId, tile.imageExt]

                                    running: tile.kind === "image"

                                    onExited: function (exitCode, exitStatus) {
                                        tile.imageReady = exitCode === 0;
                                        tile.imageFailed = exitCode !== 0;
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 6

                                    radius: Theme.radius
                                    color: Theme.surface
                                    clip: true

                                    // Image preview
                                    // Image preview, clipped to rounded corners
                                    Rectangle {
                                        id: imageFrame

                                        anchors {
                                            top: parent.top
                                            left: parent.left
                                            right: parent.right
                                        }

                                        height: 112
                                        radius: Theme.radius
                                        clip: true
                                        color: Theme.bg
                                        visible: tile.kind === "image"

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
                                            id: previewImage

                                            anchors.fill: parent

                                            visible: tile.imageReady
                                            source: tile.imageReady ? "file://" + tile.thumbnailPath : ""

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

                                        // Image loading label
                                        Text {
                                            anchors.centerIn: parent
                                            visible: !tile.imageReady && !tile.imageFailed

                                            text: "Loading image..."
                                            color: Theme.dim
                                            font.family: Theme.font
                                        }

                                        // Image failure label
                                        Text {
                                            anchors.centerIn: parent
                                            visible: tile.imageFailed

                                            text: "Preview unavailable"
                                            color: Theme.dim
                                            font.family: Theme.font
                                        }
                                    }
                                    // Image loading label
                                    Text {
                                        anchors.centerIn: previewImage
                                        visible: tile.kind === "image" && !tile.imageReady && !tile.imageFailed

                                        text: "Loading image..."
                                        color: Theme.dim
                                        font.family: Theme.font
                                    }

                                    // Image failure label
                                    Text {
                                        anchors.centerIn: previewImage
                                        visible: tile.imageFailed

                                        text: "Preview unavailable"
                                        color: Theme.dim
                                        font.family: Theme.font
                                    }

                                    // Text preview
                                    Text {
                                        anchors {
                                            fill: parent
                                            margins: 12
                                        }

                                        visible: tile.kind === "text"

                                        text: tile.preview
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize

                                        wrapMode: Text.WrapAnywhere
                                        maximumLineCount: 7
                                        elide: Text.ElideRight
                                        textFormat: Text.PlainText
                                    }

                                    // Image type label
                                    Text {
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            bottom: parent.bottom
                                            margins: 8
                                        }

                                        visible: tile.kind === "image"

                                        text: tile.preview
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 1
                                    }

                                    // Highlight border, drawn above the content
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

                                    // Mouse interaction
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
                                            ClipHistory.copy(tile.clipId);
                                        }
                                    }
                                }
                            }
                        }

                        // ------------------------------
                        // Empty state
                        // ------------------------------
                        Text {
                            Layout.fillWidth: true

                            visible: ClipHistory.entries.count === 0
                            horizontalAlignment: Text.AlignHCenter

                            text: ClipHistory.items.length === 0 ? "No clipboard history found" : "No matching entries"

                            color: Theme.dim
                            font.family: Theme.font
                        }

                        Text {
                            Layout.fillWidth: true

                            text: "Enter to copy • Arrows to navigate • Esc to close • Ctrl+R to refresh"
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

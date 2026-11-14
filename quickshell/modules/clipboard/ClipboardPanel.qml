import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.config
import qs.services
import qs.components

DropdownPanel {
    name: "clipboard"
    edge: "center"
    cardWidth: 1000
    cardHeight: 760
    padding: 20
    autoFocus: false            // the search box takes the focus itself

    ColumnLayout {
        spacing: 16

        function copyCurrent() {
            const item = ClipHistory.entries.get(grid.currentIndex);
            if (item)
                ClipHistory.copy(item.clipId);
        }

        function navigate(direction) {
            switch (direction) {
            case "up":
                grid.moveCurrentIndexUp();
                break;
            case "down":
                grid.moveCurrentIndexDown();
                break;
            case "left":
                grid.moveCurrentIndexLeft();
                break;
            case "right":
                grid.moveCurrentIndexRight();
                break;
            }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_R && (event.modifiers & Qt.ControlModifier)) {
                ClipHistory.refresh();
                event.accepted = true;
            }
        }

        // ---------- header ----------
        PanelHeader {
            icon: Icons.clipboard
            title: "Clipboard"
            subtitle: ClipHistory.entries.count + " entries"
        }

        SearchBox {
            placeholder: "Search clipboard..."
            horizontalNav: true

            onTextChanged: ClipHistory.query = text
            onMoved: direction => parent.navigate(direction)
            onAccepted: parent.copyCurrent()
        }

        // ---------- history grid ----------
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

                readonly property string thumbnailPath: ClipHistory.cacheDir + "/" + clipId + ".thumb." + imageExt
                readonly property bool highlighted: hovered || grid.currentIndex === index

                // image thumbnail generation
                Process {
                    command: ["bash", "-c", ['set -e', 'cache="$1"', 'id="$2"', 'ext="$3"', 'mkdir -p "$cache"', 'original="$cache/$id.$ext"', 'thumb="$cache/$id.thumb.$ext"', 'if [ ! -s "$original" ]; then', '  clipvault get "$id" > "$original.tmp"', '  mv "$original.tmp" "$original"', 'fi', 'if [ ! -s "$thumb" ]; then', '  if command -v magick >/dev/null 2>&1; then', '    magick "$original" -thumbnail "256x256>" "$thumb" 2>/dev/null || cp -f "$original" "$thumb"', '  else', '    cp -f "$original" "$thumb"', '  fi', 'fi'].join("\n"), "clipboard-thumbnail", ClipHistory.cacheDir, tile.clipId, tile.imageExt]

                    running: tile.kind === "image"

                    onExited: (exitCode, exitStatus) => {
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

                    // image preview, clipped to rounded corners
                    ClippingRectangle {
                        visible: tile.kind === "image"
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                        }
                        height: 112
                        radius: Theme.radius
                        color: Theme.bgSolid

                        Image {
                            anchors.fill: parent
                            visible: tile.imageReady
                            source: tile.imageReady ? "file://" + tile.thumbnailPath : ""
                            sourceSize.width: 416
                            asynchronous: true
                            cache: true
                            fillMode: Image.PreserveAspectCrop
                        }

                        Txt {
                            anchors.centerIn: parent
                            visible: !tile.imageReady
                            variant: "dim"
                            text: tile.imageFailed ? "Preview unavailable" : "Loading image..."
                        }
                    }

                    // text preview
                    Txt {
                        anchors {
                            fill: parent
                            margins: 12
                        }
                        visible: tile.kind === "text"
                        text: tile.preview
                        wrapMode: Text.WrapAnywhere
                        maximumLineCount: 7
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    // image type label
                    Txt {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                            margins: 8
                        }
                        visible: tile.kind === "image"
                        variant: "row"
                        text: tile.preview
                    }

                    // highlight border, above the content
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
                        onClicked: ClipHistory.copy(tile.clipId)
                    }
                }
            }
        }

        Txt {
            Layout.fillWidth: true
            visible: ClipHistory.entries.count === 0
            horizontalAlignment: Text.AlignHCenter
            variant: "dim"
            text: ClipHistory.items.length === 0 ? "No clipboard history found" : "No matching entries"
        }

        Hint {
            text: "Enter to copy • arrows to navigate • Ctrl+R refresh • Esc to close"
        }
    }
}

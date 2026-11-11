import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config

Scope {
    id: root

    property bool open: false
    property var historyItems: []

    readonly property string cacheRoot: Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")

    readonly property string cacheDir: cacheRoot + "/clipvault/thumbs"

    ListModel {
        id: entries
    }

    // --------------------------------------------------
    // IPC
    // --------------------------------------------------

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            root.open = !root.open;

            if (root.open) {
                searchText = "";
                root.refreshHistory();
            }
        }

        function close(): void {
            root.open = false;
        }

        function refresh(): void {
            root.refreshHistory();
        }
    }

    // --------------------------------------------------
    // Clipboard history
    // --------------------------------------------------

    Process {
        id: historyProcess

        command: ["clipvault", "list"]

        stdout: StdioCollector {
            onStreamFinished: root.parseHistory(this.text)
        }
    }

    function refreshHistory() {
        entries.clear();
        historyProcess.running = false;
        historyProcess.running = true;
    }

    function parseHistory(output) {
        let parsed = [];
        const lines = output.split(/\r?\n/);

        for (let i = 0; i < lines.length; i++) {
            const match = lines[i].match(/^([0-9]+)\s+(.*)$/);

            if (!match)
                continue;
            const clipId = match[1];
            const content = match[2];

            // Ignore HTML metadata
            if (content.startsWith("<meta http-equiv="))
                continue;

            // Image entry
            if (/^\[\[\s*binary/i.test(content)) {
                const extMatch = content.match(/\b(jpeg|jpg|png|bmp|webp|tiff|tif|gif)\b/i);

                if (!extMatch)
                    continue;
                const ext = extMatch[1].toLowerCase();

                parsed.push({
                    clipId: clipId,
                    kind: "image",
                    imageExt: ext,
                    preview: "Image • " + ext.toUpperCase(),
                    searchText: "image " + ext + " " + clipId
                });

                continue;
            }

            // Normal text entry
            let preview = content;

            if (preview.length > 240)
                preview = preview.substring(0, 240) + "…";

            parsed.push({
                clipId: clipId,
                kind: "text",
                imageExt: "",
                preview: preview,
                searchText: content.toLowerCase()
            });
        }

        historyItems = parsed;
        filterEntries(searchText);
    }

    // --------------------------------------------------
    // Search
    // --------------------------------------------------

    property string searchText: ""

    function filterEntries(query) {
        entries.clear();

        const needle = (query || "").toLowerCase().trim();

        for (let i = 0; i < historyItems.length; i++) {
            const item = historyItems[i];

            if (needle.length === 0 || item.searchText.indexOf(needle) !== -1) {
                entries.append(item);
            }
        }

        grid.currentIndex = entries.count > 0 ? 0 : -1;
    }

    // --------------------------------------------------
    // Copy entry
    // --------------------------------------------------

    function copyEntry(id) {
        if (!/^[0-9]+$/.test(id))
            return;
        Quickshell.execDetached(["bash", "-c", "set -o pipefail; clipvault get \"$1\" | wl-copy", "clipboard-copy", id]);

        root.open = false;
    }

    // --------------------------------------------------
    // Window
    // --------------------------------------------------

    LazyLoader {
        active: root.open

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
                anchors.fill: parent
                focus: true

                Keys.onEscapePressed: root.open = false

                Shortcut {
                    sequence: "Ctrl+R"
                    onActivated: root.refreshHistory()
                }

                // Click outside to close
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.open = false
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

                        // --------------------------------
                        // Header
                        // --------------------------------

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
                                text: entries.count + " entries"
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

                        // --------------------------------
                        // Search
                        // --------------------------------

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40

                            radius: Theme.radius
                            color: Theme.surface

                            TextInput {
                                id: search

                                focus: true

                                Component.onCompleted: forceActiveFocus()
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12

                                verticalAlignment: TextInput.AlignVCenter

                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize

                                clip: true
                                selectByMouse: true

                                onTextChanged: {
                                    root.searchText = text;
                                    root.filterEntries(text);
                                }

                                onAccepted: grid.forceActiveFocus()

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Search clipboard..."
                                    color: Theme.dim
                                    visible: search.text.length === 0
                                }
                            }
                        }

                        // --------------------------------
                        // History grid
                        // --------------------------------

                        GridView {
                            id: grid

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            clip: true

                            cellWidth: 220
                            cellHeight: 166

                            model: entries

                            keyNavigationEnabled: true
                            currentIndex: entries.count > 0 ? 0 : -1

                            Keys.onReturnPressed: {
                                const item = entries.get(grid.currentIndex);

                                if (item)
                                    root.copyEntry(item.clipId);
                            }

                            Keys.onEnterPressed: {
                                const item = entries.get(grid.currentIndex);

                                if (item)
                                    root.copyEntry(item.clipId);
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

                                property string thumbnailPath: root.cacheDir + "/" + clipId + ".thumb." + imageExt

                                property bool highlighted: hovered || grid.currentIndex === index

                                // --------------------------------
                                // Image thumbnail process
                                // --------------------------------

                                Process {
                                    id: thumbnailProcess

                                    command: ["bash", "-c", "set -e\n" + 'cache="$1"\n' + 'id="$2"\n' + 'ext="$3"\n' + 'mkdir -p "$cache"\n' + 'original="$cache/$id.$ext"\n' + 'thumb="$cache/$id.thumb.$ext"\n' + 'if [ ! -s "$original" ]; then\n' + '  clipvault get "$id" > "$original.tmp"\n' + '  mv "$original.tmp" "$original"\n' + 'fi\n' + 'if [ ! -s "$thumb" ]; then\n' + '  if command -v magick >/dev/null 2>&1; then\n' + '    magick "$original" -thumbnail "256x256>" "$thumb" 2>/dev/null || cp -f "$original" "$thumb"\n' + '  else\n' + '    cp -f "$original" "$thumb"\n' + '  fi\n' + 'fi', "clipboard-thumbnail", root.cacheDir, tile.clipId, tile.imageExt]

                                    running: tile.kind === "image"

                                    onExited: function (exitCode, exitStatus) {
                                        tile.imageReady = exitCode === 0;
                                        tile.imageFailed = exitCode !== 0;
                                    }
                                }

                                // --------------------------------
                                // Tile
                                // --------------------------------

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: 6

                                    radius: Theme.radius
                                    color: Theme.surface
                                    clip: true

                                    // Image preview
                                    Image {
                                        id: previewImage

                                        anchors {
                                            top: parent.top
                                            left: parent.left
                                            right: parent.right
                                        }

                                        height: 112

                                        visible: tile.kind === "image" && tile.imageReady

                                        source: tile.imageReady ? "file://" + tile.thumbnailPath : ""

                                        asynchronous: true
                                        cache: true
                                        fillMode: Image.PreserveAspectCrop
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

                                    // Highlight border
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
                                            root.copyEntry(tile.clipId);
                                        }
                                    }
                                }
                            }
                        }

                        // --------------------------------
                        // Empty state
                        // --------------------------------

                        Text {
                            Layout.fillWidth: true

                            visible: entries.count === 0

                            horizontalAlignment: Text.AlignHCenter

                            text: historyItems.length === 0 ? "No clipboard history found" : "No matching entries"

                            color: Theme.dim
                            font.family: Theme.font
                        }

                        Text {
                            Layout.fillWidth: true

                            text: "Enter to copy • Esc to close • Ctrl+R to refresh"

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

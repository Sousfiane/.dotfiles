import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// The clipboard history (SUPER + V): a searchable grid of text and images, Enter copies one again.
// Shown in its own panel and as the hub's tab (the clipboard history).
GridPicker {
    id: view
    icon: Icons.clipboard
    title: "Clipboard"
    subtitle: ClipHistory.entries.length + " entries"
    placeholder: "Search clipboard..."
    emptyText: ClipHistory.items.length === 0 ? "No clipboard history found" : "No matching entries"
    hint: "Enter to copy • arrows to navigate • Ctrl+R refresh • Esc to close"
    // diffed by clip id: a search keeps the tiles that still match, thumbnails and all
    model: ScriptModel {
        values: ClipHistory.entries
        objectProp: "clipId"
    }

    onSearched: text => ClipHistory.query = text
    onAccepted: index => {
        const item = ClipHistory.entries[index];
        if (item)
            ClipHistory.copy(item.clipId);
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_R && (event.modifiers & Qt.ControlModifier)) {
            ClipHistory.refresh();
            event.accepted = true;
        }
    }

    delegate: GridTile {
        id: tile

        required property var modelData
        readonly property string clipId: modelData.clipId
        readonly property string kind: modelData.kind
        readonly property string imageExt: modelData.imageExt
        readonly property string preview: modelData.preview

        readonly property string thumb: ClipHistory.thumbs[clipId] ?? ""
        readonly property bool imageReady: thumb === "ready"
        readonly property bool imageFailed: thumb === "failed"
        readonly property string thumbnailPath: ClipHistory.thumbPath(clipId, imageExt)

        // ask the service for the thumbnail when the tile appears
        Component.onCompleted: if (kind === "image")
            ClipHistory.requestThumb(clipId, imageExt)

        onClicked: ClipHistory.copy(clipId)

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
    }
}

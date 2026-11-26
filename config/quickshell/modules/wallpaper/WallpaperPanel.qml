import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// The wallpaper picker (SUPER + W): a searchable grid of the images in ~/.wallpapers.
DropdownPanel {
    name: "wallpaper"
    edge: "center"
    cardWidth: 1000
    cardHeight: 760
    padding: 20
    autoFocus: false

    GridPicker {
        icon: Icons.wallpaper
        title: "Wallpapers"
        subtitle: Wallpapers.files.count + " images"
        placeholder: "Search wallpapers..."
        emptyText: "No wallpapers found in " + Wallpapers.dir
        hint: "Enter to apply • arrows to navigate • Esc to close"
        model: Wallpapers.files

        onSearched: text => Wallpapers.query = text
        onAccepted: index => {
            const path = Wallpapers.files.get(index, "filePath");
            if (path)
                Wallpapers.apply(path);
        }

        delegate: GridTile {
            id: tile

            required property string fileName
            required property url fileUrl
            required property string filePath

            readonly property bool current: Wallpapers.isCurrent(filePath)

            onClicked: Wallpapers.apply(filePath)

            // preview, clipped to rounded corners
            ClippingRectangle {
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: 116
                radius: Theme.radius
                color: Theme.bgSolid

                Image {
                    id: preview
                    anchors.fill: parent
                    source: tile.fileUrl
                    sourceSize.width: 416          // decode at thumbnail size, not full resolution
                    asynchronous: true
                    cache: true
                    fillMode: Image.PreserveAspectCrop
                }

                Txt {
                    anchors.centerIn: parent
                    visible: preview.status === Image.Loading
                    variant: "dim"
                    text: "Loading..."
                }
            }

            Txt {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 8
                }
                variant: "row"
                text: tile.fileName
                elide: Text.ElideMiddle
            }

            // current wallpaper indicator
            Rectangle {
                anchors {
                    top: parent.top
                    right: parent.right
                    margins: 8
                }
                visible: tile.current
                width: 22
                height: 22
                radius: 11
                color: Theme.accent

                Txt {
                    anchors.centerIn: parent
                    text: "✓"
                    color: Theme.bgSolid
                    font.bold: true
                }
            }
        }
    }
}

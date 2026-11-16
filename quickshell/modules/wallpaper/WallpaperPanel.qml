import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

DropdownPanel {
    name: "wallpaper"
    edge: "center"
    cardWidth: 1000
    cardHeight: 760
    padding: 20
    autoFocus: false

    ColumnLayout {
        spacing: 16

        function applyCurrent() {
            const item = grid.itemAtIndex(grid.currentIndex);
            if (item)
                Wallpapers.apply(item.filePath);
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

        // ---------- header ----------
        PanelHeader {
            icon: Icons.wallpaper
            title: "Wallpapers"
            subtitle: Wallpapers.files.count + " images"
        }
        SearchBox {
            placeholder: "Search wallpapers..."
            horizontalNav: true

            onTextChanged: {
                Wallpapers.query = text;
                grid.currentIndex = 0;
                grid.positionViewAtBeginning();
            }
            onMoved: direction => parent.navigate(direction)
            onAccepted: parent.applyCurrent()
        }

        // ---------- wallpaper grid ----------
        GridView {
            id: grid

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            cellWidth: 220
            cellHeight: 166
            model: Wallpapers.files
            currentIndex: 0

            // reset the selection whenever the results change
            Connections {
                target: Wallpapers.files

                function onCountChanged() {
                    grid.currentIndex = Wallpapers.files.count > 0 ? 0 : -1;
                }
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

                readonly property bool current: Wallpapers.isCurrent(filePath)
                readonly property bool highlighted: grid.currentIndex === index

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: Theme.radius
                    color: Theme.surface
                    clip: true

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

                    // highlight border, above the image and content
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

                    MotionArea {
                        anchors.fill: parent
                        onMoved: grid.currentIndex = tile.index
                        onClicked: Wallpapers.apply(tile.filePath)
                    }
                }
            }
        }

        Txt {
            Layout.fillWidth: true
            visible: Wallpapers.files.count === 0
            horizontalAlignment: Text.AlignHCenter
            variant: "dim"
            text: "No wallpapers found in " + Wallpapers.dir
        }

        Hint {
            text: "Enter to apply • arrows to navigate • Esc to close"
        }
    }
}

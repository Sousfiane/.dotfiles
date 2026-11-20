import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// A searchable grid of tiles (clipboard, wallpapers): header, search box, grid, empty message, hint.
// The search box keeps the keyboard; arrows move through the grid, Enter emits `accepted`.
ColumnLayout {
    id: root

    property alias icon: header.icon
    property alias title: header.title
    property alias subtitle: header.subtitle
    property alias placeholder: search.placeholder
    property alias model: grid.model
    property alias delegate: grid.delegate      // usually a GridTile
    property alias emptyText: empty.text
    property alias hint: hintText.text
    property alias grid: grid

    signal searched(string text)
    signal accepted(int index)

    spacing: 16

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

    PanelHeader {
        id: header
    }

    SearchBox {
        id: search
        horizontalNav: true

        onTextChanged: {
            root.searched(text);
            grid.currentIndex = 0;
            grid.positionViewAtBeginning();
        }
        onMoved: direction => root.navigate(direction)
        onAccepted: root.accepted(grid.currentIndex)
    }

    GridView {
        id: grid

        Layout.fillWidth: true
        Layout.fillHeight: true

        clip: true
        cellWidth: 220
        cellHeight: 166
        currentIndex: 0

        // reset the selection whenever the results change
        onCountChanged: currentIndex = count > 0 ? 0 : -1

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
    }

    EmptyState {
        id: empty
        visible: grid.count === 0
    }

    Hint {
        id: hintText
    }
}

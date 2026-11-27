import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// One changed file in the dotfiles panel's list: its staged box, git's two status letters and its path.
// The panel's list makes one per path (modelData), at the file's index in Dotfiles.files.
ListRow {
    id: row

    required property string modelData
    required property int index

    readonly property var file: Dotfiles.files[index] ?? null
    property bool armed: false              // waiting for a second `d` to discard it

    signal stageClicked                     // the box
    signal nameClicked                      // the path: its diff

    // staged box: full when all of the file is staged, half when part of it is
    Rectangle {
        Layout.preferredWidth: 14
        Layout.preferredHeight: 14
        radius: Theme.radiusSmall
        color: "transparent"
        border.width: 1
        border.color: row.file?.staged ? Theme.foam : Theme.line

        Rectangle {
            visible: !!row.file?.staged
            anchors.centerIn: parent
            width: row.file?.unstaged ? 6 : 8
            height: row.file?.unstaged ? 2 : 8
            radius: 1
            color: Theme.foam
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: row.stageClicked()
        }
    }

    // git's two letters: the index (staged) in foam, the work tree in gold
    Row {
        Layout.preferredWidth: 20
        spacing: 0

        Txt {
            width: 10
            text: row.file?.untracked ? "?" : row.file?.x ?? ""
            color: row.file?.untracked ? Theme.dim : row.file?.x === "D" ? Theme.urgent : Theme.foam
            font.pixelSize: Theme.fontSize - 2
            font.bold: true
        }

        Txt {
            width: 10
            text: row.file?.untracked ? "?" : row.file?.y ?? ""
            color: row.file?.untracked ? Theme.dim : row.file?.y === "D" ? Theme.urgent : Theme.gold
            font.pixelSize: Theme.fontSize - 2
            font.bold: true
        }
    }

    Txt {
        Layout.fillWidth: true
        variant: "row"
        textFormat: Text.PlainText
        text: row.armed ? "discard " + row.modelData + "?  d again" : row.file?.orig ? row.file.orig + " → " + row.modelData : row.modelData
        color: row.armed ? Theme.urgent : Theme.fg
        elide: Text.ElideMiddle

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: row.nameClicked()
        }
    }
}

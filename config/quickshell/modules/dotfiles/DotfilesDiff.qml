import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// One file's diff in the dotfiles panel: its path, whether it's staged, and Dotfiles.diffLines coloured
// like git's. The panel loads the diff (Dotfiles.loadDiff) and drives the scrolling from its keys.
ColumnLayout {
    id: root

    property var file: null                 // the Dotfiles.files entry shown

    signal back                             // the ‹ button

    spacing: 12

    function scrollBy(dy) {
        list.scrollBy(dy);
    }
    // half a screen down (1) or up (-1)
    function scrollPage(direction) {
        list.scrollBy(direction * list.height / 2);
    }
    function toStart() {
        list.positionViewAtBeginning();
    }
    function toEnd() {
        list.positionViewAtEnd();
    }

    // what the status letters mean
    readonly property string status: {
        if (!file)
            return "";
        if (file.untracked)
            return "untracked";
        if (file.staged && file.unstaged)
            return "partly staged";
        return file.staged ? "staged" : "not staged";
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        IconButton {
            flat: true
            icon: "‹"
            color: Theme.dim
            onClicked: root.back()
        }

        Txt {
            Layout.fillWidth: true
            textFormat: Text.PlainText
            text: root.file?.path ?? ""
            font.bold: true
            elide: Text.ElideMiddle
        }

        Txt {
            variant: "dim"
            text: root.status
        }

        Pill {
            text: root.file?.staged && !root.file?.unstaged ? "Unstage" : "Stage"
            minWidth: 64
            onClicked: Dotfiles.toggleStage(root.file)
        }
    }

    ScrollList {
        id: list
        visible: Dotfiles.diffLines.length > 0
        maxHeight: 480
        spacing: 0
        model: Dotfiles.diffLines

        delegate: Rectangle {
            id: line
            required property string modelData

            readonly property string kind: modelData.startsWith("+") ? "add" : modelData.startsWith("-") ? "del" : modelData.startsWith("@@") ? "hunk" : "ctx"

            width: ListView.view.rowWidth
            height: lineText.implicitHeight + (kind === "hunk" ? 8 : 0)
            color: kind === "add" ? Theme.withAlpha(Theme.foam, 0.10) : kind === "del" ? Theme.withAlpha(Theme.love, 0.10) : "transparent"

            Txt {
                id: lineText
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 6
                    rightMargin: 6
                }
                textFormat: Text.PlainText
                text: line.modelData === "" ? " " : line.modelData
                wrapMode: Text.WrapAnywhere
                font.pixelSize: Theme.fontSize - 2
                color: line.kind === "add" ? Theme.foam : line.kind === "del" ? Theme.love : line.kind === "hunk" ? Theme.iris : Theme.subtle
            }
        }
    }

    EmptyState {
        visible: Dotfiles.diffLines.length === 0
        text: Dotfiles.diffLoading ? "Loading…" : "No changes against HEAD"
    }
}

import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// The dotfiles repo without leaving the shell: what changed, the diff of each file, staging,
// discarding, committing, pulling and pushing. Two views share the card: the file list, and one
// file's diff.
DropdownPanel {
    id: panel
    name: "dotfiles"
    edge: "right"
    cardWidth: 560

    ColumnLayout {
        id: menu
        spacing: 12

        property int sel: 0
        readonly property int count: Dotfiles.count
        readonly property int selIndex: Math.max(0, Math.min(sel, count - 1))
        readonly property var selFile: Dotfiles.files[selIndex] ?? null
        readonly property string selPath: selFile?.path ?? ""

        property bool diffOpen: false
        // the path waiting for a second `d` before its changes are thrown away
        property string armed: ""

        onSelIndexChanged: fileList.positionViewAtIndex(selIndex, ListView.Contain)
        onSelPathChanged: {
            armed = "";
            if (diffOpen)
                Dotfiles.loadDiff(selFile);
        }
        onCountChanged: if (count === 0 && diffOpen)
            closeDiff()

        function select(i) {
            sel = Math.max(0, Math.min(count - 1, i));
        }

        function openDiff() {
            if (!selFile)
                return;
            diffOpen = true;
            Dotfiles.loadDiff(selFile);
        }

        function closeDiff() {
            diffOpen = false;
            Dotfiles.loadDiff(null);
        }

        function discardSelected() {
            if (!selFile)
                return;
            if (armed === selPath) {
                armed = "";
                Dotfiles.discard(selFile);
            } else {
                armed = selPath;
            }
        }

        function submitCommit() {
            Dotfiles.commit(commitInput.text);
            menu.forceActiveFocus();
        }

        // what the status letters mean, for the diff header
        function stateOf(f) {
            if (!f)
                return "";
            if (f.untracked)
                return "untracked";
            if (f.staged && f.unstaged)
                return "partly staged";
            return f.staged ? "staged" : "not staged";
        }

        Keys.onPressed: event => {
            const shift = event.modifiers & Qt.ShiftModifier;
            const ctrl = event.modifiers & Qt.ControlModifier;
            if (event.key !== Qt.Key_D)
                armed = "";

            if (diffOpen) {
                switch (event.key) {
                case Qt.Key_J:
                case Qt.Key_Down:
                    if (shift)
                        select(selIndex + 1);
                    else
                        diffList.scrollBy(40);
                    break;
                case Qt.Key_K:
                case Qt.Key_Up:
                    if (shift)
                        select(selIndex - 1);
                    else
                        diffList.scrollBy(-40);
                    break;
                case Qt.Key_D:
                case Qt.Key_PageDown:
                    if (event.key === Qt.Key_D && !ctrl)
                        return;
                    diffList.scrollBy(diffList.height / 2);
                    break;
                case Qt.Key_U:
                case Qt.Key_PageUp:
                    if (event.key === Qt.Key_U && !ctrl)
                        return;
                    diffList.scrollBy(-diffList.height / 2);
                    break;
                case Qt.Key_G:
                    if (shift)
                        diffList.positionViewAtEnd();
                    else
                        diffList.positionViewAtBeginning();
                    break;
                case Qt.Key_Space:
                case Qt.Key_S:
                    Dotfiles.toggleStage(selFile);
                    break;
                case Qt.Key_R:
                    Dotfiles.refresh();
                    Dotfiles.loadDiff(selFile);
                    break;
                case Qt.Key_H:
                case Qt.Key_Left:
                case Qt.Key_Backspace:
                case Qt.Key_Escape:
                    closeDiff();
                    break;
                case Qt.Key_Q:
                    panel.close();
                    break;
                default:
                    return;
                }
            } else {
                switch (event.key) {
                case Qt.Key_J:
                case Qt.Key_Down:
                    select(selIndex + 1);
                    break;
                case Qt.Key_K:
                case Qt.Key_Up:
                    select(selIndex - 1);
                    break;
                case Qt.Key_G:
                    select(shift ? count - 1 : 0);
                    break;
                case Qt.Key_Space:
                case Qt.Key_S:
                    Dotfiles.toggleStage(selFile);
                    break;
                case Qt.Key_A:
                    Dotfiles.toggleStageAll();
                    break;
                case Qt.Key_Return:
                case Qt.Key_Enter:
                case Qt.Key_L:
                case Qt.Key_Right:
                    openDiff();
                    break;
                case Qt.Key_D:
                    discardSelected();
                    break;
                case Qt.Key_C:
                    commitInput.forceActiveFocus();
                    break;
                case Qt.Key_P:
                    if (shift)
                        Dotfiles.push();
                    else
                        Dotfiles.pull();
                    break;
                case Qt.Key_F:
                    Dotfiles.fetch();
                    break;
                case Qt.Key_R:
                    Dotfiles.refresh();
                    break;
                case Qt.Key_Q:
                    panel.close();
                    break;
                default:
                    return;
                }
            }
            event.accepted = true;
        }

        // ---------- header ----------
        PanelHeader {
            icon: Icons.git
            iconColor: Dotfiles.failed ? Theme.urgent : Dotfiles.count > 0 || Dotfiles.ahead > 0 ? Theme.accent : Theme.dim
            title: "Dotfiles"
            subtitleColor: Dotfiles.failed ? Theme.urgent : Theme.dim
            subtitle: {
                if (Dotfiles.failed)
                    return "Could not read the repository";
                const sync = Dotfiles.upstream === "" ? "no upstream" : Dotfiles.ahead || Dotfiles.behind ? `↑${Dotfiles.ahead} ↓${Dotfiles.behind}` : "up to date";
                const changes = Dotfiles.count === 0 ? "clean" : Dotfiles.count + (Dotfiles.count === 1 ? " change" : " changes");
                return [Dotfiles.branch, sync, changes].filter(s => s !== "").join(" · ");
            }

            Pill {
                text: Dotfiles.busy === "Pull" ? "Pulling…" : Dotfiles.behind > 0 ? "Pull ↓" + Dotfiles.behind : "Pull"
                active: Dotfiles.busy === "Pull"
                minWidth: 64
                onClicked: Dotfiles.pull()
            }

            Pill {
                text: Dotfiles.busy === "Push" ? "Pushing…" : Dotfiles.ahead > 0 ? "Push ↑" + Dotfiles.ahead : "Push"
                primary: Dotfiles.ahead > 0 || Dotfiles.busy === "Push"
                minWidth: 64
                onClicked: Dotfiles.push()
            }
        }

        Divider {}

        // ---------- the file list ----------
        ScrollList {
            id: fileList
            visible: !menu.diffOpen && Dotfiles.count > 0
            maxHeight: 360
            // keyed by path, so a refresh only touches the rows that changed
            model: ScriptModel {
                values: Dotfiles.files.map(f => f.path)
            }

            delegate: ListRow {
                id: row
                required property string modelData
                required property int index

                readonly property var file: Dotfiles.files[index] ?? null
                readonly property bool armed: menu.armed !== "" && menu.armed === modelData

                selected: index === menu.selIndex

                // staged box: full when all of the file is staged, half when part of it is
                Rectangle {
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    radius: 3
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
                        onClicked: {
                            menu.select(row.index);
                            Dotfiles.toggleStage(row.file);
                        }
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

                    // click the name: its diff
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            menu.select(row.index);
                            menu.openDiff();
                        }
                    }
                }
            }
        }

        Txt {
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            visible: !menu.diffOpen && Dotfiles.count === 0
            horizontalAlignment: Text.AlignHCenter
            variant: "dim"
            text: Dotfiles.failed ? "Check the repository path in Config.qml" : Dotfiles.ahead > 0 ? "Nothing to commit, " + Dotfiles.ahead + (Dotfiles.ahead === 1 ? " commit" : " commits") + " to push" : "Nothing to commit"
        }

        // ---------- one file's diff ----------
        RowLayout {
            visible: menu.diffOpen
            Layout.fillWidth: true
            spacing: 10

            Txt {
                text: "‹"
                font.pixelSize: Theme.fontSize + 4
                color: Theme.dim

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: menu.closeDiff()
                }
            }

            Txt {
                Layout.fillWidth: true
                textFormat: Text.PlainText
                text: menu.selPath
                font.bold: true
                elide: Text.ElideMiddle
            }

            Txt {
                variant: "dim"
                text: menu.stateOf(menu.selFile)
            }

            Pill {
                text: menu.selFile?.staged && !menu.selFile?.unstaged ? "Unstage" : "Stage"
                minWidth: 64
                onClicked: Dotfiles.toggleStage(menu.selFile)
            }
        }

        ScrollList {
            id: diffList
            visible: menu.diffOpen && Dotfiles.diffLines.length > 0
            maxHeight: 480
            spacing: 0
            model: Dotfiles.diffLines

            delegate: Rectangle {
                id: line
                required property string modelData

                readonly property string kind: modelData.startsWith("+") ? "add" : modelData.startsWith("-") ? "del" : modelData.startsWith("@@") ? "hunk" : "ctx"

                width: ListView.view.width
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

        Txt {
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            visible: menu.diffOpen && Dotfiles.diffLines.length === 0
            horizontalAlignment: Text.AlignHCenter
            variant: "dim"
            text: Dotfiles.diffLoading ? "Loading…" : "No changes against HEAD"
        }

        // ---------- commit ----------
        RowLayout {
            visible: !menu.diffOpen
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 30
                radius: Theme.radius
                color: Theme.surface
                border.width: commitInput.activeFocus ? 1 : 0
                border.color: Theme.border

                TextInput {
                    id: commitInput
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    clip: true
                    selectByMouse: true

                    // the draft lives in the service, so closing the panel doesn't lose it
                    text: Dotfiles.draft
                    onTextChanged: Dotfiles.draft = text

                    Keys.onReturnPressed: menu.submitCommit()
                    Keys.onEnterPressed: menu.submitCommit()
                    Keys.onEscapePressed: event => {
                        menu.forceActiveFocus();
                        event.accepted = true;
                    }

                    Txt {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: commitInput.text.length === 0
                        enabled: false
                        variant: "dim"
                        text: Dotfiles.stagedCount > 0 ? `Commit message · ${Dotfiles.stagedCount} staged` : "Commit message · everything"
                    }
                }
            }

            Pill {
                text: Dotfiles.busy === "Commit" ? "Committing…" : "Commit"
                primary: true
                minWidth: 64
                onClicked: menu.submitCommit()
            }
        }

        // what the last action said
        Txt {
            Layout.fillWidth: true
            visible: text !== ""
            variant: "small"
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            text: Dotfiles.busy !== "" ? Dotfiles.busy + "…" : Dotfiles.message
            color: Dotfiles.busy === "" && Dotfiles.messageError ? Theme.urgent : Theme.dim
        }

        Hint {
            text: menu.diffOpen ? "j k scroll • J K next / prev file • Space stage • h back • q close" : commitInput.activeFocus ? "Enter commit • Esc back to the list" : "j k select • Space stage • a all • Enter diff • d discard • c commit • p pull • P push • Esc close"
        }
    }
}

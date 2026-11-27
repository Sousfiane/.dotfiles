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

        Selection {
            id: nav
            count: Dotfiles.count
            view: fileList
        }
        readonly property int count: Dotfiles.count
        readonly property var selFile: Dotfiles.files[nav.index] ?? null
        readonly property string selPath: selFile?.path ?? ""

        property bool diffOpen: false
        // the path waiting for a second `d` before its changes are thrown away
        property string armed: ""

        onSelPathChanged: {
            armed = "";
            if (diffOpen)
                Dotfiles.loadDiff(selFile);
        }
        onCountChanged: if (count === 0 && diffOpen)
            closeDiff()

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
                        nav.move(1);
                    else
                        diff.scrollBy(40);
                    break;
                case Qt.Key_K:
                case Qt.Key_Up:
                    if (shift)
                        nav.move(-1);
                    else
                        diff.scrollBy(-40);
                    break;
                case Qt.Key_D:
                case Qt.Key_PageDown:
                    if (event.key === Qt.Key_D && !ctrl)
                        return;
                    diff.scrollPage(1);
                    break;
                case Qt.Key_U:
                case Qt.Key_PageUp:
                    if (event.key === Qt.Key_U && !ctrl)
                        return;
                    diff.scrollPage(-1);
                    break;
                case Qt.Key_G:
                    if (shift)
                        diff.toEnd();
                    else
                        diff.toStart();
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
                if (nav.navigate(event))
                    return;
                switch (event.key) {
                case Qt.Key_G:
                    nav.select(shift ? count - 1 : 0);
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
                    if (Dotfiles.stagedCount > 0)
                        commitInput.forceActiveFocus();
                    break;
                case Qt.Key_P:
                    if (shift)
                        Dotfiles.push();
                    else
                        Dotfiles.pull();
                    break;
                case Qt.Key_F:
                    Dotfiles.fetch(false);
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
                const changes = Dotfiles.count === 0 ? "clean" : Fmt.plural(Dotfiles.count, "change");
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

            delegate: DotfilesRow {
                armed: menu.armed !== "" && menu.armed === modelData
                selected: index === nav.index
                onStageClicked: {
                    nav.select(index);
                    Dotfiles.toggleStage(file);
                }
                onNameClicked: {
                    nav.select(index);
                    menu.openDiff();
                }
            }
        }

        EmptyState {
            visible: !menu.diffOpen && Dotfiles.count === 0
            text: Dotfiles.failed ? "Check the repository path in Config.qml" : Dotfiles.ahead > 0 ? "Nothing to commit, " + Fmt.plural(Dotfiles.ahead, "commit") + " to push" : "Nothing to commit"
        }

        // ---------- one file's diff ----------
        DotfilesDiff {
            id: diff
            visible: menu.diffOpen
            Layout.fillWidth: true
            file: menu.selFile
            onBack: menu.closeDiff()
        }

        // ---------- commit, once something is staged ----------
        RowLayout {
            visible: !menu.diffOpen && Dotfiles.stagedCount > 0
            Layout.fillWidth: true
            spacing: 8

            // unstaging the last file while typing: give the keys back to the list
            onVisibleChanged: if (!visible && commitInput.activeFocus)
                menu.forceActiveFocus()

            InputField {
                id: commitInput
                borderWidth: activeFocus ? 1 : 0
                placeholder: `Commit message · ${Dotfiles.stagedCount} staged`

                // the draft lives in the service, so closing the panel doesn't lose it
                text: Dotfiles.draft
                onTextChanged: Dotfiles.draft = text

                onAccepted: menu.submitCommit()
                onCancelled: menu.forceActiveFocus()
            }

            Pill {
                text: Dotfiles.busy === "Commit" ? "Committing…" : "Commit"
                primary: true
                minWidth: 64
                onClicked: menu.submitCommit()
            }
        }

        // ---------- SSH passphrase, when a pull or push needs it ----------
        DotfilesPass {
            id: pass
            Layout.fillWidth: true
            onFinished: menu.forceActiveFocus()
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
            text: menu.diffOpen ? "j k scroll • J K next / prev file • Space stage • h back • q close" : pass.typing ? "Enter send • Esc cancel" : commitInput.activeFocus ? "Enter commit • Esc back to the list" : "j k select • Space stage • a all • Enter diff • d discard • " + (Dotfiles.stagedCount > 0 ? "c commit • " : "") + "p pull • P push • Esc close"
        }
    }
}

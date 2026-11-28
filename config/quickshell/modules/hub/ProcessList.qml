import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// The hub's System tab's process list (HubSystem.qml): every process, busiest first (services/Processes.qml),
// scrolling, each one can be ended. The rows hold still under the pointer.
//
// Keys (HubPanel passes them on through HubSystem): j k / arrows, PgUp PgDn, Home End select a process,
// x or Delete asks it to quit (TERM), Shift + X or Shift + Delete kills it (KILL), Esc unselects. The pointer
// on a row shows its ×, the same as x.
Rectangle {
    id: procBox

    // the selected process, by pid: it stays selected while the list reorders under it
    property int selectedPid: -1

    function selectedIndex() {
        for (let i = 0; i < Processes.processes.count; i++)
            if (Processes.processes.get(i).pid === selectedPid)
                return i;
        return -1;
    }

    function handleKey(event) {
        const n = Processes.processes.count;
        if (n === 0)
            return false;
        const d = event.key === Qt.Key_J || event.key === Qt.Key_Down ? 1 : event.key === Qt.Key_K || event.key === Qt.Key_Up ? -1 : event.key === Qt.Key_PageDown ? procs.pageRows : event.key === Qt.Key_PageUp ? -procs.pageRows : 0;
        if (d !== 0) {
            const at = selectedIndex();
            const i = at < 0 ? (d > 0 ? 0 : n - 1) : Math.max(0, Math.min(n - 1, at + d));
            selectedPid = Processes.processes.get(i).pid;
            procs.positionViewAtIndex(i, ListView.Contain);
            return true;
        }
        if (event.key === Qt.Key_Home || event.key === Qt.Key_End) {
            const i = event.key === Qt.Key_Home ? 0 : n - 1;
            selectedPid = Processes.processes.get(i).pid;
            procs.positionViewAtIndex(i, ListView.Contain);
            return true;
        }
        if (event.key === Qt.Key_X || event.key === Qt.Key_Delete) {
            const i = selectedIndex();
            if (i < 0)
                return false;
            const p = Processes.processes.get(i);
            Processes.kill(p.pid, p.name, (event.modifiers & Qt.ShiftModifier) !== 0);
            return true;
        }
        if (event.key === Qt.Key_Escape && selectedPid >= 0) {
            selectedPid = -1;
            return true;
        }
        return false;
    }

    Component.onCompleted: Processes.use()
    Component.onDestruction: Processes.release()

    readonly property int rowHeight: 22

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: 20 + 26 + 3 * rowHeight
    radius: Theme.radius
    color: Theme.surfaceClear
    border.width: 1
    border.color: Theme.border

    // the columns, shared by the header and the rows
    component Cols: RowLayout {
        property string name
        property string user
        property string pid
        property string cpu
        property string mem
        property bool header: false
        property real cpuFraction: 0

        spacing: 10

        Txt {
            Layout.fillWidth: true
            variant: parent.header ? "small" : "row"
            font.bold: parent.header
            color: parent.header ? Theme.accent : Theme.fg
            text: parent.name
            elide: Text.ElideRight
        }

        Txt {
            Layout.preferredWidth: 76
            variant: "small"
            font.bold: parent.header
            color: parent.header ? Theme.accent : Theme.dim
            text: parent.user
            elide: Text.ElideRight
        }

        Txt {
            Layout.preferredWidth: 56
            horizontalAlignment: Text.AlignRight
            variant: "small"
            font.bold: parent.header
            color: parent.header ? Theme.accent : Theme.dim
            text: parent.pid
        }

        Item {
            Layout.preferredWidth: 72
            Layout.preferredHeight: 4

            Meter {
                anchors.fill: parent
                visible: !parent.parent.header
                fraction: parent.parent.cpuFraction
            }
        }

        Txt {
            Layout.preferredWidth: 48
            horizontalAlignment: Text.AlignRight
            variant: "small"
            font.bold: parent.header
            color: parent.header ? Theme.accent : Theme.fg
            text: parent.cpu
        }

        Txt {
            Layout.preferredWidth: 60
            horizontalAlignment: Text.AlignRight
            variant: "small"
            font.bold: parent.header
            color: parent.header ? Theme.accent : Theme.fg
            text: parent.mem
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: 10
        }
        spacing: 0

        // the header, or for a moment what ending a process did
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 26

            Cols {
                anchors {
                    left: parent.left
                    right: parent.right
                    leftMargin: 4
                    rightMargin: 4 + 14 + 8 + (procs.contentHeight > procs.height ? 10 : 0)
                    verticalCenter: parent.verticalCenter
                }
                visible: Processes.killMessage === ""
                header: true
                name: "Process  ·  " + Processes.processes.count
                user: "User"
                pid: "PID"
                cpu: "CPU"
                mem: "Memory"
            }

            Txt {
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                visible: Processes.killMessage !== ""
                variant: "small"
                font.bold: true
                color: Processes.killFailed ? Theme.urgent : Theme.accent
                text: Processes.killMessage
                elide: Text.ElideRight
            }
        }

        ListView {
            id: procs

            readonly property int pageRows: Math.max(1, Math.floor(height / procBox.rowHeight) - 1)
            readonly property real rowWidth: width - (contentHeight > height ? 10 : 0)

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: Processes.processes
            boundsBehavior: Flickable.StopAtBounds
            reuseItems: true
            cacheBuffer: 4 * procBox.rowHeight
            ScrollBar.vertical: Scroller {}

            // the rows hold still under the pointer (see Processes.held)
            HoverHandler {
                id: listHover
                onHoveredChanged: Processes.held = hovered
            }

            delegate: Rectangle {
                id: row

                required property int index
                required property int pid
                required property string name
                required property string user
                required property real cpu
                required property real rss

                readonly property bool selected: pid === procBox.selectedPid

                width: procs.rowWidth
                height: procBox.rowHeight
                radius: Theme.radius / 2
                color: selected ? Theme.surface : rowMouse.containsMouse ? Theme.withAlpha(Theme.fg, 0.05) : "transparent"

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    onClicked: procBox.selectedPid = row.selected ? -1 : row.pid
                }

                Cols {
                    anchors {
                        left: parent.left
                        right: killButton.left
                        leftMargin: 4
                        rightMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    name: row.name
                    user: row.user
                    pid: row.pid
                    cpuFraction: row.cpu
                    cpu: (row.cpu * 100).toFixed(1) + "%"
                    mem: SysMon.bytes(row.rss)
                }

                // TERM: asks it to quit
                IconButton {
                    id: killButton
                    anchors {
                        right: parent.right
                        rightMargin: 4
                        verticalCenter: parent.verticalCenter
                    }
                    width: 14
                    flat: true
                    icon: "×"
                    color: Theme.dim
                    hoverColor: Theme.urgent
                    opacity: rowMouse.containsMouse || hovered || row.selected ? 1 : 0
                    onClicked: Processes.kill(row.pid, row.name, false)
                }
            }
        }
    }

    Txt {
        anchors.centerIn: parent
        visible: !Processes.read
        variant: "dim"
        text: "Reading…"
    }
}

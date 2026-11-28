import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// The hub's System tab, btop-like: an even grid of CPU (graph, each core, temperature, clock, load), memory
// (graph, used, cache, swap), GPU (graph, VRAM, power) and network (down and up graph) with the disks, then
// every process, busiest first, scrolling, each one can be ended. Created only while the tab shows, and
// SysMon reads all this only while it exists.
//
// Keys (HubPanel passes them on): j k / arrows select a process, x or Delete asks it to quit (TERM),
// Shift + X or Shift + Delete kills it (KILL). The pointer on a row shows its ×, the same as x.
ColumnLayout {
    id: root
    spacing: 10

    Component.onCompleted: SysMon.useDetail()
    Component.onDestruction: {
        SysMon.procsHeld = false;
        SysMon.releaseDetail();
    }

    // the selected process, by pid: it stays selected while the list reorders under it
    property int selectedPid: -1

    function selectedIndex() {
        for (let i = 0; i < SysMon.processes.count; i++)
            if (SysMon.processes.get(i).pid === selectedPid)
                return i;
        return -1;
    }

    function handleKey(event) {
        const n = SysMon.processes.count;
        if (n === 0)
            return false;
        const d = event.key === Qt.Key_J || event.key === Qt.Key_Down ? 1 : event.key === Qt.Key_K || event.key === Qt.Key_Up ? -1 : event.key === Qt.Key_PageDown ? procs.pageRows : event.key === Qt.Key_PageUp ? -procs.pageRows : 0;
        if (d !== 0) {
            const at = selectedIndex();
            const i = at < 0 ? (d > 0 ? 0 : n - 1) : Math.max(0, Math.min(n - 1, at + d));
            selectedPid = SysMon.processes.get(i).pid;
            procs.positionViewAtIndex(i, ListView.Contain);
            return true;
        }
        if (event.key === Qt.Key_Home || event.key === Qt.Key_End) {
            const i = event.key === Qt.Key_Home ? 0 : n - 1;
            selectedPid = SysMon.processes.get(i).pid;
            procs.positionViewAtIndex(i, ListView.Contain);
            return true;
        }
        if (event.key === Qt.Key_X || event.key === Qt.Key_Delete) {
            const i = selectedIndex();
            if (i < 0)
                return false;
            const p = SysMon.processes.get(i);
            SysMon.kill(p.pid, p.name, (event.modifiers & Qt.ShiftModifier) !== 0);
            return true;
        }
        if (event.key === Qt.Key_Escape && selectedPid >= 0) {
            selectedPid = -1;
            return true;
        }
        return false;
    }

    // a box with a title, a figure next to it and details on the right, then its content. Its graph takes
    // the room left, so every box in the grid is the same size with its bars at the bottom
    component Box: Rectangle {
        id: box

        property string title
        property string value: ""
        property string detail: ""
        default property alias content: inner.data

        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitHeight: inner.implicitHeight + 20
        radius: Theme.radius
        color: Theme.surfaceClear
        border.width: 1
        border.color: Theme.border

        ColumnLayout {
            id: inner
            anchors {
                fill: parent
                margins: 10
            }
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Txt {
                    font.bold: true
                    text: box.title
                    color: Theme.accent
                }

                Txt {
                    font.bold: true
                    text: box.value
                }

                Item {
                    Layout.fillWidth: true
                }

                Txt {
                    variant: "small"
                    text: box.detail
                }
            }
        }
    }

    // a named bar with its figure: "Swap ▬▬▬▬▬ 0.0 / 8.0 GB"
    component BarRow: RowLayout {
        property string name
        property string text: ""
        property real fraction: 0

        Layout.fillWidth: true
        spacing: 8

        Txt {
            Layout.preferredWidth: 64
            variant: "small"
            text: parent.name
            elide: Text.ElideMiddle
        }

        Meter {
            Layout.fillWidth: true
            fraction: parent.fraction
        }

        Txt {
            Layout.preferredWidth: 104
            horizontalAlignment: Text.AlignRight
            variant: "small"
            text: parent.text
        }
    }

    // ---------- CPU, memory, GPU, network: two by two, every cell the same size ----------
    // (without a GPU: CPU, memory, network, disks)
    GridLayout {
        Layout.fillWidth: true
        Layout.fillHeight: false             // its own height: the processes take the rest
        columns: 2
        columnSpacing: 10
        rowSpacing: 10
        uniformCellWidths: true
        uniformCellHeights: true

        Box {
            title: "CPU"
            value: SysMon.pct(SysMon.cpu)
            detail: [SysMon.deg(SysMon.cpuTemp), SysMon.cpuGhz > 0 ? SysMon.cpuGhz.toFixed(1) + " GHz" : "", SysMon.load ? "load " + SysMon.load : ""].filter(s => s).join("  ·  ")

            Graph {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 40
                values: SysMon.cpuHistory
            }

            // each core (thread), in columns of four
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 10
                rowSpacing: 4
                uniformCellWidths: true

                Repeater {
                    model: SysMon.cores

                    delegate: RowLayout {
                        required property real modelData
                        required property int index

                        Layout.fillWidth: true
                        spacing: 4

                        Txt {
                            Layout.preferredWidth: 14
                            variant: "small"
                            text: index
                        }

                        Meter {
                            Layout.fillWidth: true
                            fraction: modelData
                        }
                    }
                }
            }
        }

        Box {
            title: "Memory"
            value: SysMon.memUsed < 0 ? "…" : SysMon.gib(SysMon.memUsed)
            detail: "of " + SysMon.gib(SysMon.memTotal)

            Graph {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 40
                values: SysMon.memHistory
                color: Theme.foam
            }

            BarRow {
                name: "Used"
                fraction: SysMon.memTotal > 0 ? SysMon.memUsed / SysMon.memTotal : 0
                text: SysMon.gib(Math.max(0, SysMon.memUsed))
            }

            BarRow {
                name: "Cache"
                fraction: SysMon.memTotal > 0 ? SysMon.memCached / SysMon.memTotal : 0
                text: SysMon.gib(SysMon.memCached)
            }

            BarRow {
                visible: SysMon.swapTotal > 0
                name: "Swap"
                fraction: SysMon.swapTotal > 0 ? SysMon.swapUsed / SysMon.swapTotal : 0
                text: SysMon.swapUsed.toFixed(1) + " / " + SysMon.gib(SysMon.swapTotal)
            }
        }

        Box {
            visible: SysMon.hasGpu
            title: "GPU"
            value: SysMon.pct(SysMon.gpu)
            detail: [SysMon.deg(SysMon.gpuTemp), SysMon.gpuWatts >= 0 ? Math.round(SysMon.gpuWatts) + " W" : ""].filter(s => s).join("  ·  ")

            Graph {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 40
                values: SysMon.gpuHistory
                color: Theme.gold
            }

            BarRow {
                name: "VRAM"
                fraction: SysMon.vramTotal > 0 ? SysMon.vramUsed / SysMon.vramTotal : 0
                text: SysMon.vramUsed.toFixed(1) + " / " + SysMon.gib(SysMon.vramTotal)
            }
        }

        Box {
            title: "Network"
            detail: "↓ " + SysMon.bytes(SysMon.down, true) + "   ↑ " + SysMon.bytes(SysMon.up, true)

            // down filled, up as a line, on the same scale (the busiest moment shown)
            Graph {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 40
                values: SysMon.downHistory
                values2: SysMon.upHistory
                max: 0
                color: Theme.iris
                color2: Theme.rose
            }

            Repeater {
                model: SysMon.hasGpu ? SysMon.disks : []

                delegate: BarRow {
                    required property var modelData
                    name: modelData.mount
                    fraction: modelData.used / modelData.size
                    text: SysMon.bytes(modelData.used) + " / " + SysMon.bytes(modelData.size)
                }
            }
        }

        // the GPU's cell, when there is none
        Box {
            visible: !SysMon.hasGpu
            title: "Disks"

            Item {
                Layout.fillHeight: true
            }

            Repeater {
                model: SysMon.hasGpu ? [] : SysMon.disks

                delegate: BarRow {
                    required property var modelData
                    name: modelData.mount
                    fraction: modelData.used / modelData.size
                    text: SysMon.bytes(modelData.used) + " / " + SysMon.bytes(modelData.size)
                }
            }
        }
    }

    // ---------- every process, busiest first ----------
    Rectangle {
        id: procBox

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
                    visible: SysMon.killMessage === ""
                    header: true
                    name: "Process  ·  " + SysMon.processes.count
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
                    visible: SysMon.killMessage !== ""
                    variant: "small"
                    font.bold: true
                    color: SysMon.killFailed ? Theme.urgent : Theme.accent
                    text: SysMon.killMessage
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
                model: SysMon.processes
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: true
                cacheBuffer: 4 * procBox.rowHeight
                ScrollBar.vertical: Scroller {}

                // the rows hold still under the pointer (see SysMon.procsHeld)
                HoverHandler {
                    id: listHover
                    onHoveredChanged: SysMon.procsHeld = hovered
                }

                delegate: Rectangle {
                    id: row

                    required property int index
                    required property int pid
                    required property string name
                    required property string user
                    required property real cpu
                    required property real rss

                    readonly property bool selected: pid === root.selectedPid

                    width: procs.rowWidth
                    height: procBox.rowHeight
                    radius: Theme.radius / 2
                    color: selected ? Theme.surface : rowMouse.containsMouse ? Theme.withAlpha(Theme.fg, 0.05) : "transparent"

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        onClicked: root.selectedPid = row.selected ? -1 : row.pid
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
                        onClicked: SysMon.kill(row.pid, row.name, false)
                    }
                }
            }
        }

        Txt {
            anchors.centerIn: parent
            visible: !SysMon.procsRead
            variant: "dim"
            text: "Reading…"
        }
    }
}

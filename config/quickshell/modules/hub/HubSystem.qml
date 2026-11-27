import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// The hub's System tab, btop-like: CPU (graph, each core, temperature, clock, load), memory (graph, used,
// cache, swap), GPU (graph, VRAM, power), network (down and up graph) with the disks, and the processes
// using the most CPU. Created only while the tab shows, and SysMon reads all this only while it exists.
ColumnLayout {
    id: root
    spacing: 10

    Component.onCompleted: SysMon.useDetail()
    Component.onDestruction: SysMon.releaseDetail()

    // a box with a title, a figure next to it and details on the right, then its content
    component Box: Rectangle {
        id: box

        property string title
        property string value: ""
        property string detail: ""
        default property alias content: inner.data

        Layout.fillWidth: true
        Layout.preferredWidth: 1
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

    // ---------- CPU and memory ----------
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Box {
            Layout.alignment: Qt.AlignTop
            title: "CPU"
            value: SysMon.pct(SysMon.cpu)
            detail: [SysMon.deg(SysMon.cpuTemp), SysMon.cpuGhz > 0 ? SysMon.cpuGhz.toFixed(1) + " GHz" : "", SysMon.load ? "load " + SysMon.load : ""].filter(s => s).join("  ·  ")

            Graph {
                Layout.fillWidth: true
                values: SysMon.cpuHistory
            }

            // each core (thread), in columns of four
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 10
                rowSpacing: 4

                Repeater {
                    model: SysMon.cores

                    delegate: RowLayout {
                        required property real modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
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
            Layout.alignment: Qt.AlignTop
            title: "Memory"
            value: SysMon.memUsed < 0 ? "…" : SysMon.gib(SysMon.memUsed)
            detail: "of " + SysMon.gib(SysMon.memTotal)

            Graph {
                Layout.fillWidth: true
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
    }

    // ---------- GPU, network and disks ----------
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Box {
            Layout.alignment: Qt.AlignTop
            visible: SysMon.hasGpu
            title: "GPU"
            value: SysMon.pct(SysMon.gpu)
            detail: [SysMon.deg(SysMon.gpuTemp), SysMon.gpuWatts >= 0 ? Math.round(SysMon.gpuWatts) + " W" : ""].filter(s => s).join("  ·  ")

            Graph {
                Layout.fillWidth: true
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
            Layout.alignment: Qt.AlignTop
            title: "Network"
            detail: "↓ " + SysMon.bytes(SysMon.down, true) + "   ↑ " + SysMon.bytes(SysMon.up, true)

            // down filled, up as a line, on the same scale (the busiest moment shown)
            Graph {
                Layout.fillWidth: true
                values: SysMon.downHistory
                values2: SysMon.upHistory
                max: 0
                color: Theme.iris
                color2: Theme.rose
            }

            Repeater {
                model: SysMon.disks

                delegate: BarRow {
                    required property var modelData
                    name: modelData.mount
                    fraction: modelData.used / modelData.size
                    text: SysMon.bytes(modelData.used) + " / " + SysMon.bytes(modelData.size)
                }
            }
        }
    }

    // ---------- processes: as many as fit ----------
    Rectangle {
        id: procBox

        readonly property int rowHeight: 20
        readonly property int fits: Math.max(0, Math.floor((height - 20 - 26) / rowHeight))

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 20 + 26 + 3 * rowHeight
        radius: Theme.radius
        color: Theme.surfaceClear
        border.width: 1
        border.color: Theme.border
        clip: true

        ColumnLayout {
            anchors {
                fill: parent
                margins: 10
            }
            spacing: 0

            component Cols: RowLayout {
                property string name
                property string pid
                property string cpu
                property string mem
                property bool header: false
                property real cpuFraction: 0

                Layout.fillWidth: true
                Layout.preferredHeight: procBox.rowHeight
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
                    Layout.preferredWidth: 64
                    horizontalAlignment: Text.AlignRight
                    variant: "small"
                    font.bold: parent.header
                    color: parent.header ? Theme.accent : Theme.dim
                    text: parent.pid
                }

                Meter {
                    Layout.preferredWidth: 80
                    visible: !parent.header
                    fraction: parent.cpuFraction
                }

                Item {
                    Layout.preferredWidth: 80
                    visible: parent.header
                }

                Txt {
                    Layout.preferredWidth: 52
                    horizontalAlignment: Text.AlignRight
                    variant: "small"
                    font.bold: parent.header
                    color: parent.header ? Theme.accent : Theme.fg
                    text: parent.cpu
                }

                Txt {
                    Layout.preferredWidth: 52
                    horizontalAlignment: Text.AlignRight
                    variant: "small"
                    font.bold: parent.header
                    color: parent.header ? Theme.accent : Theme.fg
                    text: parent.mem
                }
            }

            Cols {
                Layout.preferredHeight: 26
                header: true
                name: "Process"
                pid: "PID"
                cpu: "CPU"
                mem: "MEM"
            }

            Repeater {
                model: SysMon.processes.slice(0, procBox.fits)

                delegate: Cols {
                    required property var modelData
                    name: modelData.name
                    pid: modelData.pid
                    cpuFraction: modelData.cpu
                    cpu: (modelData.cpu * 100).toFixed(1) + "%"
                    mem: (modelData.mem * 100).toFixed(1) + "%"
                }
            }

            Txt {
                visible: SysMon.processes.length === 0
                variant: "dim"
                text: "Reading…"
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}

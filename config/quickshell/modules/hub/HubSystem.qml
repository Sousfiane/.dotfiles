import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// The hub's System tab, btop-like: an even grid of CPU (graph, each core, temperature, clock, load), memory
// (graph, used, cache, swap), GPU (graph, VRAM, power) and network (down and up graph) with the disks, then
// every process (ProcessList.qml), busiest first, scrolling, each one can be ended. Created only while the
// tab shows, and SysMon and Processes read all this only while it exists.
ColumnLayout {
    id: root
    spacing: 10

    Component.onCompleted: SysMon.useDetail()
    Component.onDestruction: SysMon.releaseDetail()

    // the process list takes the keys (HubPanel passes them on)
    function handleKey(event) {
        return processList.handleKey(event);
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
    ProcessList {
        id: processList
    }
}

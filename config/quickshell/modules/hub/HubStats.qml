import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// The hub's Home row: CPU, RAM and GPU, each with a bar, and the CPU and GPU temperatures (SysMon reads
// them only while this is on screen).
RowLayout {
    id: root

    property bool active: true          // false while another tab of the hub is showing

    spacing: 6

    onActiveChanged: active ? SysMon.use() : SysMon.release()
    Component.onCompleted: if (active)
        SysMon.use()
    Component.onDestruction: if (active)
        SysMon.release()

    StatCell {
        label: "CPU"
        value: SysMon.pct(SysMon.cpu)
        detail: SysMon.deg(SysMon.cpuTemp)
        fraction: SysMon.cpu
    }

    StatCell {
        label: "RAM"
        value: SysMon.memUsed < 0 ? "…" : SysMon.gib(SysMon.memUsed)
        detail: SysMon.memTotal > 0 ? "/ " + Math.round(SysMon.memTotal) : ""
        fraction: SysMon.memTotal > 0 ? SysMon.memUsed / SysMon.memTotal : -1
    }

    StatCell {
        visible: SysMon.hasGpu
        label: "GPU"
        value: SysMon.pct(SysMon.gpu)
        detail: SysMon.deg(SysMon.gpuTemp)
        fraction: SysMon.gpu
    }
}

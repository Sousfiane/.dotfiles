import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.ui

// The hub's About tab, neofetch-like and just for fun: the Arch logo in the accent colour, the machine and
// the desktop in a list, and the palette's colours. Read once each time the tab is opened.
Item {
    id: root

    property string title: ""
    property var rows: []           // [[key, value], ...]

    Process {
        running: true
        command: ["bash", "-c", `
os=$(. /etc/os-release; echo "$PRETTY_NAME")
gpu=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
[ -n "$gpu" ] || gpu=$(lspci 2>/dev/null | grep -m1 -E 'VGA|3D' | cut -d: -f3- | sed 's/^ //')
flat=$(command -v flatpak >/dev/null && flatpak list --app 2>/dev/null | wc -l)
printf 'Title\\t%s@%s\\n' "$USER" "$(cat /etc/hostname 2>/dev/null || uname -n)"
printf 'OS\\t%s %s\\n' "$os" "$(uname -m)"
printf 'Host\\t%s\\n' "$(cat /sys/devices/virtual/dmi/id/board_name 2>/dev/null)"
printf 'Kernel\\t%s\\n' "$(uname -r)"
printf 'Uptime\\t%s\\n' "$(uptime -p | sed 's/^up //')"
printf 'Packages\\t%s (pacman)%s\\n' "$(pacman -Qq | wc -l)" "\${flat:+, $flat (flatpak)}"
printf 'Shell\\t%s %s\\n' "$(basename "$SHELL")" "$("$SHELL" --version 2>/dev/null | grep -oE '[0-9]+(\\.[0-9]+)+' | head -1)"
printf 'WM\\t%s\\n' "$(hyprctl version 2>/dev/null | head -1 | awk '{print $1" "$2}')"
printf 'Shell UI\\tQuickshell %s\\n' "$(qs --version 2>/dev/null | head -1 | awk '{print $2}')"
printf 'Terminal\\t%s\\n' "$(kitty --version 2>/dev/null | awk '{print $1" "$2}')"
printf 'CPU\\t%s (%s)\\n' "$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ //; s/ [0-9]*-Core Processor//; s/(R)\\|(TM)//g')" "$(nproc)"
printf 'GPU\\t%s\\n' "$gpu"
printf 'Memory\\t%s\\n' "$(free -b | awk '/^Mem:/{printf "%.1f / %.1f GB", ($2-$7)/1073741824, $2/1073741824}')"
printf 'Disk (/)\\t%s\\n' "$(df -h --output=used,size / | tail -1 | awk '{print $1" / "$2}')"
printf 'Monitors\\t%s\\n' "$(hyprctl monitors -j 2>/dev/null | jq -r '[.[] | "\\(.width)x\\(.height) @ \\(.refreshRate | round) Hz"] | join(", ")')"
`]
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = [];
                for (const line of text.split("\n")) {
                    const [key, ...rest] = line.split("\t");
                    const value = rest.join("\t").trim();
                    if (key === "Title")
                        root.title = value;
                    else if (key && value)
                        rows.push([key, value]);
                }
                rows.push(["Theme", Theme.paletteName]);
                rows.push(["Icons", Theme.theme.icons]);
                rows.push(["Font", Theme.fonts.ui + (Theme.fonts.mono && Theme.fonts.mono !== Theme.fonts.ui ? ", " + Theme.fonts.mono : "")]);
                root.rows = rows;
            }
        }
    }

    RowLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width, implicitWidth)
        spacing: 36

        // ---------- the logo ----------
        Txt {
            Layout.alignment: Qt.AlignVCenter
            color: Theme.accent
            font.family: Theme.fonts.mono
            font.pixelSize: Theme.fontSize + 8
            font.bold: true
            lineHeight: 0.95
            text: ["       /\\", "      /  \\", "     /\\   \\", "    /      \\", "   /   ,,   \\", "  /   |  |  -\\", " /_-''    ''-_\\"].join("\n")
        }

        // ---------- the list ----------
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 3

            Txt {
                variant: "heading"
                color: Theme.accent
                font.family: Theme.fonts.mono
                text: root.title || " "
            }

            Txt {
                color: Theme.dim
                font.family: Theme.fonts.mono
                text: "─".repeat(Math.max(8, root.title.length))
            }

            Repeater {
                model: root.rows

                delegate: RowLayout {
                    required property var modelData
                    spacing: 0

                    Txt {
                        Layout.preferredWidth: 92
                        font.family: Theme.fonts.mono
                        font.bold: true
                        color: Theme.accent
                        text: modelData[0]
                    }

                    Txt {
                        Layout.maximumWidth: 380
                        font.family: Theme.fonts.mono
                        text: modelData[1]
                        elide: Text.ElideRight
                    }
                }
            }

            // ---------- the palette ----------
            Grid {
                Layout.topMargin: 10
                columns: 8
                spacing: 4

                Repeater {
                    // the 15 colours: the greys from dark to light, then the accents
                    model: ["base", "surface", "overlay", "highlightLow", "highlightMed", "highlightHigh", "muted", "subtle", "text", "love", "gold", "rose", "pine", "foam", "iris"]

                    delegate: Rectangle {
                        required property string modelData
                        width: 28
                        height: 16
                        radius: Theme.radiusSmall
                        color: Theme.colors[modelData] ?? "transparent"
                        border.width: 1
                        border.color: Theme.withAlpha(Theme.fg, 0.12)
                    }
                }
            }
        }
    }
}

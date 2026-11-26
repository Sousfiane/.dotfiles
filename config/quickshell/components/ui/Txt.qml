import QtQuick
import qs.config

// Text in the theme's font, in one of the shared styles: title, heading, body, row, dim, small.
Text {
    // title | heading | body | row | dim | small
    property string variant: "body"

    readonly property var specs: ({
            title: {
                size: Theme.fontSize + 4,
                color: Theme.fg,
                bold: true
            },
            heading: {
                size: Theme.fontSize + 1,
                color: Theme.fg,
                bold: true
            },
            body: {
                size: Theme.fontSize,
                color: Theme.fg,
                bold: false
            },
            row: {
                size: Theme.fontSize - 1,
                color: Theme.fg,
                bold: false
            },
            dim: {
                size: Theme.fontSize - 2,
                color: Theme.dim,
                bold: false
            },
            small: {
                size: Theme.fontSize - 3,
                color: Theme.dim,
                bold: false
            }
        })
    readonly property var spec: specs[variant] ?? specs.body

    color: spec.color
    font.family: Theme.font
    font.pixelSize: spec.size
    font.bold: spec.bold
}

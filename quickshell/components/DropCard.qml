import QtQuick
import QtQuick.Shapes
import qs.config

Item {
    id: root

    // "right":  stuck to the right screen edge (square outer corner, no flare there)
    // "left":   stuck to the left screen edge
    // "center": floating, rounded and flared on both sides
    property string edge: "right"

    property color color: Theme.bg           // same as the bar
    property real radius: Theme.radius + 6   // rounded bottom corners
    property real flare: 14                  // size of the concave corners at the bar

    // children declared inside a DropCard land in the card, on top of the shape
    default property alias content: holder.data

    // what each side actually gets, depending on the edge
    readonly property real fl: edge === "left" ? 0 : flare      // left flare
    readonly property real fr: edge === "right" ? 0 : flare     // right flare
    readonly property real rl: edge === "left" ? 0 : radius     // bottom-left radius
    readonly property real rr: edge === "right" ? 0 : radius    // bottom-right radius

    // one continuous silhouette, in the shape's own coordinates
    // (the card's left edge sits at x = fl)
    readonly property string outline: {
        const h = height;
        const x0 = fl;
        const x1 = fl + width;

        let d = "M 0 0";

        // left flare, curving down into the card's left edge
        if (fl > 0)
            d += ` A ${fl} ${fl} 0 0 1 ${x0} ${fl}`;
        d += ` L ${x0} ${h - rl}`;

        // bottom-left corner
        if (rl > 0)
            d += ` A ${rl} ${rl} 0 0 0 ${x0 + rl} ${h}`;
        d += ` L ${x1 - rr} ${h}`;

        // bottom-right corner
        if (rr > 0)
            d += ` A ${rr} ${rr} 0 0 0 ${x1} ${h - rr}`;
        d += ` L ${x1} ${fr}`;

        // right flare, curving back up into the bar
        if (fr > 0)
            d += ` A ${fr} ${fr} 0 0 1 ${x1 + fr} 0`;

        d += " Z";
        return d;
    }

    Shape {
        x: -root.fl
        width: root.fl + root.width + root.fr
        height: root.height
        antialiasing: true
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"

            PathSvg {
                path: root.outline
            }
        }
    }

    Item {
        id: holder
        anchors.fill: parent
    }
}

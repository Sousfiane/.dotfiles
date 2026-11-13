import Quickshell
import QtQuick
import QtQuick.Shapes
import qs.config
import qs.services

Item {
    id: root

    // "right":  stuck to the right screen edge (square outer corner, no flare there)
    // "left":   stuck to the left screen edge
    // "center": floating, rounded and flared on both sides
    property string edge: "right"

    property color color: Theme.bg           // same as the bar
    property color lineColor: Theme.line     // 1px outline
    property real radius: Theme.radius + 6   // rounded bottom corners
    property real flare: 14                  // size of the concave corners at the bar

    // children declared inside a DropCard land in the card, on top of the shape
    default property alias content: holder.data

    // what each side actually gets, depending on the edge
    readonly property real fl: edge === "left" ? 0 : flare      // left flare
    readonly property real fr: edge === "right" ? 0 : flare     // right flare
    readonly property real rl: edge === "left" ? 0 : radius     // bottom-left radius
    readonly property real rr: edge === "right" ? 0 : radius    // bottom-right radius

    // room around the card for the line, which is drawn just outside the fill
    readonly property real pad: 2

    // one continuous silhouette, in the shape's own coordinates
    function build(w, h) {
        const ox = pad;
        const x0 = ox + fl;
        const x1 = ox + fl + w;

        let d = `M ${ox} 0`;
        if (fl > 0)
            d += ` A ${fl} ${fl} 0 0 1 ${x0} ${fl}`;
        d += ` L ${x0} ${h - rl}`;
        if (rl > 0)
            d += ` A ${rl} ${rl} 0 0 0 ${x0 + rl} ${h}`;
        d += ` L ${x1 - rr} ${h}`;
        if (rr > 0)
            d += ` A ${rr} ${rr} 0 0 0 ${x1} ${h - rr}`;
        d += ` L ${x1} ${fr}`;
        if (fr > 0)
            d += ` A ${fr} ${fr} 0 0 1 ${x1 + fr} 0`;
        return d;
    }

    readonly property string linePath: build(width, height)
    readonly property string fillPath: linePath + " Z"

    Shape {
        x: -root.fl - root.pad
        width: root.fl + root.width + root.fr + 2 * root.pad
        height: root.height + root.pad
        antialiasing: true
        layer.enabled: true
        layer.samples: 4

        // the line: a 2px stroke along the open outline (no top edge),
        // half of it hidden under the fill, leaving an exact 1px line outside
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.lineColor
            strokeWidth: 2
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.FlatCap

            PathSvg {
                path: root.linePath
            }
        }

        // the card itself, painted on top of the stroke
        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"

            PathSvg {
                path: root.fillPath
            }
        }
    }

    Item {
        id: holder
        anchors.fill: parent
    }

    // ---------- tell the bar where this card touches it ----------

    readonly property string screenName: root.QsWindow.window?.screen?.name ?? ""
    readonly property string gapKey: "card" + Math.random()

    // horizontal extent of the card, flares included, on the row `y` px below its top.
    // 0 is the body's left edge, `width` its right edge.
    function extentAt(y) {
        const h = height;
        let left = 0;
        let right = width;

        if (fl > 0 && y < fl)
            left = -fl + Math.sqrt(Math.max(0, fl * fl - (fl - y) * (fl - y)));
        else if (rl > 0 && y > h - rl)
            left = rl - Math.sqrt(Math.max(0, rl * rl - (y - (h - rl)) * (y - (h - rl))));

        if (fr > 0 && y < fr)
            right = width + fr - Math.sqrt(Math.max(0, fr * fr - (fr - y) * (fr - y)));
        else if (rr > 0 && y > h - rr)
            right = width - rr + Math.sqrt(Math.max(0, rr * rr - (y - (h - rr)) * (y - (h - rr))));

        return [left, right];
    }

    function reportGap() {
        if (screenName === "")
            return;

        const p = root.mapToItem(null, 0, 0);

        // how far the card has slid up under the bar (0 = fully dropped)
        const slid = Math.max(0, -p.y);

        // fully hidden: the bar's line is complete again, right now
        if (slid >= height) {
            Panels.clearGap(screenName, gapKey);
            return;
        }

        // the outline is visible one row below the edge it crosses, so measure there
        const e = extentAt(Math.min(slid + 1, height));
        Panels.setGap(screenName, gapKey, p.x + e[0], p.x + e[1]);
    }

    onXChanged: reportGap()
    onWidthChanged: reportGap()
    onHeightChanged: reportGap()

    // the slide animation moves the card's parent, so follow it frame by frame
    Connections {
        target: root.parent

        function onYChanged() {
            root.reportGap();
        }
    }

    Component.onCompleted: Qt.callLater(reportGap)
    Component.onDestruction: Panels.clearGap(screenName, gapKey)
}

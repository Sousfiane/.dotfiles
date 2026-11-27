import QtQuick
import qs.config
import qs.components.ui

// A history graph (the hub's System tab): `values` as a line with a soft fill under it, the newest on the
// right, the graph filling up from the right as readings come. A second series (`values2`) is drawn as a
// plain line over it. Repainted only when the values change.
Canvas {
    id: root

    property var values: []
    property var values2: []
    property int length: 60                // how many readings fit across
    property real max: 1                   // the top of the graph; 0 = the largest value shown
    property color color: Theme.accent
    property color color2: Theme.fg

    implicitHeight: 56
    onValuesChanged: requestPaint()
    onValues2Changed: requestPaint()
    onWidthChanged: requestPaint()
    onColorChanged: requestPaint()

    function line(ctx, vals, top, filled, color) {
        if (vals.length < 2)
            return;
        const step = width / (length - 1);
        const x0 = width - (vals.length - 1) * step;
        const y = v => height - 1 - Math.min(1, v / top) * (height - 2);
        ctx.beginPath();
        ctx.moveTo(x0, y(vals[0]));
        for (let i = 1; i < vals.length; i++)
            ctx.lineTo(x0 + i * step, y(vals[i]));
        ctx.strokeStyle = color;
        ctx.lineWidth = 1.5;
        ctx.stroke();
        if (filled) {
            ctx.lineTo(width, height);
            ctx.lineTo(x0, height);
            ctx.closePath();
            ctx.fillStyle = Theme.withAlpha(color, 0.18);
            ctx.fill();
        }
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        // a faint middle line, for scale
        ctx.strokeStyle = Theme.withAlpha(Theme.fg, 0.08);
        ctx.lineWidth = 1;
        ctx.beginPath();
        ctx.moveTo(0, Math.round(height / 2) + 0.5);
        ctx.lineTo(width, Math.round(height / 2) + 0.5);
        ctx.stroke();

        const top = max > 0 ? max : Math.max(1, ...values, ...values2);
        line(ctx, values, top, true, color);
        line(ctx, values2, top, false, color2);
    }
}

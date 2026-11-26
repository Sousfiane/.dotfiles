import QtQuick
import QtQuick.Layouts

// The small centred line of help at the bottom of a panel ("Enter to apply • Esc to close").
Txt {
    variant: "small"
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.Wrap
}

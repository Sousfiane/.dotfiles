import QtQuick
import QtQuick.Layouts

// the centered message a panel shows instead of an empty list
Txt {
    Layout.fillWidth: true
    Layout.topMargin: 8
    Layout.bottomMargin: 8
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.Wrap
    variant: "dim"
}

import QtQuick
import QtQuick.Layouts
import qs.config

// One device or network in the bluetooth / network panels: an optional group header, then a
// selectable card with an icon, name and status, an optional detail (battery, signal), the main
// action and a forget button. Children go under the card (e.g. a password prompt).
Item {
    id: root

    property bool selected: false
    property string header: ""            // section label, empty when not the first of its group

    property alias icon: iconSlot.data    // 26 px slot on the left
    property alias titleExtras: titleRow.data
    property string title: ""
    property bool titleBold: false
    property string status: ""
    property color statusColor: Theme.dim
    property string detail: ""            // "" hides it
    property color detailColor: Theme.dim

    property string actionText: ""
    property bool primary: false          // accent-filled action (connect / pair)
    property bool busy: false             // a change is in progress: the action waits
    property bool canForget: false

    default property alias below: col.data

    signal selectRequested
    signal activated
    signal forgetRequested

    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors {
            left: parent.left
            right: parent.right
        }
        spacing: 4

        Txt {
            visible: root.header !== ""
            Layout.topMargin: root.header !== "" ? 6 : 0
            variant: "small"
            font.bold: true
            text: root.header
        }

        SelectableCard {
            Layout.fillWidth: true
            implicitHeight: 52
            selected: root.selected
            onSelectRequested: root.selectRequested()

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }
                spacing: 10

                Item {
                    id: iconSlot
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    RowLayout {
                        id: titleRow
                        spacing: 6

                        Txt {
                            Layout.fillWidth: true
                            variant: "row"
                            font.bold: root.titleBold
                            text: root.title
                            elide: Text.ElideRight
                        }
                    }

                    Txt {
                        Layout.fillWidth: true
                        variant: "small"
                        color: root.statusColor
                        text: root.status
                        elide: Text.ElideRight
                    }
                }

                Txt {
                    visible: root.detail !== ""
                    variant: "dim"
                    color: root.detailColor
                    text: root.detail
                }

                Pill {
                    minWidth: 86
                    primary: root.primary
                    enabled: !root.busy
                    opacity: root.busy ? 0.5 : 1
                    text: root.busy ? "…" : root.actionText
                    onClicked: {
                        root.selectRequested();
                        root.activated();
                    }
                }

                IconButton {
                    visible: root.canForget
                    flat: true
                    icon: "×"
                    color: Theme.dim
                    onClicked: root.forgetRequested()
                }
            }
        }
    }
}

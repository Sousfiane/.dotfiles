import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

Scope {
    id: root

    // `qs ipc call mixer toggle|close`
    IpcHandler {
        target: "mixer"
        function toggle(): void {
            Mixer.toggle();
        }
        function close(): void {
            Mixer.open = false;
        }
    }

    function focusedScreen() {
        const name = Hyprland.focusedMonitor?.name;
        for (let i = 0; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i].name === name)
                return Quickshell.screens[i];
        return Quickshell.screens[0];
    }

    LazyLoader {
        active: Mixer.open

        PanelWindow {
            screen: root.focusedScreen()
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "mixer"

            Item {
                id: content
                anchors.fill: parent
                focus: true
                Component.onCompleted: forceActiveFocus()

                // keyboard selection (a node on tabs 1-4, a card on the Config tab)
                property int sel: 0
                readonly property int selIndex: Math.max(0, Math.min(sel, Mixer.current.length - 1))
                readonly property var selNode: Mixer.current[selIndex] ?? null

                // chooser state: target device (tabs 1-2) or card profile (Config)
                property bool choosing: false
                property int chooseIdx: 0

                onSelIndexChanged: {
                    choosing = false;
                    const l = Mixer.tab === 4 ? configList : list;
                    l.positionViewAtIndex(selIndex, ListView.Contain);
                }

                function openChooser() {
                    if (!selNode || Mixer.tab === 2 || Mixer.tab === 3)
                        return;

                    if (Mixer.tab === 4) {
                        chooseIdx = Math.max(0, selNode.profiles.findIndex(p => p.name === selNode.active));
                    } else {
                        const t = Mixer.targets(selNode);
                        chooseIdx = Math.max(0, t.indexOf(Mixer.currentTarget(selNode)));
                    }
                    choosing = true;
                }

                function moveChoice(d) {
                    const n = Mixer.tab === 4 ? selNode.profiles.length : Mixer.targets(selNode).length;
                    chooseIdx = Math.max(0, Math.min(n - 1, chooseIdx + d));
                }

                function applyChoice() {
                    if (Mixer.tab === 4) {
                        Mixer.setProfile(selNode, selNode.profiles[chooseIdx]);
                    } else {
                        const t = Mixer.targets(selNode)[chooseIdx];
                        if (t)
                            Mixer.moveStream(selNode, t);
                    }
                    choosing = false;
                }

                function move(d) {
                    if (choosing)
                        moveChoice(d);
                    else
                        sel = Math.max(0, Math.min(Mixer.current.length - 1, selIndex + d));
                }
                function adjust(d) {
                    Mixer.adjust(selNode, d);
                }

                Connections {
                    target: Mixer
                    function onTabChanged() {
                        content.sel = 0;
                        content.choosing = false;
                    }
                }

                Keys.onEscapePressed: {
                    if (choosing)
                        choosing = false;
                    else
                        Mixer.open = false;
                }
                Keys.onTabPressed: Mixer.tab = (Mixer.tab + 1) % 5
                Keys.onBacktabPressed: Mixer.tab = (Mixer.tab + 4) % 5
                Keys.onUpPressed: move(-1)
                Keys.onDownPressed: move(1)
                Keys.onLeftPressed: adjust(-0.05)
                Keys.onRightPressed: adjust(0.05)

                Keys.onReturnPressed: {
                    if (choosing)
                        applyChoice();
                    else
                        openChooser();
                }
                Keys.onEnterPressed: {
                    if (choosing)
                        applyChoice();
                    else
                        openChooser();
                }

                // vim-style keys, as in wiremix
                Keys.onPressed: event => {
                    let handled = true;
                    switch (event.text) {
                    case "j":
                        move(1);
                        break;
                    case "k":
                        move(-1);
                        break;
                    case "h":
                        adjust(-0.05);
                        break;
                    case "l":
                        adjust(0.05);
                        break;
                    case "m":
                        Mixer.toggleMute(selNode);
                        break;
                    case "s":
                    case "o":
                        if (choosing)
                            choosing = false;
                        else
                            openChooser();
                        break;
                    case "d":
                        if (Mixer.tab === 2 || Mixer.tab === 3)
                            Mixer.makeDefault(selNode);
                        break;
                    case "1":
                    case "2":
                    case "3":
                    case "4":
                    case "5":
                        Mixer.tab = parseInt(event.text) - 1;
                        break;
                    case "q":
                        Mixer.open = false;
                        break;
                    default:
                        handled = false;
                    }
                    if (handled)
                        event.accepted = true;
                }

                // click outside to close
                MouseArea {
                    anchors.fill: parent
                    onClicked: Mixer.open = false
                }

                Rectangle {
                    id: card
                    anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: Theme.barHeight + 8
                        rightMargin: 8
                    }
                    width: 560
                    height: Math.min(col.implicitHeight + 32, parent.height - Theme.barHeight - 24)
                    radius: Theme.radius + 4
                    color: Theme.bg
                    border.color: Theme.border
                    border.width: 2

                    // swallow clicks on the card
                    MouseArea {
                        anchors.fill: parent
                    }

                    ColumnLayout {
                        id: col
                        anchors {
                            fill: parent
                            margins: 16
                        }
                        spacing: 12

                        Text {
                            text: "Mixer"
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 4
                            font.bold: true
                        }

                        // tabs
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: Mixer.tabLabels

                                delegate: Rectangle {
                                    id: tabPill
                                    required property string modelData
                                    required property int index

                                    readonly property bool active: Mixer.tab === index
                                    readonly property int count: Mixer.listFor(index).length

                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 1
                                    implicitHeight: 26
                                    radius: 13
                                    color: active ? Theme.accent : Theme.surface

                                    Text {
                                        anchors.centerIn: parent
                                        text: tabPill.modelData + (tabPill.count > 0 ? "  " + tabPill.count : "")
                                        color: tabPill.active ? Theme.bg : Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 2
                                        font.bold: tabPill.active
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Mixer.tab = tabPill.index
                                    }
                                }
                            }
                        }

                        // tabs 1-4: applications and devices
                        ListView {
                            id: list
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(contentHeight, 440)
                            visible: Mixer.tab < 4 && Mixer.current.length > 0
                            clip: true
                            spacing: 4
                            model: Mixer.tab < 4 ? Mixer.current : []

                            delegate: MixerRow {
                                required property var modelData
                                required property int index

                                width: ListView.view.width
                                node: modelData
                                device: Mixer.tab >= 2
                                input: Mixer.tab === 1 || Mixer.tab === 3
                                selected: content.selIndex === index
                                choosing: content.choosing && content.selIndex === index
                                chooseIndex: content.chooseIdx

                                onSelectRequested: content.sel = index

                                onChooseRequested: {
                                    if (content.choosing && content.selIndex === index)
                                        content.choosing = false;
                                    else
                                        content.openChooser();
                                }
                                onChoiceHovered: i => content.chooseIdx = i
                                onChoicePicked: target => {
                                    Mixer.moveStream(modelData, target);
                                    content.choosing = false;
                                }
                            }
                        }

                        // Config tab: sound cards and their profiles
                        ListView {
                            id: configList
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(contentHeight, 440)
                            visible: Mixer.tab === 4 && Mixer.cards.length > 0
                            clip: true
                            spacing: 4
                            model: Mixer.tab === 4 ? Mixer.cards : []

                            delegate: ConfigRow {
                                required property var modelData
                                required property int index

                                width: ListView.view.width
                                card: modelData
                                selected: content.selIndex === index
                                choosing: content.choosing && content.selIndex === index
                                chooseIndex: content.chooseIdx

                                onSelectRequested: content.sel = index

                                onChooseRequested: {
                                    if (content.choosing && content.selIndex === index)
                                        content.choosing = false;
                                    else
                                        content.openChooser();
                                }
                                onChoiceHovered: i => content.chooseIdx = i
                                onChoicePicked: profile => {
                                    Mixer.setProfile(modelData, profile);
                                    content.choosing = false;
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            Layout.bottomMargin: 8
                            visible: Mixer.current.length === 0
                            horizontalAlignment: Text.AlignHCenter
                            text: ["No application is playing audio", "No application is recording", "No output devices", "No input devices", "No sound cards found"][Mixer.tab]
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            text: content.choosing ? "j k choose • Enter apply • Esc back" : Mixer.tab === 4 ? "Tab / 1-5 tabs • j k select • s / Enter change profile • Esc close" : "Tab / 1-5 tabs • j k select • h l volume • m mute • s / Enter move app • d default • Esc close"
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                        }
                    }
                }
            }
        }
    }
}

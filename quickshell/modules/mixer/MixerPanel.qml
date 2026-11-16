import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

DropdownPanel {
    name: "mixer"
    edge: "right"
    cardWidth: 560

    ColumnLayout {
        id: mixer
        spacing: 12

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
                mixer.sel = 0;
                mixer.choosing = false;
            }
        }

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Escape:
                // Esc backs out of the chooser first; otherwise it closes the panel
                if (!choosing)
                    return;
                choosing = false;
                break;
            case Qt.Key_Tab:
                Mixer.tab = (Mixer.tab + 1) % 5;
                break;
            case Qt.Key_Backtab:
                Mixer.tab = (Mixer.tab + 4) % 5;
                break;
            case Qt.Key_J:
            case Qt.Key_Down:
                move(1);
                break;
            case Qt.Key_K:
            case Qt.Key_Up:
                move(-1);
                break;
            case Qt.Key_H:
            case Qt.Key_Left:
                adjust(-0.05);
                break;
            case Qt.Key_L:
            case Qt.Key_Right:
                adjust(0.05);
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (choosing)
                    applyChoice();
                else
                    openChooser();
                break;
            case Qt.Key_S:
            case Qt.Key_O:
                if (choosing)
                    choosing = false;
                else
                    openChooser();
                break;
            case Qt.Key_M:
                Mixer.toggleMute(selNode);
                break;
            case Qt.Key_D:
                if (Mixer.tab === 2 || Mixer.tab === 3)
                    Mixer.makeDefault(selNode);
                break;
            case Qt.Key_1:
            case Qt.Key_2:
            case Qt.Key_3:
            case Qt.Key_4:
            case Qt.Key_5:
                Mixer.tab = event.key - Qt.Key_1;
                break;
            case Qt.Key_Q:
                panel.close();
                break;
            default:
                return;
            }
            event.accepted = true;
        }

        Txt {
            text: "Mixer"
            variant: "title"
        }

        // ---------- tabs ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: Mixer.tabLabels

                delegate: Pill {
                    required property string modelData
                    required property int index

                    readonly property int count: Mixer.listFor(index).length

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    fontSize: Theme.fontSize - 2
                    active: Mixer.tab === index
                    bold: active
                    text: modelData + (count > 0 ? "  " + count : "")
                    onClicked: Mixer.tab = index
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
                selected: mixer.selIndex === index
                choosing: mixer.choosing && mixer.selIndex === index
                chooseIndex: mixer.chooseIdx

                onSelectRequested: mixer.sel = index

                onChooseRequested: {
                    if (mixer.choosing && mixer.selIndex === index)
                        mixer.choosing = false;
                    else
                        mixer.openChooser();
                }
                onChoiceHovered: i => mixer.chooseIdx = i
                onChoicePicked: target => {
                    Mixer.moveStream(modelData, target);
                    mixer.choosing = false;
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
                selected: mixer.selIndex === index
                choosing: mixer.choosing && mixer.selIndex === index
                chooseIndex: mixer.chooseIdx

                onSelectRequested: mixer.sel = index

                onChooseRequested: {
                    if (mixer.choosing && mixer.selIndex === index)
                        mixer.choosing = false;
                    else
                        mixer.openChooser();
                }
                onChoiceHovered: i => mixer.chooseIdx = i
                onChoicePicked: profile => {
                    Mixer.setProfile(modelData, profile);
                    mixer.choosing = false;
                }
            }
        }

        Txt {
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            visible: Mixer.current.length === 0
            horizontalAlignment: Text.AlignHCenter
            text: ["No application is playing audio", "No application is recording", "No output devices", "No input devices", "No sound cards found"][Mixer.tab]
        }

        Hint {
            text: mixer.choosing ? "j k choose • Enter apply • Esc back" : Mixer.tab === 4 ? "Tab / 1-5 tabs • j k select • s / Enter change profile • Esc close" : "Tab / 1-5 tabs • j k select • h l volume • m mute • s / Enter move app • d default • Esc close"
        }
    }
}

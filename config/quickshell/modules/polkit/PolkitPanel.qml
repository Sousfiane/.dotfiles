import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// The password prompt for a system action an app asked for (Polkit opens it): what the app wants, the
// password, Enter to allow, Esc to refuse. A wrong password asks again, with polkit's message.
DropdownPanel {
    name: "polkit"
    edge: "center"
    cardWidth: 420
    ipc: false                  // opened by a request, never by hand
    autoFocus: false            // the password field takes the focus itself

    ColumnLayout {
        id: prompt
        spacing: 12

        readonly property var flow: Polkit.flow
        readonly property bool waiting: !(flow?.isResponseRequired ?? false)     // checking the password

        function send() {
            if (prompt.waiting)
                return;
            Polkit.submit(field.text);
            field.text = "";
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Txt {
                text: Icons.lock
                color: Theme.accent
                font.pixelSize: Theme.fontSize + 10
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Txt {
                    variant: "heading"
                    text: "Authentication required"
                }

                Txt {
                    Layout.fillWidth: true
                    variant: "small"
                    text: prompt.flow?.actionId ?? ""
                    elide: Text.ElideMiddle
                }
            }
        }

        // what the app wants to do, in its own words
        Txt {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: prompt.flow?.message ?? ""
        }

        InputField {
            id: field
            Layout.preferredHeight: 36
            password: !(prompt.flow?.responseVisible ?? false)
            placeholder: (prompt.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password"
            enabled: !prompt.waiting
            opacity: enabled ? 1 : 0.5
            Component.onCompleted: forceActiveFocus()

            onAccepted: prompt.send()
            onCancelled: Polkit.cancel()
        }

        // a wrong password, or polkit's other messages
        Txt {
            Layout.fillWidth: true
            visible: text !== ""
            variant: "small"
            wrapMode: Text.Wrap
            color: prompt.flow?.supplementaryIsError ? Theme.urgent : Theme.dim
            text: prompt.waiting ? "Checking…" : (prompt.flow?.supplementaryMessage ?? "")
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item {
                Layout.fillWidth: true
            }

            Pill {
                text: "Cancel"
                minWidth: 90
                onClicked: Polkit.cancel()
            }

            Pill {
                text: "Authenticate"
                primary: true
                minWidth: 110
                onClicked: prompt.send()
            }
        }

        Hint {
            text: "Enter to authenticate • Esc to cancel"
        }
    }
}

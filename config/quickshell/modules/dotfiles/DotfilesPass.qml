import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components.ui

// The SSH passphrase prompt of the dotfiles panel: shown while a pull or push waits for it
// (Dotfiles.askingPass), focused as it appears.
RowLayout {
    id: root

    readonly property bool typing: input.activeFocus

    signal finished                         // sent or cancelled: the keys go back to the panel

    visible: Dotfiles.askingPass
    spacing: 8

    function submit() {
        const pass = input.text;
        input.text = "";
        Dotfiles.submitPass(pass);
        root.finished();
    }

    onVisibleChanged: {
        input.text = "";
        if (visible)
            input.forceActiveFocus();
    }

    InputField {
        id: input
        password: true
        placeholder: "SSH passphrase to " + (Dotfiles.authJob?.label ?? "").toLowerCase()

        onAccepted: root.submit()
        onCancelled: {
            Dotfiles.cancelPass();
            root.finished();
        }
    }

    Pill {
        text: Dotfiles.authJob?.label ?? "Send"
        primary: true
        minWidth: 64
        onClicked: root.submit()
    }
}

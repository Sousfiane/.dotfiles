pragma Singleton
import Quickshell
import Quickshell.Services.Polkit
import QtQuick

// The polkit agent (replaces hyprpolkitagent): when an app asks for a system action (mounting a disk,
// a package manager's GUI, `pkexec`...), the polkit panel asks for the password. Only one agent can
// register per session, so this must exist from the start (shell.qml), with no other agent running.
Singleton {
    id: root

    readonly property var flow: agent.flow                       // the request on screen, or null
    readonly property bool active: agent.isActive
    readonly property bool registered: agent.isRegistered
    readonly property bool open: Panels.isOpen("polkit")

    // a wrong password: polkit asks again, with this to show
    readonly property string error: flow?.supplementaryIsError ? flow.supplementaryMessage : ""

    function submit(password) {
        if (flow?.isResponseRequired)
            flow.submit(password);
    }

    function cancel() {
        if (flow && !flow.isCompleted)
            flow.cancelAuthenticationRequest();
        Panels.hide("polkit");
    }

    PolkitAgent {
        id: agent
    }

    // a request opens the panel; its end (allowed, cancelled or given up) closes it
    onActiveChanged: active ? Panels.show("polkit") : Panels.hide("polkit")

    // closed another way (Esc, a click outside, another panel): that's a no
    onOpenChanged: if (!open && flow && !flow.isCompleted)
        flow.cancelAuthenticationRequest()
}

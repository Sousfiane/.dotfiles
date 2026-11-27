pragma Singleton
import Quickshell
import Quickshell.Services.Polkit
import QtQuick

// The polkit agent (replaces hyprpolkitagent): when an app asks for a system action (mounting a disk,
// a package manager's GUI, `pkexec`...), the polkit panel asks for the password. Only one agent can
// register per session, so this must exist from the start (shell.qml), with no other agent running.
Singleton {
    id: root

    readonly property var agent: agentLoader.item
    readonly property var flow: agent?.flow ?? null              // the request on screen, or null
    readonly property bool active: agent?.isActive ?? false
    readonly property bool registered: agent?.isRegistered ?? false
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

    // Registering can fail: right after a crash (Quickshell restarts itself) polkit still holds the old
    // agent for a moment, and Quickshell never tries again. So while it isn't registered, the agent is made
    // again every few seconds, on a new object path (the old one stays taken within this process)
    property int attempt: 0

    Loader {
        id: agentLoader
        sourceComponent: PolkitAgent {
            path: "/org/quickshell/PolkitAgent" + (root.attempt > 0 ? root.attempt : "")
        }
    }

    Timer {
        running: !root.registered
        interval: 3000
        repeat: true
        onTriggered: {
            agentLoader.active = false;
            root.attempt++;
            agentLoader.active = true;
        }
    }

    // a request opens the panel; its end (allowed, cancelled or given up) closes it
    onActiveChanged: active ? Panels.show("polkit") : Panels.hide("polkit")

    // closed another way (Esc, a click outside, another panel): that's a no
    onOpenChanged: if (!open && flow && !flow.isCompleted)
        flow.cancelAuthenticationRequest()
}

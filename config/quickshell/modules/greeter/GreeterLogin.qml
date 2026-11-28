import Quickshell
import Quickshell.Services.Greetd
import QtQuick

// Logging in through greetd: the user, what's typed, the answer. Enter logs in to uwsm's Hyprland, after the
// screen has faded out (`leaving`). Without greetd it's test mode: any password works.
Scope {
    id: root

    required property string home

    readonly property bool testing: !Greetd.available
    // uwsm's Hyprland through the user's login shell: scripts/greeter-session.sh. One word, the script's path:
    // greetd joins the command's words with spaces and runs that with sh, quoting nothing (see the script)
    readonly property var session: [home + "/.config/quickshell/scripts/greeter-session.sh"]

    property string user: (testing ? Quickshell.env("USER") : Quickshell.env("QS_GREETER_USER")) ?? ""
    property string password: ""
    property string message: ""
    property bool busy: false
    property bool leaving: false            // fading out, the session starts right after
    signal failed                           // shakes the field

    function edit(text) {
        password = text;
        message = "";
    }

    function submit() {
        if (busy || leaving || password === "")
            return;
        if (user === "") {
            // no user known: what was typed is the user name, the password comes next
            user = password.trim();
            password = "";
            return;
        }
        busy = true;
        message = "";
        if (testing)
            fakeCheck.restart();
        else
            Greetd.createSession(user);
    }

    function fail(text) {
        busy = false;
        password = "";
        message = text;
        failed();
        if (!testing && Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession();
    }

    function start() {
        busy = false;
        leaving = true;
        launchAfterFade.restart();
    }

    Connections {
        target: Greetd

        function onAuthMessage(text, error, responseRequired, echoResponse) {
            if (responseRequired)
                Greetd.respond(root.password);
            else if (error)
                root.message = text;
        }

        function onAuthFailure(text) {
            root.fail("Wrong password");
        }

        function onReadyToLaunch() {
            root.start();
        }

        function onError(text) {
            root.fail(text);
        }
    }

    // the screen fades out, then the session starts (the greeter quits, and Hyprland with it)
    Timer {
        id: launchAfterFade
        interval: 300
        onTriggered: root.testing ? Qt.quit() : Greetd.launch(root.session)
    }

    // test mode: "checking" a moment, then in
    Timer {
        id: fakeCheck
        interval: 600
        onTriggered: root.start()
    }

    Timer {
        running: root.testing
        interval: 1000 * Number(Quickshell.env("QS_GREETER_TEST_SECONDS") || 20)
        onTriggered: Qt.quit()
    }
}

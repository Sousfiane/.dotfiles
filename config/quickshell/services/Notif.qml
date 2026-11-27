import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import qs.config

// One notification, as the toasts and the center show it. Created by Notifs, either from a live
// Notification (kept in sync with it while the app has it open) or from the saved history.
QtObject {
    id: notif

    required property int id              // ours: stable for its whole life, saved with it
    property Notification notification: null   // the live one, null once the app has closed it

    property string appName
    property string appIcon
    property string desktopEntry
    property string summary
    property string body
    property string image                 // file / icon url; raw images are swapped for a saved copy
    property int urgency: NotificationUrgency.Normal
    property real expireTimeout: -1       // ms; -1 = up to us, 0 = never
    property bool fleeting: false         // "transient": asked not to be kept in the history
    property real time: Date.now()        // when it came, ms since epoch

    // ---------- the toast ----------

    property bool popup: false
    property bool hovered: false          // a toast pauses while the pointer is on it

    readonly property bool critical: urgency === NotificationUrgency.Critical
    // the app's wish when it has one (0 = stay), else ours; critical ones stay until handled
    readonly property int timeout: critical ? 0 : expireTimeout >= 0 ? expireTimeout : urgency === NotificationUrgency.Low ? 3000 : 5000

    signal expired

    readonly property Timer timer: Timer {
        interval: notif.timeout
        running: notif.popup && notif.timeout > 0 && !notif.hovered
        onTriggered: notif.expired()
    }

    // ---------- what the cards show ----------

    readonly property string iconSource: appIcon === "" ? "" : Icons.source(appIcon, true)

    readonly property string timeText: {
        const d = new Date(time);
        const today = new Date().toDateString() === d.toDateString();
        return Qt.formatDateTime(d, today ? "HH:mm" : "dd/MM HH:mm");
    }

    // ---------- following the live notification ----------

    function follow(n: Notification) {
        notification = n;
        appName = n.appName;
        appIcon = n.appIcon;
        desktopEntry = n.desktopEntry;
        summary = n.summary;
        body = n.body;
        urgency = n.urgency;
        expireTimeout = n.expireTimeout;
        fleeting = n.transient;
        setImage(n.image);
    }

    // the app may update it while it's open (a player changing track): keep the copy current
    readonly property Connections live: Connections {
        target: notif.notification

        function onAppNameChanged() {
            notif.appName = notif.notification.appName;
        }
        function onAppIconChanged() {
            notif.appIcon = notif.notification.appIcon;
        }
        function onSummaryChanged() {
            notif.summary = notif.notification.summary;
        }
        function onBodyChanged() {
            notif.body = notif.notification.body;
        }
        function onUrgencyChanged() {
            notif.urgency = notif.notification.urgency;
        }
        function onImageChanged() {
            notif.setImage(notif.notification.image);
        }
    }

    // ---------- raw images ----------

    // An image sent as raw data (image://qsimage/..., chat avatars and the like) only exists while the app
    // keeps its notification open. So it is copied to a file as soon as it comes, whatever is on screen
    // (toasts are off in Do Not Disturb), by an invisible window that loads it and saves what it drew.
    property string savedImage: ""        // our file, removed with the notification
    property string pendingImage: ""      // the raw one being saved; shown meanwhile

    function setImage(source: string) {
        if (source.startsWith("image://qsimage/")) {
            pendingImage = source;
            image = source;
            saver.active = true;
        } else {
            image = source;
        }
    }

    readonly property LazyLoader saver: LazyLoader {
        active: false

        PanelWindow {
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            mask: Region {}
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "qs-notif-image"

            // drawn at 128px, the size cards decode at, but invisible: only its grab is wanted
            Image {
                id: raw
                width: 128
                height: 128
                opacity: 0
                source: notif.pendingImage
                sourceSize.width: 128
                sourceSize.height: 128
                fillMode: Image.PreserveAspectCrop
                asynchronous: true

                onStatusChanged: {
                    if (status === Image.Error)
                        notif.saver.active = false;
                    if (status !== Image.Ready)
                        return;
                    const path = `${Notifs.imageDir}/${notif.time}-${notif.id}.png`;
                    grabToImage(result => {
                        if (result.saveToFile(path)) {
                            notif.savedImage = path;
                            // only if the app hasn't sent another one meanwhile
                            if (notif.image === notif.pendingImage)
                                notif.image = "file://" + path;
                        }
                        notif.saver.active = false;
                    }, Qt.size(128, 128));
                }
            }
        }
    }
}

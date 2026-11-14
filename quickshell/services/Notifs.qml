pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    readonly property var list: server.trackedNotifications   // live toasts
    readonly property ListModel history: historyModel         // center content

    property bool dnd: false
    property bool centerOpen: false
    property int unread: 0

    // opening the center marks everything as read and closes the other panels
    // opening the center marks everything as read
    onCenterOpenChanged: if (centerOpen)
        unread = 0

    function clearHistory() {
        historyModel.clear();
        unread = 0;
    }

    function removeAt(i) {
        historyModel.remove(i);
    }

    ListModel {
        id: historyModel
    }

    NotificationServer {
        id: server
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: n => {
            historyModel.insert(0, {
                appName: n.appName,
                summary: n.summary,
                body: n.body,
                urgency: n.urgency,
                time: Qt.formatDateTime(new Date(), "HH:mm")
            });
            while (historyModel.count > 50)
                historyModel.remove(historyModel.count - 1);
            if (!root.centerOpen)
                root.unread++;

            // Do Not Disturb: still recorded in history, but only critical ones pop up
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                n.tracked = true;
        }
    }
}

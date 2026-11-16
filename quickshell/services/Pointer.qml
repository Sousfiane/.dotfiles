pragma Singleton
import Quickshell
import QtQuick

Singleton {
    // global position of the pointer the last time it genuinely moved
    property point last: Qt.point(-1, -1)
}

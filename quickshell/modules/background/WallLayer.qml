import QtQuick

// one of the two wallpaper layers of a screen: tells when it has finished loading the wanted image
Image {
    property string wanted
    property real dpr: 1

    signal wantedReady

    anchors.fill: parent
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    opacity: 0
    sourceSize: Qt.size(width * dpr, height * dpr)
    onStatusChanged: if (status === Image.Ready && source == wanted)
        wantedReady()
}

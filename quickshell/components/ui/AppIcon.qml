import QtQuick

// Icon-theme / app icon. Quickshell's IconImage decodes at the exact display
// size, so for themes that only ship a few PNG sizes (zen: 16/32/48/64/128)
// Qt picks the nearest smaller one and upscales it, which looks blurry.
// Decoding well above the display size and mipmapping down keeps it crisp.
Item {
    property alias source: image.source
    property real implicitSize: 24

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Image {
        id: image
        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        sourceSize.width: 128
        sourceSize.height: 128
        asynchronous: true
        smooth: true
        mipmap: true
    }
}

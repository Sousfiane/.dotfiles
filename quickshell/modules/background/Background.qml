import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

// Wallpaper on every screen, on the background layer (replaces swaybg).
// A new wallpaper fades in over the old one once it has finished loading.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData
        screen: modelData

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "black"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "qs-wallpaper"
        mask: Region {}   // click-through

        readonly property int fadeMs: 600
        readonly property string wanted: Wallpapers.currentUrl

        // two slots: `front` is on screen, the other loads the next wallpaper underneath
        property Image front: null

        function load() {
            const back = front === slotA ? slotB : slotA;
            if (back.source == wanted && back.status === Image.Ready) {
                reveal(back);
                return;
            }
            back.source = wanted;     // reveal() runs from onStatusChanged once it is ready
        }

        function reveal(img) {
            if (img === front)
                return;
            fade.stop();
            fade.duration = front ? win.fadeMs : 0;     // the very first wallpaper appears without a fade
            if (front)
                front.z = 0;
            img.z = 1;
            img.opacity = 0;
            fade.target = img;
            front = img;
            fade.start();
        }

        onWantedChanged: load()
        Component.onCompleted: load()

        NumberAnimation {
            id: fade
            property: "opacity"
            from: 0
            to: 1
            easing.type: Easing.InOutQuad

            // the old wallpaper is hidden now: free its decoded image
            onFinished: {
                const back = win.front === slotA ? slotB : slotA;
                if (back.source != win.wanted)
                    back.source = "";
            }
        }

        Image {
            id: slotA
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            opacity: 0
            sourceSize: Qt.size(win.width * win.screen.devicePixelRatio, win.height * win.screen.devicePixelRatio)
            onStatusChanged: if (status === Image.Ready && source == win.wanted)
                win.reveal(slotA)
        }

        Image {
            id: slotB
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            opacity: 0
            sourceSize: Qt.size(win.width * win.screen.devicePixelRatio, win.height * win.screen.devicePixelRatio)
            onStatusChanged: if (status === Image.Ready && source == win.wanted)
                win.reveal(slotB)
        }
    }
}

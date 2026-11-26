pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel
import qs.config

// The wallpapers in ~/.wallpapers, filtered for the picker, and the one chosen (kept in Quickshell's
// state, drawn by modules/background).
Singleton {
    id: root

    property string query: ""

    readonly property string dir: Config.wallpaperDir
    readonly property var files: folderModel      // what the grid shows

    readonly property var extensions: ["png", "jpg", "jpeg", "webp", "bmp", "gif"]
    readonly property var filters: {
        // strip characters that would act as wildcards in the filter
        const q = query.trim().replace(/[\[\]\\?*]/g, "");
        return extensions.map(e => "*" + q + "*." + e);
    }

    readonly property bool open: Panels.isOpen("wallpaper")

    function toggle() {
        Panels.toggle("wallpaper");
    }

    // start fresh on every open
    onOpenChanged: if (open)
        query = ""

    // the wallpaper on screen, drawn by modules/background (crossfades on change)
    property string current: stateFile.text().trim()
    readonly property string currentUrl: current ? "file://" + current : ""     // for Image.source

    function isCurrent(path) {
        return current === path;
    }

    function apply(path) {
        current = path;
        stateFile.setText(path + "\n");

        Panels.hide("wallpaper");
    }

    FileView {
        id: stateFile
        path: Config.wallpaperState
        blockLoading: true
    }

    FolderListModel {
        id: folderModel

        folder: "file://" + root.dir
        showDirs: false
        showFiles: true
        sortField: FolderListModel.Name
        caseSensitive: false
        nameFilters: root.filters
    }
}

pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel
import qs.config

Singleton {
    id: root

    property bool open: false
    property string query: ""

    readonly property string dir: Config.wallpaperDir
    readonly property var files: folderModel      // what the grid shows

    readonly property var extensions: ["png", "jpg", "jpeg", "webp", "bmp", "gif"]
    readonly property var filters: {
        // strip characters that would act as wildcards in the filter
        const q = query.trim().replace(/[\[\]\\?*]/g, "");
        return extensions.map(e => "*" + q + "*." + e);
    }

    function toggle() {
        open = !open;
    }

    // start fresh on every open
    onOpenChanged: if (open)
        query = ""

    function isCurrent(path) {
        return stateFile.text().trim() === path;
    }

    function apply(path) {
        stateFile.setText(path + "\n");

        Quickshell.execDetached(["bash", "-c", "pkill -x swaybg 2>/dev/null || true; " + "setsid uwsm-app -- swaybg -i \"$1\" >/dev/null 2>&1 &", "wallpaper-picker", path]);

        open = false;
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

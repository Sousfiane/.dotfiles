import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// Remove: the packages installed on purpose, filtered as you type, and removed with what only they needed
// (yay -Rns) in a floating terminal, where pacman asks before doing it. A package one of the dotfiles' lists
// names says which: removing it here doesn't take it off the list.
// Shown in its own panel and as the hub's tab (the package remover).
ColumnLayout {
    id: view

    Component.onCompleted: Packages.refresh()

    property string filter: ""
    readonly property var shown: {
        const q = filter.trim().toLowerCase();
        return q ? Packages.installed.filter(p => p.name.includes(q)) : Packages.installed;
    }

    spacing: 8

    PanelHeader {
        icon: Icons.packageRemove
        title: "Remove"
        subtitle: Packages.loading && Packages.installed.length === 0 ? "reading…" : Fmt.plural(Packages.installed.length, "package") + " installed on purpose"
    }

    SearchBox {
        placeholder: "Installed packages..."

        onTextChanged: {
            view.filter = text;
            list.currentIndex = 0;
            list.positionViewAtBeginning();
        }
        onMoved: direction => {
            if (direction === "down")
                list.incrementCurrentIndex();
            else if (direction === "up")
                list.decrementCurrentIndex();
        }
        onAccepted: {
            const pkg = view.shown[list.currentIndex];
            if (pkg)
                Packages.remove(pkg);
        }
    }

    EmptyState {
        visible: list.count === 0 && !Packages.loading
        text: "No installed package matches"
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 2
        model: ScriptModel {
            values: view.shown
        }
        currentIndex: 0

        readonly property real rowWidth: width - (vbar.size < 1 ? vbar.width + 6 : 0)

        ScrollBar.vertical: Scroller {
            id: vbar
        }

        delegate: PackageRow {
            required property var modelData
            required property int index

            width: ListView.view.rowWidth
            current: ListView.isCurrentItem
            name: modelData.name
            version: modelData.version
            tags: [
                ...(modelData.list ? [
                        {
                            text: modelData.list,
                            color: Theme.iris
                        }
                    ] : []),
                ...(modelData.aur ? [
                        {
                            text: "aur",
                            color: Theme.gold
                        }
                    ] : [])
            ]

            onMoved: list.currentIndex = index
            onClicked: Packages.remove(modelData)
        }
    }

    Hint {
        text: "Enter remove (in a terminal, which asks first) • ↑ ↓ select • Esc close"
    }
}

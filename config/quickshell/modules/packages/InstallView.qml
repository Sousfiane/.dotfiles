import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// Install: search the official repos and the AUR, and install the chosen package with yay in a floating
// terminal (where sudo, the AUR's build files and pacman's questions are answered).
// Shown in its own panel and as the hub's tab (the package installer).
ColumnLayout {
    id: view
    spacing: 8

    PanelHeader {
        icon: Icons.packageInstall
        title: "Install"
        subtitle: Packages.searching ? "searching…" : Packages.query.trim().length < 2 ? "official repositories and the AUR" : Fmt.plural(Packages.results.length, "package")
    }

    SearchBox {
        id: search
        placeholder: "Packages..."

        Component.onCompleted: text = Packages.query
        onTextChanged: {
            Packages.query = text;
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
            const pkg = Packages.results[list.currentIndex];
            if (pkg)
                Packages.install(pkg);
        }
    }

    EmptyState {
        visible: list.count === 0
        text: Packages.query.trim().length < 2 ? "Type at least two letters" : Packages.searching ? "Searching…" : "No package matches"
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 2
        model: ScriptModel {
            values: Packages.results
        }
        currentIndex: 0

        readonly property real rowWidth: width - (vbar.size < 1 ? vbar.width + 6 : 0)

        ScrollBar.vertical: ScrollBar {
            id: vbar
            policy: ScrollBar.AsNeeded
        }

        delegate: PackageRow {
            required property var modelData
            required property int index

            width: ListView.view.rowWidth
            current: ListView.isCurrentItem
            name: modelData.name
            version: modelData.version
            description: modelData.description
            tags: [
                {
                    text: modelData.repo,
                    color: modelData.repo === "aur" ? Theme.gold : Theme.foam
                },
                ...(modelData.installed ? [
                        {
                            text: "installed",
                            color: Theme.pine
                        }
                    ] : [])
            ]

            onMoved: list.currentIndex = index
            onClicked: Packages.install(modelData)
        }
    }

    Hint {
        text: "Enter install (in a terminal) • ↑ ↓ select • Esc close"
    }
}

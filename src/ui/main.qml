import QtQuick 2.6
import QtQuick.Controls 2.0 as Controls
import QtQuick.Layouts 1.2
import org.kde.kirigami 2.13 as Kirigami

import app.melo.Config 1.0

import "/dist/backend.js" as Backend
import "."

Kirigami.ApplicationWindow {
    id: root

    title: i18nc("@title:window", "Melo")

    minimumWidth: pageStack.defaultColumnWidth
    minimumHeight: 250 + (Kirigami.Units.largeSpacing * 10)

    globalDrawer: Kirigami.GlobalDrawer {
        isMenu: true
        actions: [
            Kirigami.Action {
                text: i18n("Quit")
                icon.name: "application-exit"
                shortcut: StandardKey.Quit
                onTriggered: Qt.quit()
            }
        ]
    }

    pageStack.initialPage: CollectionList {}

    Component.onCompleted: {
        Backend.exports.config.server_url = `${Config.server_url}`;
    }
}

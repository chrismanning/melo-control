import QtQuick 2.6
import QtQuick.Controls 2.0 as Controls
import QtQuick.Layouts 1.2
import org.kde.kirigami 2.13 as Kirigami

import "/dist/backend.js" as Backend

Kirigami.ApplicationWindow {
    id: root

    title: i18nc("@title:window", "Melo")

    pageStack.initialPage: Kirigami.Page {

        Controls.Label {
            anchors.centerIn: parent
            text: i18n(Backend.exports.hello())
//            text: i18n(Backend.hello())
        }
    }
}

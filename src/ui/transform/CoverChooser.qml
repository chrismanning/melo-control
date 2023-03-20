import QtQuick 2.15
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

import "."

Kirigami.ScrollablePage {
    id: coverChooserPage

    required property var coverSearchResults

    Component.onCompleted: {
        console.debug(`coverSearchResults: ${JSON.stringify(coverSearchResults)}`);
    }

    actions {
        main: Kirigami.Action {
            id: saveAction
            text: i18n("Save")
            shortcut: StandardKey.Save
            icon.name: "document-save"
            onTriggered: {
                accept();
                closeDialog();
            }
        }
        contextualActions: [
            Kirigami.Action {
                id: cancelAction
                text: i18n("Cancel")
                shortcut: "Esc"
                icon.name: "dialog-cancel"
                onTriggered: {
                    closeDialog();
                }
            }
        ]
    }

    signal accepted(var coverResult)

    function accept() {
        accepted(coverSearchResults[covers.currentIndex]);
    }

    ListView {
        id: covers
        anchors.fill: parent

        model: coverChooserPage.coverSearchResults
        delegate: Kirigami.AbstractListItem {
            hoverEnabled: true
            ColumnLayout {
                Item {
                    width: 250
                    height: 250
                    Image {
                        anchors.fill: parent

                        fillMode: Image.PreserveAspectFit
                        cache: false
                        asynchronous: true
                        mipmap: true
                        source: modelData.smallCover.url
                    }
                }
                Controls.Label {
                    text: `${modelData.bigCover.width} x ${modelData.bigCover.height} - ${(modelData.bigCover.bytes / (1024 * 1024)).toFixed(1)} MiB`
                }
            }
        }
    }
}

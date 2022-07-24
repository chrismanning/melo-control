import QtQuick 2.6
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.2
import org.kde.kirigami 2.20 as Kirigami

import "/dist/backend.js" as Backend

Kirigami.Page {

    title: i18n("Collections")

    contextualActions: [
        Kirigami.Action {
            id: addCollectionAction
            text: i18n("&Add Collection")
            icon.name: "list-add"
            shortcut: StandardKey.New
            onTriggered: addCollection.open()
        }
    ]

    Component.onCompleted: loadCollections()

    ListView {
        id: collections
        anchors.fill: parent

        delegate: collectionDelegate
        onModelChanged: console.debug("collections model changed")
    }

    Component {
        id: collectionDelegate
        Kirigami.AbstractCard {
            showClickFeedback: true

            header: Kirigami.Heading {
                Layout.fillWidth: true
                level: 1
                text: modelData.name
            }

            contentItem: Item {

                implicitWidth: delegateLayout.implicitWidth
                implicitHeight: delegateLayout.implicitHeight

                GridLayout {
                    id: delegateLayout
                    anchors {
                        left: parent.left
                        top: parent.top
                        right: parent.right
                    }
                    rowSpacing: Kirigami.Units.largeSpacing
                    columnSpacing: Kirigami.Units.largeSpacing
                    columns: 2 //root.wideScreen ? 4 : 2

                    ColumnLayout {
                        RowLayout {
                            Kirigami.Icon {
                                source: modelData.kind === "filesystem" ? "folder" : null
                            }
                            Controls.Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: modelData.rootUri.replace("file:", "")
                            }
                        }
                    }
                    RowLayout {
                        Controls.Button {
                            Layout.columnSpan: 2
                            text: i18n("Rename")
                            icon.name: "document-edit"
                        }
                        Controls.Button {
                            text: i18n("Delete")
                            icon.name: "list-remove"
                            onClicked: {
                                confirmDelete.collectionId = modelData.id
                                confirmDelete.collectionName = modelData.name
                                confirmDelete.open()
                            }
                        }
                    }
                }
            }
        }
    }

    Kirigami.PromptDialog {
        id: confirmDelete
        title: i18n("Delete collection?")
        subtitle: i18n("The collection and all its sources will be removed from the database")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

        property string collectionId
        property string collectionName

        onAccepted: {
            Backend.exports.delete_collection(confirmDelete.collectionId, response => {
                if (response.errors) {
                    showPassiveNotification(
                        i18n("Failed to delete collection '%1'")
                            .arg(confirmDelete.collectionName)
                    );
                } else {
                    showPassiveNotification(
                        i18n("Deleted collection '%1'")
                            .arg(confirmDelete.collectionName)
                    );
                    loadCollections();
                }
            });
        }
    }

    Kirigami.PromptDialog {
        id: addCollection
        title: i18n("Add Collection")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

        onOpened: name.forceActiveFocus()
        onAccepted: {
            Backend.exports.add_collection(name.text, rootPath.text, watch.checked, response => {
                if (response.errors) {
                    showPassiveNotification(i18n("Failed to add collection"));
                } else {
                    var newCollection = response.data.library.collection.add;
                    showPassiveNotification(i18n("Added collection '%1'").arg(newCollection.name));
                    loadCollections();
                }
            });
            name.text = "";
            rootPath.text = "";
            watch.checked = true;
        }

        Kirigami.FormLayout {
            id: formLayout

            Controls.TextField {
                id: name
                Kirigami.FormData.label: i18n("Name:")
            }
            Controls.TextField {
                id: rootPath
                Kirigami.FormData.label: i18n("Root Path:")
            }
            Controls.CheckBox {
                id: watch
                Kirigami.FormData.label: i18n("Watch Filesystem?:")
                checked: true
            }
        }
    }

    function loadCollections() {
        Backend.exports.get_collections(response => { collections.model = response.data.library.collections })
    }
}

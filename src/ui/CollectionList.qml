import QtQuick 2.6
import QtQuick.Controls 2.0 as Controls
import QtQuick.Layouts 1.2
import org.kde.kirigami 2.13 as Kirigami

import "/dist/backend.js" as Backend

Kirigami.Page {

    title: i18n("Collections")

    contextualActions: [
        Kirigami.Action {
            id: addCollectionAction
            text: i18n("&Add Collection")
            icon.name: "list-add"
            shortcut: StandardKey.New
            onTriggered: addCollectionSheet.open()
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
                        Kirigami.Heading {
                            Layout.fillWidth: true
                            level: 1
                            text: modelData.name
                        }
                        Kirigami.Separator {
                            Layout.fillWidth: true
                        }
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
                        }
                        Controls.Button {
                            text: i18n("Delete")
                            Layout.columnSpan: 2
                            onClicked: {
                                confirmDeleteSheet.collectionId = modelData.id
                                confirmDeleteSheet.collectionName = modelData.name
                                confirmDeleteSheet.open()
                            }
                        }
                    }
                }
            }
        }
    }

    Kirigami.OverlaySheet {
        id: confirmDeleteSheet
        title: i18n("Confirm Delete")
        property string collectionId
        property string collectionName

        ColumnLayout {
            Controls.Label {
                text: i18n("Delete collection?")
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Controls.Button {
                    text: i18nc("@action:button", "OK")
                    onClicked: {
                        Backend.exports.delete_collection(confirmDeleteSheet.collectionId, response => {
                            if (response.errors) {
                                showPassiveNotification(
                                    i18n("Failed to delete collection '%1' (%2)")
                                        .arg(confirmDeleteSheet.collectionName)
                                        .arg(confirmDeleteSheet.collectionId)
                                );
                            } else {
                                showPassiveNotification(
                                    i18n("Deleted collection '%1' (%2)")
                                        .arg(confirmDeleteSheet.collectionName)
                                        .arg(confirmDeleteSheet.collectionId)
                                );
                                loadCollections();
                            }
                        });
                        confirmDeleteSheet.close();
                    }
                }
                Controls.Button {
                    text: i18nc("@action:button", "Cancel")
                    onClicked: confirmDeleteSheet.close()
                }
            }
        }
    }

    Kirigami.OverlaySheet {
        id: addCollectionSheet
        title: i18n("Add Collection")

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

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Controls.Button {
                    text: i18nc("@action:button", "OK")
                    onClicked: {
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
                        addCollectionSheet.close();
                    }
                }
                Controls.Button {
                    text: i18nc("@action:button", "Cancel")
                    onClicked: addCollectionSheet.close()
                }
            }
        }
    }

    function loadCollections() {
        Backend.exports.get_collections(response => { collections.model = response.data.library.collections })
    }
}

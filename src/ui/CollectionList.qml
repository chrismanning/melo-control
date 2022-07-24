import QtQuick 2.6
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.2
import org.kde.kirigami 2.20 as Kirigami

import "/dist/backend.js" as Backend

Kirigami.Page {
    id: collectionsPage

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
            id: collectionCard

            header: Kirigami.Heading {
                Layout.fillWidth: true
                level: 1
                text: modelData.name
            }

            contentItem: Item {

                implicitWidth: delegateLayout.implicitWidth
                implicitHeight: delegateLayout.implicitHeight

                RowLayout {
                    id: delegateLayout
                    Kirigami.Icon {
                        source: modelData.kind === "filesystem" ? "folder" : null
                    }
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: decodeURI(modelData.rootUri.replace("file:", ""))
                    }
                }
            }

            footer: Kirigami.ActionToolBar {
                id: collectionActions
                position: Controls.ToolBar.Footer
                actions: [
                    Kirigami.Action {
                        id: browseCollectionSourcesAction
                        text: i18n("Browse Sources")
                        icon.name: "file-catalog-symbolic"
                    },
                    Kirigami.Action {
                        id: browseCollectionGenresAction
                        text: i18n("Browse Genres")
                        icon.name: "view-media-genre"
                    },
                    Kirigami.Action {
                        id: browseCollectionArtistsAction
                        text: i18n("Browse Artists")
                        icon.name: "view-media-artist"
                    },
                    Kirigami.Action {
                        id: browseCollectionAlbumsAction
                        text: i18n("Browse Albums")
                        icon.name: "view-media-album-cover"
                    },
                    Kirigami.Action {
                        id: browseCollectionTracksAction
                        text: i18n("Browse Tracks")
                        icon.name: "view-media-track"
                    },
                    Kirigami.Action {
                        id: renameCollectionAction
                        text: i18n("Rename")
                        icon.name: "document-edit"
                    },
                    Kirigami.Action {
                        id: deleteCollectionAction
                        text: i18n("Delete")
                        icon.name: "list-remove"
                        onTriggered: {
                            confirmDelete.collectionId = modelData.id
                            confirmDelete.collectionName = modelData.name
                            confirmDelete.open()
                        }
                    }

                ]
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

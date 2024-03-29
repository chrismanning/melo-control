import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.2
import org.kde.kirigami 2.20 as Kirigami
import QSyncable 1.0

import app.melo.Config 1.0

import "/dist/backend.js" as Backend

Kirigami.ScrollablePage {
    id: collectionsPage

    title: i18nc("@title", "Collections")

    padding: 10

    contextualActions: [
        Kirigami.Action {
            id: addCollectionAction
            text: i18n("&Add Collection")
            icon.name: "list-add"
            shortcut: StandardKey.New
            onTriggered: addCollectionDialog.open()
        },
        Kirigami.Action {
            id: refreshAction
            text: i18n("Refresh")
            icon.name: "view-refresh"
            shortcut: StandardKey.Refresh
            onTriggered: collectionsPage.refreshing = true;
            enabled: !collectionsPage.refreshing
        }
    ]

    readonly property var serverUrl: Config.server_url
    onServerUrlChanged: {
        Backend.exports.config.server_url = `${serverUrl}`;
    }

    Component.onCompleted: {
        collectionsPage.refreshing = true;
    }

    supportsRefreshing: true
    onRefreshingChanged: {
        if (refreshing) {
            loadCollections();
        }
    }

    Kirigami.CardsListView {
        id: collections
        anchors.fill: parent

        delegate: collectionDelegate
        model: JsonListModel {}
        onModelChanged: console.debug("collections model changed")
    }

    Component {
        id: collectionDelegate
        Kirigami.AbstractCard {
            id: collectionCard

            header: Kirigami.Heading {
                Layout.fillWidth: true
                level: 1
                text: model.name
            }

            contentItem: Item {

                implicitWidth: delegateLayout.implicitWidth
                implicitHeight: delegateLayout.implicitHeight

                RowLayout {
                    id: delegateLayout
                    Kirigami.Icon {
                        source: model.kind === "filesystem" ? "folder" : null
                    }
                    Controls.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: decodeURI(model.rootUri.replace("file:", ""))
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
                        onTriggered: {
                            applicationWindow().pageStack.push("qrc:/ui/SourceGroupList.qml", {
                                "collectionId": model.id,
                                "collectionName": model.name,
                                "basePath": model.rootUri,
                            });
                        }
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
                            confirmDeleteDialog.collectionId = model.id
                            confirmDeleteDialog.collectionName = model.name
                            confirmDeleteDialog.open()
                        }
                    }

                ]
            }
        }
    }

    Kirigami.PromptDialog {
        id: confirmDeleteDialog
        title: i18n("Delete collection?")
        subtitle: i18n("The collection and all its sources will be removed from the database")
        standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel

        property string collectionId
        property string collectionName

        onAccepted: deleteCollection(collectionId, collectionName)

        function deleteCollection(id, name) {
            Backend.exports.delete_collection(id)
                .then(response => {
                    showPassiveNotification(
                        i18n("Deleted collection '%1'").arg(name)
                    );
                    loadCollections();
                },
                error => {
                    showPassiveNotification(
                        i18n("Failed to delete collection '%1'").arg(nameame),
                        null,
                        i18n("Retry"),
                        () => { deleteCollection(id, name); }
                    );
                });
        }
    }

    Kirigami.PromptDialog {
        id: addCollectionDialog
        title: i18n("Add Collection")
        // buttons overridden as customFooterActions
        standardButtons: Controls.Dialog.NoButton

        onOpened: nameInput.forceActiveFocus()

        customFooterActions: [
            Kirigami.Action {
                id: okAction
                text: i18n("OK")
                icon.name: "dialog-ok"
                enabled: addCollectionDialog.acceptableInput
                onTriggered: {
                    if (addCollectionDialog.acceptableInput) {
                        addCollectionDialog.accept();
                    }
                }
            },
            Kirigami.Action {
                text: i18n("Cancel")
                icon.name: "dialog-cancel"
                onTriggered: addCollectionDialog.reject()
            }
        ]

        readonly property bool acceptableInput: nameInput.acceptableInput && rootPathInput.acceptableInput

        onAccepted: {
            addCollection(nameInput.text, rootPathInput.text, watchInput.checked);
            nameInput.text = "";
            rootPathInput.text = "";
            watchInput.checked = true;
        }

        function addCollection(name, rootPath, watch) {
            Backend.exports.add_collection(name, rootPath, watch)
                .then(data => {
                    loadCollections();
                    var newCollection = data.library.collection.add;
                    showPassiveNotification(i18n("Added collection '%1'").arg(newCollection.name));
                },
                error => {
                    showPassiveNotification(
                        i18n("Failed to add collection"),
                        null,
                        i18n("Retry"),
                        () => { addCollection(name, rootPath, watch); }
                    );
                });
        }

        Kirigami.FormLayout {
            id: formLayout

            Controls.TextField {
                id: nameInput
                Kirigami.FormData.label: i18n("Name:")
                onAccepted: okAction.trigger(nameInput)
            }
            Controls.TextField {
                id: rootPathInput
                Kirigami.FormData.label: i18n("Root Path:")
                validator: RegularExpressionValidator { regularExpression: /^\/[^\0]*$/ }
                onAccepted: okAction.trigger(nameInput)
            }
            Controls.CheckBox {
                id: watchInput
                Kirigami.FormData.label: i18n("Watch Filesystem?:")
                checked: true
            }
        }
    }

    function loadCollections() {
        Backend.exports.get_collections()
            .then(
                data => {
                    collectionsPage.refreshing = false;
                    collections.model.source = data.library.collections;
                },
                error => {
                    collectionsPage.refreshing = false;
                    showPassiveNotification(i18n("Failed to load collections"), null, i18n("Retry"), () => { loadCollections() });
                }
            );
    }
}

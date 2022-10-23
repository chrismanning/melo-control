import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.2
import org.kde.kirigami 2.20 as Kirigami
import QSyncable 1.0

import "."

import "/dist/backend.js" as Backend
import "/dist/diff.js" as Diff

Kirigami.ScrollablePage {
    id: previewTransformPage

    required property var sources

    title: i18n("Apply transformations?")

    Component.onCompleted: {
        previewTransformPage.refreshing = true
    }

    supportsRefreshing: true
    onRefreshingChanged: {
        if (refreshing) {
            if (applying) {
                transforms.model.remove(0, transforms.model.count);
                applyTransform();
            } else {
                previewTransform();
            }
        }
    }
    property bool applying: false

    ListView {
        id: transforms

        model: JsonListModel {
            keyField: "originalId"
            fields: [
                "original",
                "transformed",
                "error"
            ]
        }

        delegate: transformDelegate
    }

    actions {
        left: Kirigami.Action {
            id: cancelAction
            text: i18n("Cancel")

            icon.name: "dialog-cancel"
            onTriggered: {
                closeDialog();
            }
        }
        right: Kirigami.Action {
            id: confirmAction
            text: i18n("Apply")

            icon.name: "dialog-ok"
            onTriggered: {
                confirmAction.enabled = false;
                previewTransformPage.applying = true;
                previewTransformPage.refreshing = true;
            }
        }
    }

    Component {
        id: transformDelegate
        Kirigami.AbstractListItem {
            hoverEnabled: false
            ColumnLayout {
                spacing: 0

                QtObject {
                    id: changes

                    readonly property var idChanges: {
                        if (model.transformed) {
                            let changes = Diff.exports.diffSentences(model.original.id, model.transformed.id);
                            if (changes.length > 1) {
                                return changes;
                            }
                        }
                        return null;
                    }
                    readonly property var filePathChanges: {
                        if (model.transformed) {
                            let changes = Diff.exports.diffChars(model.original.filePath, model.transformed.filePath);
                            if (changes.length > 10) {
                                return Diff.exports.diffSentences(model.original.filePath, model.transformed.filePath);
                            }
                            if (changes.length > 1) {
                                return changes;
                            }
                        }
                        return null;
                    }
                    readonly property var tagChanges: {
                        if (model.transformed) {
                            let changes = Diff.exports.diffJson(model.original.metadata.tags, model.transformed.metadata.tags);
                            if (changes.length > 1) {
                                return changes;
                            }
                        }
                        return null;
                    }
                }

                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    text: model.error ? i18n(`Failed to transform source ${model.error.id}: ${model.error.msg}`) : ""
                    type: Kirigami.MessageType.Error
                    visible: !!model.error
                }
                Kirigami.InlineMessage {
                    Layout.fillWidth: true
                    text: model.error || model.transformed ? "" : i18n("No transformed source found")
                    type: Kirigami.MessageType.Warning
                    visible: !model.error && !model.transformed
                }

                Controls.Label {
                    Layout.fillWidth: true
                    text: model.original.id
                    textFormat: Text.RichText
                    visible: !changes.idChanges
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 0
                    color: Kirigami.Theme.negativeBackgroundColor
                    implicitHeight: removedId.implicitHeight
                    visible: !!changes.idChanges
                    Controls.Label {
                        id: removedId
                        anchors.fill: parent
                        text: removedChars(changes.idChanges)
                        wrapMode: "WrapAnywhere"
                        textFormat: Text.RichText
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 0
                    color: Kirigami.Theme.positiveBackgroundColor
                    implicitHeight: addedId.implicitHeight
                    visible: !!changes.idChanges
                    Controls.Label {
                        id: addedId
                        anchors.fill: parent
                        text: addedChars(changes.idChanges)
                        wrapMode: "WrapAnywhere"
                        textFormat: Text.RichText
                    }
                }

                Item {
                    implicitHeight: Kirigami.Units.smallSpacing
                }

                Controls.Label {
                    Layout.fillWidth: true
                    text: model.original.filePath
                    wrapMode: "WrapAnywhere"
                    textFormat: Text.RichText
                    visible: !changes.filePathChanges
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 0
                    color: Kirigami.Theme.negativeBackgroundColor
                    implicitHeight: removedFilePath.implicitHeight
                    visible: !!changes.filePathChanges
                    Controls.Label {
                        id: removedFilePath
                        anchors.fill: parent
                        text: removedChars(changes.filePathChanges)
                        wrapMode: "WrapAnywhere"
                        textFormat: Text.RichText
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 0
                    color: Kirigami.Theme.positiveBackgroundColor
                    implicitHeight: addedFilePath.implicitHeight
                    visible: !!changes.filePathChanges
                    Controls.Label {
                        id: addedFilePath
                        anchors.fill: parent
                        text: addedChars(changes.filePathChanges)
                        wrapMode: "WrapAnywhere"
                        textFormat: Text.RichText
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 0
                    color: Kirigami.Theme.negativeBackgroundColor
                    implicitHeight: removedTags.implicitHeight
                    visible: !!changes.tagChanges
                    Controls.Label {
                        id: removedTags
                        anchors.fill: parent
                        text: removedChars(changes.tagChanges)
                        wrapMode: "WrapAnywhere"
                        textFormat: Text.RichText
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 0
                    color: Kirigami.Theme.positiveBackgroundColor
                    implicitHeight: addedTags.implicitHeight
                    visible: !!changes.tagChanges
                    Controls.Label {
                        id: addedTags
                        anchors.fill: parent
                        text: addedChars(changes.tagChanges)
                        wrapMode: "WrapAnywhere"
                        textFormat: Text.RichText
                    }
                }
            }
        }
    }

    function removedChars(changes) {
        let removed = '';

        if (changes) {
            for (const change of changes) {
                if (change.removed) {
                    removed += `<span style="background-color: ${Kirigami.Theme.negativeTextColor}">${change.value}</span>`;
                } else if (!change.added) {
                    removed += change.value;
                }
            }
        }

        return removed;
    }

    function addedChars(changes) {
        let added = '';

        if (changes) {
            for (const change of changes) {
                if (change.added) {
                    added += `<span style="background-color: ${Kirigami.Theme.positiveTextColor}">${change.value}</span>`;
                } else if (!change.removed) {
                    added += change.value;
                }
            }
        }

        return added;
    }

    function diffJson(a, b) {
        const changes = Diff.exports.diffJson(a, b);
        let removed = '';
        let added = '';

        for (const change of changes) {
            if (change.removed) {
                removed += `<span style="background-color: ${Kirigami.Theme.negativeTextColor}">${change.value}</span>`;
            }
            else if (change.added) {
                added += `<span style="background-color: ${Kirigami.Theme.positiveTextColor}">${change.value}</span>`;
            } else {
                removed += change.value;
                added += change.value;
            }
        }

        if (removed === added) {
            return null;
        }

        return `<span style="background-color: ${Kirigami.Theme.negativeBackgroundColor}">${removed}</span><br/>` +
                `<span style="background-color: ${Kirigami.Theme.positiveBackgroundColor}">${added}</span>`;
    }

    function previewTransform() {
        Backend.exports
            .preview_transform_sources(
                    previewTransformPage.sources,
                    "%album_artist[ (%artist_origin)]/%4original_release_year - %album_title/%02track_number - %track_title"
                 ).then(
                    transformedSources => {
                        previewTransformPage.refreshing = false;
                        console.log(JSON.stringify(transformedSources));
                        transforms.model.source = transformedSources;
                    }).catch(error => {
                        console.error(error);
                        previewTransformPage.refreshing = false;
                        showPassiveNotification(
                            i18n("Failed to preview transformations"), null,
                            i18n("Retry"), () => {
                                previewTransform();
                            });
                    })
    }

    function applyTransform() {
        Backend.exports
            .transform_sources(
                    previewTransformPage.sources,
                    "%album_artist[ (%artist_origin)]/%4original_release_year - %album_title/%02track_number - %track_title"
                 ).then(
                    transformedSources => {
                        previewTransformPage.refreshing = false;
                        previewTransformPage.applying = false;
                        if (transformedSources.find(agg => !!agg.error)) {
                            console.log(JSON.stringify(transformedSources));
                            transforms.model.source = transformedSources;
                        } else {
                            showPassiveNotification(i18n("Successfully transformed sources"));
                            closeDialog();
                        }
                    }).catch(error => {
                        console.error(error);
                        previewTransformPage.applying = false;
                        previewTransformPage.refreshing = false;
                        confirmAction.enabled = false;
                        showPassiveNotification(
                            i18n("Failed to transformation sources"), null,
                            i18n("Retry"), () => {
                                applyTransform();
                            });
                    })
    }
}

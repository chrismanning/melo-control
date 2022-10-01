import QtQuick 2.6
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.2
import org.kde.kirigami 2.20 as Kirigami
import QSyncable 1.0

import "transform"

import "/dist/backend.js" as Backend

Kirigami.ScrollablePage {
    id: sourcesPage

    title: i18nc("@title", "Sources")

    required property string collectionId
    required property string collectionName
    required property string basePath

    contextualActions: [
        Kirigami.Action {
            id: selectAllAction
            text: i18n("Select &All")
            icon.name: "edit-select-all"
            shortcut: StandardKey.SelectAll
            onTriggered: {}
        }
    ]

    Component.onCompleted: {
        sourcesPage.refreshing = true;
    }

    supportsRefreshing: true
    onRefreshingChanged: {
        if (refreshing) {
            loadSourceGroups();
        }
    }

    Kirigami.CardsListView {
        id: sourceGroups
        anchors.fill: parent

        model: JsonListModel {}
        onModelChanged: console.debug("source group model changed")
        delegate: sourceGroupDelegate
    }

    Component {
        id: sourceGroupDelegate
        Controls.ItemDelegate {
            id: sourceGroupCard

            background: Kirigami.ShadowedRectangle {
                property color defaultColor: Kirigami.Theme.backgroundColor
                property int borderWidth: 1
                property color borderColor: Kirigami.ColorUtils.tintWithAlpha(color, Kirigami.Theme.textColor, 0.2)

                color: Kirigami.Theme.backgroundColor
                radius: Kirigami.Units.smallSpacing
                shadow {
                    size: Kirigami.Units.largeSpacing
                    color: Qt.rgba(0, 0, 0, 0.2)
                    yOffset: 2
                }

                border {
                    width: borderWidth
                    color: borderColor
                }
            }

            width: sourceGroups.width - (anchors.leftMargin * 2) - (anchors.rightMargin * 2)
            height: (delegateLayout.columns == 1
                            ? (coverInfoLayout.implicitHeight + groupHeading.implicitHeight)
                            : Math.max(coverInfoLayout.implicitHeight, groupHeading.implicitHeight))
                              + (Kirigami.Units.largeSpacing * 2)

            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.View

            anchors.margins: Kirigami.Units.largeSpacing

            readonly property var currentGroup: model

            GridLayout {
                id: delegateLayout
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                }
                anchors.margins: Kirigami.Units.largeSpacing
                states: [
                    State {
                        name: "single-column"
                        when: delegateLayout.width < Kirigami.Units.gridUnit * 30
                        PropertyChanges {
                            target: delegateLayout
                            columns: 1
                        }
                    },
                    State {
                        name: "double-column"
                        when: delegateLayout.width > Kirigami.Units.gridUnit * 30
                        PropertyChanges {
                            target: delegateLayout
                            columns: 2
                        }
                    }
                ]
                transitions: Transition {
                    PropertyAnimation { properties: "columns"; easing.type: Easing.InOutQuad }
                }

                ColumnLayout {
                    id: coverInfoLayout
                    Layout.columnSpan: 1
                    Layout.alignment: Qt.AlignTop
                    Layout.maximumWidth: 250

                    Item {
                        id: coverPlaceholder
                        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                        width: 250
                        height: 250

                        Image {
                            id: coverImage
                            anchors.fill: parent

                            fillMode: Image.PreserveAspectFit
                            cache: false
                            asynchronous: true
                            mipmap: true
                            source: model.coverImage && model.coverImage.downloadUri ? ("http://localhost:5000" + model.coverImage.downloadUri) : ""
                        }
                        Rectangle {
                            anchors.fill: parent
                            visible: !coverImage.visible || !coverImage.source
                            color: Kirigami.Theme.highlightColor
                        }
                    }

                    Flow {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Kirigami.Units.smallSpacing
                        Repeater {
                            model: currentGroup.groupTags.genre

                            Kirigami.Chip {
                                text: modelData
                                closable: false
                                checkable: false
                            }
                        }
                    }

                    Controls.Label {
                        Layout.alignment: Qt.AlignLeft
                        text: model.sources.length + " tracks"
                    }

                    Controls.Label {
                        Layout.alignment: Qt.AlignLeft
                        text: {
                            let ms = 0.0;
                            for (const source of model.sources) {
                                if (source["length"]) {
                                    ms += source["length"];
                                }
                            }
                            const s = ms / 1000;
                            const totalLength = `${Math.floor(s / 60)}:`+ `${Math.floor(s % 60)}`.padStart(2, '0');
                            return ("Total length: " + totalLength)
                        }
                    }

                    Kirigami.ActionToolBar {
                        alignment: Qt.AlignHCenter
                        actions: [
                            Kirigami.Action {
                                id: transformAction
                                text: i18n("Transform")
                                onTriggered: {
                                    console.log("Transform triggered");
                                    applicationWindow().pageStack.pushDialogLayer("qrc:/src/transform/PreviewTransform.qml", {
                                        'sources': model.sources,
                                    });
                                }
                            },
                            Kirigami.Action {
                                id: deleteAction
                                text: i18n("Delete")
                                icon.name: "edit-delete"
                                onTriggered: {
                                    console.log("Delete triggered");
                                }
                            }
                        ]
                    }
                }

                ColumnLayout {
                    id: groupHeading

                    Layout.columnSpan: 1
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.minimumWidth: 250
                    Layout.preferredWidth: 250
                    Layout.fillWidth: true

                    RowLayout {
                        Kirigami.Heading {
                            id: albumTitle

                            Layout.maximumWidth: delegateLayout.width - ((delegateLayout.columns - 1) * coverInfoLayout.width) - albumDate.width - Kirigami.Units.largeSpacing
                            elide: Text.ElideRight
                            text: model.groupTags.albumTitle || decodeURI(model.groupParentUri.replace('%26', '&').replace('file:', ''))
                            level: 1

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: albumTitle.truncated
                                Controls.ToolTip.visible: albumTitle.truncated && containsMouse
                                Controls.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                                Controls.ToolTip.text: albumTitle.text
                            }
                        }
                        Kirigami.Heading {
                            id: albumDate
                            text: model.groupTags.date ? '(' + model.groupTags.date + ')' : null
                            level: 2
                            color: Kirigami.Theme.disabledTextColor
                        }
                        Item {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            height: 10
                        }
                    }

                    Kirigami.Heading {
                        id: albumArtists
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        level: 1
                        text: {
                            const artists = model.groupTags.albumArtist;
                            let text = '';
                            if (artists) {
                                let i = 0;
                                do {
                                    if (i > 0) {
                                        text += ', ';
                                    }
                                    text += artists[0] ? artists[0] : '-';
                                    i++;
                                } while (i < artists.length - 1);

                                if (i < artists.length) {
                                    text += ' & ' + artists[i];
                                }
                            } else {
                                text = 'unknown artist';
                            }

                            return text;
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: albumArtists.truncated
                            Controls.ToolTip.visible: albumArtists.truncated && containsMouse
                            Controls.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                            Controls.ToolTip.text: albumArtists.text
                        }
                    }

                    Kirigami.Separator {
                        Layout.fillWidth: true
                    }

                    readonly property var groupModel: model
                    Repeater {
                        id: tracks
                        model: parent.groupModel.sources
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        delegate: Kirigami.AbstractListItem {
                            id: trackItem

                            RowLayout {
                                Controls.Label {
                                    id: trackNum
                                    Layout.preferredWidth: 30

                                    text: {
                                        let num = modelData.metadata.mappedTags.trackNumber;
                                        return num ? num.slice(0, Math.max(2, num.length)).padStart(2, '0') : '-';
                                    }
                                }
                                Controls.Label {
                                    id: trackTitle
                                    Layout.alignment: Qt.AlignLeft
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight

                                    text: modelData.metadata.mappedTags.trackTitle || modelData.sourceName

                                    Controls.ToolTip.visible: trackTitle.truncated && trackItem.containsMouse
                                    Controls.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                                    Controls.ToolTip.text: trackTitle.text
                                }
                                Controls.Label {
                                    id: trackLength
                                    Layout.alignment: Qt.AlignRight
                                    color: Kirigami.Theme.disabledTextColor
                                    text: {
                                        const s = modelData["length"] / 1000;
                                        return `${Math.floor(s / 60)}:` + `${Math.floor(s % 60)}`.padStart(2, '0');
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function loadSourceGroups() {
        Backend.exports.get_collection_sources(sourcesPage.collectionId)
            .then(
                response => {
                    sourcesPage.refreshing = false;
                    sourceGroups.model.source = response.library.collections[0].sourceGroups;
                },
                error => {
                    sourcesPage.refreshing = false;
                    showPassiveNotification(i18n("Failed to load sources"), null, i18n("Retry"), () => { loadSourceGroups() });
                }
            );
    }
}

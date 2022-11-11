import QtQuick 2.6
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.2
import org.kde.kirigami 2.20 as Kirigami
import QSyncable 1.0
import app.melo.Config 1.0
import app.melo.StreamHandler 1.0

import "transform"

import "/dist/backend.js" as Backend

Kirigami.ScrollablePage {
    id: sourcesPage

    title: i18nc("@title", "Sources")

    required property string collectionId
    required property string collectionName
    required property string basePath

    actions {
        left: Kirigami.Action {
            id: backAction
            text: i18n("Back")
            icon.name: "draw-arrow-back"
            shortcut: StandardKey.Back
            onTriggered: applicationWindow().pageStack.pop()
        }
    }

    contextualActions: [
        Kirigami.Action {
            id: refreshAction
            text: i18n("Refresh")
            icon.name: "view-refresh"
            shortcut: StandardKey.Refresh
            onTriggered: sourcesPage.refreshing = true;
            enabled: !sourcesPage.refreshing
        }
    ]

    readonly property var serverUrl: Config.server_url
    onServerUrlChanged: {
        Backend.exports.config.server_url = `${serverUrl}`;
    }

    Component.onCompleted: {
        sourcesPage.refreshing = true;
    }

    supportsRefreshing: true
    onRefreshingChanged: {
        if (refreshing) {
            sourceGroups.model.clear();
            stream_handler.start_stream();
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
                            ? (coverInfoLayout.childrenRect.height + groupHeading.childrenRect.height)
                            : Math.max(coverInfoLayout.childrenRect.height, groupHeading.childrenRect.height))
                              + (Kirigami.Units.largeSpacing * 2)

            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.View

            anchors.margins: Kirigami.Units.largeSpacing

            readonly property var currentGroup: model
            readonly property var groupTags: Backend.exports.groupTags(currentGroup.groupTags)

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
                            source: model.coverImage && model.coverImage.downloadUri ? `${Config.server_url + model.coverImage.downloadUri}` : ""
                        }
                        Rectangle {
                            anchors.fill: parent
                            visible: !coverImage.visible || !coverImage.source
                            color: Kirigami.Theme.highlightColor
                        }
                    }

                    Flow {
                        Layout.alignment: Qt.AlignHCenter
                        width: coverPlaceholder.width
                        spacing: Kirigami.Units.smallSpacing
                        Repeater {
                            model: groupTags.genre

                            Kirigami.Chip {
                                text: modelData
                                closable: false
                                checkable: false
                            }
                        }
                    }

                    Controls.Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: model.sources.length + " tracks"
                    }

                    Controls.Label {
                        Layout.alignment: Qt.AlignHCenter
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
                                    applicationWindow().pageStack.pushDialogLayer("qrc:/ui/transform/PreviewTransform.qml", {
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
                            text: groupTags.albumTitle || decodeURI(model.groupParentUri.replace('%26', '&').replace('file:', ''))
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
                            text: groupTags.year ? '(' + groupTags.year + ')' : null
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
                            const artists = groupTags.albumArtist;
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

                            readonly property var mappedTags: Backend.exports.trackTags(modelData.metadata.mappedTags)

                            RowLayout {
                                Controls.Label {
                                    id: trackNum
                                    Layout.preferredWidth: 30

                                    text: {
                                        let num = mappedTags.trackNumber;
                                        let disc = groupTags.discNumber;
                                        let totalDiscs = groupTags.totalDiscs;
                                        let txt = '-';
                                        if (num) {
                                            txt = num.slice(0, Math.max(2, num.length)).padStart(2, '0');
                                            if (disc && !totalDiscs && disc.indexOf('/') > -1) {
                                                let terms = disc.split('/');
                                                if (terms.length > 1) {
                                                    totalDiscs = terms[1];
                                                    disc = terms[0];
                                                }
                                            }

                                            if (disc && (!totalDiscs || parseInt(totalDiscs) > 1)) {
                                                txt = disc.slice(-1) + '.' + txt;
                                            }
                                        }
                                        return txt;
                                    }
                                }
                                Controls.Label {
                                    id: trackTitle
                                    Layout.alignment: Qt.AlignLeft
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight

                                    text: mappedTags.trackTitle || modelData.sourceName

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

    StreamHandler {
        id: stream_handler
        url: `${Config.server_url}/collection/${sourcesPage.collectionId}/source_groups?groupByMappings=album_artist,album_title,year,disc_number,total_discs,genre`
        request_body: `query GetCollectionSources {
                            sourceGroup {
                                groupParentUri
                                coverImage {
                                    ... on ExternalImage {
                #                        desc: fileName
                                        downloadUri
                                    }
                                    ... on EmbeddedImage {
                #                        desc: imageType
                                        downloadUri
                                    }
                                }
                                groupTags {
                                    mappingName
                                    values
                                }
                                sources {
                                    id
                                    downloadUri
                                    format
                                    sourceName
                                    filePath
                                    length
                                    metadata {
                                        format
                                        mappedTags(mappings: ["track_number", "track_title", "artist"]) {
                                            mappingName
                                            values
                                        }
                                    }
                                }
                            }
                    }`
        onText_chunk_received: {
            try {
                var res = JSON.parse(chunk);
                if (res.data && res.data.sourceGroup){
                    sourceGroups.model.append(res.data.sourceGroup);
                }
            } catch(e) {
                console.error(`${e}`);
                console.error(`chunk: ${chunk}`);
            }
        }
        onRefreshing_changed: sourcesPage.refreshing = refreshing
    }
}

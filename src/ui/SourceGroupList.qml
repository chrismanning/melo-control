import QtQuick 2.6
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.2
import org.kde.kirigami 2.20 as Kirigami

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
//            width: sourceGroups.width - anchors.leftMargin - anchors.rightMargin
//            implicitWidth: Math.max(background.implicitWidth, delegateLayout.implicitWidth) + (Kirigami.Units.largeSpacing * 2)

            implicitHeight: Math.max(coverInfoLayout.implicitHeight, Math.max(background.implicitHeight, delegateLayout.implicitHeight)) + (Kirigami.Units.largeSpacing * 2)

            Kirigami.Theme.inherit: false
            Kirigami.Theme.colorSet: Kirigami.Theme.View

            anchors.margins: Kirigami.Units.largeSpacing

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

                    Item {
                        id: coverPlaceholder
                        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                        Layout.maximumWidth: 250
                        Layout.preferredWidth: 250
                        Layout.preferredHeight: 250

                        Image {
                            id: coverImage
                            anchors.fill: parent

                            fillMode: Image.PreserveAspectFit
                            cache: false
                            asynchronous: true
                            source: modelData.coverImage && modelData.coverImage.downloadUri ? ("http://localhost:5000" + modelData.coverImage.downloadUri) : ""
                        }
                        Rectangle {
                            anchors.fill: parent
                            visible: !coverImage.visible || !coverImage.source
                            color: Kirigami.Theme.highlightColor
                        }
                    }

                    Controls.Label {
                        Layout.alignment: Qt.AlignLeft
                        text: modelData.sources.length + " tracks"
                    }

                    Controls.Label {
                        Layout.alignment: Qt.AlignLeft
                        text: {
                            let totalLength = 0;
                            for (let source in modelData.sources) {
                                totalLength += source.length;
                            }
                            return ("Total length: " + totalLength).replace(".", ":")
                        }
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

                            Layout.maximumWidth: delegateLayout.width - ((delegateLayout.columns - 1) * coverPlaceholder.width) - albumDate.width - Kirigami.Units.largeSpacing
                            elide: Text.ElideRight
                            text: modelData.groupTags.albumTitle
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
                            text: '(' + modelData.groupTags.date + ')'
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
                            const artists = modelData.groupTags.albumArtist;
                            let text = '';
                            let i = 0;
                            do {
                                if (i > 0) {
                                    text += ', '
                                }
                                text += artists[0]
                                i++;
                            } while (i < artists.length - 1);

                            if (i < artists.length) {
                                text += ' & ' + artists[i]
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

                    Repeater {
                        id: tracks
                        model: modelData.sources
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
                                        return num.slice(0, Math.max(2, num.length)).padStart(2, '0');
                                    }
                                }
                                Controls.Label {
                                    id: trackTitle
                                    Layout.alignment: Qt.AlignLeft
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight

                                    text: modelData.metadata.mappedTags.trackTitle

                                    Controls.ToolTip.visible: trackTitle.truncated && trackItem.containsMouse
                                    Controls.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                                    Controls.ToolTip.text: trackTitle.text
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
                    sourceGroups.model = response.library.collections[0].sourceGroups;
                },
                error => {
                    sourcesPage.refreshing = false;
                    showPassiveNotification(i18n("Failed to load collections"), null, i18n("Retry"), () => { loadCollections() });
                }
            );
    }
}

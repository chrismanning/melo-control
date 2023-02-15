import QtQuick 2.15
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import QSyncable 1.0
import app.melo.Config 1.0

import "."

Kirigami.Page {
    id: editGroupTagsPage

    required property var groupMappedTags
    required property var groupTags

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

    signal accepted(var groupMappedTags, var groupTags)

    function accept() {
        groupMappedTags.albumArtist = albumArtist.text.split("\n").filter(g => g);
        if (albumTitle.text) {
            groupMappedTags.albumTitle = albumTitle.text;
        } else {
            groupMappedTags.albumTitle = null;
        }
        if (releaseYear.text) {
            groupMappedTags.year = releaseYear.text;
        } else {
            groupMappedTags.year = null;
        }
        if (discNumber.text) {
            groupMappedTags.discNumber = discNumber.text;
        } else {
            groupMappedTags.discNumber = null;
        }
        groupMappedTags.genre = genre.text.split("\n").filter(g => g);

        if (advancedSwitch.checked) {
            accepted(null, advancedTagsModel.source.map(s => {return {key: s.key, value: s.value};}));
        } else {
            accepted(groupMappedTags, null);
        }
    }

    onGroupMappedTagsChanged: {
        if (!groupMappedTags) {
            return;
        }
        if (groupMappedTags.albumArtist) {
            albumArtist.text = groupMappedTags.albumArtist.join("\n");
        } else {
            albumArtist.clear();
        }
        if (groupMappedTags.albumTitle) {
            albumTitle.text = groupMappedTags.albumTitle;
        } else {
            albumTitle.clear();
        }
        if (groupMappedTags.year) {
            releaseYear.text = groupMappedTags.year;
        } else {
            releaseYear.clear();
        }
        if (groupMappedTags.genre) {
            genre.text = groupMappedTags.genre.join("\n");
        } else {
            genre.clear();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        Controls.Switch {
            id: advancedSwitch
            text: i18n("Advanced")
            checked: false
        }

        StackLayout {
            currentIndex: advancedSwitch.checked ? 1 : 0

            Kirigami.FormLayout {
                id: simpleForm
                Controls.TextArea {
                    id: albumArtist
                    Kirigami.FormData.label: i18n("Album Artist")
                    placeholderText: i18n("Input multiple artists on separate lines")
                    KeyNavigation.priority: KeyNavigation.BeforeItem
                    KeyNavigation.backtab: genre
                    KeyNavigation.tab: albumTitle
                }
                Controls.TextField {
                    id: albumTitle
                    Kirigami.FormData.label: i18n("Album Title")
                }
                Controls.TextField {
                    id: releaseYear
                    Kirigami.FormData.label: i18n("Year")
                }
                Controls.TextField {
                    id: discNumber
                    Kirigami.FormData.label: i18n("Disc Number")
                }
                Controls.TextArea {
                    id: genre
                    Kirigami.FormData.label: i18n("Genre(s)")
                    placeholderText: i18n("Input multiple genres on separate lines")
                    KeyNavigation.priority: KeyNavigation.BeforeItem
                    KeyNavigation.backtab: discNumber
                    KeyNavigation.tab: albumArtist
                }
            }

            Controls.ScrollView {
                Kirigami.FormLayout {
                    Repeater {
                        model: JsonListModel {
                            id: advancedTagsModel
                            keyField: "idx"
                            fields: [
                                "idx",
                                "key",
                                "value"
                            ]
                            source: editGroupTagsPage.groupTags
                        }

                        delegate: Kirigami.AbstractListItem {
                            contentItem: RowLayout {
                                Controls.Label {
                                    id: keyLabel
                                    Layout.fillWidth: true
                                    text: model.key
                                    elide: "ElideRight"
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: keyLabel.truncated
                                        Controls.ToolTip.visible: keyLabel.truncated && containsMouse
                                        Controls.ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                                        Controls.ToolTip.text: keyLabel.text
                                    }
                                }

                                Controls.TextField {
                                    width: 250
                                    Kirigami.FormData.label: model.key
                                    text: model.value
                                }

                                Controls.ToolButton {
                                    icon.name: "tag-delete"
                                    onClicked: {
                                        editGroupTagsPage.groupTags = editGroupTagsPage.groupTags.filter(t => t.idx !== model.idx);
                                        advancedTagsModel.source = editGroupTagsPage.groupTags;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.2
import org.kde.kirigami 2.20 as Kirigami
import QSyncable 1.0
import app.melo.Config 1.0

import "."

import "/dist/backend.js" as Backend
import "/dist/diff.js" as Diff

Kirigami.ScrollablePage {
    id: editGroupTagsPage

    property var groupTags

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

    signal accepted(var groupTags)

    function accept() {
        groupTags.albumArtist = albumArtist.text.split("\n").filter(g => g);
        if (albumTitle.text) {
            groupTags.albumTitle = albumTitle.text;
        } else {
            groupTags.albumTitle = null;
        }
        if (releaseYear.text) {
            groupTags.year = releaseYear.text;
        } else {
            groupTags.year = null;
        }
        if (discNumber.text) {
            groupTags.discNumber = discNumber.text;
        } else {
            groupTags.discNumber = null;
        }
        groupTags.genre = genre.text.split("\n").filter(g => g);

        accepted(groupTags);
    }

    onGroupTagsChanged: {
        if (!groupTags) {
            return;
        }
        if (groupTags.albumArtist) {
            albumArtist.text = groupTags.albumArtist.join("\n");
        } else {
            albumArtist.clear();
        }
        if (groupTags.albumTitle) {
            albumTitle.text = groupTags.albumTitle;
        } else {
            albumTitle.clear();
        }
        if (groupTags.year) {
            releaseYear.text = groupTags.year;
        } else {
            releaseYear.clear();
        }
        if (groupTags.genre) {
            genre.text = groupTags.genre.join("\n");
        } else {
            genre.clear();
        }
    }

    Kirigami.FormLayout {
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
}

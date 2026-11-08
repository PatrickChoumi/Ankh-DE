/***************************************************************************
 *   SPDX-License-Identifier: GPL-3.0-or-later
 *
 *   Champ de recherche du menu Démarrer — id : ankh-de-recherche
 *
 *   Réduit du BottomBar.qml de KDE-Windows-Modern (GPL-3.0, commit 7ef6bfe)
 *   au seul champ de recherche : le bouton d'alimentation est parti dans
 *   PowerButton.qml, parce que Windows 11 met la recherche EN HAUT du menu
 *   et l'alimentation en bas à droite.
 *
 *   LE NOM DU FICHIER, L'ID « bottomBarContent », L'ALIAS « searchText » ET
 *   LA FONCTION « focusSearch() » NE CHANGENT PAS. pages/SearchPage.qml,
 *   que nous ne remplaçons pas, les atteint par leur nom (ses lignes 160 et
 *   403), tout comme le corps du menu à six endroits. Les renommer pour
 *   « searchBar », qui se lirait mieux, casserait la recherche.
 *
 *   Un seul retrait de plus, et il compte : « width: parent.width ». L'amont
 *   pouvait se le permettre, son instance était ancrée. Dans un
 *   ColumnLayout, cette liaison se bat avec la disposition à chaque image.
 *   « Layout.fillWidth » sur le champ suffit.
 ***************************************************************************/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

import "../code/theme.js" as Theme

RowLayout {
    id: bottomBar

    spacing: Kirigami.Units.largeSpacing

    property alias searchText: searchFieldInput.text

    signal searchFocusResults
    signal searchNavUp
    signal searchNavDown
    signal searchActivateFirstResult
    signal searchEscapePressed
    signal tabOut

    function focusSearch() {
        searchFieldInput.forceActiveFocus();
    }

    Keys.onTabPressed: event => {
        event.accepted = true;
        tabOut();
    }


    // ── Search field (fills) ───────────────────────────────────────────
    PlasmaComponents3.TextField {
        id: searchFieldInput
        Layout.fillWidth: true
        focus: true
        placeholderText: i18n("Search for apps, settings, and documents")
        topPadding: 8
        bottomPadding: 8
        leftPadding: Kirigami.Units.gridUnit + Kirigami.Units.iconSizes.small
        font.pointSize: Kirigami.Theme.defaultFont.pointSize

        background: Rectangle {
            color: Kirigami.Theme.backgroundColor
            radius: Kirigami.Units.smallSpacing * 3
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                                   Kirigami.Theme.textColor.g,
                                   Kirigami.Theme.textColor.b, Theme.fieldBorderOpacity)
            Behavior on border.color { ColorAnimation { duration: 100 } }
        }

        onTextChanged: bottomBar.searchTextChanged(text)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                event.accepted = true;
                bottomBar.searchEscapePressed();
                return;
            }
            if (event.key === Qt.Key_Down) {
                event.accepted = true;
                bottomBar.searchNavDown();
                return;
            }
            if (event.key === Qt.Key_Up) {
                event.accepted = true;
                bottomBar.searchNavUp();
                return;
            }
            if (event.key === Qt.Key_Tab) {
                event.accepted = true;
                bottomBar.searchFocusResults();
                return;
            }
        }
        Keys.onReturnPressed: bottomBar.searchActivateFirstResult()

        Kirigami.Icon {
            source: "search"
            anchors.left: searchFieldInput.left
            anchors.verticalCenter: searchFieldInput.verticalCenter
            anchors.leftMargin: Kirigami.Units.smallSpacing * 2
            height: Kirigami.Units.iconSizes.small
            width: height
        }
    }
}

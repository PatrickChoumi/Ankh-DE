/***************************************************************************
 *   SPDX-License-Identifier: GPL-3.0-or-later
 *
 *   Page « Épinglées » d'Ankh DE — la GRILLE de Windows 11.
 *
 *   Remplace la page de KDE-Windows-Modern (GPL-3.0, commit 7ef6bfe), qui
 *   dessinait une LISTE verticale : c'est la disposition de Windows 7, pas
 *   celle de Windows 11. Le constat vient d'une capture de session réelle
 *   du 2026-11-08, pas d'une impression.
 *
 *   Ce qu'on garde de l'amont, intact : le modèle (favoris de Kicker), le
 *   lancement par « model.trigger(index, "", null) », et l'API de cette
 *   page — mêmes signaux, mêmes fonctions — pour que MenuRepresentation
 *   n'ait rien à savoir du changement.
 *
 *   Ce qu'on change : ListView -> GridView à 6 colonnes, icône de 32 px
 *   au-dessus du libellé, libellé centré sur deux lignes.
 *
 *   Les mesures viennent de sources publiées, jamais d'un fichier de
 *   Microsoft (DE-005) :
 *     - 6 colonnes sur 3 rangées pour les épingles, sur un écran 1080p ;
 *     - icône de 32 px à l'échelle 100 % (40 à 125 %, 48 à 150 %), d'après
 *       la page « Construct your Windows App's Icon » de Microsoft Learn.
 *       Kirigami.Units.iconSizes.medium vaut 32 et suit l'échelle : on
 *       prend donc la valeur de Kirigami plutôt qu'un 32 écrit en dur.
 ***************************************************************************/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

import "../components"

ColumnLayout {
    id: pinnedPage

    spacing: Kirigami.Units.largeSpacing

    // L'amont expose la vue sous ce nom et MenuRepresentation lui pose son
    // modèle (« pinnedPage.favoritesList.model = globalFavorites »). Le nom
    // reste, la vue change de nature.
    property alias favoritesList: favoritesGrid

    // Nombre de colonnes. Réglable, et à 6 par défaut comme Windows 11 —
    // c'est déjà la valeur par défaut de « numberColumns » dans le
    // main.xml de l'amont, qui ne s'en servait pas pour cette page.
    readonly property int colonnes: Math.max(1, Plasmoid.configuration.numberColumns || 6)

    signal showAllAppsRequested
    signal keyNavUpFromList

    function tryActivate(row) {
        if (favoritesGrid.count > 0) {
            favoritesGrid.currentIndex = Math.min(row, favoritesGrid.count - 1);
        }
    }

    // Dans une grille, « haut » et « bas » se déplacent d'une RANGÉE, donc
    // du nombre de colonnes — et non d'un cran comme dans une liste.
    function navigateUp() {
        if (favoritesGrid.count <= 0) {
            return;
        }
        if (favoritesGrid.currentIndex - pinnedPage.colonnes < 0) {
            pinnedPage.keyNavUpFromList();
            return;
        }
        favoritesGrid.currentIndex -= pinnedPage.colonnes;
    }

    function navigateDown() {
        if (favoritesGrid.count <= 0) {
            return;
        }
        favoritesGrid.currentIndex = Math.min(favoritesGrid.count - 1,
                                              favoritesGrid.currentIndex + pinnedPage.colonnes);
    }

    function navigateLeft() {
        if (favoritesGrid.count > 0) {
            favoritesGrid.currentIndex = Math.max(0, favoritesGrid.currentIndex - 1);
        }
    }

    function navigateRight() {
        if (favoritesGrid.count > 0) {
            favoritesGrid.currentIndex = Math.min(favoritesGrid.count - 1,
                                                  favoritesGrid.currentIndex + 1);
        }
    }

    function activateCurrent() {
        if (favoritesGrid.currentIndex >= 0 && favoritesGrid.model) {
            favoritesGrid.model.trigger(favoritesGrid.currentIndex, "", null);
            root.closeMenu();
        }
    }

    // ── En-tête : « Épinglées » … « Toutes les applications > » ──────────
    RowLayout {
        id: headerRow
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.Label {
            text: i18n("Pinned")
            color: Kirigami.Theme.textColor
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.95
            font.weight: Font.DemiBold
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        AToolButton {
            buttonHeight: 25
            flat: true
            iconName: "go-next"
            text: i18n("All apps")
            Layout.rightMargin: Kirigami.Units.mediumSpacing
            onClicked: pinnedPage.showAllAppsRequested()
        }
    }

    // ── La grille des épingles ──────────────────────────────────────────
    GridView {
        id: favoritesGrid
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        interactive: true
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: -1
        focus: true

        // Une case par application : l'icône, puis deux lignes de libellé.
        cellWidth: Math.floor(width / pinnedPage.colonnes)
        cellHeight: Math.round(Kirigami.Units.gridUnit * 5.5)

        PlasmaComponents3.ScrollBar.vertical: PlasmaComponents3.ScrollBar {
            policy: PlasmaComponents3.ScrollBar.AsNeeded
        }

        highlightMoveDuration: 0

        delegate: Item {
            id: caseEpingle
            width: favoritesGrid.cellWidth
            height: favoritesGrid.cellHeight
            enabled: model.disabled !== undefined ? !model.disabled : true

            readonly property bool actif: favoritesGrid.currentIndex === index
            readonly property string libelle: ("name" in model && model.name !== undefined)
                ? model.name
                : (model.display !== undefined ? model.display : "")

            Accessible.role: Accessible.Button
            Accessible.name: caseEpingle.libelle

            Rectangle {
                id: fond
                anchors.fill: parent
                anchors.margins: Math.round(Kirigami.Units.smallSpacing / 2)
                radius: Kirigami.Units.cornerRadius !== undefined
                    ? Kirigami.Units.cornerRadius
                    : 4
                color: Kirigami.Theme.textColor
                opacity: caseEpingle.actif ? 0.14 : (souris.containsMouse ? 0.08 : 0)
                Behavior on opacity {
                    NumberAnimation { duration: Kirigami.Units.shortDuration }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    // 32 px à 100 % : la mesure de Windows 11, portée par
                    // Kirigami pour qu'elle suive les échelles 125 et 150 %.
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    source: model.decoration !== undefined ? model.decoration : ""
                    animated: false
                }

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: caseEpingle.libelle
                    color: Kirigami.Theme.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignTop
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                }
            }

            MouseArea {
                id: souris
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                onEntered: favoritesGrid.currentIndex = index
                onClicked: {
                    if (favoritesGrid.model
                            && typeof favoritesGrid.model.trigger === "function") {
                        favoritesGrid.model.trigger(index, "", null);
                        root.closeMenu();
                    }
                }
            }
        }

        // La première rangée rend le clavier à la recherche, qui est
        // au-dessus d'elle.
        Keys.onUpPressed: event => {
            event.accepted = true;
            pinnedPage.navigateUp();
        }
        Keys.onDownPressed: event => {
            event.accepted = true;
            pinnedPage.navigateDown();
        }
        Keys.onLeftPressed: event => {
            event.accepted = true;
            pinnedPage.navigateLeft();
        }
        Keys.onRightPressed: event => {
            event.accepted = true;
            pinnedPage.navigateRight();
        }
        Keys.onReturnPressed: event => {
            event.accepted = true;
            pinnedPage.activateCurrent();
        }
        Keys.onEnterPressed: event => {
            event.accepted = true;
            pinnedPage.activateCurrent();
        }
    }
}

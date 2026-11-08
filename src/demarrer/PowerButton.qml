/***************************************************************************
 *   SPDX-License-Identifier: GPL-3.0-or-later
 *
 *   Bouton d'alimentation d'Ankh DE — id : ankh-de-alimentation
 *
 *   Extrait TEL QUEL du BottomBar.qml de KDE-Windows-Modern (GPL-3.0,
 *   commit 7ef6bfe), où il partageait une seule rangée avec le champ de
 *   recherche. Windows 11 met la recherche EN HAUT et l'alimentation en bas
 *   à droite : les deux moitiés partent à des endroits opposés de la
 *   fenêtre, et un composant ne peut pas être à deux places.
 *
 *   Copié, pas retapé, et c'est délibéré : tout ce bloc tient sur une seule
 *   MouseArea dont l'abscisse décide entre « éteindre » et « ouvrir le
 *   menu », avec chevronWidth recalculé au moment du clic. C'est là qu'un
 *   « > » devient un « >= » quand on recopie à la main.
 *
 *   Trois changements, aucun dans la logique : l'identifiant devient
 *   « powerButton », il porte lui-même ses deux signaux, et le
 *   Layout.alignment est posé au point d'emploi.
 ***************************************************************************/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

import "../code/theme.js" as Theme

Item {
    id: powerButton

    signal menuRequested
    signal shutdownRequested
    implicitWidth: splitRow.implicitWidth + Kirigami.Units.largeSpacing * 2
    implicitHeight: Math.floor(Kirigami.Units.gridUnit * 1.6)

    Rectangle {
        id: splitBg
        anchors.fill: parent
        radius: Kirigami.Units.smallSpacing
        color: splitMouse.containsMouse
               ? Qt.rgba(Kirigami.Theme.textColor.r,
                         Kirigami.Theme.textColor.g,
                         Kirigami.Theme.textColor.b, Theme.buttonFlatHoverOpacity)
               : Qt.rgba(Kirigami.Theme.textColor.r,
                         Kirigami.Theme.textColor.g,
                         Kirigami.Theme.textColor.b, Theme.buttonFlatBackgroundOpacity)
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                               Kirigami.Theme.textColor.g,
                               Kirigami.Theme.textColor.b, Theme.buttonBorderOpacity)
        Behavior on color { ColorAnimation { duration: 90 } }
    }

    Row {
        id: splitRow
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            anchors.verticalCenter: parent.verticalCenter
            width: Kirigami.Units.iconSizes.smallMedium
            height: width
            source: "system-shutdown"
        }

        PlasmaComponents3.Label {
            id: shutdownLabel
            anchors.verticalCenter: parent.verticalCenter
            text: i18n("Shut down")
            color: Kirigami.Theme.textColor
            font.pointSize: Kirigami.Theme.defaultFont.pointSize - 1
        }

        // Subtle divider between the two zones.
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: shutdownSplit.height * 0.5
            color: Qt.rgba(Kirigami.Theme.textColor.r,
                           Kirigami.Theme.textColor.g,
                           Kirigami.Theme.textColor.b, Theme.buttonDividerOpacity)
        }

        Kirigami.Icon {
            anchors.verticalCenter: parent.verticalCenter
            width: Kirigami.Units.iconSizes.small
            height: width
            source: "go-next"
            opacity: Theme.buttonChevronOpacity
        }
    }

    // Single MouseArea: hover for the whole button; click position
    // decides whether to shut down (left) or open the menu (right).
    MouseArea {
        id: splitMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            // Chevron zone = rightmost portion (icon + padding).
            var chevronWidth = Kirigami.Units.iconSizes.small + Kirigami.Units.smallSpacing * 2;
            if (mouse.x > powerButton.width - chevronWidth) {
                powerButton.menuRequested();
            } else {
                powerButton.shutdownRequested();
            }
        }
    }
}

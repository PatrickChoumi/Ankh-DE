/*
 * Écran de chargement d'Ankh DE.
 *
 * Dérivé de celui de Breeze (lookandfeel/contents/splash/Splash.qml de
 * plasma-workspace, LGPL-2.0-or-later) : même structure, mêmes étapes,
 * couleurs et mouvement d'Ankh.
 *
 * KSplashQML pose « stage » de 1 à 6 au fil du démarrage. Rien ici ne doit
 * bloquer : un écran de chargement qui plante retarde l'ouverture de la
 * session.
 *
 * Couleurs : le fond de fenêtre d'Ankh (28,32,39) et le violet du logo
 * (#a78bfa), comme src/colors/Ankh.colors. Durées : 333 ms, celle de
 * Windows 11 (page signature-experiences/motion de Microsoft).
 */
import QtQuick

Rectangle {
    id: root
    color: "#1c2027"

    property int stage

    onStageChanged: {
        if (stage === 2) {
            introAnimation.running = true
        }
    }

    // Le nom du système, au centre, comme le logo de Windows 11 au démarrage.
    Item {
        id: contenu
        anchors.centerIn: parent
        width: parent.width
        height: titre.height + barre.height + 48
        opacity: 0

        Text {
            id: titre
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            text: "Ankh"
            color: "#e6edf3"
            // 40 px : la taille « Title » de WinUI
            // (CommonStyles/TextBlock_themeresources.xaml).
            font.pixelSize: 40
            font.weight: Font.DemiBold
            font.family: "Selawik"
            renderType: Text.NativeRendering
        }

        // Barre de progression de 3 px, l'épaisseur de Windows 11
        // (ProgressBarMinHeight de WinUI), large de 160 px.
        Rectangle {
            id: barre
            anchors.horizontalCenter: parent.horizontalCenter
            y: titre.height + 48
            width: 160
            height: 3
            radius: 1.5
            color: "#2b303a"

            Rectangle {
                id: avancement
                height: parent.height
                radius: parent.radius
                color: "#a78bfa"
                // Six étapes : la barre suit le démarrage réel plutôt
                // qu'une animation décorative.
                width: parent.width * Math.min(root.stage, 6) / 6

                Behavior on width {
                    NumberAnimation {
                        duration: 333
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    // Apparition douce, comme le démarrage de Windows 11.
    NumberAnimation {
        id: introAnimation
        running: false
        target: contenu
        property: "opacity"
        from: 0
        to: 1
        duration: 333
        easing.type: Easing.InOutQuad
    }
}

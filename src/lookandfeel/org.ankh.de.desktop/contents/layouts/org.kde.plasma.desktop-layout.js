// Barre des tâches d'Ankh DE : celle de Windows 11 (DE-003, lot 4).
//
// Adapté du modèle de KDE (layout-templates/org.kde.plasma.desktop.defaultPanel
// de https://invent.kde.org/plasma/plasma-desktop, LGPL-2.0-or-later).
// Différences avec le modèle, toutes mesurées sur Windows 11 :
//   - collée en bas, pleine largeur (le modèle de KDE est flottant depuis
//     Plasma 6.0, et Ankh l'était aussi avant D-052) ;
//   - 48 px de haut (le modèle : 2,5 unités de grille, soit 44 px) ;
//   - Démarrer et les applications au centre, par deux espaceurs ;
//   - zone de notification, horloge sur deux lignes et « Afficher le
//     bureau » à droite ;
//   - le sélecteur de bureaux virtuels est retiré (Windows 11 ne l'affiche
//     pas dans la barre).
// Le trait d'accent sous l'application active (16×3) vient du style Plasma
// « ankh » (src/desktoptheme), pas d'ici.

var panel = new Panel
var panelScreen = panel.screen

// 48 px à l'échelle 100 %. gridUnit vaut 18 avec la police par défaut de
// Plasma : le rapport garde les 48 px quand la police grandit.
panel.height = 2 * Math.round(48 * (gridUnit / 18) / 2)
panel.location = "bottom"
// Collée, pleine largeur : la barre de Windows 11 n'est pas flottante.
panel.floating = false
panel.alignment = "center"
panel.lengthMode = "fill"
// Toujours en verre, même sous une fenêtre agrandie. Plasma la rendrait
// opaque dans ce cas (« adaptive », PanelView::OpacityMode de
// shell/panelview.h, plasma-workspace).
panel.opacity = "translucent"
panel.hiding = "none"

// Deux espaceurs extensibles centrent ce qui est entre eux
// (optimalSize de applets/panelspacer/main.qml, plasma-workspace).
panel.addWidget("org.kde.plasma.panelspacer")

// Nos applets quand ils sont installés, ceux de Plasma sinon : le fichier
// doit marcher même sur une installation partielle.
function ajouter(notre, celuiDePlasma) {
    try {
        return panel.addWidget(notre)
    } catch (e) {
        return panel.addWidget(celuiDePlasma)
    }
}

// Démarrer : le nôtre (DE-011, repris de KDE-Windows-Modern), sinon Kickoff.
ajouter("org.ankh.demarrer", "org.kde.plasma.kickoff")

// Applications épinglées : seulement celles que toute installation de KDE
// possède, et les applications par défaut du système (preferred://,
// applets/taskmanager/main.xml de plasma-desktop). Ankh DE n'épingle rien
// qui lui soit propre : c'est à la distribution ou à l'utilisateur de le
// faire.
var epinglees = ["preferred://filemanager", "preferred://browser"]
var terminal = ["org.kde.konsole.desktop", "org.kde.yakuake.desktop"]
for (var i = 0; i < terminal.length; i++) {
    if (applicationExists(terminal[i])) {
        epinglees.push("applications:" + terminal[i])
        break
    }
}
if (applicationExists("systemsettings.desktop")) {
    epinglees.push("applications:systemsettings.desktop")
}
// icontasks : des icônes seules, sans texte, comme Windows 11.
var taches = panel.addWidget("org.kde.plasma.icontasks")
taches.currentConfigGroup = ["General"]
taches.writeConfig("launchers", epinglees)
// Les 8 px autour de chaque icône (valeur relevée sur AnduinOS) se règlent
// au lot 4, dans le style Plasma : la clé « iconSpacing » d'icontasks est
// une énumération, pas des pixels. Rien n'est écrit ici tant que ce n'est
// pas mesuré par le banc.

panel.addWidget("org.kde.plasma.panelspacer")

// Méthode de saisie pour les langues qui en ont besoin, comme dans le
// modèle de KDE.
var langIds = ["as", "bn", "bo", "brx", "doi", "gu", "hi", "ja", "kn", "ko",
               "kok", "ks", "lep", "mai", "ml", "mni", "mr", "ne", "or", "pa",
               "sa", "sat", "sd", "si", "ta", "te", "th", "ur", "vi", "zh_CN",
               "zh_TW"]
if (langIds.indexOf(languageId) != -1) {
    panel.addWidget("org.kde.plasma.kimpanel")
}

// Zone de notification : icônes à 16 px, comme Windows 11.
panel.addWidget("org.kde.plasma.systemtray")

// Horloge : la nôtre dispose déjà l'heure au-dessus de la date, comme
// Windows 11. Avec celle de Plasma, on s'en approche par ses réglages —
// « BesideTime » met la date À CÔTÉ de l'heure, et c'est le mieux que son
// schéma propose (à revérifier dans applets/digitalclock/…/main.xml).
var horloge = ajouter("org.ankh.horloge", "org.kde.plasma.digitalclock")
if (horloge.type === "org.kde.plasma.digitalclock") {
    horloge.currentConfigGroup = ["Appearance"]
    horloge.writeConfig("dateDisplayFormat", "BesideTime")
    horloge.writeConfig("showSeconds", "Never")
}

// Bande « Afficher le bureau » au coin droit, comme Windows 11.
ajouter("org.ankh.bureau", "org.kde.plasma.showdesktop")

// Fond d'écran : le module d'images, pour que l'accent suive le fond
// (DE-004).
var bureaux = desktopsForActivity(currentActivity())
for (var j = 0; j < bureaux.length; j++) {
    bureaux[j].wallpaperPlugin = "org.kde.image"
}

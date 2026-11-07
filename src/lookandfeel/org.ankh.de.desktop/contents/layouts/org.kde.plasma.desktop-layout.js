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
// Ajoute notre applet, ou celui de Plasma s'il n'est pas installé — et le
// DIT. Au premier passage en VM, le repli était muet : la barre portait
// Kickoff, la capture montrait notre icône (venue du thème), et on a cru
// que notre menu était là. Un repli silencieux est un mensonge.
function ajouter(notre, celuiDePlasma) {
    var w = null
    try {
        w = panel.addWidget(notre)
    } catch (e) {
        w = null
    }
    // addWidget ne lève pas toujours : il peut rendre un applet de
    // remplacement. On vérifie ce qu'on a réellement obtenu.
    if (w && w.type === notre) {
        print("ANKH-LAYOUT " + notre + " : installé")
        return w
    }
    if (w) {
        print("ANKH-LAYOUT " + notre + " : absent (obtenu « " + w.type + " »), repli sur " + celuiDePlasma)
        w.remove()
    } else {
        print("ANKH-LAYOUT " + notre + " : absent, repli sur " + celuiDePlasma)
    }
    return panel.addWidget(celuiDePlasma)
}

// Démarrer : le nôtre (DE-011, repris de KDE-Windows-Modern), sinon Kickoff.
ajouter("org.ankh.demarrer", "org.kde.plasma.kickoff")

// « Vue des tâches » : le bouton qui ouvre la vue d'ensemble, à droite de
// Démarrer comme dans Windows 11 (lot 4, repris de Tidewater). Plasma n'a
// pas d'équivalent à un seul bouton : sans le nôtre, on n'en met aucun
// plutôt qu'un applet qui ferait autre chose.
try {
    var vue = panel.addWidget("org.ankh.vuetaches")
    if (vue && vue.type === "org.ankh.vuetaches") {
        print("ANKH-LAYOUT org.ankh.vuetaches : installé")
    } else {
        print("ANKH-LAYOUT org.ankh.vuetaches : absent, aucun remplaçant")
        if (vue) vue.remove()
    }
} catch (e) {
    print("ANKH-LAYOUT org.ankh.vuetaches : absent, aucun remplaçant")
}

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
// Des icônes seules, sans texte, comme Windows 11. La nôtre est reprise de
// Tidewater (DE-011) ; à défaut, icontasks de Plasma. Les deux lisent la
// même clé « launchers », donc les épingles suivent dans les deux cas.
var taches = ajouter("org.ankh.taches", "org.kde.plasma.icontasks")
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
//
// Elle est GARDÉE, et c'est un choix. Notre volet d'état (ci-dessous)
// affiche déjà réseau, Bluetooth, volume et luminosité — mais les éteindre
// dans la zone, comme le fait Tidewater, couperait aussi les invites de
// mot de passe Wi-Fi et les touches de volume, qui passent par ces
// services. On les REND DISCRÈTES au lieu de les supprimer : elles restent
// vivantes, derrière le chevron, comme les icônes masquées de Windows 11.
var zone = panel.addWidget("org.kde.plasma.systemtray")
zone.currentConfigGroup = ["General"]
zone.writeConfig("hiddenItems", [
    "org.kde.plasma.networkmanagement",
    "org.kde.plasma.bluetooth",
    "org.kde.plasma.brightness",
    "org.kde.plasma.volume",
    "org.kde.plasma.notifications"
])

// Le volet unique : Wi-Fi, Bluetooth, volume, luminosité en un bouton, comme
// les « Paramètres rapides » de Windows 11 (lot 6, repris de Tidewater).
// Pas de remplaçant chez Plasma : ses équivalents sont justement les cinq
// icônes qu'on vient de ranger.
try {
    var etat = panel.addWidget("org.ankh.etat")
    if (etat && etat.type === "org.ankh.etat") {
        print("ANKH-LAYOUT org.ankh.etat : installé")
    } else {
        print("ANKH-LAYOUT org.ankh.etat : absent, aucun remplaçant")
        if (etat) etat.remove()
        // Sans notre volet, les cinq icônes rangées seraient introuvables :
        // on les ressort.
        zone.writeConfig("hiddenItems", [])
        print("ANKH-LAYOUT zone système : icônes ressorties, faute de volet d'état")
    }
} catch (e) {
    zone.writeConfig("hiddenItems", [])
    print("ANKH-LAYOUT org.ankh.etat : absent, zone système laissée entière")
}

// Les notifications, à gauche de l'horloge (lot 6, repris de Tidewater).
try {
    var notifs = panel.addWidget("org.ankh.notifications")
    if (notifs && notifs.type === "org.ankh.notifications") {
        print("ANKH-LAYOUT org.ankh.notifications : installé")
    } else {
        print("ANKH-LAYOUT org.ankh.notifications : absent, aucun remplaçant")
        if (notifs) notifs.remove()
    }
} catch (e) {
    print("ANKH-LAYOUT org.ankh.notifications : absent, aucun remplaçant")
}

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

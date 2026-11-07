// Barre des tâches d'Ankh DE : celle de Windows 11 (DE-003, DE-015, lot 4).
//
// Adapté du modèle de KDE (layout-templates/org.kde.plasma.desktop.defaultPanel
// de https://invent.kde.org/plasma/plasma-desktop, LGPL-2.0-or-later).
// Différences avec le modèle, toutes mesurées sur Windows 11 :
//   - collée en bas, pleine largeur (le modèle de KDE est flottant depuis
//     Plasma 6.0) ;
//   - 48 px de haut (le modèle : 2,5 unités de grille, soit 44 px) ;
//   - Démarrer et les applications au centre, par deux espaceurs ;
//   - zone de notification, horloge sur deux lignes, cloche et « Afficher le
//     bureau » à droite ;
//   - le sélecteur de bureaux virtuels est retiré (Windows 11 ne l'affiche
//     pas dans la barre).
// Le trait d'accent sous l'application active (16×3) vient du style Plasma
// « ankh » (src/desktoptheme), pas d'ici.
//
// ── DE-015 : UN SEUL applet nous appartient ici, et c'est Démarrer. ──
//
// Jusqu'au 2026-11-07, cette barre portait six applets repris de Tidewater
// et de KDE-Windows-Modern : tâches, vue des tâches, séparateur, volet
// d'état, horloge, « Afficher le bureau ». Aucun des six n'avait jamais été
// prouvé INTERACTIF. Pire, pour faire place au volet d'état, ce fichier
// MASQUAIT les cinq applets natives qui marchent — réseau, Bluetooth,
// volume, luminosité, notifications. Ankh DE retirait donc à l'utilisateur
// le contrôle du volume et du Wi-Fi pour les remplacer par un panneau non
// éprouvé : une régression contre Plasma nu, pas une amélioration.
//
// Ils sont tous remplacés par les applets natives de Plasma, habillées par
// notre style Plasma, nos couleurs et nos icônes. L'apparence est à nous ;
// le comportement est celui de KDE, déjà traduit, déjà accessible, déjà
// maintenu, et qui n'a rien à reporter à chaque version de Plasma.

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

// Notre applet quand il est installé, celui de Plasma sinon — et le DIT.
// Au premier passage en VM, le repli était muet : la barre portait Kickoff,
// la capture montrait notre icône (venue du thème), et on a cru que notre
// menu était là. Un repli silencieux est un mensonge.
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

// --- Démarrer : le seul applet d'Ankh dans cette barre -------------------
// Repris de KDE-Windows-Modern (DE-011). GARDÉ parce qu'il est le seul à
// avoir été prouvé interactif en VM : il s'ouvre, prend le clavier sans
// qu'on clique dedans, cherche, et se referme sur Échap (09e4950). Kickoff
// n'a pas la disposition de Windows 11 ; c'est le repli, jamais le parallèle.
ajouter("org.ankh.demarrer", "org.kde.plasma.kickoff")

// Pas de bouton « Vue des tâches » dans 0.1 (DE-015, stratégie DEFER).
// L'applet repris de Tidewater n'a jamais été prouvé, et son rôle face à
// l'effet Overview de KWin n'était pas établi : un bouton qui réimplémente
// un effet natif est précisément le doublon qu'on refuse. La vue d'ensemble
// reste accessible par son raccourci natif, Meta+W, et par le coin d'écran.
// Elle revient en bouton quand un essai aura prouvé qu'elle appelle bien
// l'effet de KWin plutôt que de le refaire.

// --- Les fenêtres ouvertes : le gestionnaire natif, en icônes seules -----
// org.kde.plasma.icontasks, et non org.ankh.taches (DE-015). C'EST le
// gestionnaire de tâches en icônes seules de Plasma : groupement par
// programme, aperçus au survol, listes de sauts, glisser-déposer,
// indicateur audio, clic sur l'actif qui minimise — tout ce que Windows 11
// fait, déjà écrit et déjà traduit. Ses défauts, relevés dans
// applets/taskmanager/main.xml de plasma-desktop (Plasma 6.6), sont déjà
// ceux de Windows 11 : groupingStrategy=1 (par programme),
// minimizeActiveTaskOnClick=true, showOnlyCurrentDesktop=true.
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
var taches = panel.addWidget("org.kde.plasma.icontasks")
taches.currentConfigGroup = ["General"]
taches.writeConfig("launchers", epinglees)
// « fill » vaut true par défaut : l'applet prendrait TOUTE la place entre
// les deux espaceurs, et le centrage de Windows 11 tomberait à plat. Les
// icônes doivent se serrer au centre, pas s'étaler.
taches.writeConfig("fill", false)
// Les 8 px autour de chaque icône (valeur relevée sur AnduinOS) ne sont pas
// écrits ici : « iconSpacing » est un entier, mais rien ne dit que son
// unité soit le pixel, et le banc ne l'a pas mesuré. (Le commentaire qui
// vivait ici affirmait que la clé était une énumération : c'est faux,
// main.xml la déclare « Int » de défaut 1. Une valeur lue vaut mieux qu'une
// valeur retenue de mémoire.)

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

// --- Zone de notification : entière, et c'est le point de DE-015 ---------
// Réseau, Bluetooth, volume, luminosité restent VISIBLES et vivants. Ce
// sont eux qui portent les invites de mot de passe Wi-Fi, les touches de
// volume et le réglage de luminosité. Les masquer derrière un volet maison
// non éprouvé était la pire décision de ce dépôt pour l'usage quotidien.
var zone = panel.addWidget("org.kde.plasma.systemtray")
zone.currentConfigGroup = ["General"]
// Une seule exception, et elle évite un doublon : la cloche est ajoutée
// plus bas comme applet à part, pour la placer à DROITE de l'horloge comme
// Windows 11. Sans ce masquage, il y aurait deux interfaces de
// notifications dans la même barre.
zone.writeConfig("hiddenItems", ["org.kde.plasma.notifications"])

// Neuf pixels entre la zone système et l'horloge. Sur la capture du
// 2026-11-06, l'icône de réseau TOUCHAIT le « 2 » de « 2:10 PM » : zéro
// pixel entre les deux.
//
// C'est un espaceur natif à longueur fixe, et non notre org.ankh.separateur
// (DE-015) : applets/panelspacer/main.xml de plasma-workspace donne
// « expanding » (bool) et « length » (entier, en pixels), donc exactement
// les 9 px, en natif. org.kde.plasma.marginsseparator aurait été plus
// propre encore, mais il N'EXISTE PAS en Plasma 6.6 — vérifié sur la
// branche Plasma/6.6 de plasma-workspace — et 6.6 est la cible.
var ecart = panel.addWidget("org.kde.plasma.panelspacer")
ecart.currentConfigGroup = ["General"]
ecart.writeConfig("expanding", false)
ecart.writeConfig("length", 9)

// --- Horloge : la native, sur deux lignes --------------------------------
// org.kde.plasma.digitalclock, et non org.ankh.horloge (DE-015).
// Le commentaire qui vivait ici disait que « BesideTime » — la date À CÔTÉ
// de l'heure — était « le mieux que son schéma propose », et se notait
// lui-même « à revérifier ». Vérification faite dans
// applets/digital-clock/main.xml de plasma-workspace : dateDisplayFormat
// offre « BelowTime ». L'horloge native met donc la date SOUS l'heure,
// comme Windows 11 — et elle apporte en plus un calendrier, un agenda et
// les fuseaux horaires, que notre horloge n'avait pas.
var horloge = panel.addWidget("org.kde.plasma.digitalclock")
horloge.currentConfigGroup = ["Appearance"]
horloge.writeConfig("showDate", true)
horloge.writeConfig("dateDisplayFormat", "BelowTime")
horloge.writeConfig("showSeconds", "Never")

// --- La cloche, à droite de la date, comme Windows 11 --------------------
// L'interface native des notifications (org.kde.plasma.notifications), en
// applet à part. Elle EST l'interface du service de notifications de
// Plasma : aucun second service, aucune seconde interface — la même est
// masquée dans la zone juste au-dessus.
panel.addWidget("org.kde.plasma.notifications")

// Bande « Afficher le bureau » au coin droit, comme Windows 11. Native
// (DE-015) : org.ankh.bureau ne faisait rien de plus.
panel.addWidget("org.kde.plasma.showdesktop")

// Fond d'écran : le module d'images, pour que l'accent suive le fond
// (DE-004).
var bureaux = desktopsForActivity(currentActivity())
for (var j = 0; j < bureaux.length; j++) {
    bureaux[j].wallpaperPlugin = "org.kde.image"
    // « Prismes d'Ankh » : le fond de Fluent que livre AnduinOS (GPL-3.0),
    // tourné aux violets d'Ankh par third_party/preparer.sh. Il porte ses
    // deux variantes, claire et sombre, et déclare l'accent d'Ankh — c'est
    // par là que « accentColorFromWallpaper » trouve le bon violet (DE-004).
    bureaux[j].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"]
    bureaux[j].writeConfig("Image", "Ankh-Prismes")
}

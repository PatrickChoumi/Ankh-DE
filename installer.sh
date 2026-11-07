#!/usr/bin/env bash
# Ankh DE : installation sur n'importe quelle distribution avec KDE Plasma 6
# (DE-001). Compile le style et la décoration, installe les thèmes, puis
# applique le thème global « Ankh DE ».
#
#   ./installer.sh                 installation système (/usr/local), par sudo
#   ./installer.sh --utilisateur   installation dans ~/.local, sans root
#   ./installer.sh --barre         remplace AUSSI vos barres par celle de
#                                  Windows 11 (efface vos barres actuelles)
#   ./installer.sh --sans-tiers    sans la police, les curseurs ni le thème GTK
#
# Pour revenir en arrière : ./desinstaller.sh
set -euo pipefail

racine="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
mode=systeme
barre=non
tiers=oui

while (( $# )); do
    case "$1" in
        --utilisateur|--user) mode=utilisateur ;;
        --barre|--panel)      barre=oui ;;
        --sans-tiers)         tiers=non ;;
        -h|--help)            sed -n '2,13p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *) echo "Option inconnue : $1" >&2; exit 1 ;;
    esac
    shift
done

echo "== Ankh DE, installation (${mode})"

# --- 1. Plasma 6 est-il là ? ---------------------------------------------
if ! command -v plasma-apply-lookandfeel > /dev/null; then
    echo "plasma-apply-lookandfeel est introuvable : Ankh DE demande KDE Plasma 6." >&2
    exit 1
fi
version="$(plasmashell --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 || true)"
if [[ -n "${version}" ]]; then
    echo "Plasma ${version} détecté."
    if [[ "${version%%.*}" != 6 ]]; then
        echo "Ankh DE ne vise que Plasma 6 (voir docs/REBASE.md)." >&2
        exit 1
    fi
fi

# --- 2. Dépendances de compilation ---------------------------------------
# Nommées par commande et par fichier CMake, jamais par paquet : chaque
# distribution les range ailleurs.
manquants=()
command -v cmake > /dev/null || manquants+=(cmake)
command -v g++ > /dev/null || command -v clang++ > /dev/null || manquants+=("g++")
if (( ${#manquants[@]} )); then
    cat >&2 << AIDE
Outils de compilation manquants : ${manquants[*]}

  Fedora  : sudo dnf install cmake gcc-c++ extra-cmake-modules qt6-qtbase-devel \\
              kf6-kconfig-devel kf6-kcoreaddons-devel kf6-kguiaddons-devel \\
              kf6-kiconthemes-devel kf6-kwindowsystem-devel kf6-kcolorscheme-devel \\
              kf6-frameworkintegration-devel kdecoration-devel
  Arch    : sudo pacman -S cmake gcc extra-cmake-modules qt6-base kconfig \\
              kcoreaddons kguiaddons kiconthemes kwindowsystem kcolorscheme \\
              frameworkintegration kdecoration
  Ubuntu  : sudo apt install cmake g++ extra-cmake-modules qt6-base-dev \\
              libkf6config-dev libkf6coreaddons-dev libkf6guiaddons-dev \\
              libkf6iconthemes-dev libkf6windowsystem-dev libkf6colorscheme-dev \\
              libkf6style-dev libkdecorations3-dev
AIDE
    exit 1
fi

# --- 2bis. Ce dont le volet d'état a besoin pour PARLER -------------------
# Le volet « État du système » (lot 6, repris de Tidewater) ne passe pas par
# un module QML de réseau : il appelle ces outils en ligne de commande. Sans
# eux, il s'affiche et ne répond pas — un volet muet, le pire des deux
# mondes. On le DIT à l'installation, plutôt que de laisser l'utilisateur
# le découvrir.
#
# Ce n'est pas bloquant : le reste du DE n'en dépend pas, et chaque outil ne
# désactive que sa propre tuile.
muets=()
command -v wpctl        > /dev/null || muets+=("wpctl (volume)")
command -v nmcli        > /dev/null || muets+=("nmcli (Wi-Fi)")
command -v rfkill       > /dev/null || muets+=("rfkill (mode avion)")
command -v bluetoothctl > /dev/null || muets+=("bluetoothctl (Bluetooth)")
command -v busctl       > /dev/null || muets+=("busctl (luminosité)")
if (( ${#muets[@]} )); then
    cat >&2 << MUETS

Le volet d'état sera partiellement muet : ${muets[*]}

  Fedora  : sudo dnf install wireplumber NetworkManager util-linux bluez systemd
  Arch    : sudo pacman -S wireplumber networkmanager util-linux bluez-utils systemd
  Ubuntu  : sudo apt install wireplumber network-manager util-linux bluez systemd

Les noms de paquets ci-dessus ne sont VÉRIFIÉS que pour Fedora, où la session
tourne en VM à chaque changement. Sur Arch et Ubuntu, ce sont les noms usuels :
si l'un est faux, dites-le dans une issue.

L'installation continue : rien d'autre n'en dépend.
MUETS
else
    echo "== Volet d'état : les cinq outils sont là"
fi

# --- 3. Pièces venues d'ailleurs -----------------------------------------
if [[ "${tiers}" == oui ]]; then
    echo "== Police, curseurs et thème GTK"
    "${racine}/third_party/preparer.sh" || {
        echo
        echo "La préparation a échoué. Relancez avec --sans-tiers pour installer" >&2
        echo "le reste : le DE marchera, avec la police et les curseurs de votre" >&2
        echo "distribution." >&2
        exit 1
    }
fi

# --- 4. Compilation -------------------------------------------------------
if [[ "${mode}" == utilisateur ]]; then
    prefixe="${HOME}/.local"
else
    prefixe=/usr/local
fi
build="${racine}/build"
cmake -S "${racine}" -B "${build}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${prefixe}" \
    -DKDE_INSTALL_SYSCONFDIR="${prefixe}/etc"
cmake --build "${build}" -j "$(nproc)"

# --- 5. Installation ------------------------------------------------------
if [[ "${mode}" == utilisateur ]]; then
    cmake --install "${build}"
    # Qt et KWin ne cherchent pas les greffons sous ~/.local : Plasma lit les
    # scripts de ~/.config/plasma-workspace/env au début de chaque session
    # (startplasma.cpp de plasma-workspace), on y ajoute le chemin.
    greffons="$(cmake -L "${build}" 2>/dev/null | sed -n 's/^KDE_INSTALL_QTPLUGINDIR:PATH=//p')"
    [[ -n "${greffons}" ]] || greffons="${prefixe}/lib64/qt6/plugins"
    [[ "${greffons}" = /* ]] || greffons="${prefixe}/${greffons}"
    env_dir="${HOME}/.config/plasma-workspace/env"
    install -d -m 0755 "${env_dir}"
    cat > "${env_dir}/ankh-de.sh" << ENV
# Ajouté par l'installateur d'Ankh DE : sans cette ligne, Qt et KWin ne
# trouvent pas le style ni la décoration installés dans votre dossier
# personnel. Supprimez ce fichier pour revenir en arrière.
export QT_PLUGIN_PATH="${greffons}\${QT_PLUGIN_PATH:+:\$QT_PLUGIN_PATH}"
ENV
    # fontconfig ne lit pas ~/.local/etc : on relie le fichier de rendu là
    # où il le cherche.
    install -d -m 0755 "${HOME}/.config/fontconfig/conf.d"
    ln -sf "${prefixe}/etc/fonts/conf.d/29-ankh-rendu.conf" \
        "${HOME}/.config/fontconfig/conf.d/29-ankh-rendu.conf"
    echo
    echo "Installé dans ${prefixe}."
    echo "Le style et la décoration ne seront chargés qu'à votre PROCHAINE session :"
    echo "déconnectez-vous et reconnectez-vous, puis relancez ce script pour"
    echo "appliquer le thème global."
else
    echo "== Installation système (sudo)"
    sudo cmake --install "${build}"
fi

command -v fc-cache > /dev/null && fc-cache -f > /dev/null 2>&1 || true

# --- 6. Application du thème global ---------------------------------------
# C'est le seul geste qui change votre session : il écrit les réglages du
# fichier contents/defaults du thème. Réversible par ./desinstaller.sh.
echo "== Application du thème global « Ankh DE »"
if [[ "${barre}" == oui ]]; then
    cat << 'AVERTIR'

  ATTENTION : --barre efface vos barres actuelles et les remplace par celle
  de Windows 11 (collée en bas, 48 px, Démarrer et applications au centre).
  Vos applets et vos épingles actuels seront perdus.

AVERTIR
    read -r -p "  Continuer ? [o/N] " reponse
    [[ "${reponse}" =~ ^[oOyY]$ ]] || { echo "  Barres gardées."; barre=non; }
fi

# plasma-apply-lookandfeel est une application Qt : sans session graphique
# — depuis un TTY, par SSH, ou dans un script d'installation — elle
# S'ARRÊTE SUR UN DÉFAUT (« Aborted, core dumped »). Constaté le 2026-11-06
# dans une vraie VM : l'installation échouait là, après avoir pourtant tout
# installé correctement.
# Hors session, on lui donne la plateforme « offscreen » : elle écrit alors
# ses réglages sans rien afficher. Vérifié en conteneur et en VM.
# Second piège, celui-là trouvé dans la VM le 2026-11-06 : l'outil n'écrit
# « widgetStyle » que s'il arrive à CHARGER le greffon du style. Lancé par
# l'installateur, il ne connaît pas notre préfixe — le style n'était donc
# pas appliqué, EN SILENCE, et le rapport de la session le montrait vide.
greffons_installes="$(find "${prefixe}" -type d -name styles -printf '%h\n' 2>/dev/null | head -1)"
appliquer() {
    local env=()
    if [[ -n "${greffons_installes}" ]]; then
        env+=("QT_PLUGIN_PATH=${greffons_installes}${QT_PLUGIN_PATH:+:${QT_PLUGIN_PATH}}")
    fi
    if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${DISPLAY:-}" ]]; then
        # Sans session graphique, l'outil s'arrête sur un défaut.
        echo "  (hors session graphique : application sans affichage)"
        env+=("QT_QPA_PLATFORM=offscreen")
    fi
    env "${env[@]}" plasma-apply-lookandfeel "$@"
}

if [[ "${barre}" == oui ]]; then
    # On SAUVEGARDE avant d'effacer. Les deux gestes vivent dans
    # lib/barres.sh, où tests/barres.sh les éprouve sur un faux HOME : du
    # code de sauvegarde qu'on ne peut pas essayer ne vaut pas mieux que
    # l'avertissement qu'il remplace.
    # shellcheck source=lib/barres.sh
    . "${racine}/lib/barres.sh"
    ankh_barres_sauver
    appliquer -a org.ankh.de.desktop --resetLayout
else
    # Sans --resetLayout, vos barres ne sont pas touchées.
    appliquer -a org.ankh.de.desktop
fi

echo
echo "Fait. Ankh DE est appliqué."
echo
# DE-010 : le thème global ne sait pas porter les polices, le rendu, les
# animations ni l'accent qui suit le fond d'écran. C'est la session qui les
# porte. Le taire laisserait l'utilisateur devant un Ankh DE à moitié
# appliqué, sans savoir pourquoi.
cat << 'SUITE'
  IMPORTANT — déconnectez-vous, puis choisissez « Ankh DE » à l'écran
  de connexion, dans la liste des sessions.

  C'est la session d'Ankh DE qui applique la police Selawik, le rendu des
  textes, les durées d'animation de Windows 11, l'accent qui suit le fond
  d'écran et la disposition des boutons de fenêtre. Le thème global, seul,
  ne sait pas les porter : vous auriez les couleurs, le style des contrôles
  et la décoration, mais pas le reste.

SUITE
echo "Pour la barre des tâches de Windows 11 : ./installer.sh --barre"
echo "Pour tout défaire                      : ./desinstaller.sh"

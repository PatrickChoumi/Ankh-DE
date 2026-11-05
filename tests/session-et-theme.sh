#!/usr/bin/env bash
# Vérifie, clé par clé, que ce qu'Ankh DE promet est RÉELLEMENT appliqué.
#
# C'est l'absence de ce test qui a laissé passer le défaut du 2026-11-05 :
# onze réglages du thème global — dont toutes les polices — étaient
# silencieusement ignorés, et rien ne le disait (AUDIT.md §1.1).
#
# Deux mécanismes, deux vérifications :
#   1. le THÈME GLOBAL, appliqué par plasma-apply-lookandfeel, dont les
#      valeurs atterrissent dans la couche « kdedefaults » ;
#   2. la SESSION (DE-010), qui place nos valeurs par défaut dans
#      XDG_CONFIG_DIRS : polices, rendu, animations, accent.
#
# Ni VM ni session graphique : QT_QPA_PLATFORM=offscreen suffit.
#
#   tests/session-et-theme.sh [préfixe d'installation]
set -euo pipefail

racine="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
travail="$(mktemp -d)"
trap 'rm -rf "${travail}"' EXIT

prefixe="${1:-${travail}/prefixe}"
echecs=0
verifies=0

attendre() { # $1 : libellé, $2 : attendu, $3 : obtenu
    verifies=$((verifies + 1))
    if [[ "$3" == "$2" ]]; then
        printf '  ok    %-44s %s\n' "$1" "$3"
    else
        printf '  ECHEC %-44s attendu « %s », obtenu « %s »\n' "$1" "$2" "$3" >&2
        echecs=$((echecs + 1))
    fi
}

for outil in cmake kreadconfig6 plasma-apply-lookandfeel kpackagetool6; do
    command -v "${outil}" > /dev/null || { echo "Outil manquant : ${outil}" >&2; exit 1; }
done

# --- Installation --------------------------------------------------------
if [[ ! -d "${prefixe}" ]]; then
    echo "== Installation dans ${prefixe}"
    cmake -S "${racine}" -B "${travail}/build" -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${prefixe}" ${ANKH_DE_CMAKE_EXTRA:-} > "${travail}/cmake.log" 2>&1 \
        || { tail -20 "${travail}/cmake.log" >&2; exit 1; }
    cmake --build "${travail}/build" -j"$(nproc)" >> "${travail}/cmake.log" 2>&1 \
        || { tail -30 "${travail}/cmake.log" >&2; exit 1; }
    cmake --install "${travail}/build" >> "${travail}/cmake.log" 2>&1
fi

# --- 1. La session existe-t-elle vraiment ? ------------------------------
echo "== La session (DE-010)"
session="${prefixe}/share/wayland-sessions/ankh-de.desktop"
lanceur="${prefixe}/bin/ankh-de-session"
config="${prefixe}/share/ankh-de/config"

for fichier in "${session}" "${lanceur}" "${config}/kdeglobals" "${config}/kwinrc"; do
    verifies=$((verifies + 1))
    if [[ -e "${fichier}" ]]; then
        printf '  ok    %s\n' "${fichier#${prefixe}/}"
    else
        printf '  ECHEC %s est absent\n' "${fichier#${prefixe}/}" >&2
        echecs=$((echecs + 1))
    fi
done
[[ -x "${lanceur}" ]] || { echo "  ECHEC ${lanceur} n'est pas exécutable" >&2; echecs=$((echecs + 1)); }

attendre "session : Name" "Ankh DE" \
    "$(awk -F= '/^Name=/{print $2; exit}' "${session}" 2>/dev/null || true)"
attendre "session : DesktopNames" "KDE" \
    "$(awk -F= '/^DesktopNames=/{print $2; exit}' "${session}" 2>/dev/null || true)"
attendre "session : Exec pointe sur le lanceur installé" "${lanceur}" \
    "$(awk -F= '/^Exec=/{print $2; exit}' "${session}" 2>/dev/null || true)"
# Aucun @MARQUEUR@ ne doit subsister après configure_file.
verifies=$((verifies + 1))
if grep -q '@[A-Z_]*@' "${session}" "${lanceur}" 2>/dev/null; then
    echo "  ECHEC un marqueur @...@ n'a pas été remplacé" >&2
    grep -Hn '@[A-Z_]*@' "${session}" "${lanceur}" >&2
    echecs=$((echecs + 1))
else
    printf '  ok    %s\n' "aucun marqueur @...@ restant"
fi
# Le lanceur doit être un script shell valide.
verifies=$((verifies + 1))
if sh -n "${lanceur}" 2>/dev/null; then
    printf '  ok    %s\n' "le lanceur est un script shell valide"
else
    echo "  ECHEC le lanceur n'est pas un script shell valide" >&2
    echecs=$((echecs + 1))
fi

# --- 2. Ce que la SESSION applique : polices, rendu, animations, accent --
echo "== Les valeurs par défaut de la session (XDG_CONFIG_DIRS)"
export XDG_CONFIG_HOME="${travail}/conf-session"
install -d "${XDG_CONFIG_HOME}"
export XDG_CONFIG_DIRS="${config}:/etc/xdg"

lire() { kreadconfig6 "$@" 2>/dev/null || true; }
attendre "police de l'interface"        "Selawik,10.5,-1,5,50,0,0,0,0,0" "$(lire --group General --key font)"
attendre "police des menus"             "Selawik,10.5,-1,5,50,0,0,0,0,0" "$(lire --group General --key menuFont)"
attendre "police des barres d'outils"   "Selawik,10.5,-1,5,50,0,0,0,0,0" "$(lire --group General --key toolBarFont)"
attendre "plus petite police lisible"   "Selawik,9,-1,5,50,0,0,0,0,0"    "$(lire --group General --key smallestReadableFont)"
attendre "police à chasse fixe"         "JetBrains Mono,10,-1,5,50,0,0,0,0,0" "$(lire --group General --key fixed)"
attendre "police du titre des fenêtres" "Selawik,9,-1,5,50,0,0,0,0,0"    "$(lire --group WM --key activeFont)"
attendre "lissage"                      "true"        "$(lire --group General --key XftAntialias)"
attendre "contours"                     "hintslight"  "$(lire --group General --key XftHintStyle)"
attendre "sous-pixels"                  "none"        "$(lire --group General --key XftSubPixel)"
attendre "accent suit le fond d'écran"  "true"        "$(lire --group General --key accentColorFromWallpaper)"
attendre "facteur d'animation"          "0.8333333"   "$(lire --group KDE --key AnimationDurationFactor)"
attendre "Alt+Tab"                      "org.kde.breeze.desktop" \
    "$(lire --file kwinrc --group TabBox --key LayoutName)"
# Portés par la session depuis le 2026-11-05 : le thème global ne les écrit
# jamais (vérifié).
attendre "bouton gauche (icône)"        "M"   "$(lire --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft)"
attendre "boutons droite (_ □ ×)"       "IAX" "$(lire --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight)"

# La règle de DE-010 : l'utilisateur garde la priorité.
echo "== Les réglages de l'utilisateur passent avant les nôtres"
printf '[General]\nfont=Comic Sans MS,12,-1,5,50,0,0,0,0,0\n' > "${XDG_CONFIG_HOME}/kdeglobals"
attendre "la police de l'utilisateur gagne" "Comic Sans MS,12,-1,5,50,0,0,0,0,0" \
    "$(lire --group General --key font)"
rm -f "${XDG_CONFIG_HOME}/kdeglobals"

# --- 3. Ce que le THÈME GLOBAL applique ----------------------------------
echo "== Le thème global"
export XDG_CONFIG_HOME="${travail}/conf-theme"
install -d "${XDG_CONFIG_HOME}"
export XDG_RUNTIME_DIR="${travail}/run"
install -d -m 0700 "${XDG_RUNTIME_DIR}"
export QT_QPA_PLATFORM=offscreen
export XDG_DATA_DIRS="${prefixe}/share:/usr/share"
# Comme le fait la session : sans cela, « plasma-apply-lookandfeel » n'écrit
# même pas widgetStyle, en silence (vérifié le 2026-11-05).
greffons="$(find "${prefixe}" -type d -name styles -printf '%h\n' 2>/dev/null | head -1)"
if [[ -n "${greffons}" ]]; then
    export QT_PLUGIN_PATH="${greffons}"
else
    echo "  ECHEC aucun dossier de greffons trouvé sous ${prefixe}" >&2
    echecs=$((echecs + 1))
fi

# Le lanceur doit poser ce chemin lui-même : c'est ce qui rend une
# installation hors de /usr utilisable.
verifies=$((verifies + 1))
if grep -q 'QT_PLUGIN_PATH' "${lanceur}" && grep -q "${greffons}" "${lanceur}"; then
    printf '  ok    %s\n' "le lanceur pose QT_PLUGIN_PATH sur ${greffons}"
else
    echo "  ECHEC le lanceur ne pose pas QT_PLUGIN_PATH sur ${greffons}" >&2
    echecs=$((echecs + 1))
fi

verifies=$((verifies + 1))
if plasma-apply-lookandfeel --list 2>/dev/null | grep -qx org.ankh.de.desktop; then
    printf '  ok    %s\n' "Plasma liste org.ankh.de.desktop"
else
    echo "  ECHEC Plasma ne liste pas org.ankh.de.desktop" >&2
    echecs=$((echecs + 1))
fi

plasma-apply-lookandfeel -a org.ankh.de.desktop > /dev/null 2>&1 || true
# Les valeurs atterrissent dans la couche « kdedefaults », que la session de
# Plasma place dans XDG_CONFIG_DIRS.
export XDG_CONFIG_DIRS="${XDG_CONFIG_HOME}/kdedefaults:${config}:/etc/xdg"

attendre "style des contrôles"   "Ankh"                 "$(lire --group KDE --key widgetStyle)"
attendre "jeu de couleurs"       "Ankh"                 "$(lire --group General --key ColorScheme)"
attendre "décoration"            "org.ankh.decoration"  "$(lire --file kwinrc --group org.kde.kdecoration2 --key library)"
attendre "bords des fenêtres"    "None"                 "$(lire --file kwinrc --group org.kde.kdecoration2 --key BorderSize)"
attendre "thème du curseur"      "Ankh-curseurs"        "$(lire --file kcminputrc --group Mouse --key cursorTheme)"

# Le thème global ne doit désigner AUCUNE pièce absente (AUDIT.md §1.2).
echo "== Le thème global ne désigne rien d'absent"
defauts="${prefixe}/share/plasma/look-and-feel/org.ankh.de.desktop/contents/defaults"
for couple in \
    "Icons|Theme|${prefixe}/share/icons" \
    "Theme|name|${prefixe}/share/plasma/desktoptheme"
do
    IFS='|' read -r groupe cle dossier <<< "${couple}"
    valeur="$(grep -A4 "^\[kdeglobals\]\[${groupe}\]\|^\[plasmarc\]\[${groupe}\]" "${defauts}" 2>/dev/null \
        | awk -F= -v k="${cle}" '$1==k{print $2; exit}' || true)"
    verifies=$((verifies + 1))
    if [[ -z "${valeur}" ]]; then
        printf '  ok    %s\n' "${groupe}/${cle} n'est pas désigné (pièce non livrée)"
    elif [[ -d "${dossier}/${valeur}" || -d "/usr/share/${dossier##*/share/}/${valeur}" ]]; then
        printf '  ok    %s\n' "${groupe}/${cle}=${valeur} existe"
    else
        echo "  ECHEC ${groupe}/${cle}=${valeur} est désigné mais n'existe pas" >&2
        echecs=$((echecs + 1))
    fi
done

echo
if (( echecs )); then
    echo "${echecs} échec(s) sur ${verifies} vérification(s)." >&2
    exit 1
fi
echo "${verifies} vérifications, toutes passées."

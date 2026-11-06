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
# Même piège pour les DONNÉES : sans XDG_DATA_DIRS, Plasma ne trouve ni nos
# applets, ni nos thèmes, et retombe sur les siens sans un mot.
verifies=$((verifies + 1))
if grep -q 'XDG_DATA_DIRS' "${lanceur}" && grep -q "${prefixe}/share" "${lanceur}"; then
    printf '  ok    %s\n' "le lanceur pose XDG_DATA_DIRS sur ${prefixe}/share"
else
    echo "  ECHEC le lanceur ne pose pas XDG_DATA_DIRS sur ${prefixe}/share" >&2
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
    # Lecture d'un vrai fichier INI : on entre dans la section, on en sort au
    # prochain en-tête, et on ignore les commentaires. Un « grep -A4 » ratait
    # la clé dès qu'un commentaire la précédait — et rendait un faux « ok ».
    valeur="$(awk -F= -v g="${groupe}" -v k="${cle}" '
        /^\[/ { dedans = ($0 ~ "\\]\\[" g "\\]$"); next }
        /^[[:space:]]*#/ { next }
        dedans && $1 == k { print $2; exit }
    ' "${defauts}" 2>/dev/null || true)"
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

# --- 3bis. L'écran de chargement et les aperçus --------------------------
echo "== Écran de chargement et aperçus"
paquet="${prefixe}/share/plasma/look-and-feel/org.ankh.de.desktop"
for fichier in contents/splash/Splash.qml contents/previews/preview.png \
               contents/previews/fullscreenpreview.jpg; do
    verifies=$((verifies + 1))
    if [[ -s "${paquet}/${fichier}" ]]; then
        printf '  ok    %s\n' "${fichier}"
    else
        echo "  ECHEC ${fichier} est absent ou vide" >&2
        echecs=$((echecs + 1))
    fi
done
# Un QML qui ne compile pas retarde l'ouverture de la session.
# Le nom varie : qmllint-qt6 sur Fedora, qmllint6 ailleurs, et Qt l'installe
# aussi dans son propre dossier.
lint=""
for candidat in qmllint-qt6 qmllint6 qmllint /usr/lib64/qt6/bin/qmllint /usr/lib/qt6/bin/qmllint; do
    if command -v "${candidat}" > /dev/null 2>&1; then lint="$(command -v "${candidat}")"; break; fi
    if [[ -x "${candidat}" ]]; then lint="${candidat}"; break; fi
done
if [[ -n "${lint}" ]]; then
    verifies=$((verifies + 1))
    if "${lint}" "${paquet}/contents/splash/Splash.qml" > /tmp/qmllint.log 2>&1; then
        printf '  ok    %s\n' "Splash.qml compile"
    else
        echo "  ECHEC Splash.qml ne compile pas :" >&2
        head -10 /tmp/qmllint.log >&2
        echecs=$((echecs + 1))
    fi
else
    echo "  (qmllint absent : la syntaxe du splash n'est pas vérifiée)"
fi
# L'écran de VERROUILLAGE doit rester celui de Plasma : s'en emparer sans
# l'avoir essayé enfermerait l'utilisateur dehors.
verifies=$((verifies + 1))
if grep -qE '^\[kscreenlockerrc\]' "${defauts}"; then
    echo "  ECHEC le thème désigne un écran de verrouillage : interdit tant qu'il" >&2
    echo "        n'a pas été déverrouillé pour de vrai en VM" >&2
    echecs=$((echecs + 1))
else
    printf '  ok    %s\n' "l'écran de verrouillage reste celui de Plasma (délibéré)"
fi

# --- 3ter. Les applets repris (DE-011) ------------------------------------
applets="${prefixe}/share/plasma/plasmoids"
if [[ -d "${applets}/org.ankh.demarrer" ]]; then
    echo "== Les applets"
    for id in org.ankh.demarrer org.ankh.horloge org.ankh.bureau; do
        verifies=$((verifies + 1))
        if [[ -f "${applets}/${id}/metadata.json" ]]; then
            printf '  ok    %s\n' "${id}"
        else
            echo "  ECHEC ${id} est absent" >&2
            echecs=$((echecs + 1))
        fi
    done
    # DE-011 : aucune pièce ne doit écraser une pièce de la distribution.
    verifies=$((verifies + 1))
    etrangers="$(python3 -I - "${applets}" << 'PYEOF'
import json, pathlib, sys
mauvais = []
for m in pathlib.Path(sys.argv[1]).glob("*/metadata.json"):
    try:
        ident = json.loads(m.read_text(encoding="utf-8"))["KPlugin"]["Id"]
    except Exception as e:
        mauvais.append(f"{m.parent.name} (illisible : {e})")
        continue
    if not ident.startswith("org.ankh."):
        mauvais.append(ident)
print(" ".join(mauvais))
PYEOF
)"
    if [[ -z "${etrangers}" ]]; then
        printf '  ok    %s\n' "aucun applet n'usurpe un identifiant de Plasma"
    else
        echo "  ECHEC identifiants hors org.ankh.* : ${etrangers}" >&2
        echecs=$((echecs + 1))
    fi
    # L'attribution doit survivre au renommage.
    verifies=$((verifies + 1))
    if grep -q 'Jeysef' "${applets}/org.ankh.demarrer/metadata.json"; then
        printf '  ok    %s\n' "l'auteur amont est conservé dans les métadonnées"
    else
        echo "  ECHEC l'attribution de l'auteur amont a disparu" >&2
        echecs=$((echecs + 1))
    fi
else
    echo "== Les applets : absents (third_party/preparer.sh n'a pas été lancé)"
fi

# --- 4. Les icônes sont-elles vraiment au violet d'Ankh ? ----------------
# Le thème peut être présent et les dessins restés roses : c'est la
# recoloration qui porte l'identité, pas le nom du dossier.
icones="${prefixe}/share/icons/Fluent-Ankh"
if [[ -d "${icones}" ]]; then
    echo "== Les icônes"
    attendre "nom affiché du thème d'icônes" "Ankh" \
        "$(awk -F= '/^Name=/{print $2; exit}' "${icones}/index.theme" 2>/dev/null || true)"
    dossier_svg="$(find "${prefixe}/share/icons" -name 'folder_color_purple.svg' 2>/dev/null | head -1)"
    verifies=$((verifies + 1))
    if [[ -z "${dossier_svg}" ]]; then
        echo "  ECHEC aucun dessin de dossier trouvé dans le thème d'icônes" >&2
        echecs=$((echecs + 1))
    elif grep -qi '#8455f0' "${dossier_svg}" && ! grep -qiE '#dc63ee|#e275f0|#ff85de' "${dossier_svg}"; then
        printf '  ok    %s\n' "les dossiers portent le violet d'Ankh, plus de rose"
    else
        echo "  ECHEC les dossiers ne sont pas au violet d'Ankh : ${dossier_svg}" >&2
        grep -oE '#[0-9a-fA-F]{6}' "${dossier_svg}" | sort -u | head -4 >&2
        echecs=$((echecs + 1))
    fi
    # Un thème d'icônes dont les liens pointent dans le vide se voit tout de
    # suite. L'amont en livre 10 de morts (icônes d'applications disparues).
    morts=0
    while read -r lien; do [[ -e "${lien}" ]] || morts=$((morts + 1)); done \
        < <(find "${prefixe}/share/icons/Fluent-Ankh" "${prefixe}/share/icons/Fluent-Ankh-dark" \
                 "${prefixe}/share/icons/Fluent-Ankh-light" -type l 2>/dev/null)
    verifies=$((verifies + 1))
    if (( morts <= 10 )); then
        printf '  ok    %s\n' "${morts} lien(s) mort(s), pas plus qu'en amont"
    else
        echo "  ECHEC ${morts} liens morts dans le thème d'icônes (10 attendus au plus)" >&2
        echecs=$((echecs + 1))
    fi
else
    echo "== Les icônes : thème absent (third_party/preparer.sh n'a pas été lancé)"
fi

echo
if (( echecs )); then
    echo "${echecs} échec(s) sur ${verifies} vérification(s)." >&2
    exit 1
fi
echo "${verifies} vérifications, toutes passées."

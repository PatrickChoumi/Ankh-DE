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
# Sans cette clé, plasmashell construit la barre des tâches de BREEZE et
# aucun de nos applets n'y entre (DE-014). Le défaut a vécu du 2026-11-06 au
# 2026-11-06 sans qu'aucun test ne le voie, parce qu'aucun ne regardait ici.
attendre "thème global de la session"   "org.ankh.de.desktop" \
    "$(lire --group KDE --key LookAndFeelPackage)"
# DE-015 : le sélecteur est « thumbnail_grid », celui que KWin livre
# lui-même (src/tabbox/switchers de plasma/kwin). Il est donc présent partout
# où KWin est présent, Plasma 6.6 de la cible Ubuntu comprise — ce qui n'est
# pas vrai de tous les sélecteurs, dont certains viennent de
# plasma-workspace.
attendre "Alt+Tab"                      "thumbnail_grid" \
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
# Clair par défaut depuis DE-017, comme Windows 11 sorti de la boîte.
attendre "jeu de couleurs"       "AnkhClair"            "$(lire --group General --key ColorScheme)"
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
    # DE-015 : un seul applet nous appartient désormais. Les sept autres ont
    # été remplacés par les applets natives de Plasma, qui ne s'installent
    # pas ici parce qu'elles arrivent avec Plasma.
    for id in org.ankh.demarrer; do
        verifies=$((verifies + 1))
        if [[ -f "${applets}/${id}/metadata.json" ]]; then
            printf '  ok    %s\n' "${id}"
        else
            echo "  ECHEC ${id} est absent" >&2
            echecs=$((echecs + 1))
        fi
    done
    # Le sélecteur Alt+Tab ne s'installe plus chez nous (DE-015) : c'est
    # celui de KWin. Ce qu'on vérifie ici, c'est qu'on n'en installe PAS un
    # second sous ce nom — sans quoi kwinrc en désignerait un et KWin en
    # chargerait un autre, en silence.
    verifies=$((verifies + 1))
    nom_voulu="$(lire --file kwinrc --group TabBox --key LayoutName)"
    if [[ -e "${prefixe}/share/kwin/tabbox/${nom_voulu}" ]]; then
        echo "  ECHEC nous installons un sélecteur « ${nom_voulu} » alors que celui de KWin est attendu" >&2
        echecs=$((echecs + 1))
    else
        printf '  ok    %-44s %s\n' "le sélecteur attendu est celui de KWin" "${nom_voulu}"
    fi

    # Le fond d'écran, et surtout ses DEUX variantes : un paquet qui n'a que
    # la claire laisse le bureau sombre sur une image claire, sans erreur et
    # sans que personne ne le voie passer.
    fond="${prefixe}/share/wallpapers/Ankh-Prismes"
    for variante in images images_dark; do
        verifies=$((verifies + 1))
        if [[ -s "${fond}/contents/${variante}/3840x2160.png" ]]; then
            printf '  ok    %-44s %s\n' "fond d'écran, variante ${variante}" "3840x2160"
        else
            echo "  ECHEC ${fond}/contents/${variante}/3840x2160.png est absent" >&2
            echecs=$((echecs + 1))
        fi
    done
    # Et l'accent qu'il déclare : c'est par cette clé que DE-004 trouve
    # l'accent de Windows 11 plutôt qu'une couleur calculée depuis l'image.
    verifies=$((verifies + 1))
    accent="$(python3 -I -c "
import json, sys
d = json.load(open(sys.argv[1]))
print(d.get('X-KDE-PlasmaImageWallpaper-AccentColor', {}).get('Dark', ''))
" "${fond}/metadata.json" 2>/dev/null || true)"
    if [[ "${accent}" == "#4CC2FF" ]]; then
        printf '  ok    %-44s %s\n' "l'accent déclaré par le fond" "${accent}"
    else
        echo "  ECHEC le fond déclare l'accent sombre « ${accent} », attendu « #4CC2FF »" >&2
        echecs=$((echecs + 1))
    fi

    # Plus de module QML partagé à vérifier : « ankh-de/qml » n'existait que
    # pour les applets repris de Tidewater, tous retirés (DE-015). En
    # revanche, il ne doit plus RIEN rester de ces applets, sinon la barre en
    # porterait deux de chaque — exactement le doublon que DE-015 supprime.
    verifies=$((verifies + 1))
    restes=""
    for parti in org.ankh.etat org.ankh.notifications org.ankh.taches \
                 org.ankh.vuetaches org.ankh.separateur org.ankh.horloge \
                 org.ankh.bureau; do
        [[ -e "${applets}/${parti}" ]] && restes="${restes} ${parti}"
    done
    [[ -e "${prefixe}/share/ankh-de/qml" ]] && restes="${restes} ankh-de/qml"
    [[ -e "${prefixe}/share/kwin/tabbox/ankh-selecteur" ]] && restes="${restes} ankh-selecteur"
    if [[ -z "${restes}" ]]; then
        printf '  ok    %s\n' "aucune pièce retirée par DE-015 n'est installée"
    else
        echo "  ECHEC des pièces retirées par DE-015 sont encore installées :${restes}" >&2
        echecs=$((echecs + 1))
    fi

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

# --- 4. Les dossiers sont-ils au jaune de Windows 11 ? -------------------
# Le thème peut être présent et la mauvaise variante construite : c'est la
# couleur des dossiers qui se voit, pas le nom du paquet. Depuis DE-017 on
# construit la variante « yellow » de Fluent (#ffcb52) et on ne recolore
# plus rien — le jaune des dossiers de Windows 11, relevé à #ffcd3e–#ffd14d
# sur une capture le 2026-11-08.
icones="${prefixe}/share/icons/Fluent-Ankh"
if [[ -d "${icones}" ]]; then
    echo "== Les icônes"
    attendre "nom affiché du thème d'icônes" "Ankh" \
        "$(awk -F= '/^Name=/{print $2; exit}' "${icones}/index.theme" 2>/dev/null || true)"
    # Le dossier que l'utilisateur VOIT, et non un fichier jaune par son nom.
    #
    # Ce contrôle regardait « folder_color_yellow.svg ». Or ce fichier est la
    # variante jaune NOMMÉE de Fluent : il est jaune dans toutes les
    # versions, y compris celles dont les dossiers sont violets. Éprouvé le
    # 2026-11-09 sur la version du 2026-11-07, d'avant DE-017 :
    #   folder_color_yellow.svg  -> #ffcb52  (le contrôle passait)
    #   default-folder.svg       -> #dc63ee  (ce qu'on voyait à l'écran)
    # Un contrôle qui ne peut pas échouer n'est pas un contrôle.
    #
    # On suit donc « places/folder.svg », qui est le lien que Plasma résout,
    # jusqu'à son fichier réel.
    dossier_svg="$(readlink -f "${icones}/scalable/places/folder.svg" 2>/dev/null || true)"
    [[ -s "${dossier_svg}" ]] \
        || dossier_svg="$(find "${icones}" -name 'default-folder.svg' 2>/dev/null | head -1)"
    verifies=$((verifies + 1))
    if [[ -z "${dossier_svg}" || ! -s "${dossier_svg}" ]]; then
        echo "  ECHEC « places/folder.svg » du thème d'icônes ne mène à aucun dessin" >&2
        echecs=$((echecs + 1))
    elif grep -qi '#ffcb52' "${dossier_svg}" \
            && ! grep -qiE '#a78bfa|#8455f0|#7c3aed|#c4b5fd|#dc63ee' "${dossier_svg}"; then
        printf '  ok    %s\n' "le dossier par défaut porte le jaune de Windows 11, aucun violet"
        printf '        %s\n' "(${dossier_svg##*/}, suivi depuis places/folder.svg)"
    else
        echo "  ECHEC le dossier PAR DÉFAUT n'est pas au jaune de Windows 11 : ${dossier_svg}" >&2
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

#!/usr/bin/env bash
# Captures et mesures du style d'Ankh DE, sans VM et sans Plasma (DE-007).
#
# La galerie des contrôles ne dépend que de Qt Widgets : elle tourne sous
# Xvfb, dans un conteneur. On peut donc mesurer et photographier le style à
# chaque changement, bien avant le test en VM — qui reste nécessaire pour
# tout ce qui touche au shell (barre des tâches, Démarrer, notifications).
#
#   bench/captures.sh [dossier de sortie]
#
# Produit, dans bench/sortie par défaut :
#   ui-<theme>-<style>.png      la galerie, en sombre et en clair,
#                               dans le style d'Ankh et dans Breeze (« avant »)
#   mesures-<theme>-<style>.json  les tailles que le style impose
#   rapport.md                  le tableau des écarts avec jetons.toml
set -euo pipefail

racine="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
sortie="${1:-${racine}/bench/sortie}"
travail="$(mktemp -d)"
trap 'rm -rf "${travail}"' EXIT

install -d -m 0755 "${sortie}"

manquants=()
for outil in cmake Xvfb import; do
    command -v "${outil}" > /dev/null || manquants+=("${outil}")
done
if (( ${#manquants[@]} )); then
    echo "Outils manquants : ${manquants[*]}" >&2
    echo "  Fedora : sudo dnf install cmake xorg-x11-server-Xvfb ImageMagick" >&2
    exit 1
fi

# --- 1. Construire le style et la galerie --------------------------------
echo "== Construction"
prefixe="${travail}/prefixe"
cmake -S "${racine}" -B "${travail}/de" -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${prefixe}" \
    ${ANKH_DE_CMAKE_EXTRA:-} > "${travail}/cmake.log" 2>&1 \
    || { tail -20 "${travail}/cmake.log" >&2; exit 1; }
cmake --build "${travail}/de" -j"$(nproc)" >> "${travail}/cmake.log" 2>&1 \
    || { tail -30 "${travail}/cmake.log" >&2; exit 1; }
cmake --install "${travail}/de" >> "${travail}/cmake.log" 2>&1

# Chaque étape dit pourquoi elle échoue : un « set -e » muet fait perdre
# une demi-heure (vu à la première exécution).
cmake -S "${racine}/bench/galerie" -B "${travail}/galerie" -DCMAKE_BUILD_TYPE=Release \
    >> "${travail}/cmake.log" 2>&1 \
    || { echo "La configuration de la galerie a échoué :" >&2; tail -20 "${travail}/cmake.log" >&2; exit 1; }
cmake --build "${travail}/galerie" -j"$(nproc)" >> "${travail}/cmake.log" 2>&1 \
    || { echo "La compilation de la galerie a échoué :" >&2; tail -30 "${travail}/cmake.log" >&2; exit 1; }
galerie="${travail}/galerie/galerie"

# Qt ne cherche pas les greffons sous un préfixe quelconque : on le lui dit.
greffons="$(find "${prefixe}" -type d -name styles -printf '%h\n' | head -1)"
[[ -n "${greffons}" ]] || { echo "Le greffon de style n'a pas été installé." >&2; exit 1; }
export QT_PLUGIN_PATH="${greffons}"
echo "   style : $(find "${prefixe}" -name 'ankh6.so')"

# La couche de valeurs par défaut que la session installe (DE-010).
config_livre="${prefixe}/share/ankh-de/config"
if [[ ! -r "${config_livre}/kdeglobals" ]]; then
    echo "${config_livre}/kdeglobals n'a pas été installé." >&2
    exit 1
fi
echo "   valeurs par défaut : ${config_livre}/kdeglobals"

# --- 2. Un environnement de session minimal ------------------------------
# Le style lit les couleurs par KColorScheme, donc dans kdeglobals. Appliquer
# un jeu de couleurs, c'est exactement recopier son fichier .colors dedans :
# il porte déjà les groupes [Colors:*].
preparer_session() { # $1 : fichier .colors
    local conf="${travail}/config-$(basename "$1" .colors)"
    install -d -m 0755 "${conf}"
    cp "$1" "${conf}/kdeglobals"
    # Police : Selawik si preparer.sh l'a fabriquée, sinon celle du système.
    local famille='Selawik'
    if [[ -d "${racine}/third_party/sortie/polices/selawik" ]]; then
        # fontconfig cherche les polices dans $XDG_DATA_HOME/fonts : on fait
        # de ${conf} la racine des données ET de la configuration, et on
        # reconstruit le cache, sinon Qt ne voit pas Selawik et fontconfig
        # substitue silencieusement (vu le 2026-11-05 : « Noto Sans »).
        install -d "${conf}/fonts"
        cp "${racine}"/third_party/sortie/polices/selawik/*.ttf "${conf}/fonts/"
        XDG_DATA_HOME="${conf}" fc-cache -f "${conf}/fonts" > /dev/null 2>&1 || true
        if ! XDG_DATA_HOME="${conf}" fc-match -f '%{family[0]}' Selawik 2>/dev/null | grep -qx Selawik; then
            echo "   ERREUR : Selawik est présente mais fontconfig ne la trouve pas." >&2
            exit 1
        fi
    else
        famille="$(fc-match -f '%{family[0]}' sans-serif 2>/dev/null || echo 'DejaVu Sans')"
        echo "   NOTE : Selawik absente (third_party/preparer.sh non lancé) ; police « ${famille} »" >&2
    fi
    # Les polices ne sont PAS écrites ici : elles viennent de la couche que
    # la session d'Ankh DE place dans XDG_CONFIG_DIRS, c'est-à-dire du
    # fichier réellement installé (src/config/kdeglobals). Le banc mesure
    # ainsi ce qu'on livre, et non une configuration écrite pour l'occasion.
    # Quand Selawik manque, on retombe sur la police du système, et seule
    # cette substitution est écrite ici.
    if [[ "${famille}" != Selawik ]]; then
        cat >> "${conf}/kdeglobals" << CONF

[General]
font=${famille},10.5,-1,5,50,0,0,0,0,0
menuFont=${famille},10.5,-1,5,50,0,0,0,0,0
smallestReadableFont=${famille},9,-1,5,50,0,0,0,0,0
CONF
    fi
    echo "${conf}"
}

capturer() { # $1 : nom du thème, $2 : fichier .colors, $3 : style Qt, $4 : étiquette
    local theme=$1 couleurs=$2 style=$3 etiquette=$4
    local conf; conf="$(preparer_session "${couleurs}")"
    local nom="ui-${theme}-${etiquette}"
    local ecran=99
    while [[ -e "/tmp/.X${ecran}-lock" ]]; do ecran=$((ecran + 1)); done

    # 96 ppp, explicitement : toutes les mesures de WinUI sont à 96 ppp, et
    # Xvfb calcule sinon une résolution d'après la taille de l'écran (10,5 pt
    # y donnaient 12 px au lieu de 14 — un défaut du banc, pas du style).
    Xvfb ":${ecran}" -screen 0 1280x900x24 -dpi 96 -nolisten tcp > /dev/null 2>&1 &
    local xvfb=$!
    # Xvfb met un instant à ouvrir sa socket.
    for _ in $(seq 40); do [[ -e "/tmp/.X11-unix/X${ecran}" ]] && break; sleep 0.1; done

    (
        export DISPLAY=":${ecran}"
        export XDG_CONFIG_HOME="${conf}"
        # Exactement ce que fait ankh-de-session : nos valeurs par défaut
        # après celles de l'utilisateur, avant celles de la distribution.
        export XDG_CONFIG_DIRS="${config_livre}:/etc/xdg"
        export QT_QPA_PLATFORM=xcb
        # Comme dans une vraie session : le greffon de thème de plateforme de
        # Plasma, s'il est installé. La galerie applique de toute façon la
        # palette et la police elle-même, pour rester reproductible sans lui.
        export QT_QPA_PLATFORMTHEME=kde
        export QT_SCALE_FACTOR=1
        export QT_FONT_DPI=96
        # Les polices de la session vivent sous ${conf} (voir preparer_session).
        export XDG_DATA_HOME="${conf}"
        # La galerie se photographie elle-même puis se ferme : pas de
        # « sleep » au jugé, pas de fond noir de l'écran Xvfb, et une image
        # identique d'une exécution à l'autre.
        "${galerie}" -style "${style}" \
            --titre "Ankh DE — ${theme}" \
            --mesures "${sortie}/mesures-${theme}-${etiquette}.json" \
            --capture "${sortie}/${nom}.png" > /dev/null 2>&1
    )
    kill "${xvfb}" 2>/dev/null || true
    wait "${xvfb}" 2>/dev/null || true

    if [[ -f "${sortie}/${nom}.png" ]]; then
        echo "   ${nom}.png  $(identify -format '%wx%h' "${sortie}/${nom}.png" 2>/dev/null)"
    else
        echo "   ${nom}.png  MANQUANTE" >&2
    fi
    # Qt retombe en silence sur « fusion » quand le style demandé n'existe
    # pas : une colonne « avant » qui n'est pas Breeze ne compare rien.
    local mesures="${sortie}/mesures-${theme}-${etiquette}.json"
    if [[ -f "${mesures}" ]]; then
        local obtenu
        obtenu="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))[sys.argv[2]])' "${mesures}" style.nom)"
        if [[ "${obtenu,,}" != "${style,,}" ]]; then
            echo "   ERREUR : style « ${style} » demandé, « ${obtenu} » obtenu." >&2
            echo "   Installez-le (Fedora : plasma-breeze-qt6) ou corrigez le nom." >&2
            exit 1
        fi
    fi
}

echo "== Captures"
# « Après » : le style d'Ankh. « Avant » : Breeze, aux mêmes couleurs, pour
# que la comparaison ne porte que sur le style.
for jeu in "sombre:${racine}/src/colors/Ankh.colors" "clair:${racine}/src/colors/AnkhClair.colors"; do
    theme="${jeu%%:*}"; couleurs="${jeu##*:}"
    capturer "${theme}" "${couleurs}" Ankh ankh
    capturer "${theme}" "${couleurs}" Breeze breeze
done

# --- 3. Planches « avant / après » ---------------------------------------
# C'est la pièce qui se regarde : Breeze et Ankh côte à côte, aux mêmes
# couleurs, à la même police, à la même échelle. Seul le style change.
echo "== Planches avant / après"
for theme in sombre clair; do
    avant="${sortie}/ui-${theme}-breeze.png"
    apres="${sortie}/ui-${theme}-ankh.png"
    [[ -f "${avant}" && -f "${apres}" ]] || continue
    fond=$([[ "${theme}" == sombre ]] && echo '#15181f' || echo '#e9eaee')
    texte=$([[ "${theme}" == sombre ]] && echo '#e6edf3' || echo '#1c1f26')
    # Les deux images n'ont pas la même hauteur (les contrôles d'Ankh sont
    # plus grands) : on les met sur une toile commune, alignées en haut, pour
    # que la comparaison porte sur les contrôles et non sur le cadrage.
    hauteur=$(identify -format '%h\n' "${avant}" "${apres}" | sort -rn | head -1)
    largeur=$(identify -format '%w\n' "${avant}" "${apres}" | sort -rn | head -1)
    for cote in "avant|${avant}|Breeze (avant)" "apres|${apres}|Ankh DE (après)"; do
        IFS='|' read -r nom image etiquette <<< "${cote}"
        magick "${image}" \
            -background "${fond}" -gravity north -extent "${largeur}x${hauteur}" \
            -bordercolor "${fond}" -border 24 \
            -background "${fond}" -fill "${texte}" -pointsize 18 \
            -gravity center label:"${etiquette}" -append \
            "${travail}/planche-${nom}.png"
    done
    magick "${travail}/planche-avant.png" "${travail}/planche-apres.png" \
        -background "${fond}" -gravity north +append \
        -bordercolor "${fond}" -border 20 \
        "${sortie}/comparaison-${theme}.png"
    echo "   comparaison-${theme}.png  $(identify -format '%wx%h' "${sortie}/comparaison-${theme}.png")"
done

# --- 4. Aperçus du thème global ------------------------------------------
# Sans eux, Ankh DE apparaît sans vignette dans la page « Thème global » de
# la configuration du système : il a l'air cassé avant d'être essayé. Ils
# sont tirés de la capture du banc, jamais dessinés à la main, donc toujours
# à jour avec ce que le style produit vraiment.
echo "== Aperçus du thème global"
apercus="${racine}/src/lookandfeel/org.ankh.de.desktop/contents/previews"
install -d -m 0755 "${apercus}"
source_apercu="${sortie}/ui-sombre-ankh.png"
if [[ -f "${source_apercu}" ]]; then
    # Vignette de la liste des thèmes : la taille de celle de Breeze.
    magick "${source_apercu}" -resize 400x250^ -gravity north -extent 400x250 \
        "${apercus}/preview.png"
    # Aperçu plein écran : la fenêtre posée sur le fond d'Ankh.
    magick -size 1920x1080 "xc:#1c2027" \
        \( "${source_apercu}" -resize 1100x \) -gravity center -composite \
        -quality 88 "${apercus}/fullscreenpreview.jpg"
    for f in preview.png fullscreenpreview.jpg; do
        echo "   ${f}  $(identify -format '%wx%h' "${apercus}/${f}")"
    done
else
    echo "   capture source absente : aperçus non régénérés" >&2
fi

# --- 5. Rapport ----------------------------------------------------------
echo "== Rapport"
python3 "${racine}/bench/rapport.py" "${sortie}"

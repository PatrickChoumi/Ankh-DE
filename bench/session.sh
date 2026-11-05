#!/usr/bin/env bash
# Mesures et captures de la DÉCORATION des fenêtres (lot 2), dans une vraie
# session KWin — ce que la galerie du banc ne peut pas faire (DE-007).
#
#   ÉTAT : NE FONCTIONNE PAS ENCORE. Ce fichier est gardé parce qu'il porte
#   ce qui a été appris ; il n'est lancé par aucune CI.
#
# Ce qui a été essayé, le 2026-11-05, dans un conteneur Fedora 44 :
#
#   1. « kwin_wayland --x11-display », le compositeur imbriqué dans un
#      serveur X — la façon dont les développeurs de KDE testent KWin sans
#      matériel. L'option existe toujours dans KWin 6.8.2 (« --help » la
#      liste), mais le binaire sort avec le code 1 SANS ÉCRIRE UNE LIGNE,
#      même avec QT_LOGGING_RULES="kwin*=true". Aucun greffon de backend
#      n'est trouvable sur le disque : Plasma 6.8 étant Wayland seul, le
#      backend X11 imbriqué semble ne plus être livré par Fedora.
#      À vérifier auprès de KDE avant de conclure.
#   2. « kwin_x11 », que Fedora livre encore en 6.7.5 : le paquet s'installe
#      mais n'apporte aucun binaire de ce nom à côté de kwin 6.8.2.
#   3. Première embûche, elle résolue : kwin_wayland porte la capability
#      cap_sys_nice. Sans « --cap-add=SYS_NICE », son exec échoue sur
#      « Operation not permitted ».
#
# Les trois voies qui restent, par coût croissant :
#
#   a. une VM sur un runner GitHub (ils exposent /dev/kvm) : c'est ce que
#      fait déjà le dépôt Ankh pour ses tests de démarrage. Voir
#      .github/workflows/vm.yml, qui commence par en établir le fait ;
#   b. un harnais qui charge le greffon de décoration et le dessine hors
#      écran, sans compositeur : c'est ce qu'Ankh appelle « l'aperçu hors
#      écran », et c'est lui qui avait attrapé le défaut d'antialiasing de
#      la croix du bouton Fermer. Demande d'écrire un DecorationBridge ;
#   c. attendre une session Plasma réelle, sur la machine.
#
# Ce que le script fait déjà, et qui est bon à garder : construire, installer,
# préparer un XDG_CONFIG_HOME complet (couleurs, police, kwinrc avec notre
# décoration), lancer Xvfb, attendre qu'une image soit composée plutôt que de
# dormir au jugé, et relever la géométrie du cadre que le gestionnaire de
# fenêtres donne à la fenêtre (bench/galerie l'écrit si un cadre existe).
#
#   bench/session.sh [dossier de sortie]
set -euo pipefail

racine="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
sortie="${1:-${racine}/bench/sortie}"
travail="$(mktemp -d)"
nettoyer() {
    [[ -n "${kwin_pid:-}"  ]] && kill "${kwin_pid}"  2>/dev/null
    [[ -n "${xvfb_pid:-}"  ]] && kill "${xvfb_pid}"  2>/dev/null
    rm -rf "${travail}"
}
trap nettoyer EXIT

install -d -m 0755 "${sortie}"

manquants=()
for outil in cmake Xvfb import kwin_wayland; do
    command -v "${outil}" > /dev/null || manquants+=("${outil}")
done
if (( ${#manquants[@]} )); then
    echo "Outils manquants : ${manquants[*]}" >&2
    echo "  Fedora : sudo dnf install cmake xorg-x11-server-Xvfb ImageMagick kwin kwin-wayland" >&2
    exit 1
fi

# --- 1. Construire et installer le style et la décoration ----------------
echo "== Construction"
prefixe="${travail}/prefixe"
cmake -S "${racine}" -B "${travail}/de" -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${prefixe}" ${ANKH_DE_CMAKE_EXTRA:-} > "${travail}/cmake.log" 2>&1 \
    || { tail -20 "${travail}/cmake.log" >&2; exit 1; }
cmake --build "${travail}/de" -j"$(nproc)" >> "${travail}/cmake.log" 2>&1 \
    || { tail -30 "${travail}/cmake.log" >&2; exit 1; }
cmake --install "${travail}/de" >> "${travail}/cmake.log" 2>&1
cmake -S "${racine}/bench/galerie" -B "${travail}/galerie" -DCMAKE_BUILD_TYPE=Release \
    >> "${travail}/cmake.log" 2>&1
cmake --build "${travail}/galerie" -j"$(nproc)" >> "${travail}/cmake.log" 2>&1

greffons="$(find "${prefixe}" -type d -name styles -printf '%h\n' | head -1)"
[[ -n "${greffons}" ]] || { echo "Greffons introuvables." >&2; exit 1; }
deco="$(find "${prefixe}" -name 'org.ankh.decoration.so' | head -1)"
[[ -n "${deco}" ]] || { echo "La décoration n'a pas été installée." >&2; exit 1; }
echo "   décoration : ${deco}"

# --- 2. Configuration de la session --------------------------------------
theme="${ANKH_DE_THEME:-sombre}"
couleurs="${racine}/src/colors/Ankh.colors"
[[ "${theme}" == clair ]] && couleurs="${racine}/src/colors/AnkhClair.colors"

conf="${travail}/config"
install -d -m 0755 "${conf}" "${conf}/fonts"
cp "${couleurs}" "${conf}/kdeglobals"
famille='Selawik'
if [[ -d "${racine}/third_party/sortie/polices/selawik" ]]; then
    cp "${racine}"/third_party/sortie/polices/selawik/*.ttf "${conf}/fonts/"
    XDG_DATA_HOME="${conf}" fc-cache -f "${conf}/fonts" > /dev/null 2>&1 || true
else
    famille="$(fc-match -f '%{family[0]}' sans-serif)"
    echo "   NOTE : Selawik absente ; police « ${famille} »" >&2
fi
cat >> "${conf}/kdeglobals" << CONF

[General]
font=${famille},10.5,-1,5,50,0,0,0,0,0
menuFont=${famille},10.5,-1,5,50,0,0,0,0,0
smallestReadableFont=${famille},9,-1,5,50,0,0,0,0,0

[KDE]
widgetStyle=Ankh
CONF

# Exactement ce que porte notre thème global (src/lookandfeel/.../defaults).
cat > "${conf}/kwinrc" << 'CONF'
[org.kde.kdecoration2]
library=org.ankh.decoration
ButtonsOnLeft=M
ButtonsOnRight=IAX
BorderSize=None
BorderSizeAuto=false

[Wayland]
InputMethod=
CONF

# --- 3. La session -------------------------------------------------------
echo "== Session KWin (${theme})"
ecran=99
while [[ -e "/tmp/.X${ecran}-lock" ]]; do ecran=$((ecran + 1)); done
Xvfb ":${ecran}" -screen 0 1280x900x24 -dpi 96 -nolisten tcp > "${travail}/xvfb.log" 2>&1 &
xvfb_pid=$!
for _ in $(seq 40); do [[ -e "/tmp/.X11-unix/X${ecran}" ]] && break; sleep 0.1; done

export DISPLAY=":${ecran}"
export XDG_CONFIG_HOME="${conf}"
export XDG_DATA_HOME="${conf}"
export XDG_RUNTIME_DIR="${travail}/run"
install -d -m 0700 "${XDG_RUNTIME_DIR}"
export QT_PLUGIN_PATH="${greffons}"
export QT_QPA_PLATFORMTHEME=kde
export QT_FONT_DPI=96
export QT_QPA_PLATFORM=wayland
export KWIN_COMPOSE=Q          # rendu logiciel : pas de GPU sur un runner
export LIBGL_ALWAYS_SOFTWARE=1
unset WAYLAND_DISPLAY

# KWin ouvre une fenêtre dans le serveur X et y compose la session. La
# galerie, lancée par KWin, reçoit donc une vraie décoration.
kwin_wayland --width 1280 --height 900 --x11-display ":${ecran}" \
    --no-lockscreen --no-global-shortcuts \
    -- "${travail}/galerie/galerie" --titre "Ankh DE" \
    --mesures "${sortie}/mesures-session-${theme}.json" \
    > "${travail}/kwin.log" 2>&1 &
kwin_pid=$!

# La session met un moment à composer la première image.
pret=non
for _ in $(seq 60); do
    sleep 1
    import -window root -silent "${travail}/essai.png" 2>/dev/null || continue
    # Tant que rien n'est composé, l'image est uniformément noire.
    if [[ "$(identify -format '%[standard-deviation]' "${travail}/essai.png" 2>/dev/null || echo 0)" != "0" ]]; then
        pret=oui; break
    fi
done
if [[ "${pret}" != oui ]]; then
    echo "La session n'a rien composé en 60 s." >&2
    tail -25 "${travail}/kwin.log" >&2
    exit 1
fi
sleep 3   # laisser la galerie finir de se dessiner

import -window root -silent "${sortie}/session-${theme}.png"
echo "   session-${theme}.png  $(identify -format '%wx%h' "${sortie}/session-${theme}.png")"

# --- 4. Mesures ----------------------------------------------------------
echo "== Mesures de la décoration"
echo "   (mesures de l.image : étape suivante)"
: python3 "${racine}/bench/mesurer-decoration.py" \
    "${sortie}/session-${theme}.png" \
    "${sortie}/mesures-session-${theme}.json"

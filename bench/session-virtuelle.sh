#!/usr/bin/env bash
# Mesure la DÉCORATION des fenêtres (lot 2) dans un vrai KWin, sans VM.
#
# KWin tourne ici avec son backend « --virtual » : le rendu part dans une
# mémoire tampon, sans écran ni carte graphique. C'est le mode dont KDE se
# sert pour ses propres tests d'intégration. La galerie du banc s'y connecte
# comme un client Wayland ordinaire et reçoit donc une vraie décoration.
#
# Pourquoi passer par le compositeur plutôt que par la fenêtre : sous
# Wayland, un client IGNORE la taille de sa décoration — frameGeometry y vaut
# geometry. Seul KWin la connaît. On lui demande par son scripting, comme le
# fait le banc d'Ankh.
#
#   bench/session-virtuelle.sh [dossier de sortie]
#
# Produit mesures-decoration.json, au format des jetons de bench/jetons.toml.
set -euo pipefail

racine="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
sortie="${1:-${racine}/bench/sortie}"
travail="$(mktemp -d)"
nettoyer() {
    [[ -n "${kwin_pid:-}" ]] && kill "${kwin_pid}" 2>/dev/null
    [[ -n "${bus_pid:-}"  ]] && kill "${bus_pid}"  2>/dev/null
    rm -rf "${travail}"
}
trap nettoyer EXIT
install -d -m 0755 "${sortie}"

for outil in cmake kwin_wayland dbus-daemon; do
    command -v "${outil}" > /dev/null || {
        echo "Outil manquant : ${outil}" >&2
        echo "  Fedora : sudo dnf install cmake kwin dbus-daemon" >&2
        exit 1
    }
done

# --- 1. Construire et installer ------------------------------------------
echo "== Construction"
prefixe="${travail}/prefixe"
cmake -S "${racine}" -B "${travail}/b" -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${prefixe}" ${ANKH_DE_CMAKE_EXTRA:-} > "${travail}/c.log" 2>&1 \
    || { tail -20 "${travail}/c.log" >&2; exit 1; }
cmake --build "${travail}/b" -j"$(nproc)" >> "${travail}/c.log" 2>&1 \
    || { tail -30 "${travail}/c.log" >&2; exit 1; }
cmake --install "${travail}/b" >> "${travail}/c.log" 2>&1
cmake -S "${racine}/bench/galerie" -B "${travail}/g" -DCMAKE_BUILD_TYPE=Release >> "${travail}/c.log" 2>&1
cmake --build "${travail}/g" -j"$(nproc)" >> "${travail}/c.log" 2>&1

deco="$(find "${prefixe}" -name 'org.ankh.decoration.so' | head -1)"
[[ -n "${deco}" ]] || { echo "La décoration n'a pas été installée." >&2; exit 1; }
echo "   décoration : ${deco#${prefixe}/}"

# --- 2. Une session minimale ---------------------------------------------
conf="${travail}/conf"
install -d -m 0755 "${conf}"
cp "${racine}/src/colors/Ankh.colors" "${conf}/kdeglobals"
printf '\n[KDE]\nwidgetStyle=Ankh\n' >> "${conf}/kdeglobals"
# Exactement ce que portent le thème global et la couche de la session.
cat > "${conf}/kwinrc" << 'CONF'
[org.kde.kdecoration2]
library=org.ankh.decoration
ButtonsOnLeft=M
ButtonsOnRight=IAX
BorderSize=None
BorderSizeAuto=false
CONF

export XDG_RUNTIME_DIR="${travail}/run"
install -d -m 0700 "${XDG_RUNTIME_DIR}"
export XDG_CONFIG_HOME="${conf}"
export XDG_CONFIG_DIRS="${prefixe}/share/ankh-de/config:/etc/xdg"
export XDG_DATA_DIRS="${prefixe}/share:/usr/share"
export QT_PLUGIN_PATH="$(find "${prefixe}" -type d -name styles -printf '%h\n' | head -1)"
export QT_QPA_PLATFORMTHEME=kde
export QT_FONT_DPI=96
export LIBGL_ALWAYS_SOFTWARE=1
# Sans cela, KDE journalise dans journald et la sortie du script KWin est
# introuvable (une demi-journée perdue le 2026-11-06).
export QT_FORCE_STDERR_LOGGING=1
export QT_LOGGING_RULES="js.debug=true"
unset WAYLAND_DISPLAY DISPLAY

DBUS_SESSION_BUS_ADDRESS="$(dbus-daemon --session --fork --print-address)"
export DBUS_SESSION_BUS_ADDRESS

# --- 3. KWin, puis la galerie --------------------------------------------
echo "== KWin (backend virtuel)"
socle=ankh-banc
kwin_wayland --virtual --width 1280 --height 800 --socket="${socle}" \
    > "${travail}/kwin.log" 2>&1 &
kwin_pid=$!
for _ in $(seq 60); do
    [[ -S "${XDG_RUNTIME_DIR}/${socle}" ]] && break
    sleep 0.25
done
[[ -S "${XDG_RUNTIME_DIR}/${socle}" ]] || {
    echo "KWin n'a pas créé sa socket :" >&2; tail -20 "${travail}/kwin.log" >&2; exit 1; }
echo "   socket ${socle} prête"

export WAYLAND_DISPLAY="${socle}"
export QT_QPA_PLATFORM=wayland
"${travail}/g/galerie" --titre "Ankh DE" \
    --mesures "${sortie}/mesures-decoration-controles.json" > "${travail}/gal.log" 2>&1 &
# Attendre que KWin voie la fenêtre, plutôt que dormir au jugé.
for _ in $(seq 40); do
    grep -q 'galerie' "${travail}/kwin.log" 2>/dev/null && break
    sleep 0.5
done
sleep 2

# --- 4. Demander la géométrie au COMPOSITEUR -----------------------------
echo "== Géométrie, demandée à KWin"
cat > "${travail}/geo.js" << 'JS'
// Un client Wayland ne connaît pas son cadre : seul le compositeur le sait.
for (const w of workspace.windowList()) {
    if (!w.normalWindow) {
        continue;
    }
    const f = w.frameGeometry;
    const c = w.clientGeometry;
    print("ANKH-GEO"
        + " nom=" + w.resourceName
        + " barre=" + (c.y - f.y)
        + " gauche=" + (c.x - f.x)
        + " droite=" + ((f.x + f.width) - (c.x + c.width))
        + " bas=" + ((f.y + f.height) - (c.y + c.height)));
}
JS
qdbus=""
for q in qdbus6 qdbus-qt6 qdbus; do command -v "$q" > /dev/null && { qdbus="$q"; break; }; done
[[ -n "${qdbus}" ]] || { echo "Aucun outil qdbus." >&2; exit 1; }
"${qdbus}" org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "${travail}/geo.js" ankhgeo > /dev/null
"${qdbus}" org.kde.KWin /Scripting org.kde.kwin.Scripting.start > /dev/null
sleep 2

ligne="$(grep -o 'ANKH-GEO.*' "${travail}/kwin.log" | tail -1 || true)"
if [[ -z "${ligne}" ]]; then
    echo "KWin n'a pas rendu la géométrie :" >&2
    tail -25 "${travail}/kwin.log" >&2
    exit 1
fi
echo "   ${ligne}"

valeur() { sed -n "s/.*[[:space:]]$1=\([-0-9]*\).*/\1/p" <<< "${ligne}"; }
python3 - "${sortie}/mesures-decoration.json" \
    "$(valeur barre)" "$(valeur gauche)" "$(valeur droite)" "$(valeur bas)" \
    "$(kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft)" \
    "$(kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight)" << 'PY'
import json, sys
sortie, barre, gauche, droite, bas, bg, bd = sys.argv[1:8]
json.dump({
    "fenetre.barre_de_titre.hauteur": int(barre),
    "fenetre.bord.gauche": int(gauche),
    "fenetre.bord.droit": int(droite),
    "fenetre.bord.bas": int(bas),
    "fenetre.boutons.gauche": bg,
    "fenetre.boutons.droite": bd,
}, open(sortie, "w"), indent=2, ensure_ascii=False)
print(f"   {sortie} écrit")
PY

# --- 5. Capture de l'écran virtuel ---------------------------------------
# ESSAYÉ LE 2026-11-06, ET ÇA NE MARCHE PAS : org.kde.KWin.ScreenShot2
# répond NoReply et KWin meurt sur un défaut de segmentation. Le backend
# virtuel rend par llvmpipe, sans contexte graphique réel, et le chemin de
# capture de KWin n'y survit pas.
# La capture n'est donc PAS demandée par défaut : elle tuerait le
# compositeur après coup, et un outil qui fait planter ce qu'il mesure est
# pire qu'un outil qui dit ne pas savoir.
# ANKH_DE_CAPTURE=1 la tente quand même, pour réessayer après une mise à
# jour de KWin. Les cinq jetons qu'elle donnerait — rayon des coins, taille
# et couleur du bouton Fermer, alignement du titre — restent à mesurer
# autrement : en VM, ou par le harnais hors écran (voir l'en-tête).
if [[ "${ANKH_DE_CAPTURE:-0}" == 1 ]]; then
    echo "== Capture de l'écran virtuel (ANKH_DE_CAPTURE=1)"
    python3 "${racine}/bench/capture-kwin.py" "${sortie}/session-ankh.png" 2>&1 | sed 's/^/   /' \
        || echo "   capture indisponible, comme attendu" >&2
fi

echo
echo "Mesuré : barre de titre, les trois bords, la disposition des boutons."
echo "NON mesuré ici : rayon des coins, taille et couleur du bouton Fermer,"
echo "alignement du titre — ils demandent une capture de l'écran virtuel."

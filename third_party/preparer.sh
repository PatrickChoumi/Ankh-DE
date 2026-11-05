#!/usr/bin/env bash
# Ankh DE : fabrique les pièces qui viennent d'ailleurs et ne se compilent
# pas avec CMake (DE-005). Chacune est prise à un commit figé, vérifié après
# le téléchargement, et recolorée au violet d'Ankh :
#
#   polices/selawik        la police Selawik, sosie libre de Segoe UI publié
#                          par Microsoft (OFL 1.1), compilée depuis ses
#                          sources UFO ;
#   icones/Ankh-curseurs   les curseurs Fluent blancs (GPL-3.0), dont le bleu
#                          de l'anneau d'attente et des flèches de
#                          redimensionnement devient le violet d'Ankh ;
#   themes/Fluent-Ankh     le thème GTK Fluent (GPL-3.0), variante ronde et
#                          sans bord, au violet d'Ankh, pour que les
#                          applications GTK suivent ;
#   icones/Fluent-Ankh     le thème d'icônes Fluent (GPL-3.0), aux dossiers
#                          violets (lot 9 : pas encore fait).
#
# Dérivé de build_files/outils.sh d'Ankh (https://github.com/PatrickChoumi/Ankh),
# vérifié en VM le 2026-10-20. Différences : plus rien de Fedora (ni rpm, ni
# dnf), la décoration et le style sont compilés par CMake, et le résultat va
# dans third_party/sortie, que le CMake de la racine installe s'il le trouve.
#
# Il n'écrit que dans son dossier de sortie : aucun droit root nécessaire.
set -euo pipefail

racine="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
sortie="${1:-${racine}/third_party/sortie}"
travail="$(mktemp -d)"
trap 'rm -rf "${travail}"' EXIT

readonly SELAWIK_DEPOT=https://github.com/microsoft/Selawik
readonly SELAWIK_COMMIT=89362e84731d1f5777fa078fd4d5ebbd339e4378 # 2023-06-05, sources de la version 1.01
readonly FLUENT_DEPOT=https://github.com/vinceliuice/Fluent-icon-theme
readonly FLUENT_COMMIT=c8a244f571ef8fb47812bdc9dbce76546cedce69 # 2026-08-31
readonly FLUENT_GTK_DEPOT=https://github.com/vinceliuice/Fluent-gtk-theme
readonly FLUENT_GTK_COMMIT=7a49a464b0188c340101c52965c18190b1c694cf # 2026-08-18

# Violets du thème « purple » de Fluent (Material) -> violets d'Ankh : accent
# en clair (#7c3aed) et en sombre (#a78bfa), et les deux teintes des liens
# visités, de la même famille.
readonly VIOLETS_GTK=('AB47BC:7C3AED' 'BA68C8:A78BFA' '9C27B0:6D28D9' 'CE93D8:C4B5FD')
# Bleu d'accent des curseurs Fluent (#0078d4, celui de Windows, et son reflet
# #23e6fa) -> violet d'Ankh (sélection #8455f0 et violet du logo #a78bfa).
readonly COULEURS=('0078d4:8455f0' '23e6fa:a78bfa')
# Tailles de chaque curseur, comme le build.sh des curseurs Fluent.
readonly TAILLES=('x1:32' 'x1_25:40' 'x1_5:48' 'x2:64')

# --- Outils nécessaires ---------------------------------------------------
# Nommés par commande, pas par paquet : chaque distribution les range
# ailleurs. Le message dit quoi installer sur les trois grandes familles.
manquants=()
for outil in git fontmake rsvg-convert xcursorgen sassc fc-scan; do
    command -v "${outil}" > /dev/null || manquants+=("${outil}")
done
if (( ${#manquants[@]} )); then
    cat >&2 << AIDE
Outils manquants : ${manquants[*]}

  Fedora  : sudo dnf install git python3-fontmake librsvg2-tools xorg-x11-apps sassc fontconfig
  Arch    : sudo pacman -S git python-fontmake librsvg xorg-xcursorgen sassc fontconfig
  Ubuntu  : sudo apt install git fontmake librsvg2-bin x11-apps sassc fontconfig
AIDE
    exit 1
fi

# Récupère un dépôt à un commit, seulement les dossiers demandés.
recuperer() { # $1 : dépôt, $2 : commit, $3 : dossier de travail, puis les dossiers voulus
    local depot=$1 commit=$2 dossier=$3
    shift 3
    git init -q "${dossier}"
    git -C "${dossier}" remote add origin "${depot}"
    git -C "${dossier}" sparse-checkout set "$@"
    git -C "${dossier}" fetch -q --depth 1 --filter=blob:none origin "${commit}"
    git -C "${dossier}" checkout -q FETCH_HEAD
    if [[ "$(git -C "${dossier}" rev-parse HEAD)" != "${commit}" ]]; then
        echo "${depot} : commit inattendu $(git -C "${dossier}" rev-parse HEAD)" >&2
        exit 1
    fi
    echo "${depot} : ${commit}"
}

install -d -m 0755 "${sortie}"

echo "== Police Selawik"
recuperer "${SELAWIK_DEPOT}" "${SELAWIK_COMMIT}" "${travail}/selawik" "Source files/UFO"
polices="${sortie}/polices/selawik"
install -d -m 0755 "${polices}"
# Date des fichiers de police : celle du commit, pour que la compilation
# donne toujours les mêmes octets (SOURCE_DATE_EPOCH, lu par ufo2ft).
SOURCE_DATE_EPOCH="$(git -C "${travail}/selawik" log -1 --format=%ct)"
export SOURCE_DATE_EPOCH
for graisse in Light Regular Bold; do
    fontmake -u "${travail}/selawik/Source files/UFO/Selawik-${graisse}.ufo" -o ttf --output-dir "${polices}"
    if [[ "$(fc-scan --format '%{family[0]}' "${polices}/Selawik-${graisse}.ttf")" != Selawik ]]; then
        echo "Selawik ${graisse} : fichier de police illisible" >&2
        exit 1
    fi
done
# Compilée sans modification, elle garde son nom réservé (OFL 1.1,
# « Reserved Font Name »).
install -m 0644 "${travail}/selawik/LICENSE.txt" "${polices}/OFL.txt"
ls -l "${polices}"

echo "== Curseurs Ankh-curseurs"
recuperer "${FLUENT_DEPOT}" "${FLUENT_COMMIT}" "${travail}/fluent" cursors
source_curseurs="${travail}/fluent/cursors/src"
dessins="${travail}/dessins"
cp -r "${source_curseurs}/svg-white" "${dessins}"
for couple in "${COULEURS[@]}"; do
    avant="${couple%%:*}"; apres="${couple##*:}"
    # La couleur doit encore exister : sinon, le dessin a changé en amont et
    # le violet d'Ankh ne serait pas appliqué.
    if ! grep -qil "#${avant}" "${dessins}"/*.svg; then
        echo "Curseurs Fluent : la couleur #${avant} n'existe plus dans les sources" >&2
        exit 1
    fi
    sed -i "s/#${avant}/#${apres}/gI" "${dessins}"/*.svg
done
if grep -qil '#0078d4\|#23e6fa' "${dessins}"/*.svg; then
    echo "Curseurs Fluent : du bleu reste après la recoloration" >&2
    exit 1
fi
images="${travail}/images"
for taille in "${TAILLES[@]}"; do
    install -d "${images}/${taille%%:*}"
    for dessin in "${dessins}"/*.svg; do
        rsvg-convert -w "${taille##*:}" -h "${taille##*:}" \
            -o "${images}/${taille%%:*}/$(basename "${dessin}" .svg).png" "${dessin}"
    done
done
theme="${sortie}/icones/Ankh-curseurs"
rm -rf "${theme}"
install -d -m 0755 "${theme}/cursors"
for config in "${source_curseurs}"/config/*.cursor; do
    xcursorgen -p "${images}" "${config}" "${theme}/cursors/$(basename "${config}" .cursor)"
done
# Autres noms des mêmes curseurs (cursorList : « nom cible »).
while read -r nom cible; do
    if [[ -n "${nom}" && ! -e "${theme}/cursors/${nom}" ]]; then
        ln -s "${cible}" "${theme}/cursors/${nom}"
    fi
done < "${source_curseurs}/cursorList"
for lien in "${theme}"/cursors/*; do
    if [[ ! -e "${lien}" ]]; then
        echo "Curseur sans cible : ${lien}" >&2
        exit 1
    fi
done
cat > "${theme}/index.theme" << 'THEME'
[Icon Theme]
Name=Ankh-curseurs
Comment=Curseurs blancs d'Ankh : curseurs Fluent, au violet d'Ankh
Inherits=breeze_cursors
THEME
install -m 0644 "${travail}/fluent/cursors/LICENSE" "${theme}/LICENSE"
echo "$(find "${theme}/cursors" -type f | wc -l) curseurs, $(find "${theme}/cursors" -type l | wc -l) autres noms"

echo "== Thème GTK Fluent-Ankh"
recuperer "${FLUENT_GTK_DEPOT}" "${FLUENT_GTK_COMMIT}" "${travail}/fluent-gtk" src
fluent_gtk="${travail}/fluent-gtk"
fichiers_violets=(
    "${fluent_gtk}/src/_sass/_color-palette.scss"
    "${fluent_gtk}/src/gtk/assets-purple.svg"
    "${fluent_gtk}/src/gtk-2.0/gtkrc-purple"
    "${fluent_gtk}/src/gtk-2.0/gtkrc-purple-Dark"
    "${fluent_gtk}/src/gtk-2.0/assets-folder/assets-purple.svg"
    "${fluent_gtk}/src/gtk-2.0/assets-folder/assets-purple-Dark.svg"
)
for couple in "${VIOLETS_GTK[@]}"; do
    avant="${couple%%:*}"; apres="${couple##*:}"
    if ! grep -qi "#${avant}" "${fichiers_violets[@]}"; then
        echo "Fluent GTK : #${avant} introuvable dans ses sources" >&2
        exit 1
    fi
    sed -i "s/#${avant}/#${apres}/Ig" "${fichiers_violets[@]}"
done
# Images des contrôles, redessinées depuis les dessins recolorés, à 1x et 2x
# (comme render-assets.sh de Fluent, avec rsvg-convert au lieu d'Inkscape).
redessiner() { # $1 : dossier des images, $2 : dessin, $3 : liste des images
    rm -rf "$1"; mkdir -p "$1"
    while read -r image; do
        [[ -n "${image}" ]] || continue
        rsvg-convert --export-id="${image}" -o "$1/${image}.png" "$2"
        rsvg-convert --export-id="${image}" --zoom=2 -o "$1/${image}@2.png" "$2"
    done < "$3"
}
redessiner "${fluent_gtk}/src/gtk/assets-purple" "${fluent_gtk}/src/gtk/assets-purple.svg" \
    "${fluent_gtk}/src/gtk/assets.txt"
for variante in assets-purple assets-purple-Dark; do
    redessiner "${fluent_gtk}/src/gtk-2.0/assets-folder/${variante}" \
        "${fluent_gtk}/src/gtk-2.0/assets-folder/${variante}.svg" \
        "${fluent_gtk}/src/gtk-2.0/assets-folder/assets.txt"
done
themes="${travail}/themes"; mkdir -p "${themes}"
(cd "${fluent_gtk}" && ./install.sh --dest "${themes}" --name Fluent --theme purple \
    --color light --size standard --tweaks round noborder)
theme="${sortie}/themes/Fluent-Ankh"
rm -rf "${theme}"
install -d -m 0755 "${theme}"
# Seulement ce qui sert à KDE : GTK 2, 3 et 4 (pas GNOME Shell ni Cinnamon).
# Un seul thème : la variante claire, dont gtk-dark.css est celle de la
# variante sombre, octet pour octet. GTK prend la feuille sombre quand KDE
# demande le sombre (gtk-application-prefer-dark-theme, écrit à chaque
# session par kded/gtkconfig.cpp de kde-gtk-config) : le thème suit donc le
# clair et le sombre d'Ankh DE.
cp -r "${themes}/Fluent-round-purple-Light/"{gtk-2.0,gtk-3.0,gtk-4.0} "${theme}/"
install -m 0644 "${fluent_gtk}/COPYING" "${theme}/COPYING"
cat > "${theme}/index.theme" << 'THEME'
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=Fluent-Ankh
Comment=Thème GTK Fluent (vinceliuice/Fluent-gtk-theme, GPL-3.0), au violet d'Ankh
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=Fluent-Ankh
THEME
# Plus aucun violet de Fluent, sauf dans la palette nommée que GTK propose
# aux applications (« @define-color GRAPE_500 #9C27B0 »), qui n'est pas
# l'accent du thème.
for couple in "${VIOLETS_GTK[@]}"; do
    if grep -rhi "#${couple%%:*}" "${theme}" | grep -vE '^@define-color [A-Z0-9_]+ #' > /dev/null; then
        echo "Fluent-Ankh : le violet #${couple%%:*} de Fluent est resté" >&2
        exit 1
    fi
done
for feuille in gtk-3.0/gtk.css gtk-3.0/gtk-dark.css gtk-4.0/gtk.css gtk-4.0/gtk-dark.css; do
    echo "Fluent-Ankh, ${feuille} : $(grep -o -i '#7c3aed\|#a78bfa' "${theme}/${feuille}" | sort | uniq -c | tr '\n' ' ')"
done

echo
echo "Prêt dans ${sortie}. Le CMake de la racine l'installera."

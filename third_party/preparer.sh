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
readonly WM_DEPOT=https://github.com/Jeysef/KDE-Windows-Modern
readonly WM_COMMIT=7ef6bfe99a472f2fc7fa473383eda50f411a8840 # 2026-07-19
readonly FLUENT_GTK_DEPOT=https://github.com/vinceliuice/Fluent-gtk-theme
readonly FLUENT_GTK_COMMIT=7a49a464b0188c340101c52965c18190b1c694cf # 2026-08-18

# Violets du thème « purple » de Fluent (Material) -> violets d'Ankh : accent
# en clair (#7c3aed) et en sombre (#a78bfa), et les deux teintes des liens
# visités, de la même famille.
readonly VIOLETS_GTK=('AB47BC:7C3AED' 'BA68C8:A78BFA' '9C27B0:6D28D9' 'CE93D8:C4B5FD')
# Bleu d'accent des curseurs Fluent (#0078d4, celui de Windows, et son reflet
# #23e6fa) -> violet d'Ankh (sélection #8455f0 et violet du logo #a78bfa).
readonly COULEURS=('0078d4:8455f0' '23e6fa:a78bfa')
# Rose-magenta de la variante « purple » des icônes Fluent -> violets d'Ankh,
# de la teinte principale à la plus claire. Relevé le 2026-11-05 dans ses
# sources : 39 occurrences de #dc63ee, une de #e275f0, une de #ff85de.
readonly VIOLETS_ICONES=('dc63ee:8455f0' 'e275f0:a78bfa' 'ff85de:c4b5fd')
# Thème Plasma de KDE-Windows-Modern : il mêle les accents de Windows 11
# (#4CC2FF et #60CDFF en sombre, #0078D4 en clair) et les bleus de Breeze
# restés dans sa base (#3DAEE9, #3DAEE6, #93CEE9). Tous deviennent les
# violets d'Ankh. Relevé le 2026-11-06 dans le commit figé.
readonly VIOLETS_PLASMA_SOMBRE=(
    '4CC2FF:a78bfa' '60CDFF:c4b5fd'
    '3DAEE9:8455f0' '3DAEE6:8455f0' '93CEE9:c4b5fd'
)
readonly VIOLETS_PLASMA_CLAIR=(
    '0078D4:7c3aed' '4CC2FF:a78bfa'
    '3DAEE9:7c3aed' '3DAEE6:7c3aed' '93CEE9:c4b5fd'
)
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

  Fedora  : sudo dnf install git fontmake librsvg2-tools xcursorgen sassc fontconfig
  Arch    : sudo pacman -S git python-fontmake librsvg xorg-xcursorgen sassc fontconfig
  Ubuntu  : sudo apt install git fontmake librsvg2-bin x11-apps sassc fontconfig
AIDE
    exit 1
fi

# Les modules Python, contrôlés comme les outils — et pour la même raison.
#
# Le 2026-11-07, la recoloration du fond d'écran importait « numpy », absent
# du conteneur Fedora de la CI et de l'invité de la VM : les workflows Banc
# et « VM — session réelle » ont échoué tous les deux, sur un
# « ModuleNotFoundError » survenu APRÈS vingt minutes de travail. Mon
# conteneur, lui, avait numpy — donc rien ne l'avait signalé ici.
#
# La dépendance a été supprimée (Pillow fait la rotation de teinte seul),
# mais le contrôle reste : il échoue en deux secondes au lieu de vingt
# minutes, et il nomme le paquet à installer.
modules=()
python3 -I -c "import PIL" 2> /dev/null || modules+=("PIL (Pillow)")
if (( ${#modules[@]} )); then
    cat >&2 << PYAIDE
Modules Python manquants : ${modules[*]}

  Fedora  : sudo dnf install python3-pillow
  Arch    : sudo pacman -S python-pillow
  Ubuntu  : sudo apt install python3-pil
PYAIDE
    exit 1
fi

# Récupère un dépôt à un commit, seulement les dossiers demandés.
#
# ANKH_DE_SOURCES=/chemin fait travailler le script SANS RÉSEAU, sur des
# sources déjà présentes : c'est la règle de Fedora, de Debian et d'Arch, qui
# interdisent toutes de télécharger pendant la construction d'un paquet
# (AUDIT.md §2.3). Chaque dépôt y est attendu dans un dossier nommé d'après
# lui, au commit voulu ; la fonction vérifie le commit comme elle le ferait
# après un téléchargement.
recuperer() { # $1 : dépôt, $2 : commit, $3 : dossier de travail, puis les dossiers voulus
    local depot=$1 commit=$2 dossier=$3
    shift 3
    if [[ -n "${ANKH_DE_SOURCES:-}" ]]; then
        local nom="${depot##*/}" local_src
        local_src="${ANKH_DE_SOURCES}/${nom}"
        if [[ ! -d "${local_src}" ]]; then
            echo "ANKH_DE_SOURCES : ${local_src} est absent." >&2
            echo "Attendu : un dossier par dépôt, au commit ${commit}." >&2
            exit 1
        fi
        cp -a "${local_src}" "${dossier}"
        # Même exigence que pour un téléchargement : le commit doit être le
        # bon. Une source locale n'est pas une raison de moins vérifier.
        if [[ -d "${dossier}/.git" ]]; then
            local obtenu
            obtenu="$(git -C "${dossier}" rev-parse HEAD)"
            if [[ "${obtenu}" != "${commit}" ]]; then
                echo "${local_src} : commit ${obtenu}, attendu ${commit}" >&2
                exit 1
            fi
        elif [[ -r "${local_src}.commit" ]]; then
            local declare_
            declare_="$(cat "${local_src}.commit")"
            if [[ "${declare_}" != "${commit}" ]]; then
                echo "${local_src}.commit dit ${declare_}, attendu ${commit}" >&2
                exit 1
            fi
        else
            echo "${local_src} : ni dépôt git ni fichier ${nom}.commit." >&2
            echo "Impossible de vérifier qu'il s'agit bien de ${commit}." >&2
            exit 1
        fi
        echo "${depot} : ${commit} (source locale, hors réseau)"
        return 0
    fi
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

echo "== Thème d'icônes Fluent-Ankh (lot 9)"
# Mon choix du 2026-10-15 : les icônes Fluent, au violet d'Ankh. Sa variante
# « purple » est en réalité un rose-magenta (#dc63ee) : on la recolore.
recuperer "${FLUENT_DEPOT}" "${FLUENT_COMMIT}" "${travail}/fluent-icones" src links install.sh
fluent_icones="${travail}/fluent-icones"
dessins_violets=( "${fluent_icones}"/src/scalable/places/purple-*.svg )
if (( ${#dessins_violets[@]} == 0 )); then
    echo "Icônes Fluent : aucun dessin « purple » dans les sources" >&2
    exit 1
fi
for couple in "${VIOLETS_ICONES[@]}"; do
    avant="${couple%%:*}"; apres="${couple##*:}"
    # La couleur doit encore exister : sinon, les dessins ont changé en amont
    # et le violet d'Ankh ne serait pas appliqué.
    if ! grep -qil "#${avant}" "${dessins_violets[@]}"; then
        echo "Icônes Fluent : la couleur #${avant} n'existe plus dans les sources" >&2
        exit 1
    fi
    sed -i "s/#${avant}/#${apres}/gI" "${dessins_violets[@]}"
done
if grep -qil '#dc63ee\|#e275f0\|#ff85de' "${dessins_violets[@]}"; then
    echo "Icônes Fluent : du rose reste après la recoloration" >&2
    exit 1
fi
echo "${#dessins_violets[@]} dessins recolorés"

brut="${travail}/icones-brut"
(cd "${fluent_icones}" && ./install.sh --dest "${brut}" --name Fluent-Ankh purple > /dev/null)

# install.sh nomme la variante « <nom>-purple » et range le gros des dessins
# dans des dossiers cachés que les thèmes atteignent par des liens RELATIFS
# (vérifié : aucun lien absolu). Renommer le dossier du thème est donc sûr.
install -d -m 0755 "${sortie}/icones"
renommer() { # $1 : suffixe produit par install.sh, $2 : notre nom, $3 : libellé
    local source="${brut}/Fluent-Ankh${1}" cible="${sortie}/icones/$2"
    [[ -d "${source}" ]] || { echo "Icônes : ${source} n'a pas été produit" >&2; exit 1; }
    rm -rf "${cible}"
    cp -a "${source}" "${cible}"
    sed -i "s/^Name=.*/Name=$3/" "${cible}/index.theme"
    sed -i "s/^Comment=.*/Comment=Icônes Fluent (vinceliuice\/Fluent-icon-theme, GPL-3.0), au violet d'Ankh/" "${cible}/index.theme"
}
renommer "-purple"       Fluent-Ankh       "Ankh"
renommer "-purple-dark"  Fluent-Ankh-dark  "Ankh (sombre)"
renommer "-purple-light" Fluent-Ankh-light "Ankh (clair)"

# Les variantes sombre et claire atteignent le thème principal PAR SON NOM :
# leurs liens « scalable », « scalable@2x » et « scalable@3x » pointent vers
# « Fluent-Ankh-purple ». Le renommer les casse. On les retarge.
retargetes=0
for variante in Fluent-Ankh Fluent-Ankh-dark Fluent-Ankh-light; do
    while read -r lien; do
        cible="$(readlink "${lien}")"
        case "${cible}" in
            *Fluent-Ankh-purple*)
                ln -sfn "${cible//Fluent-Ankh-purple/Fluent-Ankh}" "${lien}"
                retargetes=$((retargetes + 1))
                ;;
        esac
    done < <(find "${sortie}/icones/${variante}" -type l)
done
echo "${retargetes} lien(s) retargé(s) après le renommage"
# Les dossiers cachés portent l'essentiel des dessins : sans eux, tous les
# liens des thèmes pointent dans le vide.
for base in "${brut}"/.Fluent-Ankh*; do
    [[ -d "${base}" ]] || continue
    rm -rf "${sortie}/icones/$(basename "${base}")"
    cp -a "${base}" "${sortie}/icones/"
done
install -m 0644 "${fluent_icones}/src/../LICENSE" "${sortie}/icones/Fluent-Ankh/LICENSE" 2>/dev/null \
    || install -m 0644 "${travail}/fluent/cursors/LICENSE" "${sortie}/icones/Fluent-Ankh/LICENSE"

# Un thème d'icônes à moitié installé se voit tout de suite et se diagnostique
# mal : il faut vérifier que les liens mènent quelque part. Mais l'amont en
# livre lui-même quelques-uns de morts (gnome-hideseek, regexxer, kerry… des
# icônes d'applications disparues). On compare donc notre copie à ce que
# l'amont produit : un lien mort de plus est une vraie casse, par exemple un
# dossier caché oublié à la copie.
compter_liens_morts() { # $1 : dossier d'un thème
    local n=0 lien
    while read -r lien; do
        [[ -e "${lien}" ]] || n=$((n + 1))
    done < <(find "$1" -type l 2>/dev/null)
    echo "${n}"
}
morts_amont=0
morts_chez_nous=0
for variante in "" "-dark" "-light"; do
    morts_amont=$((morts_amont + $(compter_liens_morts "${brut}/Fluent-Ankh-purple${variante}")))
    morts_chez_nous=$((morts_chez_nous + $(compter_liens_morts "${sortie}/icones/Fluent-Ankh${variante}")))
done
if (( morts_chez_nous > morts_amont )); then
    echo "Icônes Fluent : ${morts_chez_nous} liens morts chez nous contre ${morts_amont} en amont." >&2
    echo "Un dossier a probablement été oublié à la copie. Premiers liens morts :" >&2
    find "${sortie}/icones/Fluent-Ankh" -type l ! -exec test -e {} \; -print 2>/dev/null \
        | head -5 | sed "s|${sortie}/icones/|  |" >&2
    exit 1
fi
echo "liens : ${morts_chez_nous} morts, autant qu'en amont (icônes d'applications disparues)"
# DE-013 : « start-here » de Fluent EST le quadrillage à quatre carreaux de
# Windows. Repéré le 2026-11-06 sur la capture d'une VRAIE session — aucun
# contrôle de licence ne pouvait le voir, le fichier n'étant pas versionné
# chez nous mais fabriqué ici. On le remplace par le logo d'Ankh.
# Toutes les variantes y passent (« -kde », « -kde-plasma », « -symbolic ») :
# n'importe laquelle peut atterrir sur un bouton Démarrer.
nos_icones="${racine}/src/icons/ankh"
[[ -d "${nos_icones}" ]] || { echo "src/icons/ankh manque" >&2; exit 1; }
remplaces=0
while read -r icone; do
    # On prend le dessin calé pour la taille du dossier, sinon le
    # redimensionnable : à 16 px, un trait à cheval sur deux pixels se délave.
    case "${icone}" in
        */16/*|*/16@*) source_icone="${nos_icones}/16/places/start-here.svg" ;;
        */22/*|*/22@*) source_icone="${nos_icones}/22/places/start-here.svg" ;;
        *)             source_icone="${nos_icones}/scalable/places/start-here.svg" ;;
    esac
    # Un lien est retiré, jamais écrasé : écraser un lien réécrirait sa cible.
    [[ -L "${icone}" ]] && rm -f "${icone}"
    install -m 0644 "${source_icone}" "${icone}"
    remplaces=$((remplaces + 1))
done < <(find "${sortie}/icones" -name 'start-here*.svg')
(( remplaces > 0 )) || { echo "Aucun start-here à remplacer : le thème a changé en amont" >&2; exit 1; }
restants=0
while read -r icone; do
    grep -q "Ankh DE" "${icone}" 2>/dev/null || { restants=$((restants + 1)); echo "  resté : ${icone#${sortie}/icones/}" >&2; }
done < <(find "${sortie}/icones" -name 'start-here*.svg')
(( restants == 0 )) || { echo "DE-013 : ${restants} icône(s) « start-here » ne sont pas les nôtres" >&2; exit 1; }
echo "bouton Démarrer : ${remplaces} icône(s) au logo d'Ankh"

echo "Fluent-Ankh : $(find "${sortie}/icones/Fluent-Ankh" | wc -l) entrées ; les trois thèmes et leurs bases font $(du -sh "${sortie}/icones" | cut -f1)"

echo "== Style Plasma d'Ankh (lot 4)"
# SPEC §5.6 interdit d'embarquer un projet tiers comme CODE, mais autorise
# les IMAGES et les FEUILLES DE STYLE à un commit figé : un thème Plasma est
# fait de SVG, il entre donc dans ce qui est permis.
# Source : KDE-Windows-Modern (GPL-3.0), lui-même dérivé de Win11OS-kde et
# de Breeze. Son ATTRIBUTION.md est repris dans docs/UPSTREAMS.md.
recuperer "${WM_DEPOT}" "${WM_COMMIT}" "${travail}/wm" \
    plasma/desktoptheme/Windows-modern-dark plasma/desktoptheme/Windows-modern-light
wm="${travail}/wm/plasma/desktoptheme"

habiller_plasma() { # $1 : dossier amont, $2 : notre nom, $3 : libellé, puis les couples
    local amont="${wm}/$1" nom="$2" libelle="$3"
    shift 3
    local cible="${sortie}/desktoptheme/${nom}"
    [[ -d "${amont}" ]] || { echo "Style Plasma : ${amont} absent des sources" >&2; exit 1; }
    rm -rf "${cible}"
    install -d -m 0755 "$(dirname "${cible}")"
    cp -a "${amont}" "${cible}"

    local couple avant apres
    for couple in "$@"; do
        avant="${couple%%:*}"; apres="${couple##*:}"
        # La couleur doit encore exister : sinon leur thème a changé et
        # l'accent d'Ankh ne serait pas appliqué partout.
        if ! grep -qril "#${avant}" "${cible}"; then
            echo "Style Plasma ${nom} : la couleur #${avant} n'existe plus en amont" >&2
            exit 1
        fi
        grep -rlZi "#${avant}" "${cible}" | xargs -0 sed -i "s/#${avant}/#${apres}/gI"
    done
    for couple in "$@"; do
        if grep -qril "#${couple%%:*}" "${cible}"; then
            echo "Style Plasma ${nom} : #${couple%%:*} est resté" >&2
            exit 1
        fi
    done

    # Le thème se nomme chez nous, et retombe sur Breeze pour ce qu'il
    # ne dessine pas.
    cat > "${cible}/metadata.json" << META
{
    "KPackageStructure": "Plasma/Theme",
    "KPlugin": {
        "Id": "${nom}",
        "Name": "${libelle}",
        "Description": "Style Plasma d'Ankh, dérivé de KDE-Windows-Modern (GPL-3.0)",
        "License": "GPL-3.0-or-later",
        "Website": "https://github.com/PatrickChoumi/Ankh-DE"
    },
    "X-Plasma-API-Minimum-Version": "6.0"
}
META
    echo "${nom} : $(find "${cible}" -type f | wc -l) fichiers, $(du -sh "${cible}" | cut -f1)"
}

habiller_plasma Windows-modern-dark  ankh        "Ankh"         "${VIOLETS_PLASMA_SOMBRE[@]}"
habiller_plasma Windows-modern-light ankh-clair  "Ankh (clair)" "${VIOLETS_PLASMA_CLAIR[@]}"
# Les deux pièces que le lot 4 vise vraiment doivent exister.
for piece in widgets/panel-background.svg widgets/tasks.svg; do
    [[ -f "${sortie}/desktoptheme/ankh/${piece}" ]] \
        || { echo "Style Plasma : ${piece} manque" >&2; exit 1; }
done
echo "panel-background.svg et tasks.svg présents"

echo "== Applets d'Ankh (lot 5 et lot 4 partiel)"
# DE-011 : reprendre le code libre plutôt que le réécrire. Source :
# KDE-Windows-Modern (GPL-3.0), commit figé ; provenance dans
# docs/UPSTREAMS.md. Trois applets seulement, et pour des raisons nommées :
#   - ils sont en QML PUR : rien à compiler, donc rien à reporter en C++ ;
#   - aucun n'écrase une pièce de la distribution. L'applet « icontasks » de
#     ce même dépôt porte l'identifiant « org.kde.plasma.icontasks », celui
#     de l'applet standard de Plasma : il n'est PAS repris (DE-011) ;
#   - la zone système du même dépôt embarque du C++ et remplace un
#     conteneur : remise à plus tard, pour la même raison de prudence.
recuperer "${WM_DEPOT}" "${WM_COMMIT}" "${travail}/wm-applets" \
    plasma/applets/org.kde.windowsmodern.startmenu \
    plasma/applets/org.kde.windowsmodern.digitalclock \
    plasma/applets/org.kde.windowsmodern.showdesktop
wma="${travail}/wm-applets/plasma/applets"

# grep rend 1 quand il ne trouve rien, et 2 ou plus sur une vraie erreur.
# Avec « set -e » et « pipefail », un « rien trouvé » tuait le script en
# silence (vu le 2026-11-06). On distingue les deux, plutôt que de masquer
# l'échec par « || true », que CLAUDE.md §3.12 interdit.
remplacer_partout() { # $1 : motif grep, $2… : expressions sed
    local motif=$1 dossier=$2
    shift 2
    # Pas de « -Z » ici : la substitution de commande de bash supprime les
    # octets nuls, ce qui rendait la liste inutilisable. Les chemins d'un
    # applet ne contiennent pas de retour à la ligne : une liste par lignes
    # suffit, et reste lisible.
    local liste code
    liste="$(grep -rli -- "${motif}" "${dossier}")" && code=0 || code=$?
    case "${code}" in
        0) printf '%s\n' "${liste}" | xargs -r -d '\n' sed -i "$@" ;;
        1) ;;  # aucune correspondance : rien à faire
        *) echo "grep a échoué (code ${code}) sur « ${motif} »" >&2; exit 1 ;;
    esac
}

reprendre_applet() { # $1 : nom amont, $2 : notre identifiant, $3 : libellé
    local amont="${wma}/org.kde.windowsmodern.$1" cible="${sortie}/applets/$2"
    [[ -d "${amont}" ]] || { echo "Applet : ${amont} absent des sources" >&2; exit 1; }
    rm -rf "${cible}"
    install -d -m 0755 "$(dirname "${cible}")"
    cp -a "${amont}" "${cible}"
    # Scripts de développement de l'amont : ils n'ont rien à faire chez nous.
    rm -f "${cible}/dev.sh"

    # L'identifiant est dans metadata.json ET cité dans le QML (chemins de
    # configuration, i18n). On le remplace partout, et on vérifie.
    local ancien="org.kde.windowsmodern.$1"
    remplacer_partout "${ancien}" "${cible}" "s/${ancien}/$2/g"
    # Leur propre domaine, employé pour les chemins de configuration.
    remplacer_partout "com.jeysef.windowsmodern" "${cible}" \
        "s/com\.jeysef\.windowsmodern[a-z]*/$2/g"
    # Tout reste de « windowsmodern » devient « ankh ». Le NOM DE L'AUTEUR,
    # lui, est conservé : c'est l'attribution (docs/UPSTREAMS.md).
    remplacer_partout "windowsmodern" "${cible}" \
        -e "s/WindowsModern/Ankh/g" -e "s/windowsmodern/ankh/g"
    # Et le nom affiché qui cite leur projet, avec son espace.
    remplacer_partout "Windows Modern" "${cible}" "s/ *(\?Windows Modern)\?//g"
    if grep -rqi 'windowsmodern' "${cible}"; then
        echo "Applet $2 : « windowsmodern » est resté" >&2
        grep -ril 'windowsmodern' "${cible}" | head -3 >&2
        exit 1
    fi

    # Nom affiché et licence, à notre nom ; le reste du metadata est gardé.
    python3 -I - "${cible}/metadata.json" "$2" "$3" << 'META'
import json, sys
chemin, ident, libelle = sys.argv[1:4]
with open(chemin, encoding="utf-8") as f:
    d = json.load(f)
k = d.setdefault("KPlugin", {})
k["Id"] = ident
k["Name"] = libelle
# Les traductions du nom d'origine ne valent plus pour le nôtre.
for cle in [c for c in k if c.startswith("Name[")]:
    del k[cle]
k["License"] = "GPL-3.0-or-later"
k["Website"] = "https://github.com/PatrickChoumi/Ankh-DE"
with open(chemin, "w", encoding="utf-8") as f:
    json.dump(d, f, indent=4, ensure_ascii=False)
    f.write("\n")
META
    echo "$2 : $(find "${cible}" -type f | wc -l) fichiers"
}

reprendre_applet startmenu    org.ankh.demarrer "Démarrer"

# Le menu s'ouvrait sans jamais recevoir le clavier — ni la saisie, ni Échap
# (passage en VM du 2026-11-07, deux captures identiques avant et après
# Échap, champ de recherche resté sur son texte d'invite).
#
# La cause est dans libplasma, src/plasmaquick/dialog.cpp, applyType() :
#
#     if (q->flags() & Qt::WindowStaysOnTopHint) {
#         // If the AppletPopup type is not explicitly requested, then use
#         // the Dock type in this case to avoid bug #454635.
#         if (type != Dialog::AppletPopup && type != Dialog::Tooltip) {
#             type = Dialog::Dock;
#
# Le menu pose « flags: Qt.WindowStaysOnTopHint » et ne déclare AUCUN type.
# Le défaut étant « Normal », libplasma le bascule donc en « Dock » et lui
# donne le rôle Wayland « role_panel ». Un panneau ne prend pas le focus
# clavier : le menu s'affiche, reste au-dessus, et n'entend rien.
#
# Le correctif est celui que ce commentaire amont désigne lui-même :
# demander AppletPopup explicitement. La branche garde alors le type, pose
# « role_appletpopup », et la surface redevient un popup qui reçoit les
# touches.
#
# C'est un ADAPT sur une pièce déjà reprise, pas un import (CLAUDE.md §0.1).
menu_rep="${sortie}/applets/org.ankh.demarrer/contents/ui/MenuRepresentation.qml"
sed -i 's|^\( *\)flags: Qt.WindowStaysOnTopHint$|\1flags: Qt.WindowStaysOnTopHint\n\1// Ankh : sans type explicite, libplasma bascule ce dialogue en Dock\n\1// (dialog.cpp, applyType) et un panneau ne reçoit pas le clavier.\n\1type: PlasmaCore.Dialog.AppletPopup|' \
    "${menu_rep}"
grep -q "type: PlasmaCore.Dialog.AppletPopup" "${menu_rep}" \
    || { echo "Menu : le type AppletPopup n'a pas été posé" >&2; exit 1; }
echo "org.ankh.demarrer : type AppletPopup posé (focus clavier)"

# ── La disposition de Windows 11, et non celle de Windows 7 ─────────────
#
# Constat du 2026-11-08, sur une capture de session réelle et non sur une
# impression : le menu repris dessine DEUX colonnes — une liste verticale
# d'épingles à gauche, une colonne « Places » (Home, Documents, Pictures,
# This PC, Run…) à droite — avec la recherche TOUT EN BAS, portant le texte
# littéral de Windows 7 : « Search programs and files ». C'est un menu de
# Windows 7. Windows 11 met la recherche en haut et les épingles en grille.
#
# Les mesures viennent de sources publiées, jamais d'un fichier de Microsoft
# (DE-005) : menu de 642 × 726 à l'échelle 100 %, épingles en 6 colonnes,
# icône de 32 px à 100 % (page « Construct your Windows App's Icon » de
# Microsoft Learn).
demarrer="${sortie}/applets/org.ankh.demarrer"

# 1. La page des épingles : notre grille remplace leur liste. L'API de la
#    page est conservée — mêmes signaux, mêmes fonctions — donc
#    MenuRepresentation n'a rien à savoir du changement.
install -m 0644 "${racine}/src/demarrer/PinnedPage.qml" \
    "${demarrer}/contents/ui/pages/PinnedPage.qml"
grep -q "GridView" "${demarrer}/contents/ui/pages/PinnedPage.qml" \
    || { echo "Menu : la grille des épingles n'a pas été posée" >&2; exit 1; }

# 2. Les dimensions. Le rapport à gridUnit garde les 642 × 726 quand la
#    police grandit, comme pour les 48 px de la barre.
sed -i 's|^\( *\)width: leftColumnWidth + rightColumnWidth + Kirigami.Units.gridUnit \* 3$|\1// Ankh : 642 x 726, les mesures du menu de Windows 11 à 100 %.\n\1width: Math.round(642 * (Kirigami.Units.gridUnit / 18))|' \
    "${demarrer}/contents/ui/MenuRepresentation.qml"
sed -i 's|^\( *\)height: mainContentHeight + bottomBar.height + Kirigami.Units.gridUnit \* 3$|\1height: Math.round(726 * (Kirigami.Units.gridUnit / 18))|' \
    "${demarrer}/contents/ui/MenuRepresentation.qml"
grep -q "642 \* (Kirigami.Units.gridUnit / 18)" "${demarrer}/contents/ui/MenuRepresentation.qml" \
    || { echo "Menu : la largeur de Windows 11 n'a pas été posée" >&2; exit 1; }
grep -q "726 \* (Kirigami.Units.gridUnit / 18)" "${demarrer}/contents/ui/MenuRepresentation.qml" \
    || { echo "Menu : la hauteur de Windows 11 n'a pas été posée" >&2; exit 1; }

# 3. Le texte d'invite de la recherche. « Search programs and files » est
#    la chaîne de Windows 7, et elle sautait aux yeux sur la capture.
sed -i 's|placeholderText: i18n("Search programs and files")|placeholderText: i18n("Search for apps, settings, and documents")|' \
    "${demarrer}/contents/ui/components/BottomBar.qml"
grep -q 'Search for apps, settings, and documents' "${demarrer}/contents/ui/components/BottomBar.qml" \
    || { echo "Menu : le texte d'invite de Windows 7 est resté" >&2; exit 1; }

# 4. La colonne « Places » n'existe pas dans Windows 11. L'amont la rend
#    déjà facultative : on change SON DÉFAUT plutôt que son code — c'est
#    configurer le natif avant d'y toucher (CLAUDE.md §0.1).
python3 -I - "${demarrer}/contents/config/main.xml" << 'CONFIG'
import re, sys
chemin = sys.argv[1]
with open(chemin, encoding="utf-8") as f:
    xml = f.read()
avant = xml
xml = re.sub(
    r'(<entry name="showRightColumn" type="Bool">\s*<default>)true(</default>)',
    r'\1false\2', xml, count=1)
if xml == avant:
    print("Menu : le défaut de showRightColumn n'a pas été trouvé", file=sys.stderr)
    sys.exit(1)
with open(chemin, "w", encoding="utf-8") as f:
    f.write(xml)
CONFIG
grep -A2 'name="showRightColumn"' "${demarrer}/contents/config/main.xml" | grep -q '<default>false</default>' \
    || { echo "Menu : la colonne « Places » est encore affichée par défaut" >&2; exit 1; }

echo "org.ankh.demarrer : grille 6 colonnes, 642x726, sans colonne « Places »"
# L'horloge et « Afficher le bureau » de KDE-Windows-Modern ne sont PLUS
# reprises (DE-015). Plasma fait les deux, en natif :
#   - org.kde.plasma.digitalclock met la date SOUS l'heure
#     (dateDisplayFormat=BelowTime, applets/digital-clock/main.xml de
#     plasma-workspace) — donc la forme de Windows 11 — et apporte en plus
#     un calendrier, un agenda et les fuseaux, que la nôtre n'avait pas ;
#   - org.kde.plasma.showdesktop est la même bande au coin droit.
# Les reprendre n'ajoutait rien et nous laissait deux pièces à reporter à
# chaque version de Plasma.

# --- Tidewater : plus rien n'en est repris (DE-015) ----------------------
#
# Ce script a repris de Tidewater (4484377, GPL-3.0) six pièces les
# 2026-11-06 et 2026-11-07 : org.ankh.etat (paramètres rapides),
# org.ankh.notifications, org.ankh.taches, org.ankh.vuetaches,
# org.ankh.separateur et ankh-selecteur (Alt+Tab), plus leur module QML
# partagé.
#
# TOUTES sont retirées, et la raison n'est ni la licence ni la qualité de
# Tidewater — c'est que pas UNE n'a jamais été prouvée interactive. Trois
# passages en VM de suite les ont trouvées « installées » et « chargées »,
# jamais « qui répondent » (les cinq états de CLAUDE.md §0.2). Pendant ce
# temps, Plasma livre pour chacune une pièce native qui marche, traduite,
# accessible, et qui n'a rien à reporter à chaque version :
#
#   org.ankh.etat          -> org.kde.plasma.{volume,networkmanagement,
#                             bluetooth,brightness} dans la zone système
#   org.ankh.notifications -> org.kde.plasma.notifications
#   org.ankh.taches        -> org.kde.plasma.icontasks
#   org.ankh.vuetaches     -> l'effet Overview de KWin (Meta+W), DEFER
#   org.ankh.separateur    -> org.kde.plasma.panelspacer, longueur fixe 9 px
#   ankh-selecteur         -> « thumbnail_grid », le sélecteur natif de KWin
#
# Le volet d'état était le plus coûteux des six : pour lui faire place, la
# disposition MASQUAIT les cinq applets natives de la zone système. Ankh DE
# retirait donc le contrôle du volume, du Wi-Fi, du Bluetooth et de la
# luminosité pour les remplacer par un panneau qui pilotait le matériel par
# « wpctl », « nmcli », « rfkill » et « bluetoothctl », et dont aucune tuile
# n'avait jamais été pressée.
#
# Le module QML partagé (« ankh-de/qml ») disparaît avec eux : il n'existait
# que pour ces applets. Rien d'autre ne le lisait.
#
# Ce qui vient de KDE-Windows-Modern reste : le menu Démarrer a été prouvé
# interactif (09e4950), et le style Plasma porte notre identité.

# --- Le fond d'écran : « Prismes d'Ankh » --------------------------------
#
# Pas dessiné ici, et c'est délibéré. Trois tentatives de fond fait maison
# ont été jetées le 2026-11-07 — un ankh géant qui se lisait comme le symbole
# de Vénus, des voiles de lumière, des crêtes molles comme de la cire. Le
# défaut commun était le flou : des dégradés doux, aucun contraste de valeur.
#
# Les fonds qui tiennent ont l'inverse : arêtes nettes, facettes à dégradé
# linéaire, écart de valeur franc entre la face éclairée et celle à l'ombre.
# AnduinOS en livre deux, clair et sombre, en GPL-3.0 — même famille Fluent
# que le thème GTK et le thème d'icônes que ce script reprend déjà.
#
# On les reprend, et on les fait nôtres par une ROTATION DE TEINTE : les
# valeurs sont conservées, donc le modelé des facettes aussi. C'est la même
# méthode que pour le thème d'icônes, où le rose de la variante « purple »
# devient le violet d'Ankh.
ANDUIN_COMMIT=c659fae21267ba8c6d93c3d313147c8b17cf63da
recuperer https://github.com/Anduin2017/AnduinOS "${ANDUIN_COMMIT}" \
    "${travail}/anduin" src/mods/23-wallpaper-mod
fonds="${travail}/anduin/src/mods/23-wallpaper-mod"

paquet="${sortie}/wallpapers/Ankh-Prismes"
rm -rf "${paquet}"
install -d -m 0755 "${paquet}/contents/images" "${paquet}/contents/images_dark"
python3 -I "${racine}/third_party/recolorer-fond.py" \
    "${fonds}/Fluent-building-light.png" "${paquet}/contents/images/3840x2160.png"
python3 -I "${racine}/third_party/recolorer-fond.py" \
    "${fonds}/Fluent-building-night.png" "${paquet}/contents/images_dark/3840x2160.png"

# La vignette de la page « Fond d'écran » de Plasma : la variante sombre,
# qui est celle par défaut d'Ankh DE.
python3 -I -c "
from PIL import Image
import sys
im = Image.open(sys.argv[1])
im.resize((1280, 720), Image.LANCZOS).save(sys.argv[2], optimize=True)
" "${paquet}/contents/images_dark/3840x2160.png" "${paquet}/contents/screenshot.png"

# « X-KDE-PlasmaImageWallpaper-AccentColor » : c'est par cette clé que
# l'accent de Plasma suit le fond d'écran (DE-004). Sans elle, Plasma
# calcule une couleur depuis l'image, et tombe sur un violet voisin mais pas
# sur LE violet d'Ankh.
cat > "${paquet}/metadata.json" << 'FOND'
{
    "KPlugin": {
        "Authors": [
            {
                "Name": "AnduinOS"
            },
            {
                "Name": "Ankh DE (recoloration)"
            }
        ],
        "Id": "Ankh-Prismes",
        "License": "GPL-3.0-or-later",
        "Name": "Prismes d'Ankh",
        "Name[en]": "Ankh Prisms"
    },
    "X-KDE-PlasmaImageWallpaper-AccentColor": {
        "Light": "#7c3aed",
        "Dark": "#a78bfa"
    }
}
FOND

for f in "${paquet}/contents/images/3840x2160.png" \
         "${paquet}/contents/images_dark/3840x2160.png" \
         "${paquet}/contents/screenshot.png"; do
    [[ -s "${f}" ]] || { echo "Fond d'écran : ${f} n'a pas été produit" >&2; exit 1; }
done
echo "Ankh-Prismes : $(du -sh "${paquet}" | cut -f1), clair + sombre + vignette"

# Aucun de nos applets ne doit porter un identifiant de Plasma : ce serait
# écraser une pièce de la distribution (DE-011).
for m in "${sortie}"/applets/*/metadata.json; do
    ident="$(python3 -I -c 'import json,sys;print(json.load(open(sys.argv[1]))["KPlugin"]["Id"])' "${m}")"
    case "${ident}" in
        org.ankh.*) ;;
        *) echo "Applet : identifiant « ${ident} » hors de org.ankh.* " >&2; exit 1 ;;
    esac
done
echo "identifiants vérifiés : tous en org.ankh.*"

echo
echo "Prêt dans ${sortie}. Le CMake de la racine l'installera."

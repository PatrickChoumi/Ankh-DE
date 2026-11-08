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

# ── Les couleurs : celles de Windows 11, et on cesse de les repeindre ────
#
# Jusqu'au 2026-11-08, cinq tableaux teintaient en violet d'Ankh les couleurs
# des pièces amont. Or ces couleurs SONT celles de Windows 11 : les curseurs
# Fluent portent #0078d4, le thème Plasma porte #4CC2FF et #60CDFF. On les
# repeignait pour les reteindre, et il suffit de ne plus le faire.
#
# Deux pièces demandent mieux qu'une suppression : elles étaient construites
# dans leur variante VIOLETTE, qu'il faut remplacer par la bonne, pas
# simplement cesser de recolorer.
#   - icônes : variante « yellow » (#ffcb52), et non « purple ». Relevé sur
#     une capture de Windows 11 fournie par le propriétaire le 2026-11-08 :
#     le dossier de « File Explorer » y est à #ffcd3e–#ffd14d. C'est donc
#     une mesure, pas un goût.
#   - thème GTK : variante par défaut, qui est le bleu (install.sh de
#     Fluent-gtk-theme : « Default: blue »), et non « purple ».
#
# Il reste UNE recoloration, et elle va dans l'autre sens : le thème Plasma
# de KDE-Windows-Modern a gardé des bleus de BREEZE dans sa base (#3DAEE9,
# #3DAEE6, #93CEE9), qui ne sont pas ceux de Windows. On les amène sur les
# accents de Windows 11 au lieu de les laisser.
readonly BREEZE_VERS_WINDOWS_SOMBRE=(
    '3DAEE9:4CC2FF' '3DAEE6:4CC2FF' '93CEE9:60CDFF'
)
readonly BREEZE_VERS_WINDOWS_CLAIR=(
    '3DAEE9:0078D4' '3DAEE6:0078D4' '93CEE9:4CC2FF'
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
# Aucune recoloration : l'anneau d'attente des curseurs Fluent est déjà à
# #0078d4, l'accent de Windows 11. On le vérifie quand même — s'il
# disparaissait en amont, les curseurs cesseraient d'être ceux de Windows
# sans que rien ne le dise.
if ! grep -qil '#0078d4' "${dessins}"/*.svg; then
    echo "Curseurs Fluent : l'accent #0078d4 de Windows a disparu des sources" >&2
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
# On construit la variante PAR DÉFAUT de Fluent, qui est « bleue » — mais
# PAS du bleu de Windows : l'écho du 2026-11-08 montre #1a73e8 (le bleu de
# Google) comme couleur dominante de ses feuilles, 89 fois dans gtk-3.0.
# C'est donc la SEULE recoloration qui reste du côté GTK, et elle va vers la
# cible au lieu de s'en éloigner. Jusqu'au 2026-11-08 on construisait la
# variante « purple » puis on la repeignait en violet d'Ankh : deux étapes
# pour s'éloigner de la cible.
themes="${travail}/themes"; mkdir -p "${themes}"
(cd "${fluent_gtk}" && ./install.sh --dest "${themes}" --name Fluent \
    --color light --size standard --tweaks round noborder)
theme="${sortie}/themes/Fluent-Ankh"
rm -rf "${theme}"
install -d -m 0755 "${theme}"
# Seulement ce qui sert à KDE : GTK 2, 3 et 4 (pas GNOME Shell ni Cinnamon).
# Un seul thème : la variante claire, dont gtk-dark.css est celle de la
# variante sombre, octet pour octet. GTK prend la feuille sombre quand KDE
# demande le sombre (gtk-application-prefer-dark-theme, écrit à chaque
# session par kded/gtkconfig.cpp de kde-gtk-config) : le thème suit donc le
# clair et le sombre.
produit="${themes}/Fluent-round-Light"
[[ -d "${produit}" ]] || {
    echo "Fluent GTK : « ${produit} » absent ; install.sh a nommé sa sortie autrement :" >&2
    ls -1 "${themes}" >&2
    exit 1
}
cp -r "${produit}/"{gtk-2.0,gtk-3.0,gtk-4.0} "${theme}/"
# #1a73e8 (bleu de Google) -> #0078D4 (accent de Windows 11), et sa variante
# appuyée. Relevé sur les feuilles produites, pas deviné.
# UNE seule couleur est exigée, #1a73e8, parce que c'est la seule que
# l'écho a réellement montrée (89 fois dans gtk-3.0). Les deux autres sont
# ses variantes probables : on les recolore SI elles sont là, sans les
# exiger. Mon premier jet exigeait les trois et faisait échouer le banc sur
# une couleur supposée — le garde-fou était faux, pas le thème.
grep -rqiF '#1a73e8' "${theme}" \
    || { echo "Fluent GTK : #1a73e8 a disparu de ses feuilles ; la variante a changé" >&2; exit 1; }
for couple in '1a73e8:0078D4' '1967d2:005FB8' '8ab4f8:4CC2FF'; do
    avant="${couple%%:*}"; apres="${couple##*:}"
    # « || true » OBLIGATOIRE, et c'est la troisième fois que ce dépôt y
    # tombe. Sous « set -o pipefail », un grep qui ne trouve rien rend 1,
    # le pipeline rend 1, et « set -e » tue le script SANS UN MOT. Le
    # passage f9add82 est mort exactement là, juste après le « Done. » de
    # install.sh, sans message : #1967d2 n'existe pas dans ces feuilles.
    { grep -rliZ --include='*.css' --include='*.rc' -i "#${avant}" "${theme}" 2>/dev/null || true; } \
        | xargs -0 -r sed -i "s/#${avant}/#${apres}/gI"
done
grep -rqiF '#1a73e8' "${theme}" \
    && { echo "Fluent-Ankh : le bleu de Google est resté" >&2; exit 1; }
install -m 0644 "${fluent_gtk}/COPYING" "${theme}/COPYING"
cat > "${theme}/index.theme" << 'THEME'
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=Fluent-Ankh
Comment=Thème GTK Fluent (vinceliuice/Fluent-gtk-theme, GPL-3.0), couleurs d'origine
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=Fluent-Ankh
THEME
# Le thème doit porter l'accent de Windows et AUCUN violet d'Ankh. Les deux
# sens sont vérifiés : un thème qui aurait perdu son bleu serait aussi faux
# qu'un thème resté violet.
if grep -rqiE '#(7c3aed|a78bfa|8455f0|c4b5fd)' "${theme}"; then
    echo "Fluent-Ankh : un violet d'Ankh est resté dans le thème GTK" >&2
    grep -rliE '#(7c3aed|a78bfa|8455f0|c4b5fd)' "${theme}" | head -3 >&2
    exit 1
fi
# Ce qu'on affiche, c'est la couleur d'accent RÉELLEMENT présente, et non
# un hexadécimal deviné : le premier jet cherchait #0078d4 et ne trouvait
# rien, donc n'apprenait rien.
# On ne devine plus quel hexadécimal chercher — les deux tentatives
# précédentes n'affichaient rien du tout, donc n'apprenaient rien. On montre
# les trois couleurs les plus fréquentes, quelles qu'elles soient.
for feuille in gtk-3.0/gtk.css gtk-4.0/gtk.css; do
    echo "Fluent-Ankh, ${feuille} : $(grep -ohiE '#[0-9a-f]{6}' "${theme}/${feuille}" | tr 'A-F' 'a-f' | sort | uniq -c | sort -rn | head -3 | tr '\n' ' ')"
done

echo "== Thème d'icônes Fluent-Ankh (lot 9)"
# La variante « yellow » de Fluent, et AUCUNE recoloration (DE-017).
#
# Le choix de la variante est une mesure, pas un goût : sur la capture de
# Windows 11 fournie par le propriétaire le 2026-11-08, le dossier de
# « File Explorer » est à #ffcd3e–#ffd14d. La variante « yellow » de Fluent
# vaut #ffcb52 (install.sh, « case $color in »), soit le même jaune ambré.
# Les autres candidates en sont loin : « standard » est bleu (#198ee6) et
# « orange » tire au #ff9c33.
#
# Jusqu'au 2026-11-08 on construisait « purple » — en réalité un rose-magenta
# #dc63ee — puis on la repeignait au violet d'Ankh.
recuperer "${FLUENT_DEPOT}" "${FLUENT_COMMIT}" "${travail}/fluent-icones" src links install.sh
fluent_icones="${travail}/fluent-icones"
dessins_jaunes=( "${fluent_icones}"/src/scalable/places/yellow-*.svg )
if (( ${#dessins_jaunes[@]} == 0 )); then
    echo "Icônes Fluent : aucun dessin « yellow » dans les sources" >&2
    exit 1
fi
if ! grep -qil '#ffcb52' "${dessins_jaunes[@]}"; then
    echo "Icônes Fluent : le jaune #ffcb52 a disparu des sources ; la variante a changé" >&2
    exit 1
fi
echo "${#dessins_jaunes[@]} dessins « yellow », repris tels quels"

brut="${travail}/icones-brut"
(cd "${fluent_icones}" && ./install.sh --dest "${brut}" --name Fluent-Ankh yellow > /dev/null)

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
    sed -i "s/^Comment=.*/Comment=Icônes Fluent (vinceliuice\/Fluent-icon-theme, GPL-3.0), variante jaune de Windows 11/" "${cible}/index.theme"
}
renommer "-yellow"       Fluent-Ankh       "Ankh"
renommer "-yellow-dark"  Fluent-Ankh-dark  "Ankh (sombre)"
renommer "-yellow-light" Fluent-Ankh-light "Ankh (clair)"

# Les variantes sombre et claire atteignent le thème principal PAR SON NOM :
# leurs liens « scalable », « scalable@2x » et « scalable@3x » pointent vers
# « Fluent-Ankh-yellow ». Le renommer les casse. On les retarge.
retargetes=0
for variante in Fluent-Ankh Fluent-Ankh-dark Fluent-Ankh-light; do
    while read -r lien; do
        cible="$(readlink "${lien}")"
        case "${cible}" in
            *Fluent-Ankh-yellow*)
                ln -sfn "${cible//Fluent-Ankh-yellow/Fluent-Ankh}" "${lien}"
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
    morts_amont=$((morts_amont + $(compter_liens_morts "${brut}/Fluent-Ankh-yellow${variante}")))
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
# Le « start-here » de Fluent est remplacé par le nôtre (DE-013, DE-017).
#
# Le dessin de Fluent reprend le logo de Microsoft, qui est une marque
# déposée : il ne peut pas être livré par un dépôt public. Le nôtre est une
# grille de quatre carreaux monochromes — un motif d'interface courant, aux
# couleurs du thème, sans les proportions ni les teintes de la marque. Qui
# veut exactement le bouton de Windows le met lui-même : l'applet offre
# « useCustomButtonImage », et docs/INSTALL.md l'explique.
#
# Repéré le 2026-11-06 sur la capture d'une VRAIE session — aucun contrôle de
# licence ne pouvait le voir, le fichier n'étant pas versionné chez nous mais
# fabriqué ici.
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
    grep -q "ankh-de-demarrer" "${icone}" 2>/dev/null || { restants=$((restants + 1)); echo "  resté : ${icone#${sortie}/icones/}" >&2; }
done < <(find "${sortie}/icones" -name 'start-here*.svg')
(( restants == 0 )) || { echo "${restants} icône(s) « start-here » ne sont pas les nôtres : le logo de Microsoft serait livré" >&2; exit 1; }
echo "bouton Démarrer : ${remplaces} icône(s) remplacées par la grille neutre"

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
        "Description": "Style Plasma aux couleurs de Windows 11, dérivé de KDE-Windows-Modern (GPL-3.0)",
        "License": "GPL-3.0-or-later",
        "Website": "https://github.com/PatrickChoumi/Ankh-DE"
    },
    "X-Plasma-API-Minimum-Version": "6.0"
}
META
    # L'amont livre AUSSI un metadata.desktop, que nous ne réécrivions pas :
    # il annonçait encore « Name=Windows-modern-dark » et l'auteur amont. Un
    # paquet qui porte deux identités selon le fichier lu finit par en
    # afficher une qu'on n'a pas choisie.
    if [[ -f "${cible}/metadata.desktop" ]]; then
        sed -i -e "s/^Name=.*/Name=${libelle}/" \
               -e "s/^X-KDE-PluginInfo-Name=.*/X-KDE-PluginInfo-Name=${nom}/" \
               -e "s|^Comment=.*|Comment=Style Plasma aux couleurs de Windows 11, dérivé de KDE-Windows-Modern (GPL-3.0)|" \
               "${cible}/metadata.desktop"
        grep -q "^Name=${libelle}$" "${cible}/metadata.desktop" \
            || { echo "Style Plasma ${nom} : metadata.desktop n'a pas été renommé" >&2; exit 1; }
    fi
    echo "${nom} : $(find "${cible}" -type f | wc -l) fichiers, $(du -sh "${cible}" | cut -f1)"
}

# Les accents de Windows 11 que porte déjà l'amont (#4CC2FF, #60CDFF en
# sombre, #0078D4 en clair) sont GARDÉS. Seuls les bleus de Breeze restés
# dans sa base sont amenés sur ceux de Windows (DE-017).
habiller_plasma Windows-modern-dark  ankh        "Windows 11"         "${BREEZE_VERS_WINDOWS_SOMBRE[@]}"
habiller_plasma Windows-modern-light ankh-clair  "Windows 11 (clair)" "${BREEZE_VERS_WINDOWS_CLAIR[@]}"
# Le thème doit porter l'accent de Windows, et aucun violet d'Ankh. Les deux
# sens, parce qu'un thème qui aurait perdu son bleu serait aussi faux qu'un
# thème resté violet.
for style in ankh ankh-clair; do
    if grep -rqiE '#(7c3aed|a78bfa|8455f0|c4b5fd)' "${sortie}/desktoptheme/${style}"; then
        echo "Style Plasma ${style} : un violet d'Ankh est resté" >&2
        exit 1
    fi
done
grep -rqi '#4CC2FF' "${sortie}/desktoptheme/ankh" \
    || { echo "Style Plasma ankh : l'accent #4CC2FF de Windows a disparu" >&2; exit 1; }
grep -rqi '#0078D4' "${sortie}/desktoptheme/ankh-clair" \
    || { echo "Style Plasma ankh-clair : l'accent #0078D4 de Windows a disparu" >&2; exit 1; }

# Le « colors » du thème Plasma est en RGB DÉCIMAL, pas en hexadécimal : la
# substitution ci-dessus ne l'a jamais touché, dans un sens comme dans
# l'autre. Il porte donc encore les accents de Windows (76,194,255 = #4CC2FF
# et 96,205,255 = #60CDFF), ce qui est exactement ce qu'on veut maintenant.
# On le vérifie plutôt que de le supposer.
# Les deux variantes n'ont pas le même accent, et c'est juste : l'amont
# transcrit #4CC2FF en sombre (76,194,255) et #0067C0 en clair (0,103,192),
# qui sont les deux accents de Windows 11. Mon premier garde-fou n'attendait
# que la valeur sombre et a fait échouer le banc sur le thème clair — le
# contrôle était faux, pas le thème.
declare -A ACCENT_ATTENDU=( [ankh]='76,194,255' [ankh-clair]='0,103,192' )
for style in ankh ankh-clair; do
    f="${sortie}/desktoptheme/${style}/colors"
    [[ -f "${f}" ]] || continue
    grep -qF "${ACCENT_ATTENDU[${style}]}" "${f}" \
        || { echo "Style Plasma ${style} : « colors » ne porte plus l'accent ${ACCENT_ATTENDU[${style}]} de Windows" >&2; exit 1; }
done
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

# Nos quatre fichiers remplacent ceux de l'amont. On COPIE au lieu de
# rapiécer par sed : la refonte touche l'arbre visuel entier, et quatre des
# sed d'hier seraient devenus des no-ops silencieux — « sed -i » sort en 0
# quand il ne remplace rien.
#
# En contrepartie, un changement amont ne casse plus la construction : c'est
# la propriété que les sed donnaient gratuitement. Les « grep -q » qui
# suivent la remplacent, et ils vérifient maintenant quelque chose de plus
# utile — non pas « mon sed a-t-il mordu », mais « le fichier livré porte-t-il
# bien la forme de Windows 11 ».
for f in MenuRepresentation.qml components/BottomBar.qml \
         components/PowerButton.qml pages/PinnedPage.qml; do
    install -m 0644 "${racine}/src/demarrer/$(basename "${f}")" "${demarrer}/contents/ui/${f}"
done

# Ce que le menu livré DOIT porter. Chaque ligne : fichier | motif | ce qui
# serait faux sans lui.
verifier_menu() { # $1 : fichier, $2 : motif, $3 : ce qu'on perdrait
    grep -q "$2" "${demarrer}/contents/ui/$1" \
        || { echo "Menu : ${1} ne porte pas « $2 » — $3" >&2; exit 1; }
}
verifier_menu MenuRepresentation.qml "642 \* (Kirigami.Units.gridUnit / 18)" "la largeur de Windows 11"
verifier_menu MenuRepresentation.qml "726 \* (Kirigami.Units.gridUnit / 18)" "la hauteur de Windows 11"
verifier_menu MenuRepresentation.qml "type: PlasmaCore.Dialog.AppletPopup"    "le menu ne prendrait pas le clavier"
verifier_menu MenuRepresentation.qml "id: mainColumn"                         "la colonne unique de Windows 11"
verifier_menu MenuRepresentation.qml "id: pageSlot"                           "SearchPage entrerait en boucle de liaison"
verifier_menu MenuRepresentation.qml "Kicker.RecentUsageModel"                "la section « Recommandé »"
verifier_menu MenuRepresentation.qml "id: bottomBarContent"                   "SearchPage l'atteint par ce nom"
verifier_menu MenuRepresentation.qml "id: powerButton"                        "l'alimentation en bas à droite"
# Le composant s'appelle « bottomBar » chez lui ; « bottomBarContent » est
# le nom de SON INSTANCE dans MenuRepresentation. J'avais confondu les deux,
# et le banc me l'a dit.
verifier_menu components/BottomBar.qml "id: bottomBar"                        "le composant perdrait son identité"
verifier_menu components/BottomBar.qml "property alias searchText"            "SearchPage lit cet alias"
verifier_menu components/BottomBar.qml "function focusSearch"                 "SearchPage appelle cette fonction"
verifier_menu components/BottomBar.qml "Search for apps, settings, and documents" "le texte d'invite de Windows 7 resterait"
verifier_menu components/PowerButton.qml "powerButton.menuRequested"          "le chevron n'ouvrirait plus le menu"
verifier_menu pages/PinnedPage.qml "GridView"                                 "la grille 6 colonnes"

# Et ce qu'il ne doit PLUS porter — fichier par fichier, et hors
# commentaires. Mon premier jet cherchait « width: parent.width » dans les
# DEUX fichiers : or il est légitime sur le Rectangle « bottomBar » de
# MenuRepresentation, qui est ancré. Il n'est interdit que dans BottomBar,
# où il se battrait avec le ColumnLayout.
interdit_dans() { # $1 : fichier, $2 : motif, $3 : pourquoi
    if grep -vE '^\s*(//|\*|/\*)' "${demarrer}/contents/ui/$1" | grep -qF "$2"; then
        echo "Menu : « $2 » est resté dans $1 — $3" >&2
        exit 1
    fi
}
interdit_dans components/BottomBar.qml "width: parent.width" "il se bat avec le ColumnLayout"
interdit_dans components/BottomBar.qml "shutdownSplit"       "l'alimentation doit être dans PowerButton"
interdit_dans MenuRepresentation.qml   "SystemLocationsColumn" "la colonne « Places » de Windows 7"
interdit_dans MenuRepresentation.qml   "id: mainColumns"     "le RowLayout à deux colonnes"

# La colonne « Places » n'existe plus dans l'arbre : son réglage et le
# composant qui la dessinait n'ont plus d'objet. Les laisser, ce serait une
# case à cocher qui ne fait rien.
rm -f "${demarrer}/contents/ui/components/SystemLocationsColumn.qml"
python3 -I - "${demarrer}/contents/config/main.xml" << 'CONFIG'
import re, sys
chemin = sys.argv[1]
with open(chemin, encoding="utf-8") as f:
    xml = f.read()
avant = xml
for cle in ("showRightColumn", "rightColumnItems"):
    xml = re.sub(r'\s*<entry name="%s".*?</entry>' % cle, "", xml, flags=re.S)
if xml == avant:
    print("Menu : ni showRightColumn ni rightColumnItems dans main.xml", file=sys.stderr)
    sys.exit(1)
with open(chemin, "w", encoding="utf-8") as f:
    f.write(xml)
CONFIG
grep -q 'showRightColumn' "${demarrer}/contents/config/main.xml" \
    && { echo "Menu : showRightColumn est resté dans la configuration" >&2; exit 1; }

echo "org.ankh.demarrer : une colonne, recherche en haut, grille 6x3, Recommandé, 642x726"
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
# Repris TELS QUELS (DE-017). recolorer-fond.py tournait leur teinte de +52°
# pour aller du bleu au violet d'Ankh ; son propre en-tête le disait : « les
# teintes dominantes sont à 210° et 220°, le bleu de Windows ». Elles sont
# donc déjà la cible, et le script a été supprimé.
install -m 0644 "${fonds}/Fluent-building-light.png" "${paquet}/contents/images/3840x2160.png"
install -m 0644 "${fonds}/Fluent-building-night.png" "${paquet}/contents/images_dark/3840x2160.png"

# La vignette de la page « Fond d'écran » de Plasma : la variante sombre,
# qui est celle par défaut d'Ankh DE.
python3 -I -c "
from PIL import Image
import sys
im = Image.open(sys.argv[1])
im.resize((1280, 720), Image.LANCZOS).save(sys.argv[2], optimize=True)
" "${paquet}/contents/images_dark/3840x2160.png" "${paquet}/contents/screenshot.png"

# « X-KDE-PlasmaImageWallpaper-AccentColor » : c'est par cette clé que
# l'accent de Plasma suit le fond d'écran (DE-004). Sans elle, Plasma calcule
# une couleur depuis l'image et tombe sur un bleu voisin, pas sur l'accent de
# Windows 11.
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
        "Light": "#0078D4",
        "Dark": "#4CC2FF"
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

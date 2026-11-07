#!/usr/bin/env bash
# « avant = après » : ce qui revient est-il ce qui est parti ?
#
# C'est le test qui manquait quand « installer.sh --barre » détruisait les
# barres de l'utilisateur sans retour possible (constat du 2026-11-07). Le
# correctif est dans lib/barres.sh ; celui-ci le met à l'épreuve, sur un faux
# HOME, sans Plasma, sans session graphique — donc à chaque PR.
#
#   tests/barres.sh
set -euo pipefail

racine="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
travail="$(mktemp -d)"
trap 'rm -rf "${travail}"' EXIT

echecs=0
verifies=0
attendre() { # $1 : libellé, $2 : attendu, $3 : obtenu
    verifies=$((verifies + 1))
    if [[ "$3" == "$2" ]]; then
        printf '  ok    %-50s %s\n' "$1" "$3"
    else
        printf '  ECHEC %-50s attendu « %s », obtenu « %s »\n' "$1" "$2" "$3" >&2
        echecs=$((echecs + 1))
    fi
}

# Un faux HOME : rien de ce test ne touche la session de qui le lance.
export HOME="${travail}/maison"
export XDG_DATA_HOME="${HOME}/.local/share"
# lib/barres.sh arrête plasmashell avant de remettre les fichiers. Ici il n'y
# en a pas, et on ne veut surtout pas toucher à celui de la machine.
export ANKH_BARRES_SANS_PLASMA=1
install -d "${HOME}/.config"

# shellcheck source=../lib/barres.sh
. "${racine}/lib/barres.sh"

echo "== Une session qui a des barres"
# Un contenu reconnaissable, et des octets qui ne se devinent pas : si la
# restauration recopiait un fichier par défaut, la comparaison le verrait.
empreinte_depart=""
cat > "${HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc" << 'CONF'
[Containments][1]
plugin=org.kde.panel

[Containments][1][Applets][7]
plugin=org.kde.plasma.kickoff

[Containments][1][Applets][7][Configuration][General]
favoritesPortedToKAstats=true
CONF
printf '[PlasmaViews][Panel 1]\nthickness=44\n' > "${HOME}/.config/plasmashellrc"
empreinte_depart="$(cat "${HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc" \
                        "${HOME}/.config/plasmashellrc" | sha256sum | cut -d' ' -f1)"

ankh_barres_sauver > /dev/null
attendre "la sauvegarde note son horodatage" "oui" \
    "$([[ -s "$(ankh_barres_dossier)/dernier" ]] && echo oui || echo non)"
attendre "les deux fichiers sont copiés" "2" \
    "$(find "$(ankh_barres_dossier)" -name 'plasma*' -type f | wc -l)"

echo "== Ankh DE écrase les barres, comme « --resetLayout » le ferait"
printf '[Containments][1]\nplugin=org.kde.panel\n' \
    > "${HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc"
printf '[PlasmaViews][Panel 1]\nthickness=48\n' > "${HOME}/.config/plasmashellrc"
apres_ecrasement="$(cat "${HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc" \
                        "${HOME}/.config/plasmashellrc" | sha256sum | cut -d' ' -f1)"
attendre "l'écrasement a bien changé les fichiers" "différent" \
    "$([[ "${apres_ecrasement}" != "${empreinte_depart}" ]] && echo différent || echo identique)"

echo "== Le désinstallateur remet ce qui était là"
ankh_barres_remettre > /dev/null
empreinte_retour="$(cat "${HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc" \
                        "${HOME}/.config/plasmashellrc" | sha256sum | cut -d' ' -f1)"
attendre "avant = après, octet pour octet" "${empreinte_depart}" "${empreinte_retour}"

echo "== Une session NEUVE, sans barre : pas d'erreur, et rien à remettre"
export HOME="${travail}/maison-neuve"
export XDG_DATA_HOME="${HOME}/.local/share"
install -d "${HOME}/.config"
ankh_barres_sauver > /dev/null
attendre "sauver une session sans barre réussit" "0" "$?"
code=0
ankh_barres_remettre > /dev/null 2>&1 || code=$?
attendre "remettre sans sauvegarde rend 1, pour que l'appelant décide" "1" "${code}"

echo "== Un horodatage qui ne désigne aucun fichier ne doit pas mentir"
export HOME="${travail}/maison-cassee"
export XDG_DATA_HOME="${HOME}/.local/share"
install -d "${HOME}/.config" "$(ankh_barres_dossier)"
echo "20260101-000000" > "$(ankh_barres_dossier)/dernier"
code=0
ankh_barres_remettre > /dev/null 2>&1 || code=$?
attendre "une sauvegarde vide rend 1, et ne prétend pas avoir remis" "1" "${code}"

echo
if (( echecs )); then
    echo "${echecs} échec(s) sur ${verifies} vérification(s)." >&2
    exit 1
fi
echo "${verifies} vérifications, toutes passées."

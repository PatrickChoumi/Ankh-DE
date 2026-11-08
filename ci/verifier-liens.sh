#!/usr/bin/env bash
# Refuse un lien Markdown qui pointe vers un fichier absent du dépôt.
#
# Le 2026-11-08, neuf documents de règles ont été supprimés et fondus dans
# CLAUDE.md. Vingt-neuf liens les désignaient encore, répartis dans douze
# fichiers — y compris des README de sous-dossiers que personne ne pense à
# relire. Un lien mort n'est pas qu'une gêne : il renvoie vers une règle
# qu'on croit toujours en vigueur.
set -euo pipefail

racine="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
cd "${racine}"

morts=0
while IFS= read -r fichier; do
    dossier="$(dirname "${fichier}")"
    # Les liens Markdown relatifs. On écarte les URL et les ancres pures.
    while IFS= read -r cible; do
        [[ -n "${cible}" ]] || continue
        case "${cible}" in
            http*|mailto:*|'#'*) continue ;;
        esac
        # On ne juge que le chemin, pas l'ancre.
        chemin="${cible%%#*}"
        [[ -n "${chemin}" ]] || continue
        if [[ ! -e "${dossier}/${chemin}" ]]; then
            echo "  ECHEC ${fichier} renvoie vers « ${chemin} », qui n'existe pas" >&2
            morts=$((morts + 1))
        fi
    done < <(grep -oE '\]\([^)]+\)' "${fichier}" | sed 's/^](//; s/)$//' || true)
done < <(git ls-files '*.md')

if (( morts > 0 )); then
    echo >&2
    echo "${morts} lien(s) mort(s). Un lien vers un document supprimé renvoie" >&2
    echo "vers une règle qu'on croit encore en vigueur." >&2
    exit 1
fi
echo "Liens : $(git ls-files '*.md' | wc -l) fichier(s) Markdown, aucun lien mort."

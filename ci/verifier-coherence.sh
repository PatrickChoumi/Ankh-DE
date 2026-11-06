#!/usr/bin/env bash
# Refuse que le dépôt porte deux règles contradictoires.
#
# Le 2026-11-06, DE-011 a autorisé la reprise de code libre tandis que
# CLAUDE.md §3.2 l'interdisait encore : le dépôt a porté les deux pendant
# plusieurs commits, et Claude Code aurait pu travailler avec des consignes
# qui se contredisent. Rien ne l'avait signalé.
#
# L'en-tête de CLAUDE.md dit pourtant la règle : « En cas de contradiction,
# DECISIONS.md fait foi pour les choix. Ce fichier est alors à corriger ».
# Ce script la rend exécutable.
#
# Il vérifie trois choses :
#   1. chaque décision a une entrée d'index, et chaque entrée d'index a sa
#      section — un index en retard cache une décision ;
#   2. une décision REMPLACÉE est marquée comme telle dans l'index ;
#   3. aucune formulation qu'une décision a abrogée ne subsiste dans les
#      documents. C'est le contrôle qui aurait attrapé la contradiction.
#
# Pour ajouter un contrôle : une ligne dans ABROGEES, « décision | fichier |
# phrase ». La phrase est cherchée telle quelle, hors des lignes qui citent
# la décision elle-même (un document a le droit d'expliquer ce qu'il a
# remplacé).
set -euo pipefail

racine="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
cd "${racine}"

echecs=0
signaler() { echo "  ECHEC $*" >&2; echecs=$((echecs + 1)); }

# --- 1 et 2. L'index des décisions ---------------------------------------
sections="$(grep -oE '^## (DE-[0-9]+)' DECISIONS.md | awk '{print $2}' | sort -u)"
index="$(grep -oE '^\| (DE-[0-9]+) \|' DECISIONS.md | awk '{print $2}' | sort -u)"

while read -r de; do
    [[ -n "${de}" ]] || continue
    grep -q "^${de}$" <<< "${index}" || signaler "${de} a une section mais n'est pas dans l'index"
done <<< "${sections}"

while read -r de; do
    [[ -n "${de}" ]] || continue
    grep -q "^${de}$" <<< "${sections}" || signaler "${de} est dans l'index mais n'a pas de section"
done <<< "${index}"

# Une décision qu'une autre remplace doit le dire dans l'index : sinon on la
# lit comme en vigueur.
while read -r remplacee; do
    [[ -n "${remplacee}" ]] || continue
    ligne="$(grep -E "^\| ${remplacee} \|" DECISIONS.md || true)"
    if [[ -n "${ligne}" ]] && ! grep -qiE 'REMPLACÉE|REMPLACEE' <<< "${ligne}"; then
        signaler "${remplacee} est remplacée par une autre décision, mais l'index la donne encore pour acquise"
    fi
done < <(grep -oiE 'remplace (DE-[0-9]+)' DECISIONS.md | grep -oE 'DE-[0-9]+' | sort -u)

# --- 3. Les formulations abrogées ----------------------------------------
# décision | fichier | phrase abrogée
#
# DECISIONS.md n'est JAMAIS contrôlé ici, et c'est voulu : c'est l'archive
# du projet, elle doit garder le texte des décisions remplacées. On ne
# contrôle que les documents qui énoncent les règles en vigueur.
ABROGEES=(
    "DE-011|CLAUDE.md|On n'embarque pas un projet tiers"
    "DE-011|ANKH-DE-SPEC.md|Pas de projet tiers embarqué comme code"
    # Celle-ci a survécu au contrôle précédent parce qu'elle est formulée
    # autrement : le document de PROVENANCE citait encore l'interdiction
    # pendant que le menu QML tiers était déjà intégré (constat du
    # 2026-11-06). Une règle abrogée se cache dans ses paraphrases.
    "DE-011|docs/UPSTREAMS.md|on n'embarque pas un projet"
)
for regle in "${ABROGEES[@]}"; do
    IFS='|' read -r decision fichier phrase <<< "${regle}"
    if [[ "${fichier}" == "DECISIONS.md" ]]; then
        signaler "ABROGEES ne doit pas viser DECISIONS.md : c'est l'archive"
        continue
    fi
    [[ -f "${fichier}" ]] || continue
    # On ignore les lignes qui nomment la décision : un document a le droit
    # d'expliquer ce qu'il a remplacé.
    if grep -F -- "${phrase}" "${fichier}" | grep -vq "${decision}"; then
        signaler "${fichier} porte encore « ${phrase}… », que ${decision} a abrogé"
        grep -nF -- "${phrase}" "${fichier}" | grep -v "${decision}" | head -3 | sed 's/^/        /' >&2
    fi
done

# --- Bilan ---------------------------------------------------------------
if (( echecs )); then
    echo >&2
    echo "${echecs} incohérence(s). Une décision qui change une règle corrige les" >&2
    echo "documents qui la portent DANS LE MÊME COMMIT (CLAUDE.md §4)." >&2
    exit 1
fi
echo "Cohérence : $(wc -l <<< "${sections}") décision(s), index à jour, aucune règle abrogée en vigueur."

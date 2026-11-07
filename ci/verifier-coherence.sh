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

# --- 4. Le compte des jetons, cité en prose -------------------------------
# Le 2026-11-06, README.md et CHANGELOG.md annonçaient 46 vérifications quand
# le test en passait 47, et douze documents citaient « 47 mesures » de
# mémoire. Un nombre répété à la main dérive sans que rien ne le dise.
#
# Deux essais trop gourmands avant celui-ci, et ils apprennent la forme du
# problème :
#   — « 18 jetons sur 53 » porte DEUX nombres, et seul le second est un
#     dénominateur ;
#   — « 6 jetons sur 11 » est un compte DU LOT 2, parfaitement juste ;
#   — « 7 mesures conformes » est un relevé d'un passage, pas un total.
#
# D'où deux règles, étroites exprès :
#   a) un dénominateur (« sur N », « of N ») doit être le total OU le compte
#      d'un lot — les deux sont calculés depuis jetons.toml, donc un total
#      périmé reste attrapé ;
#   b) « N mesures » n'est lu comme un total que sur une ligne qui parle de
#      l'ENSEMBLE : elle nomme jetons.toml, le banc, ou décrit chaque mesure.
#
# AUDIT.md est exclu (instantané daté) et docs/FIDELITE.md aussi (engendré).
comptes="$(python3 -I -c "
import tomllib, collections
d = tomllib.loads(open('bench/jetons.toml','rb').read().decode())
c = collections.Counter(m['lot'] for m in d['mesure'])
print(len(d['mesure']))
print(' '.join(str(n) for n in sorted(set(c.values()) | {len(d['mesure'])})))
" 2>/dev/null)"
total_jetons="$(head -1 <<< "${comptes}")"
acceptables=" $(tail -1 <<< "${comptes}") "
if [[ -z "${total_jetons}" || "${total_jetons}" == 0 ]]; then
    signaler "impossible de compter les jetons de bench/jetons.toml"
else
    MARQUEURS='jetons\.toml|Banc de mesure|Measurement bench|La référence|chacune avec|each with|leurs cibles'
    while IFS= read -r f; do
        [[ -n "${f}" ]] || continue
        while IFS=: read -r ligne texte; do
            [[ -n "${ligne}" ]] || continue
            grep -qE "${MARQUEURS}" <<< "${texte}" || continue
            cite="$(grep -oE '[0-9]+ (mesures|jetons|measurements)' <<< "${texte}" | grep -oE '^[0-9]+' | head -1)"
            [[ -n "${cite}" && "${cite}" != "${total_jetons}" ]] \
                && signaler "${f}:${ligne} annonce « ${cite} » pour l'ensemble, bench/jetons.toml en porte ${total_jetons}"
        done < <(grep -nE '[0-9]+ (mesures|jetons|measurements)' "${f}" 2>/dev/null)

        while IFS=: read -r ligne cite; do
            [[ -n "${cite}" ]] || continue
            [[ "${acceptables}" == *" ${cite} "* ]] \
                || signaler "${f}:${ligne} compte « sur ${cite} », qui n'est ni le total (${total_jetons}) ni le compte d'un lot"
        done < <(grep -noE '(jetons|tokens) (sur|of) [0-9]+' "${f}" 2>/dev/null \
                 | sed -E 's/^([0-9]+):.* (sur|of) ([0-9]+)$/\1:\3/')
    done < <(grep -rl '' --include='*.md' . 2>/dev/null \
             | grep -v '^\./\.git' | grep -v '^\./AUDIT\.md' | grep -v '^\./docs/FIDELITE\.md')
fi

# --- 5. La version de Plasma annoncée -------------------------------------
# Le 2026-11-06, docs/INSTALL.md a été corrigé de « 6.7.x, 6.8 pas encore pris
# en charge » vers 6.8.x — et README.md:114 disait encore la même chose le
# lendemain. Une correction qui vise un fichier à la main en manque un autre.
#
# docs/consignes/ est exclu, et pour une raison plus forte que les autres :
# ce sont les documents du propriétaire, reproduits tels quels. On ne
# réécrit pas le texte de quelqu'un d'autre pour faire taire un contrôle —
# et leurs mentions de « Plasma 6.6 » sont justes : elles parlent de
# Tidewater, pas de notre cible.
#
# La source de vérité est src/decoration/VERSION-BREEZE, que le CMake fait
# respecter (DE-008, DE-016). Depuis le 2026-11-07 il y porte une PLAGE :
# « plasma= » est la cible (Ubuntu 26.04, donc 6.6) et « plasma_min= » /
# « plasma_max= » les bornes éprouvées. Un document peut donc légitimement
# nommer 6.6 (la cible) ou 6.8 (les VM de preuve, Fedora 44 et Arch) : ce
# contrôle accepte toute version DANS la plage, et refuse le reste.
# Deux lignes nomment légitimement une AUTRE version, et les taire en bloc
# reviendrait à désarmer le contrôle. Elles sont donc nommées une à une, avec
# la raison, comme ABROGEES plus haut : fichier | fragment qui la justifie.
PLASMA_EXCEPTIONS=(
    # Tidewater est développé et testé sur 6.6 : c'est un fait sur EUX.
    "docs/UPSTREAMS.md|ils développent et testent sur"
    # La rupture KDecoration2 -> 3 de 6.3 est un précédent historique.
    "docs/REBASE.md|KDecoration2 à KDecoration3"
)
plasma_vise="$(sed -n 's/^plasma=//p' src/decoration/VERSION-BREEZE 2>/dev/null | head -1)"
plasma_min="$(sed -n 's/^plasma_min=//p' src/decoration/VERSION-BREEZE 2>/dev/null | head -1)"
plasma_max="$(sed -n 's/^plasma_max=//p' src/decoration/VERSION-BREEZE 2>/dev/null | head -1)"
if [[ -z "${plasma_vise}" || -z "${plasma_min}" || -z "${plasma_max}" ]]; then
    signaler "src/decoration/VERSION-BREEZE ne dit pas la cible et la plage de Plasma (plasma=, plasma_min=, plasma_max=)"
else
    while IFS=: read -r fichier ligne texte; do
        [[ -n "${fichier}" ]] || continue
        # « Plasma 6.x », hors de la version visée. On ignore « Plasma 6 »
        # tout court, qui nomme la génération et reste juste.
        # « || true » : sous « set -e », un grep qui ne trouve rien (code 1)
        # tue l'affectation, donc le script — en silence. C'est le piège que
        # ce dépôt a déjà rencontré dans preparer.sh, et j'y suis retombé ici.
        exemptee=non
        for regle in "${PLASMA_EXCEPTIONS[@]}"; do
            IFS='|' read -r ex_fichier ex_phrase <<< "${regle}"
            [[ "${fichier}" == "./${ex_fichier}" || "${fichier}" == "${ex_fichier}" ]] || continue
            grep -qF -- "${ex_phrase}" <<< "${texte}" && { exemptee=oui; break; }
        done
        [[ "${exemptee}" == non ]] || continue
        # Toute version citée doit tomber dans la plage éprouvée. « sort -V »
        # ordonne les versions : si la citée reste entre les deux bornes après
        # tri, elle est dans la plage.
        mauvaise=""
        while read -r citee; do
            [[ -n "${citee}" ]] || continue
            dans_plage=oui
            [[ "$(printf '%s\n%s\n' "${plasma_min}" "${citee}" | sort -V | head -1)" == "${plasma_min}" ]] \
                || dans_plage=non
            [[ "$(printf '%s\n%s\n' "${citee}" "${plasma_max}" | sort -V | head -1)" == "${citee}" ]] \
                || dans_plage=non
            [[ "${dans_plage}" == oui ]] || { mauvaise="${citee}"; break; }
        done < <(grep -oE 'Plasma \*{0,2}6\.[0-9]+' <<< "${texte}" | grep -oE '6\.[0-9]+' || true)
        [[ -n "${mauvaise}" ]] \
            && signaler "${fichier}:${ligne} annonce Plasma ${mauvaise}, hors de la plage éprouvée ${plasma_min} à ${plasma_max} (VERSION-BREEZE vise ${plasma_vise})"
    done < <(grep -rnE 'Plasma \*{0,2}6\.[0-9]+' --include='*.md' . 2>/dev/null \
             | grep -v '^\./\.git' | grep -v '^\./AUDIT\.md' | grep -v '^\./AVANCEMENT\.md' \
             | grep -v '^\./CHANGELOG\.md' | grep -v '^\./DECISIONS\.md' \
             | grep -v '^\./docs/consignes/')
fi

# --- 6. Les consignes permanentes du propriétaire -------------------------
# Deux documents déposés le 2026-11-07 sont contraignants. Ils ont déjà un
# précédent fâcheux dans ce dépôt : une règle qui n'est pas contrôlée finit
# par être contredite ailleurs sans que rien ne le dise (DE-011 contre
# CLAUDE.md, l'interdiction du code tiers dans UPSTREAMS.md).
#
# On vérifie donc qu'ils existent, qu'ils ne sont pas vidés, et que CLAUDE.md
# — le seul fichier lu à chaque session — y renvoie.
CONSIGNES=(
    "docs/consignes/INTEGRATION-SOURCES.md"
    "docs/consignes/ANTI-DOUBLONS.md"
)
for consigne in "${CONSIGNES[@]}"; do
    if [[ ! -s "${consigne}" ]]; then
        signaler "la consigne permanente ${consigne} est absente ou vide"
        continue
    fi
    lignes="$(wc -l < "${consigne}")"
    (( lignes >= 100 )) \
        || signaler "${consigne} ne fait que ${lignes} lignes : elle a été tronquée"
    grep -qF -- "${consigne}" CLAUDE.md \
        || signaler "CLAUDE.md ne renvoie pas à ${consigne}, qui ne sera donc jamais lue"
done

# --- 7. Le compte des jetons MESURÉS, et non plus seulement le total ------
# Le contrôle n° 4 vérifie le dénominateur (« sur 53 »). Il ne regardait pas
# le numérateur, et c'est par là que la dérive est revenue le 2026-11-07 :
# README et CLAUDE.md disaient 25, ROADMAP et AVANCEMENT 27, CHANGELOG 25.
# Cinq documents, trois chiffres, pour une seule question.
#
# On ne peut pas calculer ce nombre ici — il vient d'un passage en VM, pas
# d'un fichier. Mais on peut exiger que tous les documents en citent UN
# SEUL. Le désaccord est l'erreur ; la valeur, c'est au passage de la dire.
mesures_citees="$(grep -rhoE '[0-9]+ (jetons |tokens )?(sur|of) 53' --include='*.md' . 2>/dev/null \
    --exclude-dir=.git --exclude=AUDIT.md \
    | grep -oE '^[0-9]+' | sort -u || true)"
nb_valeurs="$(grep -c . <<< "${mesures_citees}" || true)"
if [[ -n "${mesures_citees}" ]] && (( nb_valeurs > 1 )); then
    signaler "les documents citent $(tr '\n' ' ' <<< "${mesures_citees}")jetons mesurés sur 53 : un seul chiffre pour une seule question"
    grep -rnE '[0-9]+ (jetons |tokens )?(sur|of) 53' --include='*.md' . 2>/dev/null \
        --exclude-dir=.git --exclude=AUDIT.md | sed 's/^/        /' | cut -c1-120 >&2
fi

# --- 8. Un seul état fonctionnel, un seul SHA de preuve -------------------
# Le 2026-11-07, cinq documents portaient cinq états différents du menu
# Démarrer : le README le disait interactif, la ROADMAP disait l'inverse,
# AVANCEMENT disait qu'aucune interaction n'était testée. Chacun était vrai à
# sa date et faux au présent — exactement le défaut que le §5 corrige pour la
# version de Plasma et le §7 pour le compte des jetons.
#
# docs/ANTI_DOUBLONS.md est la source unique (son en-tête le déclare). Tout
# autre document qui parle d'une interaction PROUVÉE doit citer le même SHA.
#
# AVANCEMENT.md est exclu, et pour une raison de fond : c'est un JOURNAL. Ses
# entrées datées doivent garder ce qui était vrai à leur date, sinon elles ne
# servent plus à rien. Son tableau « ce qui est vérifié » renvoie ici.
canonique="$(sed -n 's/^| \*\*SHA des preuves d.interaction\*\* | `\([0-9a-f]\{7,40\}\)` |.*/\1/p'     docs/ANTI_DOUBLONS.md 2>/dev/null | head -1)"
if [[ -z "${canonique}" ]]; then
    signaler "docs/ANTI_DOUBLONS.md ne déclare plus de « SHA des preuves d'interaction » : l'état fonctionnel n'a plus de source"
else
    # Les mots qui font d'une phrase une affirmation d'interaction. « ouvre »
    # seul ne suffit pas : on veut les verdicts, pas les descriptions.
    MOTS_INTERACTION='interactif|interaction|prend le clavier|se referme sur Échap|closes on Esc|takes the keyboard|lance réellement|really launches'
    while IFS=: read -r fichier ligne texte; do
        [[ -n "${fichier}" ]] || continue
        # Les SHA cités sur cette ligne, en 7 caractères pour comparer.
        while read -r cite; do
            [[ -n "${cite}" ]] || continue
            [[ "${cite:0:7}" == "${canonique:0:7}" ]] && continue
            signaler "${fichier}:${ligne} attribue une interaction au SHA ${cite}, alors que docs/ANTI_DOUBLONS.md déclare ${canonique}"
        done < <(grep -oE '`[0-9a-f]{7,40}`' <<< "${texte}" | tr -d '`' || true)
    done < <(grep -rnE "${MOTS_INTERACTION}" --include='README.md' --include='README.en.md' \
                 --include='ROADMAP.md' --include='CLAUDE.md' . 2>/dev/null \
             | grep -v '^\./\.git' | grep -E '`[0-9a-f]{7,40}`' || true)
fi

# --- Bilan ---------------------------------------------------------------
if (( echecs )); then
    echo >&2
    echo "${echecs} incohérence(s). Une décision qui change une règle corrige les" >&2
    echo "documents qui la portent DANS LE MÊME COMMIT (CLAUDE.md §4)." >&2
    exit 1
fi
echo "Cohérence : $(wc -l <<< "${sections}") décision(s), index à jour, aucune règle abrogée en vigueur."

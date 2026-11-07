#!/usr/bin/env bash
# Éprouve le garde-fou de version de Plasma (DE-008, DE-016) sans Qt, sans
# KF6 et sans kdecoration : « cmake -P » suffit, parce que le garde-fou vit
# dans cmake/GardeVersionPlasma.cmake et non au milieu du CMake principal.
#
# Pourquoi ce fichier existe : jusqu'au 2026-11-07, le garde-fou exigeait
# l'ÉGALITÉ avec Plasma 6.8 et « Construire » le contournait sur les trois
# distributions avec -DANKH_DE_PLASMA_NON_TESTE=ON. Personne n'a donc vu
# qu'Ankh DE refusait de se construire sur Ubuntu 26.04 — sa cible, en 6.6.
# Un garde-fou que rien n'éprouve finit par garder la mauvaise chose.
set -euo pipefail

racine="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
module="${racine}/cmake/GardeVersionPlasma.cmake"
travail="$(mktemp -d)"
trap 'rm -rf "${travail}"' EXIT

griefs=()
grief() { griefs+=("$1"); echo "   ÉCHEC $1" >&2; }
ok() { echo "   ok    $1"; }

# Lance le garde-fou sur un VERSION-BREEZE donné, avec une version trouvée.
# Rend le code de sortie et laisse la sortie dans ${travail}/sortie.txt.
essayer() {
    local fichier="$1" trouvee="$2" non_teste="${3:-OFF}"
    cat > "${travail}/pilote.cmake" <<EOF
include("${module}")
ankh_de_lire_plage("${fichier}")
ankh_de_garde_version("${trouvee}" "${trouvee}.0" ${non_teste})
EOF
    local code=0
    cmake -P "${travail}/pilote.cmake" > "${travail}/sortie.txt" 2>&1 || code=$?
    return "${code}"
}

# $1 libellé, $2 fichier, $3 version trouvée, $4 accepte|refuse, $5 fragment
cas() {
    local libelle="$1" fichier="$2" trouvee="$3" attendu="$4" fragment="${5:-}" non_teste="${6:-OFF}"
    local code=0
    essayer "${fichier}" "${trouvee}" "${non_teste}" || code=$?
    local obtenu=accepte
    (( code == 0 )) || obtenu=refuse
    if [[ "${obtenu}" != "${attendu}" ]]; then
        grief "${libelle} : attendu « ${attendu} », obtenu « ${obtenu} »"
        sed 's/^/        /' "${travail}/sortie.txt" >&2
        return
    fi
    # CMake replie message() sur plusieurs lignes et double parfois les
    # espaces : chercher un fragment long dans la sortie brute échoue
    # toujours. On compare donc sur un texte mis à plat. (Le premier jet de
    # ce test est tombé dessus, et le même piège attendait le test négatif
    # de construire.yml.)
    local a_plat
    a_plat="$(tr '\n' ' ' < "${travail}/sortie.txt" | tr -s ' ')"
    if [[ -n "${fragment}" ]] && ! grep -qF -- "${fragment}" <<< "${a_plat}"; then
        grief "${libelle} : ${attendu}, mais le message ne dit pas « ${fragment} »"
        sed 's/^/        /' "${travail}/sortie.txt" >&2
        return
    fi
    ok "${libelle}"
}

# Fabrique un VERSION-BREEZE d'essai.
fabriquer() {
    local nom="$1" vise="$2" bmin="$3" bmax="$4"
    {
        echo "depot=https://invent.kde.org/plasma/breeze"
        echo "tag=v6.7.5"
        echo "commit=ca217f1"
        [[ "${vise}" == "-" ]] || echo "plasma=${vise}"
        [[ "${bmin}" == "-" ]] || echo "plasma_min=${bmin}"
        [[ "${bmax}" == "-" ]] || echo "plasma_max=${bmax}"
    } > "${travail}/${nom}"
    echo "${travail}/${nom}"
}

echo "== Garde-fou de version de Plasma"
reel="${racine}/src/decoration/VERSION-BREEZE"

# --- Ce que livre le dépôt, contre les versions réellement rencontrées ---
cas "6.6 (Ubuntu 26.04) est accepté"      "${reel}" 6.6 accepte "la version visée en premier"
cas "6.7 est accepté (dans la plage)"     "${reel}" 6.7 accepte "dans la plage éprouvée"
cas "6.8 (Fedora 44, Arch) est accepté"   "${reel}" 6.8 accepte "dans la plage éprouvée"
cas "6.5 est refusé (sous la borne)"      "${reel}" 6.5 refuse  "n'est éprouvé que de Plasma 6.6 à 6.8"
cas "6.9 est refusé (au-dessus)"          "${reel}" 6.9 refuse  "n'est éprouvé que de Plasma 6.6 à 6.8"

# --- Le cas exact du test négatif de construire.yml ----------------------
# Il resserre la plage ET la cible sur une valeur absurde, puis vérifie le
# message. Au premier passage de DE-016, il ne resserrait QUE les bornes :
# « plasma= » se retrouvait hors de sa propre plage, c'est ce contrôle-là qui
# refusait, avec un autre message, et le test échouait pour la mauvaise
# raison. Le cas est ici pour que la CI ne soit plus la première à le voir.
cas "les trois clés à 0.1 : refus pour cause de plage" \
    "$(fabriquer tout-0-1 0.1 0.1 0.1)" 6.8 refuse \
    "n'est éprouvé que de Plasma 0.1 à 0.1"

# --- L'échappatoire avertit, mais ne bloque pas ---------------------------
cas "6.9 passe avec l'échappatoire"       "${reel}" 6.9 accepte "n'est éprouvé que de Plasma 6.6 à 6.8" ON

# --- Un fichier mal écrit doit arrêter la construction, pas tout accepter -
cas "sans plasma_min : refusé"       "$(fabriquer sans-min 6.6 - 6.8)"   6.6 refuse "il faut « plasma= »"
cas "sans plasma_max : refusé"       "$(fabriquer sans-max 6.6 6.6 -)"   6.6 refuse "il faut « plasma= »"
cas "sans plasma= : refusé"          "$(fabriquer sans-vise - 6.6 6.8)"  6.6 refuse "il faut « plasma= »"
cas "plage à l'envers : refusée"     "$(fabriquer envers 6.6 6.8 6.6)"   6.6 refuse "une plage à l'envers"
cas "cible hors de sa plage : refusée" "$(fabriquer dehors 6.4 6.6 6.8)" 6.6 refuse "hors de sa propre plage"
cas "fichier absent : refusé"        "${travail}/pas-la"                 6.6 refuse "est introuvable"

echo
if (( ${#griefs[@]} > 0 )); then
    echo "== ${#griefs[@]} ÉCHEC(S)" >&2
    for g in "${griefs[@]}"; do echo "  - ${g}" >&2; done
    exit 1
fi
echo "== Le garde-fou garde ce qu'il doit, et refuse ce qu'il doit."

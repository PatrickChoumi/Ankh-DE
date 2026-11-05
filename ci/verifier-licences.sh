#!/usr/bin/env bash
# Garde-fou de DE-005 : aucun fichier de police, d'icône, de son ou d'image ne
# peut entrer dans le dépôt sans que sa provenance soit déclarée dans
# LICENSES/README.md. C'est ce qui empêche un fichier de Microsoft d'arriver
# par inadvertance.
#
# Lancé par la CI à chaque PR, et utile en local avant de committer.
set -euo pipefail

racine="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
cd "${racine}"

notices="LICENSES/README.md"
[[ -f "${notices}" ]] || { echo "${notices} est absent." >&2; exit 1; }

# Extensions qui demandent une déclaration.
readonly SURVEILLEES='\.(ttf|otf|woff2?|eot|pfb|svg|png|jpe?g|webp|gif|ico|icns|wav|ogg|mp3|flac|oga|cur|ani)$'

# Dossiers dispensés : ce qui est généré ou purement interne.
exempt() {
    case "$1" in
        third_party/sortie/*|build/*|bench/sortie/*) return 0 ;;
        *) return 1 ;;
    esac
}

echec=0
manquants=()
while read -r fichier; do
    [[ -n "${fichier}" ]] || continue
    exempt "${fichier}" && continue
    # Un fichier est déclaré si son dossier ou son nom apparaît dans les notices.
    dossier="$(dirname "${fichier}")"
    if grep -qF "${dossier}" "${notices}" || grep -qF "$(basename "${fichier}")" "${notices}"; then
        continue
    fi
    manquants+=("${fichier}")
done < <(git ls-files | grep -Ei "${SURVEILLEES}" || true)

if (( ${#manquants[@]} )); then
    echo "Ces fichiers ne sont pas déclarés dans ${notices} (DE-005) :" >&2
    printf '  %s\n' "${manquants[@]}" >&2
    echo >&2
    echo "Ajoutez leur provenance, leur commit et leur licence, ou retirez-les." >&2
    echec=1
fi

# Noms qui ne doivent jamais apparaître : ce sont ceux des actifs de Microsoft.
readonly INTERDITS=('segoe' 'SegoeUI' 'SegoeFluent' 'windows11' 'win11-wallpaper' 'MSShell')
for motif in "${INTERDITS[@]}"; do
    if git ls-files | grep -qi "${motif}"; then
        echo "Un fichier porte « ${motif} » dans son nom : interdit par DE-005." >&2
        git ls-files | grep -i "${motif}" >&2
        echec=1
    fi
done

if (( echec == 0 )); then
    nb="$(git ls-files | grep -Eci "${SURVEILLEES}" || true)"
    echo "Licences : ${nb} fichier(s) surveillé(s), tous déclarés."
fi
exit "${echec}"

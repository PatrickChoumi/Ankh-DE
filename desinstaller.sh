#!/usr/bin/env bash
# Ankh DE : retour en arrière. Réapplique Breeze, puis retire les fichiers
# installés. Vos barres ne sont touchées que si vous passez --barre.
set -euo pipefail

racine="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
barre=non
[[ "${1:-}" == --barre ]] && barre=oui

echo "== Retour à Breeze"
if command -v plasma-apply-lookandfeel > /dev/null; then
    sombre=org.kde.breezedark.desktop
    plasma-apply-lookandfeel --list 2>/dev/null | grep -q "${sombre}" || sombre=org.kde.breeze.desktop
    if [[ "${barre}" == oui ]]; then
        plasma-apply-lookandfeel -a "${sombre}" --resetLayout
    else
        plasma-apply-lookandfeel -a "${sombre}"
    fi
else
    echo "plasma-apply-lookandfeel introuvable : thème global non changé." >&2
fi

echo "== Retrait des fichiers"
if [[ -f "${racine}/build/install_manifest.txt" ]]; then
    # cmake --install n'a pas de « uninstall » : on relit son manifeste.
    while read -r fichier; do
        [[ -n "${fichier}" ]] || continue
        if [[ -w "$(dirname "${fichier}")" ]]; then
            rm -f "${fichier}"
        else
            sudo rm -f "${fichier}"
        fi
    done < "${racine}/build/install_manifest.txt"
    echo "$(wc -l < "${racine}/build/install_manifest.txt") fichiers retirés."
else
    cat >&2 << AIDE
build/install_manifest.txt est absent : je ne sais pas ce qui a été installé.
Les fichiers d'Ankh DE portent tous son nom. À retirer à la main, selon le
préfixe utilisé (/usr/local ou ~/.local) :

  <préfixe>/share/plasma/look-and-feel/org.ankh.de.desktop
  <préfixe>/share/color-schemes/Ankh.colors  et  AnkhClair.colors
  <préfixe>/share/kstyle/themes/ankh.themerc
  <préfixe>/share/icons/Ankh-curseurs   <préfixe>/share/themes/Fluent-Ankh
  <préfixe>/share/fonts/selawik
  <préfixe>/lib64/qt6/plugins/styles/ankh6.so
  <préfixe>/lib64/qt6/plugins/org.kde.kdecoration3/org.ankh.decoration.so
AIDE
fi

rm -f "${HOME}/.config/plasma-workspace/env/ankh-de.sh"
rm -f "${HOME}/.config/fontconfig/conf.d/29-ankh-rendu.conf"
command -v fc-cache > /dev/null && fc-cache -f > /dev/null 2>&1 || true

echo
echo "Fait. Déconnectez-vous et reconnectez-vous pour que le style de Breeze"
echo "reprenne complètement."

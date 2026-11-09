#!/usr/bin/env bash
# Ankh DE : retour en arrière. Réapplique Breeze, puis retire les fichiers
# installés. Vos barres ne sont touchées que si vous passez --barre.
set -euo pipefail

racine="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
barre=non
[[ "${1:-}" == --barre ]] && barre=oui

echo "== Retour à Breeze"
if command -v plasma-apply-lookandfeel > /dev/null; then
    # Le défaut de Plasma est Breeze CLAIR, et Ankh DE livre clair depuis
    # DE-017 : revenir en sombre serait un troisième état, ni le nôtre ni
    # celui de la distribution.
    sombre=org.kde.breeze.desktop
    plasma-apply-lookandfeel --list 2>/dev/null | grep -q "${sombre}" || sombre=org.kde.breezedark.desktop
    # Même défaut que dans installer.sh : hors session graphique,
    # plasma-apply-lookandfeel s'arrête sur un défaut. Un désinstallateur
    # qui plante laisse le système à moitié défait, ce qui est pire.
    appliquer() {
        if [[ -n "${WAYLAND_DISPLAY:-}" || -n "${DISPLAY:-}" ]]; then
            plasma-apply-lookandfeel "$@"
        else
            QT_QPA_PLATFORM=offscreen plasma-apply-lookandfeel "$@"
        fi
    }
    if [[ "${barre}" == oui ]]; then
        # Remettre les barres de l'UTILISATEUR, et non celles de Plasma.
        # « --resetLayout » donne la disposition par défaut de Breeze : ce
        # n'est pas un retour à l'état de départ, c'est un autre état.
        # shellcheck source=lib/barres.sh
        . "${racine}/lib/barres.sh"
        if ankh_barres_remettre; then
            appliquer -a "${sombre}"
        else
            echo "  Aucune sauvegarde de barre trouvée : on remet celle de Plasma." >&2
            echo "  (Une installation faite sans « --barre » n'en crée pas.)" >&2
            appliquer -a "${sombre}" --resetLayout
        fi
    else
        appliquer -a "${sombre}"
    fi
else
    echo "plasma-apply-lookandfeel introuvable : thème global non changé." >&2
fi

echo "== Retrait des fichiers"
if [[ -f "${racine}/build/install_manifest.txt" ]]; then
    # cmake --install n'a pas de « uninstall » : on relit son manifeste.
    dossiers=""
    while read -r fichier; do
        [[ -n "${fichier}" ]] || continue
        if [[ -w "$(dirname "${fichier}")" ]]; then
            rm -f "${fichier}"
        else
            sudo rm -f "${fichier}"
        fi
        dossiers="${dossiers}$(dirname "${fichier}")"$'\n'
    done < "${racine}/build/install_manifest.txt"
    echo "$(wc -l < "${racine}/build/install_manifest.txt") fichiers retirés."

    # Et les DOSSIERS, que « rm -f » ne touche pas.
    #
    # Le 2026-11-08, le passage en VM a nommé cinq restes :
    # org.ankh.de.desktop, org.ankh.demarrer, ankh, Fluent-Ankh et
    # Ankh-Prismes. Tous des dossiers, tous VIDES — leurs fichiers étaient
    # bien partis. Un thème global dont le dossier existe encore est vu par
    # Plasma, donc ce n'était pas cosmétique.
    #
    # « rmdir » et non « rm -rf » : rmdir REFUSE un dossier non vide, ce qui
    # est exactement le garde-fou qu'on veut. Et on ne touche qu'aux
    # dossiers dont un segment porte notre nom, pour ne jamais remonter dans
    # /usr/local/share/icons ou /usr/local/share/plasma eux-mêmes.
    echo "== Retrait des dossiers devenus vides"
    partis=0
    while read -r d; do
        [[ -n "${d}" && -d "${d}" ]] || continue
        case "${d}" in
            */ankh*|*/Ankh*|*/Fluent-Ankh*|*/selawik*|*/org.ankh.*) ;;
            *) continue ;;
        esac
        # Du plus profond vers la racine, tant que rmdir accepte.
        courant="${d}"
        while [[ -d "${courant}" ]]; do
            case "${courant}" in
                */ankh*|*/Ankh*|*/Fluent-Ankh*|*/selawik*|*/org.ankh.*) ;;
                *) break ;;
            esac
            if rmdir "${courant}" 2> /dev/null || sudo rmdir "${courant}" 2> /dev/null
            then
                partis=$((partis + 1))
                courant="$(dirname "${courant}")"
            else
                break
            fi
        done
    done < <(printf '%s' "${dossiers}" | sort -u | awk '{print length, $0}' \
             | sort -rn | cut -d" " -f2-)
    echo "${partis} dossier(s) retiré(s)."
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

# Et les clés, écrites EN CLAIR dans le kdeglobals de l'utilisateur.
#
# Le 2026-11-08, le passage en VM a lu « LookAndFeelPackage » VIDE après la
# désinstallation. Ce n'était pas un oubli de plasma-apply-lookandfeel :
# ces clés ne vivaient que dans NOTRE couche de valeurs par défaut
# (<préfixe>/share/ankh-de/config/kdeglobals, DE-010), que la
# désinstallation vient de supprimer. Plus de couche, plus de valeur.
#
# « plasmashell reprendra Breeze par défaut » n'est pas la même chose que
# « la configuration désigne Breeze » : la première est une supposition, la
# seconde se lit. On écrit donc, après le retrait des fichiers.
if command -v kwriteconfig6 > /dev/null; then
    case "${sombre:-org.kde.breeze.desktop}" in
        *breezedark*) jeu=BreezeDark ;;
        *)            jeu=BreezeLight ;;
    esac
    kwriteconfig6 --file kdeglobals --group KDE \
        --key LookAndFeelPackage "${sombre:-org.kde.breeze.desktop}"
    kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Breeze
    kwriteconfig6 --file kdeglobals --group General --key ColorScheme "${jeu}"
    echo "Configuration : thème global « ${sombre:-org.kde.breeze.desktop} », style Breeze, couleurs ${jeu}."
else
    echo "kwriteconfig6 introuvable : les clés du thème ne sont pas réécrites." >&2
fi

rm -f "${HOME}/.config/plasma-workspace/env/ankh-de.sh"
rm -f "${HOME}/.config/fontconfig/conf.d/29-ankh-rendu.conf"
command -v fc-cache > /dev/null && fc-cache -f > /dev/null 2>&1 || true

echo
echo "Fait. Déconnectez-vous et reconnectez-vous pour que le style de Breeze"
echo "reprenne complètement."

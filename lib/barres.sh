#!/usr/bin/env bash
# Sauvegarder et remettre les barres de l'utilisateur.
#
# Pourquoi ce fichier existe
# --------------------------
# Jusqu'au 2026-11-07, « installer.sh --barre » avertissait, demandait
# confirmation, puis détruisait sans retour possible : « --resetLayout »
# remplace la disposition, et « desinstaller.sh --barre » ne savait que
# remettre celle de Plasma par défaut — un autre état, pas l'état de départ.
# CLAUDE.md §3.8 exige pourtant qu'on puisse revenir d'où l'on vient. Un
# avertissement n'est pas une sauvegarde.
#
# Les deux gestes vivent ici, et non recopiés dans les deux scripts, pour une
# raison précise : ils doivent être ÉPROUVÉS. tests/barres.sh les fait tourner
# sur un faux HOME et vérifie que ce qui revient est octet pour octet ce qui
# est parti. Du code dupliqué dans deux scripts qui demandent une session
# Plasma ne se teste pas.
#
# Les deux fonctions n'écrivent que sous HOME et ne lancent aucune application
# Qt : elles sont utilisables hors session.

# Les fichiers qui portent les barres. plasmashellrc tient les réglages de la
# coquille (écrans, emplacements) ; sans lui, une barre remise peut revenir
# sur le mauvais écran.
ANKH_BARRES_FICHIERS=(plasma-org.kde.plasma.desktop-appletsrc plasmashellrc)

ankh_barres_dossier() {
    echo "${XDG_DATA_HOME:-${HOME}/.local/share}/ankh-de/sauvegardes"
}

# Copie les fichiers de barre et note l'horodatage du jeu. Rend 0 même quand
# il n'y a rien à sauvegarder — une session neuve n'a pas de barre, et ce
# n'est pas une erreur. Affiche ce qu'elle a fait.
ankh_barres_sauver() {
    local dossier horodatage gardes=0 f
    dossier="$(ankh_barres_dossier)"
    install -d -m 0700 "${dossier}"
    horodatage="$(date +%Y%m%d-%H%M%S)"
    for f in "${ANKH_BARRES_FICHIERS[@]}"; do
        if [[ -f "${HOME}/.config/${f}" ]]; then
            cp -a "${HOME}/.config/${f}" "${dossier}/${f}.${horodatage}"
            gardes=$((gardes + 1))
        fi
    done
    if (( gardes )); then
        # Écrit APRÈS les copies : un horodatage qui désigne un jeu incomplet
        # ferait croire à une sauvegarde utilisable.
        echo "${horodatage}" > "${dossier}/dernier"
        echo "  ${gardes} fichier(s) de barre sauvegardé(s) dans ${dossier}"
        echo "  « ./desinstaller.sh --barre » les remettra."
    else
        echo "  aucune barre à sauvegarder (session neuve)"
    fi
    return 0
}

# Remet le dernier jeu sauvegardé. Rend 0 si elle a remis quelque chose, 1
# s'il n'y avait rien — l'appelant décide alors quoi faire.
#
# plasmashell réécrit ces fichiers en quittant : remettre pendant qu'il tourne
# ne sert à rien. On l'arrête, on remet, on relance.
ankh_barres_remettre() {
    local dossier horodatage="" remis=0 arrete=non f
    dossier="$(ankh_barres_dossier)"
    [[ -r "${dossier}/dernier" ]] || return 1
    horodatage="$(cat "${dossier}/dernier")"
    [[ -n "${horodatage}" ]] || return 1

    if [[ -z "${ANKH_BARRES_SANS_PLASMA:-}" ]]; then
        if systemctl --user --quiet is-active plasma-plasmashell.service 2>/dev/null; then
            systemctl --user stop plasma-plasmashell.service && arrete=systemd
        elif command -v kquitapp6 > /dev/null && pgrep -u "$(id -u)" plasmashell > /dev/null; then
            kquitapp6 plasmashell 2>/dev/null && arrete=kquitapp
        fi
    fi

    for f in "${ANKH_BARRES_FICHIERS[@]}"; do
        if [[ -f "${dossier}/${f}.${horodatage}" ]]; then
            cp -a "${dossier}/${f}.${horodatage}" "${HOME}/.config/${f}"
            remis=$((remis + 1))
        fi
    done

    case "${arrete}" in
        systemd)  systemctl --user start plasma-plasmashell.service || true ;;
        kquitapp) (setsid plasmashell > /dev/null 2>&1 &) ;;
    esac

    (( remis )) || return 1
    echo "  ${remis} fichier(s) de barre remis depuis la sauvegarde du ${horodatage}."
    return 0
}

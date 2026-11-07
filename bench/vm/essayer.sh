#!/usr/bin/env bash
# Installe et éprouve Ankh DE dans une VRAIE machine virtuelle, avec une
# vraie session Plasma. C'est le seul endroit où l'on peut dire « ça marche »
# plutôt que « ça compile » (CLAUDE.md §4).
#
# Conçu pour un runner GitHub : le job « VM » a établi le 2026-11-05 que
# /dev/kvm y est présent, que le processeur a ses extensions, que qemu 8.2.2
# propose kvm, et qu'une VM accélérée démarre — mais que /dev/kvm n'est PAS
# accessible en écriture par l'utilisateur du runner.
#
#   bench/vm/essayer.sh [dossier de travail]
#   ANKH_VM_DISTRIB=ubuntu|fedora bench/vm/essayer.sh
#
# La CIBLE est Ubuntu 26.04 LTS (DE-016) : c'est la machine de l'utilisateur,
# et elle livre Plasma 6.6. Fedora 44 reste la seconde épreuve, parce qu'elle
# livre 6.8 et prouve donc l'autre bout de la plage. Par défaut : ubuntu.
#
# Chaque étape dit ce qu'elle fait et laisse ses journaux : un passage qui
# échoue doit apprendre quelque chose, pas seulement échouer.
set -euo pipefail

racine="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
travail="${1:-${racine}/bench/vm/travail}"
sortie="${racine}/bench/sortie"
install -d -m 0755 "${travail}" "${sortie}"

PORT_SSH=2222
MEMOIRE=6G
PROCESSEURS=4
qemu_pid=""

# Quelle distribution dans l'invité. Tout ce qui diffère entre les deux est
# rassemblé ici et aux étapes 1 et 4 — nulle part ailleurs.
DISTRIB="${ANKH_VM_DISTRIB:-ubuntu}"
case "${DISTRIB}" in
    ubuntu)
        DISTRIB_NOM="Ubuntu 26.04 LTS"
        DISTRIB_IMAGE="https://cloud-images.ubuntu.com/releases/26.04/release/ubuntu-26.04-server-cloudimg-amd64.img"
        DISTRIB_GROUPE=sudo
        DISTRIB_PLASMA_ATTENDU=6.6
        ;;
    fedora)
        DISTRIB_NOM="Fedora 44"
        DISTRIB_IMAGE=""   # demandé à releases.json, le nom change à chaque compilation
        DISTRIB_GROUPE=wheel
        DISTRIB_PLASMA_ATTENDU=6.8
        ;;
    *)
        echo "ANKH_VM_DISTRIB vaut « ${DISTRIB} » : attendu « ubuntu » ou « fedora »." >&2
        exit 1
        ;;
esac

nettoyer() {
    if [[ -n "${qemu_pid}" ]] && kill -0 "${qemu_pid}" 2>/dev/null; then
        echo "== Arrêt de la VM"
        ssh_vm 'sudo poweroff' > /dev/null 2>&1 || true
        for _ in $(seq 20); do kill -0 "${qemu_pid}" 2>/dev/null || break; sleep 1; done
        kill "${qemu_pid}" 2>/dev/null || true
    fi
}
trap nettoyer EXIT

etape() { echo; echo "=== $* ==="; }

# --- Les échecs qui ne doivent PAS passer pour un succès -----------------
# Jusqu'au 2026-11-06, trois constats de ce script étaient affichés sans
# jamais changer son code de sortie : les vérifications clé par clé
# (« ÉCHEC — voir vm-tests.log » suivi d'un workflow vert), la présence de
# notre applet dans la barre, et l'ouverture du menu. Un passage pouvait
# donc écrire « ÉCHEC » à l'écran et se conclure en réussite.
#
# On ne sort pas tout de suite pour autant : les captures, le rapport et les
# journaux sont rassemblés jusqu'au bout — c'est précisément quand ça rate
# qu'ils servent. Les griefs sont donc mis de côté et rendus à la fin, et
# c'est la fin qui décide du code de sortie.
griefs=()
grief() { echo "   ÉCHEC $*" >&2; griefs+=("$*"); }
verdict() {
    echo
    if (( ${#griefs[@]} )); then
        echo "=== ${#griefs[@]} ÉCHEC(S) ==="
        printf '  - %s\n' "${griefs[@]}"
        echo
        echo "Les artéfacts du passage sont dans ${sortie}." >&2
        exit 1
    fi
    echo "=== Tout ce que ce passage vérifie est vérifié ==="
}

ssh_vm() {
    ssh -p "${PORT_SSH}" -i "${travail}/cle" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR -o ConnectTimeout=10 \
        ankh@127.0.0.1 "$@"
}
scp_vm() {
    scp -P "${PORT_SSH}" -i "${travail}/cle" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR "$@"
}

# --- 0. Ce dont on a besoin ----------------------------------------------
etape "0. Outils et accélération"
manquants=()
for outil in qemu-system-x86_64 qemu-img cloud-localds curl jq ssh-keygen; do
    command -v "${outil}" > /dev/null || manquants+=("${outil}")
done
if (( ${#manquants[@]} )); then
    echo "Outils manquants : ${manquants[*]}" >&2
    echo "  Ubuntu : sudo apt-get install -y qemu-system-x86 qemu-utils cloud-image-utils curl jq" >&2
    exit 1
fi
if [[ ! -w /dev/kvm ]]; then
    echo "/dev/kvm n'est pas accessible en écriture : on l'ouvre (constat du job VM)."
    sudo chmod 666 /dev/kvm
fi
qemu-system-x86_64 -accel help 2>&1 | grep -qw kvm || { echo "qemu ne propose pas kvm" >&2; exit 1; }
echo "kvm disponible, $(nproc) cœurs, $(free -g | awk '/^Mem:/{print $2}') Gio"

# --- 1. L'image invitée ---------------------------------------------------
etape "1. Image de ${DISTRIB_NOM}"
# Le dossier de travail est partagé entre les deux distributions : l'image
# porte donc le nom de la sienne, sinon un passage Ubuntu réutiliserait
# l'image Fedora déjà là et prouverait quelque chose sur la mauvaise cible.
base="${travail}/base-${DISTRIB}.qcow2"
if [[ ! -f "${base}" ]]; then
    if [[ -n "${DISTRIB_IMAGE}" ]]; then
        url="${DISTRIB_IMAGE}"
    else
        # Fedora : le nom du fichier change à chaque compilation, on le
        # demande à l'index publié plutôt que de le deviner.
        curl -fsSL -o "${travail}/releases.json" https://fedoraproject.org/releases.json
        url="$(jq -r '
            [ .[] | select(.arch == "x86_64")
                  | select(.variant == "Cloud")
                  | select(.link | endswith(".qcow2"))
                  | select(.version == "44") ]
            | first | .link // empty' "${travail}/releases.json")"
        if [[ -z "${url}" ]]; then
            echo "Aucune image Cloud x86_64 pour Fedora 44 dans releases.json." >&2
            echo "Versions proposées :" >&2
            jq -r '[.[] | select(.variant=="Cloud") | .version] | unique | join(", ")' \
                "${travail}/releases.json" >&2
            exit 1
        fi
    fi
    echo "   ${url}"
    curl -fL --retry 3 -o "${base}" "${url}"
fi
echo "   image : $(du -h "${base}" | cut -f1)"

rm -f "${travail}/disque.qcow2"
qemu-img create -f qcow2 -b "${base}" -F qcow2 "${travail}/disque.qcow2" 40G > /dev/null

# --- 2. cloud-init : un compte et une clé éphémère -----------------------
etape "2. Préparation du premier démarrage"
rm -f "${travail}/cle" "${travail}/cle.pub"
ssh-keygen -q -t ed25519 -N '' -f "${travail}/cle" -C ankh-de-essai
cat > "${travail}/user-data" << CLOUD
#cloud-config
users:
  - name: ankh
    groups: [${DISTRIB_GROUPE}]
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    shell: /bin/bash
    ssh_authorized_keys:
      - $(cat "${travail}/cle.pub")
ssh_pwauth: false
# Une seule mise à jour, pour que Plasma soit bien la version que la
# distribution livre aujourd'hui et non celle de l'image figée.
package_upgrade: true
CLOUD
printf 'instance-id: ankh-de\nlocal-hostname: ankh-de\n' > "${travail}/meta-data"
cloud-localds "${travail}/seed.iso" "${travail}/user-data" "${travail}/meta-data"

# --- 3. Démarrage ---------------------------------------------------------
etape "3. Démarrage de la VM"
qemu-system-x86_64 \
    -accel kvm -cpu host -smp "${PROCESSEURS}" -m "${MEMOIRE}" \
    -drive file="${travail}/disque.qcow2",if=virtio,format=qcow2 \
    -drive file="${travail}/seed.iso",if=virtio,format=raw,readonly=on \
    -device virtio-vga -display none -vga none \
    -device virtio-tablet \
    -nic user,model=virtio-net-pci,hostfwd=tcp::"${PORT_SSH}"-:22 \
    -qmp unix:"${travail}/qmp.sock",server=on,wait=off \
    -serial file:"${travail}/console.log" \
    > "${travail}/qemu.log" 2>&1 &
qemu_pid=$!

echo "   attente de SSH (jusqu'à 5 minutes)"
pret=non
for i in $(seq 150); do
    if ssh_vm 'echo pret' > /dev/null 2>&1; then pret=oui; break; fi
    kill -0 "${qemu_pid}" 2>/dev/null || { echo "qemu s'est arrêté :" >&2; tail -20 "${travail}/qemu.log" >&2; exit 1; }
    sleep 2
done
if [[ "${pret}" != oui ]]; then
    echo "Pas de SSH après 5 minutes. Fin de la console série :" >&2
    tail -40 "${travail}/console.log" >&2
    exit 1
fi
echo "   VM joignable : $(ssh_vm 'cat /etc/os-release | sed -n "s/^PRETTY_NAME=//p"')"

# cloud-init met le système à jour en arrière-plan. Installer pendant qu'il
# travaille laisse des bibliothèques dépareillées : au passage du
# 2026-11-06, rsvg-convert ne trouvait plus libglib. On attend qu'il ait
# fini avant de toucher à quoi que ce soit.
echo "   attente de la fin de cloud-init"
ssh_vm 'sudo cloud-init status --wait' > /dev/null 2>&1 || true
echo "   cloud-init : $(ssh_vm 'sudo cloud-init status' | head -1)"

# --- 4. Plasma dans l'invité ---------------------------------------------
etape "4. Installation de Plasma (${DISTRIB_NOM})"
if [[ "${DISTRIB}" == ubuntu ]]; then
    # cloud-init a déjà fait un « update », mais pas forcément avant que
    # l'image ait fini de s'installer : on le refait, sinon apt refuse des
    # paquets qu'il croit absents.
    ssh_vm 'sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq' > /dev/null 2>&1 || true
    # kde-plasma-desktop tire plasmashell, KWin, la zone système et les
    # applets natives — c'est-à-dire, depuis DE-015, presque toute notre
    # barre. Les noms de paquets de développement sont ceux de docs/INSTALL.md.
    ssh_vm 'sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        kde-plasma-desktop plasma-workspace kwin-wayland sddm \
        xwayland dbus \
        cmake g++ extra-cmake-modules \
        qt6-base-dev qt6-declarative-dev \
        libkf6config-dev libkf6coreaddons-dev libkf6guiaddons-dev \
        libkf6iconthemes-dev libkf6windowsystem-dev libkf6colorscheme-dev \
        libkf6style-dev libkdecorations3-dev \
        fontmake librsvg2-bin x11-apps sassc fontconfig git \
        python3-pil \
        konsole dolphin systemsettings \
        > /tmp/paquets.log 2>&1' || {
            echo "L'installation de Plasma a échoué :" >&2
            ssh_vm 'tail -30 /tmp/paquets.log' >&2 || true
            exit 1
        }
    echo "   $(ssh_vm 'dpkg-query -W -f "\${binary:Package} \${Version}\n" plasma-workspace kwin-wayland libkdecorations3-dev 2>/dev/null | tr "\n" " "')"
else
    ssh_vm 'sudo dnf install -y \
        plasma-desktop plasma-workspace kwin sddm \
        kf6-kconfig kf6-kirigami plasma-integration \
        xorg-x11-server-Xwayland dbus-daemon \
        cmake gcc-c++ extra-cmake-modules \
        qt6-qtbase-devel qt6-qtdeclarative-devel \
        kf6-kconfig-devel kf6-kcoreaddons-devel kf6-kguiaddons-devel \
        kf6-kiconthemes-devel kf6-kwindowsystem-devel kf6-kcolorscheme-devel \
        kf6-frameworkintegration-devel kdecoration-devel \
        fontmake librsvg2-tools xcursorgen sassc fontconfig git \
        python3-pillow \
        konsole dolphin plasma-systemsettings \
        > /tmp/paquets.log 2>&1' || {
            echo "L'installation de Plasma a échoué :" >&2
            ssh_vm 'tail -30 /tmp/paquets.log' >&2 || true
            exit 1
        }
    echo "   $(ssh_vm 'rpm -q --qf "%{NAME} %{VERSION}\n" plasma-workspace kwin kdecoration-devel | tr "\n" " "')"
fi

# Les applications dont les essais d'interaction ont BESOIN, vérifiées ici,
# là où leur absence a une cause lisible.
#
# Le 2026-11-07, « konsole » figurait dans la liste d'installation et l'essai
# Alt+Tab concluait pourtant « konsole lancé : NON » sans rien expliquer : le
# lancement était enterré sous « > /dev/null 2>&1 || true » trois cents
# lignes plus bas. Un outil manquant doit faire échouer l'étape qui
# l'installe, pas l'essai qui s'en sert.
for appli in konsole dolphin systemsettings; do
    chemin="$(ssh_vm "command -v ${appli} 2>/dev/null" || true)"
    if [[ -n "${chemin}" ]]; then
        echo "   ${appli} : ${chemin}"
    else
        grief "${appli} n'est pas installé dans l'invité : les essais qui s'en servent ne prouveront rien"
    fi
done
# La version de Plasma que l'invité livre VRAIMENT, contre celle que la
# plage de DE-016 annonce. Si elles divergent, les mesures portent sur autre
# chose que ce qu'on croit.
plasma_invite="$(ssh_vm 'plasmashell --version 2>/dev/null | grep -oE "[0-9]+\.[0-9]+" | head -1' || true)"
echo "   Plasma dans l'invité : ${plasma_invite:-inconnue} (attendu ${DISTRIB_PLASMA_ATTENDU})"
[[ "${plasma_invite}" == "${DISTRIB_PLASMA_ATTENDU}" ]] \
    || grief "l'invité livre Plasma ${plasma_invite:-inconnue}, pas ${DISTRIB_PLASMA_ATTENDU} : ce passage ne prouve pas ce qu'il annonce"

# --- 5. Ankh DE dans l'invité --------------------------------------------
etape "5. Installation d'Ankh DE"
git -C "${racine}" archive --format=tar --prefix=ankh-de/ HEAD > "${travail}/source.tar"
scp_vm "${travail}/source.tar" ankh@127.0.0.1:/tmp/ > /dev/null
ssh_vm 'rm -rf ~/ankh-de && tar -xf /tmp/source.tar -C ~'
ssh_vm 'cd ~/ankh-de && ./third_party/preparer.sh > /tmp/preparer.log 2>&1' || {
    echo "preparer.sh a échoué :" >&2; ssh_vm 'tail -25 /tmp/preparer.log' >&2 || true; exit 1; }
echo "   pièces tierces prêtes"
# Installation non interactive : pas de « --barre », qui demande confirmation.
ssh_vm 'cd ~/ankh-de && ./installer.sh > /tmp/installer.log 2>&1' || {
    echo "installer.sh a échoué :" >&2; ssh_vm 'tail -30 /tmp/installer.log' >&2; exit 1; }
echo "   installé"
ssh_vm 'ls /usr/local/share/wayland-sessions/' | sed 's/^/   session : /'

# --- 5bis. Rendre audible la voix de la disposition ----------------------
# Le script de disposition parle avec print(), que plasmashell envoie dans
# qCDebug(PLASMASHELL). Sa catégorie est « kde.plasmashell » et sa sévérité
# par défaut est Info (shell/CMakeLists.txt:23-28) : qCDebug est donc MUET,
# et le 2026-11-06 j'ai pris ce silence pour la preuve que le script
# n'avait pas tourné. Il ne prouvait rien du tout.
#
# On ouvre la catégorie, dans la VM seulement : la session livrée ne doit
# pas inonder le journal de l'utilisateur.
ssh_vm 'mkdir -p ~/.config/QtProject && cat > ~/.config/QtProject/qtlogging.ini << INI
[Rules]
kde.plasmashell.debug=true
INI'
echo "   journalisation de kde.plasmashell ouverte (print() de la disposition)"

# La disposition n'est évaluée QU'À un premier démarrage : shellcorona ne
# l'appelle que si la configuration ne porte aucun conteneur
# (shell/shellcorona.cpp:811). Si un appletsrc traîne déjà, le test ne
# mesure plus ce qu'il croit mesurer — alors on le dit avant de commencer.
if ssh_vm 'test -s ~/.config/plasma-org.kde.plasma.desktop-appletsrc'; then
    echo "   ATTENTION un appletsrc existe DÉJÀ : la disposition ne sera pas réévaluée" >&2
    premier_demarrage=non
else
    echo "   aucun appletsrc : ce sera bien un premier démarrage"
    premier_demarrage=oui
fi

# --- 6. Ouvrir la session ------------------------------------------------
etape "6. Ouverture de la session Ankh DE"
# SDDM se connecte tout seul dans NOTRE session : c'est le chemin réel,
# « choisir Ankh DE à l'écran de connexion », et non un startplasma lancé
# à la main.
ssh_vm 'sudo mkdir -p /etc/sddm.conf.d && sudo tee /etc/sddm.conf.d/ankh-essai.conf > /dev/null << CONF
[Autologin]
User=ankh
Session=ankh-de
Relogin=false
CONF
sudo systemctl set-default graphical.target
sudo systemctl isolate graphical.target' || true

echo "   attente de la session (jusqu'à 3 minutes)"
session=non
for i in $(seq 90); do
    if ssh_vm 'pgrep -u ankh plasmashell > /dev/null && pgrep -u ankh kwin_wayland > /dev/null'; then
        session=oui; break
    fi
    sleep 2
done
if [[ "${session}" != oui ]]; then
    echo "La session ne s'est pas ouverte. Diagnostic :" >&2
    ssh_vm 'systemctl --no-pager status sddm | head -20; echo ---; sudo journalctl -u sddm --no-pager | tail -40' >&2 || true
    ssh_vm 'ls -la /usr/local/share/wayland-sessions/ /usr/share/wayland-sessions/ 2>&1' >&2 || true
    exit 1
fi
echo "   plasmashell et kwin_wayland sont vivants"

# --- 6bis. PROUVER que c'est une session graphique, et la NÔTRE ---------
# Des processus vivants ne font pas une session : il faut que le
# gestionnaire de connexion ait lancé NOTRE fichier de session, que la
# session soit en Wayland, et que le compositeur compose vraiment. Un
# écran noir passerait tous les contrôles précédents.
echo "== Preuves de la session"

# Le nom de l'outil change selon la distribution : « qdbus-qt6 » sur
# Fedora, « qdbus6 » ailleurs. Le 2026-11-06, le harnais appelait « qdbus6 »
# dans la VM : TOUTES les requêtes à Plasma échouaient en silence, et le
# rapport donnait leur vide pour un fait — « notre applet n'est pas dans la
# barre » alors que la question n'avait jamais été posée.
QDBUS=""
for candidat in qdbus-qt6 qdbus6 qdbus; do
    if ssh_vm "command -v ${candidat}" > /dev/null 2>&1; then QDBUS="${candidat}"; break; fi
done
if [[ -z "${QDBUS}" ]]; then
    echo "Aucun outil qdbus dans l'invité : impossible d'interroger Plasma." >&2
    exit 1
fi
echo "   outil d'interrogation : ${QDBUS}"

# Une requête qui échoue doit le DIRE. Un vide silencieux se lit comme une
# réponse, et c'est ainsi qu'on affirme le contraire de la vérité.
plasma_script() { # $1 : JavaScript
    local sortie code
    sortie="$(dans_session "${QDBUS} org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '$1'" 2>&1)" && code=0 || code=$?
    if (( code != 0 )); then
        echo "   ECHEC evaluateScript (code ${code}) : ${sortie}" >&2
        return 1
    fi
    printf '%s' "${sortie}" | tr -d '\r'
}
environ_de() { # $1 : variable
    ssh_vm "tr '\0' '\n' < /proc/\$(pgrep -u ankh -f plasmashell | head -1)/environ | sed -n 's/^$1=//p'" \
        2>/dev/null | tr -d '\r' || true
}
preuve() { # $1 : libellé, $2 : attendu, $3 : obtenu
    if [[ "$3" == "$2" ]]; then
        printf '   ok    %-34s %s\n' "$1" "$3"
    else
        echo "   ECHEC $1 : attendu « $2 », obtenu « $3 »" >&2
        echec_session=oui
    fi
}
echec_session=non

# Quelle variable porte le nom du fichier de session ? J'ai affirmé le
# 2026-11-06 que c'était XDG_SESSION_DESKTOP, et c'est faux. Dans SDDM
# (src/daemon/Display.cpp) :
#   453  DESKTOP_SESSION      = session.desktopSession()
#   455  XDG_CURRENT_DESKTOP  = session.desktopNames()
#   462  XDG_SESSION_DESKTOP  = session.desktopNames()
# et desktopSession() rend QFileInfo(fichier).completeBaseName()
# (src/common/Session.cpp:168), donc « ankh-de ».
#
# XDG_SESSION_DESKTOP vaut donc DesktopNames, que notre fichier de session
# pose à « KDE » EXPRÈS : les portails XDG et une partie de KDE cherchent
# « KDE » là-dedans, et annoncer « ankh-de » casserait les sélecteurs de
# fichiers. Mon assertion exigeait donc le contraire de notre propre choix
# — elle a échoué à son premier passage réel, et elle avait tort.
#
# On vérifie les deux : le FICHIER lancé, et l'identité annoncée.
preuve "fichier de session lancé"           "ankh-de" "$(environ_de DESKTOP_SESSION)"
preuve "identité annoncée (portails XDG)"   "KDE"     "$(environ_de XDG_CURRENT_DESKTOP)"
preuve "type de session"                    "wayland" "$(environ_de XDG_SESSION_TYPE)"
preuve "c'est notre lanceur"                "1"       "$(environ_de ANKH_DE_SESSION)"

# Le compositeur compose-t-il vraiment ? Une image uniforme — noire ou
# autre — veut dire qu'il n'a rien dessiné.
#
# Le 2026-11-06, ce contrôle jugeait sur UN cliché pris deux secondes après
# l'apparition de plasmashell : il tombait sur l'écran de chargement (65
# couleurs, écart-type 2,5) et criait « rien n'est composé » alors que la
# session était en train de s'ouvrir normalement. Un instantané pris trop
# tôt n'est pas une preuve, c'est un tirage au sort.
#
# On attend donc que l'écran se peuple, et on dit AU BOUT DE COMBIEN DE
# TEMPS : la durée est elle-même une information, et un échec dit alors
# « jamais en N secondes », ce qui est vérifiable.
variete() { # rend « écart-type couleurs » du cliché courant
    printf '{ "execute": "qmp_capabilities" }\n{ "execute": "screendump", "arguments": { "filename": "%s" } }\n' \
        "${travail}/preuve.ppm" | timeout 30 socat - UNIX-CONNECT:"${travail}/qmp.sock" > /dev/null 2>&1 || true
    [[ -s "${travail}/preuve.ppm" ]] || { echo "0 0"; return; }
    python3 -I -c "
from PIL import Image, ImageStat
import sys
im = Image.open(sys.argv[1]).convert('RGB')
s = ImageStat.Stat(im)
print(round(max(s.stddev), 1), len(im.convert('P', palette=Image.ADAPTIVE, colors=256).getcolors(1 << 20) or []))
" "${travail}/preuve.ppm" 2>/dev/null || echo "0 0"
}
compose=non
attendu=0
for essai in $(seq 24); do          # 24 × 5 s = 2 minutes
    v="$(variete)"
    ecart="${v%% *}"; couleurs="${v##* }"
    if (( $(printf '%.0f' "${ecart}") > 5 )) && (( couleurs > 20 )); then
        compose=oui; break
    fi
    attendu=$((essai * 5))
    sleep 5
done
if [[ "${compose}" == oui ]]; then
    printf '   ok    %-34s écart-type %s, %s couleurs, au bout de %s s\n' \
        "le compositeur dessine" "${ecart}" "${couleurs}" "${attendu}"
else
    echo "   ECHEC l'écran est resté uniforme pendant ${attendu} s (écart-type ${ecart}, ${couleurs} couleurs)" >&2
    # La capture du dernier essai part avec les artéfacts : sans elle, on ne
    # peut pas savoir si c'était un écran noir ou un écran de chargement.
    python3 -I -c "
from PIL import Image
import sys
Image.open(sys.argv[1]).save(sys.argv[2])" "${travail}/preuve.ppm" "${sortie}/vm-ecran-uniforme.png" 2>/dev/null || true
    echec_session=oui
fi

if [[ "${echec_session}" == oui ]]; then
    echo "La session n'est pas celle qu'on prétend ouvrir." >&2
    ssh_vm 'sudo journalctl -u sddm --no-pager | tail -25' >&2 || true
    exit 1
fi

# --- 7. Ce que la session doit prouver -----------------------------------
etape "7. Vérifications dans la session"
uid="$(ssh_vm 'id -u')"
# Une commande lancée par SSH n'hérite RIEN de la session graphique : au
# premier passage, « kreadconfig6 » rendait des valeurs vides alors que la
# session, elle, était correcte. On reprend donc l'environnement DE LA
# SESSION, lu dans le processus plasmashell.
env_session="$(ssh_vm "tr '\0' '\n' < /proc/\$(pgrep -u ankh -f plasmashell | head -1)/environ \
    | grep -E '^(XDG_CONFIG_DIRS|XDG_CONFIG_HOME|XDG_DATA_DIRS|QT_PLUGIN_PATH)=' \
    | sed 's/^/export /' | tr '\n' ';'")"
dans_session() {
    ssh_vm "${env_session} \
            export XDG_RUNTIME_DIR=/run/user/${uid}; \
            export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${uid}/bus; \
            export WAYLAND_DISPLAY=wayland-0; $*"
}
{
    echo "## Session Ankh DE, dans une VM"
    echo
    echo "- système : $(ssh_vm 'sed -n "s/^PRETTY_NAME=//p" /etc/os-release')"
    # « plasmashell --version » marche sur les deux distributions, là où
    # « rpm -q » ne marchait que sur Fedora.
    echo "- Plasma : $(ssh_vm 'plasmashell --version 2>/dev/null | head -1' || echo inconnue)"
    echo "- cible de ce passage : ${DISTRIB_NOM}, Plasma ${DISTRIB_PLASMA_ATTENDU} attendu"
    echo "- c'est bien notre session : ANKH_DE_SESSION=$(ssh_vm "tr \"\\0\" \"\\n\" < /proc/\$(pgrep -u ankh -f plasmashell | head -1)/environ | sed -n 's/^ANKH_DE_SESSION=//p'")"
    echo "- XDG_CONFIG_DIRS : $(ssh_vm "tr \"\\0\" \"\\n\" < /proc/\$(pgrep -u ankh -f plasmashell | head -1)/environ | sed -n 's/^XDG_CONFIG_DIRS=//p'")"
    echo "- XDG_DATA_DIRS : $(ssh_vm "tr \"\\0\" \"\\n\" < /proc/\$(pgrep -u ankh -f plasmashell | head -1)/environ | sed -n 's/^XDG_DATA_DIRS=//p'")"
    echo "- style : $(dans_session 'kreadconfig6 --group KDE --key widgetStyle')"
    echo "- couleurs : $(dans_session 'kreadconfig6 --group General --key ColorScheme')"
    echo "- police : $(dans_session 'kreadconfig6 --group General --key font')"
    echo "- décoration : $(dans_session 'kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key library')"
    echo "- icônes : $(dans_session 'kreadconfig6 --group Icons --key Theme')"
    echo "- style Plasma : $(dans_session 'kreadconfig6 --file plasmarc --group Theme --key name')"
    # La clé qui décide quelle barre des tâches plasmashell construit
    # (DE-014). Elle manquait, et c'est pour cela que la nôtre n'existait
    # pas. Elle est dans le rapport pour que son absence saute aux yeux.
    echo "- thème global (décide la barre) : $(dans_session 'kreadconfig6 --group KDE --key LookAndFeelPackage')"
    echo "- premier démarrage (disposition évaluée) : ${premier_demarrage}"
    echo "- Selawik vue par fontconfig : $(ssh_vm 'fc-match -f "%{family[0]}" Selawik')"
} | tee "${sortie}/vm-rapport.md"

# Un rapport qui affiche une ligne vide n'est pas un succès : c'est un
# réglage non appliqué. Au premier passage, « style » était vide et rien ne
# le signalait (le greffon n'était pas trouvé par l'installateur).
manquants=()
while IFS= read -r ligne; do
    case "${ligne}" in
        "- "*": ") manquants+=("${ligne#- }") ;;
    esac
done < "${sortie}/vm-rapport.md"
if (( ${#manquants[@]} )); then
    echo "Réglages NON appliqués dans la session :" >&2
    printf '  %s\n' "${manquants[@]}" >&2
    exit 1
fi
echo "   tous les réglages du rapport sont renseignés"

# Pas de nombre dans le titre : le total dépend des outils présents dans
# l'invité (qmllint, par exemple, n'est pas partout). Un nombre figé ici
# devient faux sans que rien ne le dise — README annonçait 46 quand le test
# en passait 47. Le script imprime son propre compte, c'est lui qui fait foi.
etape "8. Les vérifications clé par clé, dans la VM"
dans_session 'cd ~/ankh-de && ANKH_DE_CMAKE_EXTRA=-DANKH_DE_PLASMA_NON_TESTE=ON ./tests/session-et-theme.sh' \
    > "${sortie}/vm-tests.log" 2>&1 \
    && echo "   toutes passées" \
    || { grief "les vérifications clé par clé ne passent pas dans la session"
         tail -25 "${sortie}/vm-tests.log" >&2; }
# Le compte réel, dans le rapport : c'est lui qu'on cite, pas un souvenir.
compte_tests="$(sed -n 's/^\([0-9]*\) vérifications.*/\1/p' "${sortie}/vm-tests.log" | tail -1)"
echo "   compte annoncé par le test : ${compte_tests:-inconnu}"
echo "- vérifications clé par clé passées dans la session : ${compte_tests:-inconnu}" \
    >> "${sortie}/vm-rapport.md"

etape "9. Capture du bureau"
printf '{ "execute": "qmp_capabilities" }\n{ "execute": "screendump", "arguments": { "filename": "%s" } }\n' \
    "${travail}/bureau.ppm" | timeout 30 socat - UNIX-CONNECT:"${travail}/qmp.sock" > /dev/null 2>&1 || true
if [[ -s "${travail}/bureau.ppm" ]]; then
    python3 -c "
from PIL import Image
import sys
Image.open(sys.argv[1]).save(sys.argv[2])" "${travail}/bureau.ppm" "${sortie}/vm-bureau.png" 2>/dev/null \
        && echo "   vm-bureau.png écrit" \
        || cp "${travail}/bureau.ppm" "${sortie}/vm-bureau.ppm"
else
    echo "   capture indisponible" >&2
fi

etape "10. Le menu Démarrer"
# Première question, et elle n'est pas rhétorique : la barre porte-t-elle
# NOTRE applet, ou celui de Plasma avec nos icônes ? On le demande à
# plasmashell plutôt que de le déduire d'une capture.
applets="$(plasma_script 'var n=[]; panels().forEach(function(p){p.widgetIds.forEach(function(i){n.push(p.widgetById(i).type)})}); print(n.join(","))' || true)"
echo "   applets de la barre : ${applets:-inconnus}"
# Ce que la disposition a dit en construisant la barre : c'est là qu'un
# repli silencieux se voit.
dit_layout="$(ssh_vm "journalctl --user --no-pager -b 2>/dev/null | grep -o 'ANKH-LAYOUT.*' | head -8" || true)"
if [[ -n "${dit_layout}" ]]; then
    printf '%s\n' "${dit_layout}" | sed 's/^/   /'
else
    echo "   la disposition n'a rien dit (voir « script évalué » ci-dessous)"
fi
# Et SURTOUT : quelle disposition plasmashell a-t-il évaluée ? C'est la
# seule ligne qui distingue « notre script a tourné et n'a rien trouvé » de
# « notre script n'a jamais tourné ». shellcorona.cpp:1125 la journalise,
# dans la catégorie qu'on vient d'ouvrir (étape 5bis).
script_evalue="$(ssh_vm "journalctl --user --no-pager -b 2>/dev/null | sed -n 's/.*evaluating startup script: //p' | tail -1" || true)"
echo "   script de disposition évalué : ${script_evalue:-inconnu}"
case "${script_evalue}" in
    *org.ankh.de.desktop*) ;;
    "") grief "on ne sait pas quelle disposition plasmashell a évaluée" ;;
    *)  grief "plasmashell a évalué une disposition qui n'est pas la nôtre : ${script_evalue}" ;;
esac
[[ "${premier_demarrage}" == oui ]] \
    || grief "un appletsrc existait déjà : la disposition n'a pas été réévaluée, ce passage ne mesure pas ce qu'il annonce"

if [[ -z "${applets}" ]]; then
    demarrer_present="INCONNU — la requête a échoué"
else
    demarrer_present=non
    case "${applets}" in *org.ankh.demarrer*) demarrer_present=oui ;; esac
fi
echo "   org.ankh.demarrer dans la barre : ${demarrer_present}"
case "${demarrer_present}" in
    oui) ;;
    non) grief "org.ankh.demarrer n'est pas dans la barre (applets : ${applets})" ;;
    *)   grief "impossible de savoir ce que porte la barre : la requête à plasmashell a échoué" ;;
esac

# Les applets NATIVES que la barre doit porter (DE-015). Chacune est
# demandée NOMMÉMENT : « la barre a sept applets » ne dit pas lesquels, et
# c'est exactement le genre d'approximation qui m'a fait écrire qu'un menu
# était là quand il n'y était pas.
natives=()
for applet in org.kde.plasma.icontasks org.kde.plasma.systemtray \
              org.kde.plasma.digitalclock org.kde.plasma.notifications \
              org.kde.plasma.showdesktop org.kde.plasma.panelspacer; do
    if [[ -z "${applets}" ]]; then
        natives+=("${applet##org.kde.plasma.}=inconnu")
    elif [[ "${applets}" == *"${applet}"* ]]; then
        natives+=("${applet##org.kde.plasma.}=oui")
    else
        natives+=("${applet##org.kde.plasma.}=NON")
        grief "${applet} n'est pas dans la barre"
    fi
done
echo "   applets natives : ${natives[*]}"

# Et l'inverse : AUCUNE des pièces retirées par DE-015 ne doit reparaître.
# Si l'une revenait, la barre porterait deux implémentations de la même
# responsabilité — le doublon que DE-015 supprime (CLAUDE.md §0.3).
for parti in org.ankh.taches org.ankh.vuetaches org.ankh.etat \
             org.ankh.notifications org.ankh.separateur org.ankh.horloge \
             org.ankh.bureau; do
    [[ "${applets}" == *"${parti}"* ]] \
        && grief "${parti} est de retour dans la barre alors que DE-015 l'a retiré"
done

# LA régression que DE-015 corrige, et le contrôle qui l'empêche de revenir.
# Jusqu'au 2026-11-07 la disposition MASQUAIT les cinq applets natives de la
# zone système pour faire place à org.ankh.etat : plus de volume, plus de
# Wi-Fi, plus de Bluetooth, plus de luminosité. Seule la cloche peut être
# masquée, parce qu'elle est ajoutée à part, à droite de l'horloge.
# Lu dans tout le fichier, et non à un index d'applet : le numéro que
# plasmashell donne à la zone système n'est pas prévisible, et un index
# codé en dur aurait rendu « aucune » pour la mauvaise raison — un contrôle
# qui passe parce qu'il regarde ailleurs.
masquees="$(ssh_vm "grep -h '^hiddenItems=' /home/ankh/.config/plasma-org.kde.plasma.desktop-appletsrc 2>/dev/null | sed 's/^hiddenItems=//' | paste -sd, -" 2>/dev/null || true)"
echo "   zone système, icônes masquées : « ${masquees:-aucune} »"
for vital in networkmanagement bluetooth volume brightness; do
    [[ "${masquees}" == *"${vital}"* ]] \
        && grief "la zone système masque org.kde.plasma.${vital} : Ankh DE retire un réglage que Plasma nu offrait"
done

# Le sélecteur Alt+Tab : celui de KWin (DE-015). Ce qu'on établit, c'est que
# kwinrc demande « thumbnail_grid » ET que nous n'installons PAS un paquet de
# ce nom — sans quoi kwinrc en désignerait un et KWin en chargerait un autre.
selecteur_voulu="$(dans_session 'kreadconfig6 --file kwinrc --group TabBox --key LayoutName' || true)"
notre_paquet=non
ssh_vm "test -e /usr/local/share/kwin/tabbox/${selecteur_voulu}" 2>/dev/null && notre_paquet=oui
echo "   Alt+Tab : kwinrc demande « ${selecteur_voulu:-rien} », paquet à nous sous ce nom : ${notre_paquet}"
[[ "${selecteur_voulu}" == thumbnail_grid ]] \
    || grief "kwinrc ne demande pas le sélecteur natif de KWin mais « ${selecteur_voulu:-rien} »"
[[ "${notre_paquet}" == non ]] \
    || grief "nous installons un sélecteur nommé « ${selecteur_voulu} » : il masquerait celui de KWin"

fond_present=non
ssh_vm 'test -s /usr/local/share/wallpapers/Ankh-Prismes/contents/images_dark/3840x2160.png' \
    2>/dev/null && fond_present=oui
fond_pose="$(dans_session 'kreadconfig6 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group Wallpaper --group org.kde.image --group General --key Image' || true)"
echo "   fond d'écran : paquet ${fond_present}, posé « ${fond_pose:-?} »"
[[ "${fond_present}" == oui ]] || grief "le fond d'écran Ankh-Prismes n'est pas installé"

# Plus de module QML partagé : « ankh-de/qml » n'existait que pour les
# applets repris de Tidewater (DE-015). Ce qu'on vérifie désormais, c'est
# qu'il ne traîne PAS — un reste de third_party/sortie réinstallerait des
# pièces que la barre ne demande plus.
module_reste=non
ssh_vm 'test -e /usr/local/share/ankh-de/qml' 2>/dev/null && module_reste=oui
echo "   reste du module QML partagé : ${module_reste}"
[[ "${module_reste}" == non ]] \
    || grief "/usr/local/share/ankh-de/qml existe encore alors que DE-015 l'a retiré"

# Ce que la SESSION elle-même a constaté de ses pièces, au démarrage
# (ANKH-PIECE, src/session/ankh-de-session.in). C'est le contrôle qui vaut
# pour tous les modes d'installation — y compris le RPM seul, qui ne porte
# pas les pièces fabriquées par preparer.sh.
# Trois endroits, parce que la destination dépend du gestionnaire de
# connexion : le journal utilisateur, le journal du système (systemd-cat y
# écrit sous l'étiquette « ankh-de »), et le journal de session que SDDM
# tient à part — c'est là que partait tout, le 2026-11-07, et le harnais
# n'y regardait pas.
pieces="$(ssh_vm "{ journalctl --user --no-pager -b 2>/dev/null
                    sudo journalctl --no-pager -b -t ankh-de 2>/dev/null
                    cat ~/.local/share/sddm/wayland-session.log 2>/dev/null
                    sudo cat /var/log/sddm.log 2>/dev/null
                  } | grep -o 'ANKH-PIECE.*' | sort -u" || true)"
if [[ -n "${pieces}" ]]; then
    printf '%s\n' "${pieces}" | sed 's/^/   /'
    absentes="$(grep -c 'ABSENTE' <<< "${pieces}" || true)"
    absentes="${absentes:-0}"
    (( absentes == 0 )) \
        || grief "${absentes} pièce(s) désignée(s) par le thème sont absentes : Plasma retombe sur les siennes"
else
    grief "la session n'a rien dit de ses pièces : le contrôle ANKH-PIECE n'a pas tourné"
fi

# Ouvrir le menu par le chemin que Plasma emploie lui-même pour la touche
# Meta. S'il s'ouvre, l'applet se charge et répond.
#
# Une image AVANT, prise juste maintenant, pour que la comparaison ne porte
# que sur l'ouverture. (La capture de l'étape 9 est trop vieille : l'horloge
# a pu changer entre-temps.)
printf '{ "execute": "qmp_capabilities" }\n{ "execute": "screendump", "arguments": { "filename": "%s" } }\n' \
    "${travail}/avant-menu.ppm" | timeout 30 socat - UNIX-CONNECT:"${travail}/qmp.sock" > /dev/null 2>&1 || true

dans_session "${QDBUS} org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu" \
    > /dev/null 2>&1 && echo "   demande d'ouverture envoyée" \
    || grief "activateLauncherMenu a échoué : la demande d'ouverture n'est même pas partie"
sleep 3

printf '{ "execute": "qmp_capabilities" }\n{ "execute": "screendump", "arguments": { "filename": "%s" } }\n' \
    "${travail}/demarrer.ppm" | timeout 30 socat - UNIX-CONNECT:"${travail}/qmp.sock" > /dev/null 2>&1 || true

# Ce que l'ÉCRAN dit, indépendamment de toute requête à Plasma.
#
# Le 2026-11-06, « vm-demarrer-ouvert.png » s'écrivait quoi qu'il arrive :
# les trois captures du passage étaient octet pour octet identiques, et un
# fichier nommé « menu ouvert » montrait un bureau vide. Un nom de fichier
# ne prouve rien. On mesure donc l'ampleur du changement — mesuré ici :
# 0,02 % de l'écran pour une minute d'horloge, 24 % pour un menu. Le seuil
# de 2 % laisse trois ordres de grandeur de marge.
ecran_change="INCONNU"
mesure_menu="?"
if [[ -s "${travail}/demarrer.ppm" && -s "${travail}/avant-menu.ppm" ]]; then
    mesure_menu="$(python3 -I "${racine}/bench/vm/comparer.py" \
        "${travail}/avant-menu.ppm" "${travail}/demarrer.ppm" 2>&1 || echo '')"
    part="$(awk '{print $6+0}' <<< "${mesure_menu}" 2>/dev/null || echo 0)"
    if [[ -n "${mesure_menu}" ]] && awk "BEGIN{exit !(${part:-0} >= 2)}"; then
        ecran_change=oui
    elif [[ -n "${mesure_menu}" ]]; then
        ecran_change=non
    fi
    echo "   changement à l'écran (pixels x y l h part%) : ${mesure_menu}"
    echo "   quelque chose s'est ouvert : ${ecran_change}"

    # Le nom du fichier dit ce que le fichier MONTRE.
    case "${ecran_change}" in
        oui) nom=vm-demarrer-ouvert.png ;;
        non) nom=vm-demarrer-rien-ne-sest-ouvert.png ;;
        *)   nom=vm-demarrer-indetermine.png ;;
    esac
    python3 -I -c "
from PIL import Image
import sys
Image.open(sys.argv[1]).save(sys.argv[2])" "${travail}/demarrer.ppm" "${sortie}/${nom}" 2>/dev/null \
        && echo "   ${nom} écrit"
else
    grief "pas de capture avant/après : l'ouverture du menu n'est pas observable"
fi
case "${ecran_change}" in
    oui) ;;
    non) grief "rien ne s'est ouvert à l'écran après activateLauncherMenu (${mesure_menu})" ;;
    *)   grief "impossible de savoir si le menu s'est ouvert (${mesure_menu})" ;;
esac

# Ce que cette étape prouve, et ce qu'elle ne prouve pas.
#
# Elle prouve : notre applet est dans la barre (demandé à plasmashell), la
# demande d'ouverture part, et l'écran change beaucoup. La boîte englobante
# dit OÙ : le menu de Windows 11 est centré, Kickoff est collé au bord
# gauche — les deux ne se confondent pas à l'œil sur la capture.
#
# Elle ne prouve PAS, à elle seule, que la fenêtre ouverte est la nôtre
# plutôt que Kickoff : activateLauncherMenu choisit le lanceur de la barre,
# et si les deux y étaient, rien ici ne les distinguerait. C'est la
# vérification d'applet ci-dessus qui porte ce point — et c'est pour cela
# qu'elle est bloquante.

# Un menu qui s'ouvre mais dont le QML crache des erreurs n'est pas un
# succès : on regarde ce que plasmashell a dit de NOS pièces.
#
# Le filtre ne vise plus « ankh|qml » : le 2026-11-06, il attrapait
# « plasma-welcome : module org.kde.plasma.networkmanagement is not
# installed » — une pièce de Fedora, étrangère à nous — et le rapport
# écrivait « erreurs QML signalées : oui ». On ne cherche donc que ce qui
# nomme org.ankh, et on rapporte le bruit étranger à part, sans le compter.
erreurs="$(ssh_vm "journalctl --user --no-pager -b 2>/dev/null | grep -i 'org\.ankh' | grep -iE 'error|warning|cannot|undefined|not installed' | head -8" || true)"
if [[ -n "${erreurs}" ]]; then
    echo "   plasmashell signale sur NOS pièces :" ; printf '%s\n' "${erreurs}" | sed 's/^/     /'
else
    echo "   plasmashell ne signale aucune erreur sur nos pièces"
fi
autres="$(ssh_vm "journalctl --user --no-pager -b 2>/dev/null | grep -i 'qml' | grep -iv 'org\.ankh' | grep -iE 'error|not installed' | head -4" || true)"
if [[ -n "${autres}" ]]; then
    echo "   (bruit QML étranger à Ankh, non compté :)"
    printf '%s\n' "${autres}" | sed 's/^/     /'
fi
{
    echo
    echo "### Menu Démarrer"
    echo
    echo "- script de disposition évalué : \`${script_evalue:-inconnu}\`"
    echo "- applets de la barre : \`${applets:-inconnus}\`"
    echo "- notre applet est dans la barre : ${demarrer_present}"
    echo "- l'écran a changé à l'ouverture : ${ecran_change} (\`${mesure_menu}\`)"
    echo "- pièces des lots 4 et 6 : ${nouvelles[*]}"
    echo "- Alt+Tab : kwinrc demande \`${selecteur_voulu:-rien}\`, paquet présent : ${selecteur_present}"
    echo "- module QML partagé : ${module_present}"
    echo "- fond d'écran : paquet ${fond_present}, posé \`${fond_pose:-?}\`"
    echo "- pièces désignées absentes : ${absentes:-inconnu}"
    echo "- erreurs sur nos pièces : $([[ -n "${erreurs}" ]] && echo oui || echo aucune)"
} >> "${sortie}/vm-rapport.md"

etape "11. Mesurer la barre des tâches (lot 4)"
# Cinq mesures viennent de la configuration, quatre de l'image. Les
# premières d'abord : elles disent ce que Plasma a RETENU, l'image dira ce
# qu'il a dessiné.
lire_panneau() { # $1 : expression JavaScript sur le premier panneau
    plasma_script "var p=panels()[0]; print($1)" || true
}
barre_hauteur="$(lire_panneau 'p.height')"
barre_position="$(lire_panneau 'p.location')"
barre_flottante="$(lire_panneau 'p.floating')"
# Six propriétés de plus, que « shell/scripting/panel.h » expose et que nous
# ne demandions pas. Les trois premières disent ce qui fait une barre de
# Windows 11 : centrée, pleine largeur, jamais masquée. Elles viennent de la
# CONFIGURATION, donc elles sont exactes — contrairement à une mesure sur
# l'image, qui dépend de ce que le compositeur a eu le temps de dessiner.
barre_alignement="$(lire_panneau 'p.alignment')"
barre_mode_longueur="$(lire_panneau 'p.lengthMode')"
barre_masquage="$(lire_panneau 'p.hiding')"
barre_decalage="$(lire_panneau 'p.offset')"
barre_opacite="$(lire_panneau 'p.opacity')"
barre_longueur="$(lire_panneau 'p.length')"
echo "   hauteur=${barre_hauteur} position=${barre_position} flottante=${barre_flottante}"
echo "   alignement=${barre_alignement:-?} longueur=${barre_mode_longueur:-?}/${barre_longueur:-?} masquage=${barre_masquage:-?} décalage=${barre_decalage:-?} opacité=${barre_opacite:-?}"

horloge_date="$(plasma_script 'var p=panels()[0]; p.widgetIds.forEach(function(i){var w=p.widgetById(i); if (w.type.indexOf("horloge")>=0 || w.type.indexOf("digitalclock")>=0) { w.currentConfigGroup=["Appearance"]; print(w.readConfig("dateDisplayFormat")); }})' || true)"
notif_position="$(dans_session 'kreadconfig6 --file plasmanotifyrc --group Notifications --key PopupPosition' || true)"
echo "   horloge=${horloge_date:-?} notifications=${notif_position:-?}"

# Fond uni avant de mesurer l'image : la barre est en verre, et un papier
# peint coloré se lirait à travers elle.
#
# BLANC, et non noir. Le 2026-11-07, ce fond était noir et la barre est
# translucide sombre : les deux se confondaient, et le relevé rendait
# « marge_bas=800, hauteur_visible=0 » — l'écran entier pris pour du vide.
# Une barre en verre ne se mesure que sur un fond qui tranche avec elle.
plasma_script 'desktopsForActivity(currentActivity()).forEach(function(d){ d.wallpaperPlugin="org.kde.color"; d.currentConfigGroup=["Wallpaper","org.kde.color","General"]; d.writeConfig("Color","255,255,255"); })' > /dev/null || true

# Le menu Démarrer est resté ouvert depuis l'étape 10 : il couvre une partie
# du bas de l'écran. On le referme avant de mesurer.
dans_session "${QDBUS} org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu" \
    > /dev/null 2>&1 || true
sleep 2

# La barre OPAQUE, le temps de la mesure — et c'est la correction qui compte.
#
# Capture du 2026-11-07 à l'appui : la barre est bien dessinée, mais son fond
# est en verre. Sur un papier peint blanc elle devient blanche, et il ne
# reste que les icônes. À l'abscisse 200 il n'y a donc rien à voir, et deux
# passages ont conclu « colonne uniforme » — l'instrument avait raison, c'est
# le protocole qui était faux.
#
# On mesure la GÉOMÉTRIE, pas la matière : rendue opaque, la barre tranche
# sur le fond et sa hauteur se lit. L'opacité réelle, elle, a déjà été
# relevée plus haut dans la configuration (« barre.opacite »), là où elle est
# exacte.
plasma_script 'panels().forEach(function(p){ p.opacity="opaque" })' > /dev/null || true

# On ne photographie plus à l'aveugle après trois secondes. Changer le papier
# peint fait recharger le conteneur, et la barre disparaît un instant : le
# 2026-11-06 sur fond noir puis le 2026-11-07 sur fond blanc, le cliché a été
# pris pendant ce trou et le relevé annonçait « 800 / 0 » — l'écran entier
# pris pour du vide, deux fois de suite, sur deux fonds opposés.
#
# On reprend donc le cliché jusqu'à ce que la barre y SOIT, et on dit au bout
# de combien de temps. Si elle n'y est jamais, c'est un grief : soit la barre
# ne se redessine pas, soit l'instrument est aveugle, et les deux méritent
# qu'on le sache.
mesure_barre="? ? ?"
attente_barre=0
for essai in $(seq 12); do          # 12 × 3 s = 36 secondes
    sleep 3
    attente_barre=$((essai * 3))
    printf '{ "execute": "qmp_capabilities" }\n{ "execute": "screendump", "arguments": { "filename": "%s" } }\n' \
        "${travail}/barre.ppm" | timeout 30 socat - UNIX-CONNECT:"${travail}/qmp.sock" > /dev/null 2>&1 || true
    [[ -s "${travail}/barre.ppm" ]] || continue
    mesure_barre="$(python3 -I "${racine}/bench/mesurer.py" barre "${travail}/barre.ppm" 200 2>/dev/null || echo '? ? ?')"
    [[ "${mesure_barre}" == "? ? ?" ]] || break
done

if [[ -s "${travail}/barre.ppm" ]]; then
    if [[ "${mesure_barre}" == "? ? ?" ]]; then
        grief "la barre est introuvable sur l'image après ${attente_barre} s : la colonne est uniforme"
    fi
    echo "   sur l'image après ${attente_barre} s (espace sous, hauteur, couleur) : ${mesure_barre}"
    # « vm-barre.png » portait un nom de recadrage et montrait tout l'écran :
    # elle faisait exactement les mêmes octets que vm-bureau.png. On recadre
    # vraiment sur le bas de l'écran, pour que l'image montre ce que son nom
    # annonce — et à l'échelle 3, car une barre de 48 px ne se lit pas.
    python3 -I -c "
from PIL import Image
import sys
im = Image.open(sys.argv[1]).convert('RGB')
l, h = im.size
bande = im.crop((0, max(0, h - 120), l, h))
bande.resize((bande.width * 3, bande.height * 3), Image.NEAREST).save(sys.argv[2])
print('   vm-barre.png : les %d px du bas, à l\'échelle 3' % bande.height)
" "${travail}/barre.ppm" "${sortie}/vm-barre.png" 2>/dev/null || true
fi

# La barre retrouve son verre : le passage ne doit pas laisser la session
# dans un état qu'il a lui-même fabriqué pour mesurer.
plasma_script 'panels().forEach(function(p){ p.opacity="translucent" })' > /dev/null || true

python3 -I - "${sortie}/mesures-barre.json" "${barre_hauteur}" "${barre_position}" \
    "${barre_flottante}" "${horloge_date}" "${notif_position}" "${mesure_barre}" \
    "${barre_alignement}" "${barre_mode_longueur}" "${barre_masquage}" \
    "${barre_decalage}" "${barre_opacite}" "${barre_longueur}" << 'PYEOF'
import json, sys
(sortie, hauteur, position, flottante, horloge, notif, image,
 alignement, mode_longueur, masquage, decalage, opacite, longueur) = sys.argv[1:14]
m = {}
def entier(v):
    try:
        return int(float(v))
    except (TypeError, ValueError):
        return None
if entier(hauteur) is not None:
    m["barre.hauteur"] = entier(hauteur)
if position:
    m["barre.position"] = position.strip()
if flottante:
    m["barre.flottante"] = "oui" if flottante.strip().lower() in ("true", "1") else "non"
if entier(horloge) is not None:
    m["barre.horloge.date"] = entier(horloge)
if notif:
    m["notifications.position"] = notif.strip()
for cle, valeur in (("barre.alignement", alignement), ("barre.mode_longueur", mode_longueur),
                    ("barre.masquage", masquage), ("barre.opacite", opacite)):
    if valeur.strip():
        m[cle] = valeur.strip()
for cle, valeur in (("barre.decalage", decalage), ("barre.longueur", longueur)):
    if entier(valeur) is not None:
        m[cle] = entier(valeur)
parts = image.split()
if len(parts) == 3 and parts[0] != "?":
    m["barre.marge_bas"] = entier(parts[0])
    m["barre.hauteur_visible"] = entier(parts[1])
    m["couleur.barre"] = parts[2]
json.dump({k: v for k, v in m.items() if v is not None}, open(sortie, "w"),
          indent=2, ensure_ascii=False)
print(f"   {sortie} : {len(m)} mesure(s)")
PYEOF


# =========================================================================
# ÉTAPE 12 — LES INTERACTIONS
# =========================================================================
#
# Jusqu'au 2026-11-07, ce harnais savait répondre à « la pièce est-elle
# là ? » et « l'écran a-t-il changé ? ». Il ne savait pas poser la seule
# question qui compte pour un bureau : « est-ce que ça RÉPOND ? »
#
# Douze responsabilités étaient chargées, zéro interaction essayée
# (docs/ANTI_DOUBLONS.md). C'était le plus grand écart entre ce que le dépôt
# montrait et ce qu'il prouvait.
#
# Comment on clique, et pourquoi ainsi
# ------------------------------------
# Par QEMU, pas par l'invité. « input-send-event » injecte les événements au
# niveau du matériel virtuel : rien à installer dans la VM, rien qui dépende
# de Wayland, et aucun outil (ydotool, wtype, xdotool) dont l'absence
# ferait passer un test pour un échec du bureau. La VM a déjà
# « -device virtio-tablet », donc le pointeur ABSOLU fonctionne : on vise un
# pixel, pas un déplacement relatif.
#
# L'échelle de QEMU pour un axe absolu va de 0 à 32767 sur toute la largeur.

# La taille de l'écran est LUE, pas supposée : un nombre en dur ici
# enverrait tous les clics à côté le jour où la VM change de résolution, et
# les essais échoueraient en accusant le bureau.
ECRAN_L=1280
ECRAN_H=800

qmp() { # $@ : une ou plusieurs commandes QMP, en JSON, dans l'ordre
    {
        printf '{ "execute": "qmp_capabilities" }\n'
        printf '%s\n' "$@"
    } | timeout 30 socat - UNIX-CONNECT:"${travail}/qmp.sock" > /dev/null 2>&1
}

evenement() { # $1 : le tableau d'événements, en JSON
    qmp "{\"execute\":\"input-send-event\",\"arguments\":{\"events\":[$1]}}"
}

pointer() { # $1 : x, $2 : y, en pixels écran
    local ax=$(( $1 * 32767 / (ECRAN_L - 1) ))
    local ay=$(( $2 * 32767 / (ECRAN_H - 1) ))
    evenement "{\"type\":\"abs\",\"data\":{\"axis\":\"x\",\"value\":${ax}}},
               {\"type\":\"abs\",\"data\":{\"axis\":\"y\",\"value\":${ay}}}"
}

cliquer() { # $1 : x, $2 : y
    pointer "$1" "$2"
    sleep 0.3
    evenement "{\"type\":\"btn\",\"data\":{\"down\":true,\"button\":\"left\"}}"
    sleep 0.1
    evenement "{\"type\":\"btn\",\"data\":{\"down\":false,\"button\":\"left\"}}"
}

touche() { # $1 : un qcode QEMU — esc, ret, tab, spc, a…z, 0…9
    evenement "{\"type\":\"key\",\"data\":{\"down\":true,\"key\":{\"type\":\"qcode\",\"data\":\"$1\"}}}"
    sleep 0.05
    evenement "{\"type\":\"key\",\"data\":{\"down\":false,\"key\":{\"type\":\"qcode\",\"data\":\"$1\"}}}"
}

taper() { # $1 : du texte en minuscules et chiffres
    local i c
    for (( i = 0; i < ${#1}; i++ )); do
        c="${1:i:1}"
        case "${c}" in
            " ") touche spc ;;
            [a-z0-9]) touche "${c}" ;;
            *) echo "   (caractère « ${c} » ignoré : pas de qcode)" >&2 ;;
        esac
        sleep 0.08
    done
}

# Alt+Tab en deux temps, et c'est obligatoire : le sélecteur de KWin ne
# s'affiche QUE tant qu'Alt est maintenu. Un « appui-relâche » atomique
# le ferait apparaître et disparaître entre deux clichés, et on conclurait
# qu'il ne marche pas.
alt_tab_ouvrir() {
    evenement "{\"type\":\"key\",\"data\":{\"down\":true,\"key\":{\"type\":\"qcode\",\"data\":\"alt_l\"}}}"
    sleep 0.2
    touche tab
}
alt_tab_fermer() {
    evenement "{\"type\":\"key\",\"data\":{\"down\":false,\"key\":{\"type\":\"qcode\",\"data\":\"alt_l\"}}}"
}

deux_echap() {
    touche esc
    sleep 1.2
    touche esc
}

cliche() { # $1 : nom du fichier .ppm dans le dossier de travail
    qmp "{\"execute\":\"screendump\",\"arguments\":{\"filename\":\"${travail}/$1\"}}"
}

# Combien l'écran a-t-il changé entre deux clichés ? Rend la part en %.
# C'est la même mesure que pour l'ouverture du menu, et le même seuil : une
# minute d'horloge change 0,02 % de l'écran, un panneau qui s'ouvre en
# change plusieurs pour cent.
change() { # $1 : avant.ppm, $2 : après.ppm
    [[ -s "${travail}/$1" && -s "${travail}/$2" ]] || { echo "0"; return; }
    python3 -I "${racine}/bench/vm/comparer.py" "${travail}/$1" "${travail}/$2" 2>/dev/null \
        | awk '{print ($6 == "" ? 0 : $6)}'
}

# Un essai d'interaction : on photographie, on agit, on rephotographie, et
# on compare. « attendu » dit si l'écran DOIT changer ou non — refermer un
# panneau est aussi une réponse, et un panneau qui ne se referme pas est un
# défaut qu'on ne verrait pas en ne cherchant que des changements.
essai_interaction() { # $1 : nom court (sert au fichier), $2 : libellé,
                      # $3 : oui|non (l'écran doit-il changer), $4 : seuil %,
                      # $5… : la commande à exécuter
    local nom="$1" libelle="$2" attendu="$3" seuil="$4"
    shift 4
    cliche "av.ppm"
    "$@"
    sleep 2.5
    cliche "ap.ppm"
    local part obtenu
    part="$(change av.ppm ap.ppm)"
    if awk "BEGIN{exit !(${part:-0} >= ${seuil})}"; then obtenu=oui; else obtenu=non; fi
    if [[ "${obtenu}" == "${attendu}" ]]; then
        printf '   ok    %-46s %s %% de l écran\n' "${libelle}" "${part}"
        interactions_ok=$((interactions_ok + 1))
    else
        grief "${libelle} : l'écran a changé de ${part} %, on attendait « ${attendu} »"
    fi
    # La capture d'après est la preuve, et son nom dit ce qu'elle montre.
    python3 -I -c "
from PIL import Image
import sys
Image.open(sys.argv[1]).save(sys.argv[2])" "${travail}/ap.ppm" "${sortie}/vm-i-${nom}.png" 2>/dev/null || true
}

# Un essai qui se juge sur un FAIT du système, et non sur des pixels.
#
# Le changement d'écran est une bonne sonde pour « quelque chose s'est
# ouvert », et une mauvaise pour « l'application tourne » : beaucoup de
# choses changent l'écran, et une fenêtre peut tarder à être dessinée alors
# que le processus est déjà là. Quand une question a une réponse franche
# dans l'invité, on la pose à l'invité.
essai_fait() { # $1 : nom court, $2 : libellé, $3 : commande de verdict
               # lancée dans l'invité, $4… : l'action à exécuter
    local nom="$1" libelle="$2" verdict_cmd="$3"
    shift 3
    "$@"
    local atteint=0 i
    for (( i = 0; i < 20; i++ )); do
        ssh_vm "${verdict_cmd}" > /dev/null 2>&1 && { atteint=1; break; }
        sleep 1
    done
    cliche "ap.ppm"
    if (( atteint == 1 )); then
        printf '   ok    %-46s %s\n' "${libelle}" "constaté"
        interactions_ok=$((interactions_ok + 1))
    else
        grief "${libelle} : « ${verdict_cmd} » n'a jamais répondu vrai en 20 s"
    fi
    python3 -I -c "
from PIL import Image
import sys
Image.open(sys.argv[1]).save(sys.argv[2])" "${travail}/ap.ppm" "${sortie}/vm-i-${nom}.png" 2>/dev/null || true
}

etape "12. Les interactions — est-ce que ça RÉPOND ?"
interactions_ok=0

cliche "taille.ppm"
if [[ -s "${travail}/taille.ppm" ]]; then
    lue="$(python3 -I -c "
from PIL import Image
import sys
print('%d %d' % Image.open(sys.argv[1]).size)" "${travail}/taille.ppm" 2>/dev/null || true)"
    if [[ -n "${lue}" ]]; then
        ECRAN_L="${lue%% *}"
        ECRAN_H="${lue##* }"
    fi
fi
echo "   écran : ${ECRAN_L}x${ECRAN_H}"

# Où cliquer. On ne devine pas, on repère sur l'image.
#
# Plasma n'expose pas la géométrie d'un applet par son moteur de script :
# containment.h donne les identifiants, panel.h la taille du panneau, jamais
# la place d'un widget dedans. bench/vm/reperer.py lit donc la bande du bas
# et rend le centre de chaque amas de pixels.
#
# La barre est rendue OPAQUE pour ce repérage, pour la même raison qu'à
# l'étape 11 : en verre, sur le fond uni, elle se confond avec lui et le
# repérage ne trouve qu'un seul amas (essayé le 2026-11-07 : « 640 », soit
# l'écran entier pris pour un bloc). Opaque, il en trouve sept.
plasma_script 'panels().forEach(function(p){ p.opacity="opaque" })' > /dev/null || true
sleep 3
cliche "barre-reperes.ppm"
reperes="$(python3 -I "${racine}/bench/vm/reperer.py" "${travail}/barre-reperes.ppm" 48 2>/dev/null || true)"
plasma_script 'panels().forEach(function(p){ p.opacity="translucent" })' > /dev/null || true
sleep 2
if [[ -z "${reperes}" ]]; then
    grief "aucun applet repéré dans la barre : impossible de cliquer dessus"
else
    echo "   amas repérés dans la barre (x du centre) : ${reperes}"
fi

# --- 12.1 Le menu Démarrer ----------------------------------------------
# Trois questions, dans l'ordre : s'ouvre-t-il, accepte-t-il le clavier, se
# referme-t-il ? La troisième compte autant que les deux premières : un menu
# qui ne se ferme pas sur Échap piège l'utilisateur.
#
# L'ouverture passe par D-Bus, pas par un clic : c'est le chemin qu'emploie
# la touche Windows, et il ne dépend pas d'un repérage.
essai_interaction demarrer-ouvert "le menu Démarrer s'ouvre" oui 2 \
    dans_session "${QDBUS} org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu"

# Où est le champ de recherche ? On ne le code pas en dur : la boîte du
# changement, mesurée à l'ouverture, donne le cadre du menu, et le champ est
# à une place fixe dedans — en bas à gauche. Relevé sur la capture du
# 2026-11-07 : 39 % de la largeur, 85 % de la hauteur de la boîte.
boite="$(python3 -I "${racine}/bench/vm/comparer.py" "${travail}/av.ppm" "${travail}/ap.ppm" 2>/dev/null || true)"
champ_x=0; champ_y=0
if [[ -n "${boite}" ]]; then
    champ_x=$(awk '{printf "%d", $2 + 0.39 * $4}' <<< "${boite}")
    champ_y=$(awk '{printf "%d", $3 + 0.85 * $5}' <<< "${boite}")
    echo "   cadre du menu : ${boite} → champ de recherche vers ${champ_x},${champ_y}"
fi

# Premier essai : taper SANS cliquer. C'est le comportement de Windows 11 —
# touche Windows, puis on tape. Un échec ici n'est pas un échec du clavier,
# c'est un menu qui ne prend pas le focus, et les deux ne se corrigent pas
# au même endroit.
avant_saisie=${interactions_ok}
essai_interaction demarrer-saisie-directe \
    "le menu prend le clavier sans qu'on clique dedans" oui 0.15 \
    taper "konsole"

# Le DISCRIMINANT, et il ne se lance que si l'essai précédent a échoué.
#
# Son rôle est de départager « le menu ne prend pas le focus » de « mes
# touches n'arrivent pas du tout » : on clique dans le champ, puis on tape.
# Si le texte apparaît alors, les touches arrivaient bien et c'est le focus
# qui manquait.
#
# Le lancer quand la saisie directe a DÉJÀ marché n'a aucun sens, et il
# échouait pour cette raison le 2026-11-07 : cliquer dans un champ qui a
# déjà le focus et déjà du texte ne change rien à l'écran, et l'essai
# réclamait un changement. Un contrôle qui exige l'impossible est un faux
# échec, et un faux échec coûte autant qu'un défaut manqué.
if (( champ_x > 0 )) && (( avant_saisie == interactions_ok )); then
    echo "   la saisie directe a échoué : on départage par un clic dans le champ"
    essai_interaction demarrer-saisie-apres-clic \
        "le champ répond après un clic dedans" oui 0.15 \
        cliquer "${champ_x}" "${champ_y}"
    essai_interaction demarrer-saisie-clavier \
        "la saisie s'affiche une fois le champ cliqué" oui 0.1 \
        taper "konsole"
else
    echo "   saisie directe réussie : le discriminant par clic est inutile, il est sauté"
fi

# Échap. Dans Windows 11, un premier Échap vide la recherche et un second
# ferme le menu : on en envoie donc deux, et on juge sur le résultat.
essai_interaction demarrer-ferme "le menu se referme sur Échap" oui 2 \
    deux_echap

# --- 12.1bis Démarrer lance VRAIMENT une application --------------------
#
# C'est LE test qui décide si org.ankh.demarrer méritait d'être gardé quand
# tous les autres applets repris ont été remplacés par ceux de Plasma
# (DE-015). On avait prouvé qu'il s'ouvre, qu'il prend le clavier et qu'il
# cherche. Chercher sans pouvoir lancer, c'est une vitrine.
#
# Le verdict est rendu par pgrep, pas par un pourcentage de pixels : la
# question « est-ce que l'application tourne » a une réponse franche.
#
# Échap vient de fermer le menu, donc on le rouvre. Et on vérifie d'abord
# qu'aucun konsole ne tourne déjà : sinon le pgrep d'après répondrait vrai
# sans que Démarrer y soit pour quoi que ce soit — un essai qui ne peut que
# réussir ne prouve rien.
konsole_avant=0
ssh_vm 'pgrep -u ankh -x konsole > /dev/null' 2>/dev/null && konsole_avant=1
if (( konsole_avant == 1 )); then
    grief "konsole tournait déjà avant l'essai : le lancement depuis Démarrer n'est pas testable"
else
    lancer_depuis_demarrer() {
        dans_session "${QDBUS} org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu" \
            > /dev/null 2>&1 || true
        sleep 2.5
        taper "konsole"
        # Le menu doit avoir le temps de filtrer avant qu'Entrée choisisse.
        sleep 2.5
        touche ret
    }
    essai_fait demarrer-lancement \
        "Entrée dans Démarrer lance l'application" \
        'pgrep -u ankh -x konsole > /dev/null' \
        lancer_depuis_demarrer
fi

# Konsole sert maintenant de SECONDE FENÊTRE au reste des essais. S'il n'a
# pas démarré par le menu, on le lance directement : l'essai d'Alt+Tab porte
# sur le sélecteur, pas sur le lanceur, et il ne doit pas hériter de l'échec
# du précédent. Le 2026-11-07, faute de cette séparation, Alt+Tab accusait
# le sélecteur pour une fenêtre qui n'existait pas.
if ! ssh_vm 'pgrep -u ankh -x konsole > /dev/null' 2>/dev/null; then
    echo "   konsole n'a pas été lancé par le menu : on le lance directement pour la suite"
    dans_session 'setsid konsole > /tmp/konsole.log 2>&1 &' > /dev/null 2>&1 || true
    sleep 8
fi

# --- 12.2 Les applets de droite -----------------------------------------
# On clique chaque amas de la moitié droite, un par un, avec Échap entre
# deux. On ne dit PAS lequel est lequel : le repérage donne une abscisse,
# pas un identifiant, et affirmer « c'est le volet d'état » serait inventer.
# Ce que cet essai établit, et c'est déjà beaucoup : la zone de droite
# répond au clic.
#
# Le dernier amas est écarté : « Afficher le bureau » occupe le coin, et le
# presser réduirait toutes les fenêtres au milieu des essais.
if [[ -n "${reperes}" ]]; then
    # shellcheck disable=SC2206
    amas=( ${reperes} )
    droite=()
    for x in "${amas[@]}"; do (( x > ECRAN_L / 2 + 100 )) && droite+=("${x}"); done
    if (( ${#droite[@]} >= 2 )); then
        for (( k = 0; k < ${#droite[@]} - 1; k++ )); do
            essai_interaction "applet-droite-${droite[k]}" \
                "un clic à x=${droite[k]} ouvre quelque chose" oui 0.5 \
                cliquer "${droite[k]}" $(( ECRAN_H - 24 ))
            touche esc
            sleep 1.5
        done
    else
        grief "moins de deux amas dans la moitié droite : les applets n'y sont pas repérables"
    fi
fi

# --- 12.3 Alt+Tab, et le sélecteur est celui de KWin --------------------
# Il faut deux fenêtres pour que le sélecteur ait quelque chose à montrer.
# konsole a été lancé plus haut — par le menu Démarrer si celui-ci marche,
# directement sinon — et c'est VÉRIFIÉ avant de juger le sélecteur.
#
# Le 2026-11-07, konsole n'était pas installé dans l'invité : « setsid
# konsole & » ne lançait rien, il n'y avait qu'une fenêtre, et l'essai
# concluait « Alt+Tab ne marche pas ». Il accusait le sélecteur pour un
# décor absent. Son absence est désormais constatée à l'étape 4, là où elle
# a une cause lisible — mais la leçon tient : on ne teste pas un sélecteur
# de fenêtres sans avoir prouvé qu'il y a des fenêtres à sélectionner.
fenetres=0
ssh_vm 'pgrep -u ankh -x konsole > /dev/null' 2>/dev/null && fenetres=1
echo "   seconde fenêtre (konsole) : $([[ ${fenetres} == 1 ]] && echo oui || echo NON)"
if (( fenetres == 0 )); then
    ssh_vm 'tail -5 /tmp/konsole.log 2>/dev/null' | sed 's/^/     /' || true
    grief "pas de seconde fenêtre : Alt+Tab n'a rien à montrer, et ce n'est pas le sélecteur qui est en cause"
else
    # Depuis DE-015 c'est « thumbnail_grid », livré par KWin. Un échec ici
    # ne met plus en cause une pièce à nous : il met en cause notre
    # configuration de KWin, ce qui est une tout autre réparation.
    essai_interaction alt-tab "Alt+Tab montre le sélecteur, Alt maintenu" oui 1 alt_tab_ouvrir
    essai_interaction alt-tab-ferme "le sélecteur disparaît au relâchement" oui 1 alt_tab_fermer

    # La barre des tâches répond-elle au clic ? C'est la demande « vérifie
    # les tâches, les fenêtres multiples et l'activation des applications ».
    #
    # org.kde.plasma.icontasks a « minimizeActiveTaskOnClick=true » par
    # défaut (applets/taskmanager/main.xml de plasma-desktop) : cliquer
    # l'entrée de la fenêtre active la minimise, la recliquer la rétablit —
    # exactement le geste de Windows 11. Deux clics, deux changements
    # d'écran.
    #
    # CE QUE CET ESSAI N'ÉTABLIT PAS, et il faut le dire : que la fenêtre
    # minimisée puis rétablie soit bien konsole. KWin n'expose pas la
    # fenêtre active sur D-Bus sans qu'un script lui soit chargé, et charger
    # un script pour l'observer est une machinerie que ce passage n'a pas.
    # Ce qui est établi : l'entrée de tâche sous le curseur répond, deux fois
    # de suite, dans les deux sens.
    if [[ -n "${reperes}" ]]; then
        # Les entrées de tâches sont groupées au centre, juste à droite de
        # Démarrer. On prend le deuxième amas de la moitié GAUCHE : le
        # premier est Démarrer.
        gauche=()
        for x in ${reperes}; do
            (( x < ECRAN_L / 2 )) && gauche+=("${x}")
        done
        if (( ${#gauche[@]} >= 2 )); then
            tache_x="${gauche[1]}"
            tache_y=$(( ECRAN_H - 24 ))
            echo "   entrée de tâche visée : x=${tache_x}"
            essai_interaction tache-minimise \
                "un clic sur l'entrée de tâche minimise la fenêtre" oui 1 \
                cliquer "${tache_x}" "${tache_y}"
            essai_interaction tache-restaure \
                "un second clic la rétablit" oui 1 \
                cliquer "${tache_x}" "${tache_y}"
        else
            echo "   (moins de deux amas à gauche : pas d'entrée de tâche à viser)"
        fi
    fi
fi

{
    echo
    echo "### Interactions"
    echo
    echo "- essais réussis : ${interactions_ok}"
    echo "- amas repérés dans la barre : \`${reperes:-aucun}\`"
    echo "- ce qui N'EST PAS établi : quel amas correspond à quel applet. Le repérage rend une"
    echo "  abscisse, pas un identifiant."
} >> "${sortie}/vm-rapport.md"

# Journaux, quoi qu'il arrive.
ssh_vm 'sudo journalctl --no-pager -b' > "${sortie}/vm-journal.log" 2>/dev/null || true
cp "${travail}/console.log" "${sortie}/vm-console.log" 2>/dev/null || true
echo
echo "Rapport : ${sortie}/vm-rapport.md"

# C'est ici, et nulle part ailleurs, que ce passage est déclaré réussi ou
# raté. Tout est rassemblé avant : les captures et les journaux d'un passage
# qui échoue sont les plus utiles de tous.
verdict

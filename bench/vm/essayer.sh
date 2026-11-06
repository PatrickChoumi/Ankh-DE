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
etape "1. Image Fedora Cloud"
# Le nom du fichier change à chaque compilation : on le demande à l'index
# publié par Fedora plutôt que de le deviner.
if [[ ! -f "${travail}/base.qcow2" ]]; then
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
    echo "   ${url}"
    curl -fL --retry 3 -o "${travail}/base.qcow2" "${url}"
fi
echo "   image : $(du -h "${travail}/base.qcow2" | cut -f1)"

rm -f "${travail}/disque.qcow2"
qemu-img create -f qcow2 -b "${travail}/base.qcow2" -F qcow2 "${travail}/disque.qcow2" 40G > /dev/null

# --- 2. cloud-init : un compte et une clé éphémère -----------------------
etape "2. Préparation du premier démarrage"
rm -f "${travail}/cle" "${travail}/cle.pub"
ssh-keygen -q -t ed25519 -N '' -f "${travail}/cle" -C ankh-de-essai
cat > "${travail}/user-data" << CLOUD
#cloud-config
users:
  - name: ankh
    groups: [wheel]
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
etape "4. Installation de Plasma"
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
    > /tmp/dnf.log 2>&1' || {
        echo "L'installation de Plasma a échoué :" >&2
        ssh_vm 'tail -30 /tmp/dnf.log' >&2 || true
        exit 1
    }
echo "   $(ssh_vm 'rpm -q --qf "%{NAME} %{VERSION}\n" plasma-workspace kwin kdecoration-devel | tr "\n" " "')"

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

# C'est SDDM qui remplit XDG_SESSION_DESKTOP, avec le NOM DU FICHIER de
# session choisi : s'il dit « ankh-de », notre session a bien été lancée,
# et non celle de Plasma.
preuve "session lancée par le gestionnaire" "ankh-de" "$(environ_de XDG_SESSION_DESKTOP)"
preuve "type de session"                    "wayland" "$(environ_de XDG_SESSION_TYPE)"
preuve "c'est notre lanceur"                "1"       "$(environ_de ANKH_DE_SESSION)"

# Le compositeur compose-t-il vraiment ? Une image uniforme — noire ou
# autre — veut dire qu'il n'a rien dessiné.
printf '{ "execute": "qmp_capabilities" }\n{ "execute": "screendump", "arguments": { "filename": "%s" } }\n' \
    "${travail}/preuve.ppm" | timeout 30 socat - UNIX-CONNECT:"${travail}/qmp.sock" > /dev/null 2>&1 || true
if [[ -s "${travail}/preuve.ppm" ]]; then
    variete="$(python3 -c "
from PIL import Image, ImageStat
import sys
im = Image.open(sys.argv[1]).convert('RGB')
s = ImageStat.Stat(im)
print(round(max(s.stddev), 1), len(im.convert('P', palette=Image.ADAPTIVE, colors=256).getcolors(1 << 20) or []))
" "${travail}/preuve.ppm" 2>/dev/null || echo "0 0")"
    ecart="${variete%% *}"; couleurs="${variete##* }"
    # Un bureau composé a de la variété : des dizaines de couleurs et un
    # écart-type franc. Un écran noir donne 0 et 1.
    if (( $(printf '%.0f' "${ecart}") > 5 )) && (( couleurs > 20 )); then
        printf '   ok    %-34s écart-type %s, %s couleurs\n' "le compositeur dessine" "${ecart}" "${couleurs}"
    else
        echo "   ECHEC l'écran est uniforme (écart-type ${ecart}, ${couleurs} couleurs) : rien n'est composé" >&2
        echec_session=oui
    fi
else
    echo "   ECHEC aucune capture : impossible de prouver que le compositeur dessine" >&2
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
    echo "- Plasma : $(ssh_vm 'rpm -q --qf "%{VERSION}" plasma-workspace')"
    echo "- c'est bien notre session : ANKH_DE_SESSION=$(ssh_vm "tr \"\\0\" \"\\n\" < /proc/\$(pgrep -u ankh -f plasmashell | head -1)/environ | sed -n 's/^ANKH_DE_SESSION=//p'")"
    echo "- XDG_CONFIG_DIRS : $(ssh_vm "tr \"\\0\" \"\\n\" < /proc/\$(pgrep -u ankh -f plasmashell | head -1)/environ | sed -n 's/^XDG_CONFIG_DIRS=//p'")"
    echo "- XDG_DATA_DIRS : $(ssh_vm "tr \"\\0\" \"\\n\" < /proc/\$(pgrep -u ankh -f plasmashell | head -1)/environ | sed -n 's/^XDG_DATA_DIRS=//p'")"
    echo "- style : $(dans_session 'kreadconfig6 --group KDE --key widgetStyle')"
    echo "- couleurs : $(dans_session 'kreadconfig6 --group General --key ColorScheme')"
    echo "- police : $(dans_session 'kreadconfig6 --group General --key font')"
    echo "- décoration : $(dans_session 'kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key library')"
    echo "- icônes : $(dans_session 'kreadconfig6 --group Icons --key Theme')"
    echo "- style Plasma : $(dans_session 'kreadconfig6 --file plasmarc --group Theme --key name')"
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

etape "8. Les 46 vérifications, dans la VM"
dans_session 'cd ~/ankh-de && ANKH_DE_CMAKE_EXTRA=-DANKH_DE_PLASMA_NON_TESTE=ON ./tests/session-et-theme.sh' \
    > "${sortie}/vm-tests.log" 2>&1 \
    && echo "   toutes passées" \
    || { echo "   ÉCHEC — voir vm-tests.log" >&2; tail -20 "${sortie}/vm-tests.log" >&2; }

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
applets="$(dans_session "qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
    'var n=[]; panels().forEach(function(p){p.widgetIds.forEach(function(i){n.push(p.widgetById(i).type)})}); print(n.join(\",\"))'" 2>/dev/null || true)"
echo "   applets de la barre : ${applets:-inconnus}"
# Ce que la disposition a dit en construisant la barre : c'est là qu'un
# repli silencieux se voit.
ssh_vm "journalctl --user --no-pager -b 2>/dev/null | grep -o 'ANKH-LAYOUT.*' | head -6" \
    | sed 's/^/   /' || true

demarrer_present=non
case "${applets}" in *org.ankh.demarrer*) demarrer_present=oui ;; esac
echo "   org.ankh.demarrer dans la barre : ${demarrer_present}"

# Ouvrir le menu par le chemin que Plasma emploie lui-même pour la touche
# Meta. S'il s'ouvre, l'applet se charge et répond.
dans_session 'qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.activateLauncherMenu' \
    > /dev/null 2>&1 && echo "   demande d'ouverture envoyée" \
    || echo "   activateLauncherMenu a échoué" >&2
sleep 3

printf '{ "execute": "qmp_capabilities" }\n{ "execute": "screendump", "arguments": { "filename": "%s" } }\n' \
    "${travail}/demarrer.ppm" | timeout 30 socat - UNIX-CONNECT:"${travail}/qmp.sock" > /dev/null 2>&1 || true
if [[ -s "${travail}/demarrer.ppm" ]]; then
    python3 -c "
from PIL import Image
import sys
Image.open(sys.argv[1]).save(sys.argv[2])" "${travail}/demarrer.ppm" "${sortie}/vm-demarrer-ouvert.png" 2>/dev/null \
        && echo "   vm-demarrer-ouvert.png écrit"
fi

# Un menu qui s'ouvre mais dont le QML crache des erreurs n'est pas un
# succès : on regarde ce que plasmashell a dit de notre applet.
erreurs="$(ssh_vm "journalctl --user --no-pager -b 2>/dev/null | grep -iE 'ankh|qml' | grep -iE 'error|warning|cannot|undefined' | head -8" || true)"
if [[ -n "${erreurs}" ]]; then
    echo "   plasmashell signale :" ; printf '%s\n' "${erreurs}" | sed 's/^/     /'
else
    echo "   plasmashell ne signale aucune erreur QML"
fi
{
    echo
    echo "### Menu Démarrer"
    echo
    echo "- applets de la barre : \`${applets:-inconnus}\`"
    echo "- notre applet est dans la barre : ${demarrer_present}"
    echo "- erreurs QML signalées : $([[ -n "${erreurs}" ]] && echo oui || echo aucune)"
} >> "${sortie}/vm-rapport.md"

etape "11. Mesurer la barre des tâches (lot 4)"
# Cinq mesures viennent de la configuration, quatre de l'image. Les
# premières d'abord : elles disent ce que Plasma a RETENU, l'image dira ce
# qu'il a dessiné.
lire_panneau() { # $1 : expression JavaScript sur le premier panneau
    dans_session "qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
        'var p=panels()[0]; print($1)'" 2>/dev/null | tr -d '\r' || true
}
barre_hauteur="$(lire_panneau 'p.height')"
barre_position="$(lire_panneau 'p.location')"
barre_flottante="$(lire_panneau 'p.floating')"
echo "   hauteur=${barre_hauteur} position=${barre_position} flottante=${barre_flottante}"

horloge_date="$(dans_session "qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
    'var p=panels()[0]; p.widgetIds.forEach(function(i){var w=p.widgetById(i);
     if (w.type.indexOf(\"horloge\")>=0 || w.type.indexOf(\"digitalclock\")>=0) {
       w.currentConfigGroup=[\"Appearance\"]; print(w.readConfig(\"dateDisplayFormat\")); }})'" \
    2>/dev/null | tr -d '\r' || true)"
notif_position="$(dans_session 'kreadconfig6 --file plasmanotifyrc --group Notifications --key PopupPosition' || true)"
echo "   horloge=${horloge_date:-?} notifications=${notif_position:-?}"

# Fond uni avant de mesurer l'image : la barre est en verre, et un papier
# peint coloré se lirait à travers elle.
dans_session "qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
    'desktopsForActivity(currentActivity()).forEach(function(d){
       d.wallpaperPlugin=\"org.kde.color\";
       d.currentConfigGroup=[\"Wallpaper\",\"org.kde.color\",\"General\"];
       d.writeConfig(\"Color\",\"0,0,0\"); })'" > /dev/null 2>&1 || true
sleep 3
printf '{ "execute": "qmp_capabilities" }\n{ "execute": "screendump", "arguments": { "filename": "%s" } }\n' \
    "${travail}/barre.ppm" | timeout 30 socat - UNIX-CONNECT:"${travail}/qmp.sock" > /dev/null 2>&1 || true

mesure_barre="?"
if [[ -s "${travail}/barre.ppm" ]]; then
    # mesurer.py rend « espace_sous hauteur couleur » à l'abscisse donnée.
    mesure_barre="$(python3 "${racine}/bench/mesurer.py" barre "${travail}/barre.ppm" 200 2>/dev/null || echo '? ? ?')"
    echo "   sur l'image (espace sous, hauteur, couleur) : ${mesure_barre}"
    python3 -c "
from PIL import Image
import sys
Image.open(sys.argv[1]).save(sys.argv[2])" "${travail}/barre.ppm" "${sortie}/vm-barre.png" 2>/dev/null || true
fi

python3 - "${sortie}/mesures-barre.json" "${barre_hauteur}" "${barre_position}" \
    "${barre_flottante}" "${horloge_date}" "${notif_position}" "${mesure_barre}" << 'PYEOF'
import json, sys
sortie, hauteur, position, flottante, horloge, notif, image = sys.argv[1:8]
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
parts = image.split()
if len(parts) == 3 and parts[0] != "?":
    m["barre.marge_bas"] = entier(parts[0])
    m["barre.hauteur_visible"] = entier(parts[1])
    m["couleur.barre"] = parts[2]
json.dump({k: v for k, v in m.items() if v is not None}, open(sortie, "w"),
          indent=2, ensure_ascii=False)
print(f"   {sortie} : {len(m)} mesure(s)")
PYEOF

# Journaux, quoi qu'il arrive.
ssh_vm 'sudo journalctl --no-pager -b' > "${sortie}/vm-journal.log" 2>/dev/null || true
cp "${travail}/console.log" "${sortie}/vm-console.log" 2>/dev/null || true
echo
echo "Rapport : ${sortie}/vm-rapport.md"

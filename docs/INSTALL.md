# INSTALL — installer, essayer, retirer

## Prérequis

| Quoi | Version |
|---|---|
| KDE Plasma | **6.8.x** — installé et la session ouverte en VM sur **6.8.2** (Fedora 44). Une autre version arrête la construction, sauf `-DANKH_DE_PLASMA_NON_TESTE=ON` ([DE-008](../DECISIONS.md), `src/decoration/VERSION-BREEZE`) |
| Session | **Wayland** (X11 non testé — Plasma 6.8 abandonne X11) |
| Qt | 6.6 ou plus (essayé sur 6.11.2) |
| KDE Frameworks | 6.0 ou plus (essayé sur 6.31.0) |

> Ce tableau annonçait « 6.7.x, 6.8 pas encore pris en charge » jusqu'au 2026-11-06, alors que
> la montée vers 6.8 était faite depuis le 2026-11-05 et que tous les passages en VM tournent
> sur 6.8.2. La source de la décoration reste Breeze **6.7.5**, qui compile tel quel contre
> 6.8 ; c'est la version de Breeze dérivée, pas la version de Plasma visée.

## Paquets à installer

L'installateur les nomme lui-même s'ils manquent. Pour anticiper :

**Fedora**
```bash
sudo dnf install cmake gcc-c++ extra-cmake-modules qt6-qtbase-devel \
  kf6-kconfig-devel kf6-kcoreaddons-devel kf6-kguiaddons-devel \
  kf6-kiconthemes-devel kf6-kwindowsystem-devel kf6-kcolorscheme-devel \
  kf6-frameworkintegration-devel kdecoration-devel \
  git fontmake librsvg2-tools xcursorgen sassc fontconfig
```

**Arch**
```bash
sudo pacman -S cmake gcc extra-cmake-modules qt6-base kconfig kcoreaddons \
  kguiaddons kiconthemes kwindowsystem kcolorscheme frameworkintegration \
  kdecoration git python-fontmake librsvg xorg-xcursorgen sassc fontconfig
```

**Ubuntu / Kubuntu**
```bash
sudo apt install cmake g++ extra-cmake-modules qt6-base-dev \
  libkf6config-dev libkf6coreaddons-dev libkf6guiaddons-dev \
  libkf6iconthemes-dev libkf6windowsystem-dev libkf6colorscheme-dev \
  libkf6style-dev libkdecorations3-dev \
  git fontmake librsvg2-bin x11-apps sassc fontconfig
```

## Installer

```bash
git clone https://github.com/PatrickChoumi/Ankh-DE
cd Ankh-DE
./installer.sh
```

Ce qu'il fait, dans l'ordre :

1. vérifie que Plasma 6 est là ;
2. `third_party/preparer.sh` fabrique la police Selawik, les curseurs et le thème GTK depuis
   leurs sources, à des commits figés et vérifiés ;
3. compile le style et la décoration (CMake) ;
4. installe dans `/usr/local` (`sudo` à cette étape seulement) ;
5. applique le thème global `org.ankh.de.desktop`.

### Vos barres ne sont pas touchées

Par défaut, `plasma-apply-lookandfeel` est appelé **sans** `--resetLayout` : votre barre, vos
applets et vos épingles restent. Pour avoir aussi la barre des tâches de Windows 11 — collée en
bas, 48 px, Démarrer et applications au centre, horloge sur deux lignes, « Afficher le bureau » à
droite :

```bash
./installer.sh --barre
```

L'installateur **avertit et demande confirmation** : cette option **efface vos barres actuelles**.

### Options

| Option | Effet |
|---|---|
| *(aucune)* | installation système dans `/usr/local`, par `sudo` |
| `--utilisateur` | installation dans `~/.local`, sans root. **Demande une reconnexion** avant que le style et la décoration soient chargés |
| `--barre` | remplace aussi vos barres par celle de Windows 11 (confirmation demandée) |
| `--sans-tiers` | n'installe ni la police, ni les curseurs, ni le thème GTK. Le DE marche, avec ceux de votre distribution |

### Pourquoi `--utilisateur` demande une reconnexion

Qt et KWin ne cherchent pas leurs greffons sous `~/.local`. L'installateur écrit donc
`~/.config/plasma-workspace/env/ankh-de.sh`, que Plasma lit au début de **chaque session**
(`startplasma.cpp` de plasma-workspace). Avant la reconnexion, les couleurs et les polices
s'appliquent, mais pas le style des contrôles ni la décoration des fenêtres.

## Essayer sans risque

`--utilisateur` n'écrit que dans votre dossier personnel. Et quel que soit le mode, revenir à
Breeze ne demande rien d'autre que :

```bash
plasma-apply-lookandfeel -a org.kde.breezedark.desktop
```

Le thème global est l'unique interrupteur
([DE-002](../DECISIONS.md#de-002--tous-les-réglages-vivent-dans-notre-thème-global-jamais-dans-etcxdg-ni-dans-les-thèmes-de-la-distribution)).

## Retirer

```bash
./desinstaller.sh            # réapplique Breeze, puis retire les fichiers
./desinstaller.sh --barre    # remet aussi les barres par défaut de Plasma
```

Il relit `build/install_manifest.txt`, écrit par CMake. Si ce fichier a disparu, il affiche la
liste des chemins à retirer à la main.

## Si quelque chose ne va pas

| Symptôme | Cause probable |
|---|---|
| Les fenêtres gardent l'allure de Breeze | la décoration n'est pas chargée. En mode `--utilisateur` : reconnectez-vous. Sinon, vérifiez `ldd` sur `org.ankh.decoration.so` |
| Les contrôles gardent l'allure de Breeze | le style n'est pas trouvé. Même cause |
| La police reste celle de la distribution | fontconfig n'a pas vu Selawik. Lancez `fc-cache -f`, puis `fc-match Selawik` : il doit répondre `Selawik`. C'est le défaut exact qui a fait échouer le premier passage du lot 1 dans Ankh |
| Le texte paraît trop fin ou coloré sur les bords | `29-ankh-rendu.conf` n'est pas lu. Vérifiez `fc-match -f '%{rgba} %{hintstyle}' Selawik` : attendu `5 1` |
| Les coins sont à 5 px, pas 8 | c'est Breeze qui dessine : la décoration d'Ankh n'est pas active |
| « Plasma non testé » à la construction | votre Plasma n'est pas 6.8.x. `-DANKH_DE_PLASMA_NON_TESTE=ON` passe outre, à vos risques ([DE-008](../DECISIONS.md)) |

Si le problème persiste, ouvrez une issue avec la sortie de :

```bash
plasmashell --version; kreadconfig6 --group KDE --key widgetStyle
kreadconfig6 --file kwinrc --group org.kde.kdecoration2 --key library
fc-match Selawik
```

# AUDIT — tout ce qui manque à Ankh DE

> Fait le 2026-11-05, à ma demande : « liste exhaustive de tout ce qui manque à Ankh DE pour
> être l'environnement de bureau que je veux, pour qu'il se rapproche de Windows 11 à la
> perfection », et « qu'Ankh DE soit téléchargeable et applicable sur n'importe quel OS Linux
> comme n'importe quel environnement de bureau ».
>
> **Méthode** : rien ici ne vient de la lecture des documents du projet. Chaque constat a été
> établi en exécutant quelque chose, dans un conteneur Fedora 44 (Qt 6.11.2, KF6 6.31.0,
> kdecoration 6.8.2) ou sur la CI. Quand un point n'a pas pu être établi, il est marqué
> `NON ÉTABLI` et dit pourquoi.

---

## 0. Ce qui est réellement acquis

Pour que la liste des manques soit lisible, voici d'abord le socle, tout entier vérifié :

| Acquis | Comment c'est établi |
|---|---|
| Le style et la décoration compilent sur Fedora 44, Arch et Ubuntu 26.04 | CI, trois jobs verts |
| Aucun symbole ni bibliothèque manquante | `ldd -r` sur les deux greffons, dans la CI |
| Le style tient 12 mesures de WinUI | `bench/captures.sh`, rejoué par la CI à chaque PR |
| Le paquet de thème global est **bien formé** et **vu par les outils de KDE** | `kpackagetool6 --global --list` le liste à côté de Breeze |
| **L'appliquer fonctionne** : style, couleurs, décoration et curseur sont écrits et relus | `plasma-apply-lookandfeel -a` puis `kreadconfig6` avec la couche `kdedefaults` active |
| `third_party/preparer.sh` fabrique police, curseurs et thème GTK | exécuté de bout en bout |
| Une VM accélérée est possible sur un runner GitHub | job `VM` : `/dev/kvm`, qemu 8.2.2, VM qui démarre |

---

## 1. Ce que j'ai affirmé à tort — à corriger en premier

### 1.1 Le thème global ignore onze de mes réglages `BLOQUANT`

**Ce que DE-002 affirme** : « son fichier `contents/defaults` porte la totalité des réglages ».
**C'est faux.** Vérifié le 2026-11-05 : après `plasma-apply-lookandfeel -a org.ankh.de.desktop`,
`kreadconfig6 --group General --key font` rend une **chaîne vide**.

L'outil ne recopie qu'un ensemble fixe de clés. Comparaison avec les paquets de référence —
ni `org.kde.breezedark.desktop` ni `org.fedoraproject.fedoradark.desktop` ne contiennent de
police : le mécanisme ne les prend pas.

| Clé de notre `defaults` | Appliquée ? |
|---|---|
| `[kdeglobals][General] ColorScheme` | **oui** |
| `[kdeglobals][KDE] widgetStyle` | **oui** |
| `[kdeglobals][Icons] Theme` | **oui** |
| `[kcminputrc][Mouse] cursorTheme` | **oui** |
| `[kwinrc][org.kde.kdecoration2] library`, `BorderSize` | **oui** |
| `[plasmarc][Theme] name`, `[ksplashrc][KSplash] Theme` | **oui** (écrites) |
| `font`, `menuFont`, `toolBarFont`, `smallestReadableFont`, `fixed` | **NON** |
| `[kdeglobals][WM] activeFont` | **NON** |
| `XftAntialias`, `XftHintStyle`, `XftSubPixel` | **NON** |
| `accentColorFromWallpaper` | **NON** |
| `[kdeglobals][KDE] AnimationDurationFactor` | **NON** |
| `[kwinrc][Effect-blur]`, `[kwinrc][TabBox]` | **NON** |

**Conséquence** : la police Selawik, les tailles de 14 et 12 px, le rendu en niveaux de gris,
les durées d'animation de Windows 11 et l'accent qui suit le fond d'écran — **tout le lot 1
hors couleurs et curseurs** — ne s'appliquent pas aujourd'hui sur une vraie session.

**La correction est la même que celle du point 2.1** : notre propre session, qui pose un
`XDG_CONFIG_DIRS` contenant nos valeurs par défaut. Elles passent alors **sous** les réglages
de l'utilisateur (qui gardent la priorité) et **au-dessus** de ceux de la distribution, sans
écraser aucun fichier. C'est le seul mécanisme qui respecte DE-002 tout en marchant.

### 1.2 Le thème global désigne quatre choses qui n'existent pas `BLOQUANT`

| Le thème demande | Ce qui existe | Effet |
|---|---|---|
| `[kdeglobals][Icons] Theme=Fluent-Ankh` | **rien** — `preparer.sh` fabrique les *curseurs* et le thème *GTK*, jamais le thème d'icônes | les icônes restent celles de la distribution |
| `[plasmarc][Theme] name=ankh` | `src/desktoptheme/` est **vide** | Plasma retombe sur son thème par défaut |
| `[kscreenlockerrc][Greeter] Theme=org.ankh.de.desktop` | pas de `contents/lockscreen/` | écran de verrouillage de Plasma |
| `[ksplashrc][KSplash] Theme=org.ankh.de.desktop` | pas de `contents/splash/` | écran de chargement de Plasma |

Le `CMakeLists.txt` installe `icones/Fluent-Ankh` « s'il existe » — il n'existe jamais. Un
`if(EXISTS)` qui ne se vérifie jamais est un mensonge silencieux : il doit devenir une erreur.

### 1.3 Le paquet n'a pas d'aperçu `MINEUR`

Breeze livre `contents/previews/preview.png` et `fullscreenpreview.jpg`. Sans eux, Ankh DE
apparaît sans vignette dans la page « Thème global » de la configuration du système : il a
l'air cassé avant même d'être essayé.

---

## 2. Ce qu'il manque pour être « un environnement de bureau, installable partout »

### 2.1 Ankh DE n'est pas une session `BLOQUANT`

**Aucun fichier `.desktop` de session n'existe dans le dépôt.** Ankh DE n'apparaît donc pas à
l'écran de connexion : ce n'est pas « un environnement de bureau qu'on choisit », c'est un
thème qu'on applique depuis l'intérieur de Plasma. C'est la différence exacte entre installer
KDE sur Ubuntu — et le voir proposé au login — et ce que nous avons aujourd'hui.

Il faut :
- `/usr/share/wayland-sessions/ankh-de.desktop` (et son équivalent X11 tant que la
  distribution le propose) ;
- un script de session `/usr/bin/ankh-de-session` qui pose `XDG_CONFIG_DIRS` sur nos valeurs
  par défaut (point 1.1) **puis** lance `startplasma-wayland`. Rien de plus : on ne remplace
  ni le compositeur ni le shell (DE-001) ;
- de quoi dire à l'utilisateur, au premier démarrage de cette session, que c'est bien Ankh DE.

C'est la pièce qui répond le plus directement à « applicable sur n'importe quel OS Linux comme
n'importe quel environnement de bureau ».

### 2.2 Rien n'est téléchargeable `BLOQUANT`

- **Aucune version publiée** : pas de tag, pas de Release GitHub, pas d'archive.
- **Aucun paquet construit** : `packaging/fedora/ankh-de.spec`, `packaging/arch/PKGBUILD` et
  `packaging/debian/` n'ont **jamais été construits ni testés**. Ce sont des squelettes.
- **Aucun dépôt** : pas de COPR (Fedora), pas d'AUR (Arch), pas de PPA (Ubuntu/Debian).
- Aujourd'hui, la seule voie est : cloner, installer une quinzaine de paquets de
  développement, compiler. Ce n'est pas « téléchargeable ».

### 2.3 Les pièces tierces ne peuvent pas être empaquetées telles quelles `MAJEUR`

`third_party/preparer.sh` **télécharge** Selawik, les curseurs et le thème GTK pendant la
construction. Les règles de Fedora, de Debian et d'Arch l'interdisent dans un paquet. Il faut
soit des sous-paquets avec les archives amont en `Source:`, soit renoncer à les empaqueter.
C'est la question ouverte 6 de la SPEC, toujours `À DÉCIDER`.

### 2.4 `installer.sh` n'a jamais été exécuté `MAJEUR`

Il compile, installe, et applique le thème. Aucune de ces étapes n'a tourné en vrai. Son mode
`--utilisateur` repose sur `~/.config/plasma-workspace/env/` — mécanisme réel, mais non vérifié
ici. `desinstaller.sh` non plus n'a jamais tourné : la règle « on n'installe pas une pièce
qu'on ne sait pas retirer » n'est donc pas démontrée.

### 2.5 La couverture des distributions est partielle `MAJEUR`

| Distribution | Compile | Plasma livré | Ankh DE y marche-t-il ? |
|---|---|---|---|
| Fedora 44 | **oui** (CI) | 6.8.2 | la version visée |
| Arch | **oui** (CI) | roulante | `NON ÉTABLI` — pas de session testée |
| Ubuntu 26.04 | **oui** (CI) | `NON ÉTABLI` | si < 6.8, le garde-fou refusera |
| Debian, openSUSE, Mint, Manjaro… | `NON ÉTABLI` | — | — |

Une version d'Ankh DE vise une version de Plasma (DE-008). Il faut **dire** publiquement
quelle distribution a quelle version, sinon l'utilisateur découvre le refus à la compilation.

---

## 3. Ce qu'il manque pour « se rapprocher de Windows 11 à la perfection »

### 3.1 Le chiffre dur : 12 mesures sur 47

Le banc mesure **12 des 47 jetons**. Les 35 autres ne sont mesurés nulle part dans ce dépôt.

| Lot | Jamais mesurés ici | Pourquoi |
|---|---|---|
| 1 — fondations | `police.legende.px`, `police.corps.interligne`, `curseur.theme`, `curseur.taille`, `animations.facteur`, `kirigami.unite`, `couleur.fenetre`, `couleur.barre_de_titre` | demandent une session (curseur, animations) ou une mesure sur l'image |
| 2 — fenêtres | **les 11** : hauteur de la barre de titre, bords, rayon des coins, alignement du titre, boutons, taille et couleur du Fermer | **aucun gestionnaire de fenêtres** dans le conteneur |
| 3 — contrôles | `controle.bouton.rayon`, `controle.champ.rayon`, `controle.interrupteur.*`, `controle.infobulle.px`, `controle.menu.element.hauteur`, `kirigami.rayon` | rayons = mesure sur l'image ; interrupteur et infobulle = contrôles **QtQuick**, pas Qt Widgets |
| 4 — shell | **les 9** : hauteur et position de la barre, marge, couleur, horloge, position des notifications, rayon des volets | demandent Plasma |

### 3.2 Les lots 4 à 10 ne sont pas commencés `MAJEUR`

`src/desktoptheme/`, `src/applets/` et `src/kwin/` sont **vides**. Il manque donc, en entier :

| Lot | Ce qui manque | Ampleur |
|---|---|---|
| **4** — shell | style Plasma d'Ankh (SVG des volets, de la barre, des infobulles, **trait d'accent 16×3** sous l'application active), barre collée de 48 px vérifiée, zone de notification à 16 px, horloge sur deux lignes, notifications en bas à droite | ~1 à 2 semaines |
| **5** — Démarrer | applet QML complet : recherche en haut, 6×3 épingles de 32 px, « Toutes les applications », « Recommandé », compte et alimentation. Dépend de `org.kde.plasma.private.kicker` | ~2 à 3 semaines |
| **6** — paramètres rapides | volet unique (Wi-Fi, Bluetooth, volume, luminosité), dérivé de trois applets, via trois modules **privés** de Plasma | ~2 semaines |
| **7** — Alt+Tab, déconnexion, verrouillage, sons, Windows+Z | thème global complété, script KWin de dispositions | ~1 semaine |
| **8** — applications | Dolphin disposé comme l'Explorateur, Configuration du système, Discover, Konsole, GTK, Flatpak, Electron | ~1 à 2 semaines |
| **9** — icônes | thème Fluent recoloré au violet d'Ankh (sa variante « purple » est en fait rose-magenta `#dc63ee`) | ~2 à 3 jours |
| **10** — finitions | 125 % et 150 %, thème clair au niveau du sombre, accessibilité, toutes les mesures obligatoires | ~1 semaine |

### 3.3 Écarts visibles repérés sur les captures `MINEUR`

- **la sélection d'un élément de liste** est un aplat d'accent sur toute la largeur. Windows 11
  pose une sélection arrondie avec une **pastille d'accent de 3×16** à gauche. Aucun jeton ne
  la mesure aujourd'hui ;
- **Selawik n'a pas de demi-gras** : un titre semi-gras de Windows 11 s'affiche en gras. Limite
  assumée, mais elle se voit ;
- les **titres des boîtes de groupe** sont centrés (héritage de Breeze) ; Windows 11 n'emploie
  pas ce contrôle.

---

## 4. Ce qui n'est jamais vérifié

| Affirmation | État |
|---|---|
| La décoration tient ses 11 mesures | `NON ÉTABLI` ici — mesuré dans le dépôt Ankh, sur Fedora, pas ici |
| Les contrôles QtQuick de KDE suivent le style | `NON ÉTABLI` — `src/qqc2/adapter.py` n'est lancé par rien |
| Le thème GTK s'applique aux applications GTK | `NON ÉTABLI` |
| Les curseurs s'affichent | `NON ÉTABLI` |
| `installer.sh` / `desinstaller.sh` | `NON ÉTABLI` — jamais lancés |
| Les paquets construisent | `NON ÉTABLI` |
| 125 % et 150 % | `NON ÉTABLI` — le banc ne tourne qu'à 100 % |
| Thème clair aussi soigné que le sombre | partiellement : mêmes 12 mesures, pas d'examen visuel systématique |

**Le test en session dans un conteneur a échoué** et c'est consigné dans l'en-tête de
`bench/session.sh` : sous KWin 6.8.2, `kwin_wayland --x11-display` sort avec le code 1 sans
écrire une ligne, et aucun greffon de backend n'est trouvable — Plasma 6.8 étant Wayland seul.
**La voie est donc la VM**, dont le job `VM` a établi la faisabilité.

---

## 5. Risques

| Risque | Portée | Atténuation |
|---|---|---|
| Démarrer et les paramètres rapides dépendent de modules **privés** de Plasma | ils peuvent casser à chaque version | le test hebdomadaire contre l'amont les surveille en premier |
| Selawik n'est plus maintenue depuis 2023, crénage incomplet, pas de demi-gras | typographie | assumé ; une alternative demanderait de refaire le lot 1 |
| Les pièces tierces se téléchargent à la construction | empaquetage impossible en l'état | point 2.3, `À DÉCIDER` |
| Une version d'Ankh DE vise une version de Plasma | la plupart des distributions ne l'ont pas | annoncer la correspondance, et tenir le rythme (DE-008) |
| `--barre` efface les barres de l'utilisateur | perte de configuration | confirmation obligatoire — **jamais testée** |

---

## 6. Ce qu'une semaine peut réellement donner

Les lots 4 à 10 représentent **deux à trois mois**. Les promettre en une semaine serait mentir.
Voici ce qui tient en une semaine, choisi pour donner **un vrai environnement de bureau,
installable partout, honnête sur ce qu'il fait** — plutôt qu'un morceau de pixel-perfection
que personne ne peut installer.

| Jour | Objet | Livré |
|---|---|---|
| **1** | **La session** (2.1) + le mécanisme des valeurs par défaut (1.1) | « Ankh DE » apparaît à l'écran de connexion ; police, animations, rendu et accent s'appliquent enfin |
| **2** | **Les quatre références mortes** (1.2) : thème d'icônes Fluent recoloré (lot 9), style Plasma minimal, écrans de chargement et de verrouillage ; aperçus du paquet (1.3) | plus une seule promesse non tenue dans le thème global |
| **3** | **Le test en VM** : la voie établie par le job `VM`, pour mesurer la décoration (les 11 jetons du lot 2) et vérifier la session de bout en bout | 23 jetons sur 47 mesurés, décoration prouvée |
| **4** | **Le lot 4, shell** : barre collée de 48 px, trait d'accent 16×3, horloge sur deux lignes, zone de notification à 16 px | 32 jetons sur 47 ; la barre des tâches ressemble à celle de Windows 11 |
| **5** | **L'installation réelle** : `installer.sh` et `desinstaller.sh` exécutés en VM sur Fedora, Arch et Ubuntu ; aller-retour complet vérifié | la promesse « s'installe partout et se retire d'un geste » devient vraie |
| **6** | **Les paquets** : `.spec`, `PKGBUILD` et `debian/` construits pour de vrai ; décision sur les pièces tierces (2.3) | des paquets qui existent |
| **7** | **La version 0.1** : tag, Release GitHub avec les archives et les paquets, README avec les captures de la VM, tableau des distributions et de leur version de Plasma | **téléchargeable** |

**Ce qui ne sera pas fait en une semaine**, et qu'il faut assumer : le Démarrer de Windows 11
(lot 5), les paramètres rapides en un volet (lot 6), les réglages par application (lot 8), le
125 % et le 150 % (lot 10). Ankh DE sera alors un environnement de bureau installable partout,
aux fenêtres et aux contrôles au pixel près, avec une barre des tâches de Windows 11 — mais
avec le menu Démarrer de Plasma.

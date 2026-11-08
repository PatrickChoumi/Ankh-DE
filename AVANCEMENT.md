# AVANCEMENT — Ankh DE

> Tout ce qui a été fait, et ce qui reste. Mis à jour à chaque compte rendu, comme dans Ankh
> (D-029). L'ordre des travaux est dans [CLAUDE.md §7](CLAUDE.md).

## 2026-11-05 — Création du dépôt (lot 0, en cours)

**Décidé** (après mes quatre arbitrages du jour) :
- DE-001 : une suite de thèmes et de shell sur Plasma 6, pas un DE écrit de zéro ;
- DE-003 : la géométrie de Windows 11, les couleurs d'Ankh ;
- DE-006 : dépôt public, GPL-3.0-or-later ;
- DE-009 : dépôt séparé d'Ankh ; Ankh le consommera plus tard.

**Écrit**
- `ANKH-DE-SPEC.md` : la référence Windows 11 (géométrie, texte, couleurs, matières, ombres,
  mouvement, contrôles, fenêtres, icônes, shell), l'identité d'Ankh, les limites, la liste NON ;
- `DECISIONS.md` : DE-001 à DE-009 ;
- `ROADMAP.md` : le lot 0 et les lots 1 à 10 ;
- `CLAUDE.md` : les règles de travail.

**Code repris d'Ankh, tel quel** (le report sur Breeze en dépend) :
- `src/style/` — le style Qt, 23 335 lignes de C++ avec la décoration, dérivé de Breeze 6.7.5 ;
- `src/decoration/` — la décoration KDecoration3 ;
- `src/qqc2/` — les adaptations des contrôles QtQuick de KDE ;
- `src/colors/` — `Ankh.colors` et `AnkhClair.colors` ;
- `src/fontconfig/29-ankh-rendu.conf` — niveaux de gris, contours légers ;
- `bench/` — le banc de mesure et ses 53 jetons.

**Écrit pour l'autonomie** (ce qu'Ankh faisait dans son `Containerfile` et son `build.sh`) :
- `CMakeLists.txt` à la racine : compile et installe tout, avec les en-têtes de KDE de n'importe
  quelle distribution ;
- `src/lookandfeel/org.ankh.de.desktop/` : **la pièce nouvelle**. Son `contents/defaults` porte
  les 20 réglages du DE, et son `layouts/*.js` la barre des tâches de Windows 11. Plus aucun
  fichier de la distribution n'est touché (DE-002) ;
- `third_party/preparer.sh` : Selawik, curseurs et thème GTK, sans rien de Fedora ;
- `installer.sh` / `desinstaller.sh` : installation système ou dans le dossier personnel, barre en
  option et confirmée, retour arrière complet.

## 2026-11-05, même jour — le lot 0 passe de « écrit » à « éprouvé »

Tout ce qui suit a tourné dans un conteneur **Fedora 44** (Qt 6.11.2, KF6 6.31.0,
kdecoration 6.8.2), pas seulement été écrit.

**Ce qui a été prouvé**
- `third_party/preparer.sh` marche de bout en bout : Selawik compilée depuis ses sources UFO
  (3 graisses), 47 curseurs et 64 alias, thème GTK recoloré — les violets d'Ankh vérifiés dans
  les quatre feuilles de style. Ce script n'avait **jamais** été lancé ;
- le style et la décoration **compilent contre Plasma 6.8**, sans erreur, `ldd -r` propre. La
  montée de version a donc coûté zéro travail d'API (DE-008) ;
- le garde-fou de version a refusé de construire contre 6.8 alors que le dépôt visait 6.7 —
  exactement son rôle ;
- le garde-fou des licences refuse un actif non déclaré et un nom interdit (testé) ;
- **le style est mesuré** : banc neuf (`bench/galerie`, `bench/captures.sh`, `bench/rapport.py`),
  sans VM et sans Plasma. Toutes les mesures du lot 3 sont conformes, avec Breeze en regard.

**Trois défauts trouvés et corrigés dans le banc lui-même**
1. Xvfb ne fixait pas 96 ppp : 10,5 pt donnaient 12 px au lieu de 14. Toutes les mesures en
   points étaient fausses ;
2. la barre de progression était mesurée par la hauteur du **widget** (25 px, texte compris) au
   lieu de la barre **dessinée**. En prime, l'option construite à la main n'avait pas
   `State_Horizontal` : le style la croyait verticale ;
3. **le plus grave** : un `QApplication` nu ne lit pas `kdeglobals`. Les couleurs et la police
   n'étaient jamais appliquées — la capture « sombre » et la capture « claire » étaient le même
   gris 239,239,239, celui de Qt par défaut. Et le style « avant » retombait en silence sur
   Fusion, faute de Breeze installé : la comparaison ne comparait rien.

**Un vrai écart du style, trouvé et corrigé**
- `controle.liste.hauteur` : 23 px au lieu des 40 px de Windows 11. Breeze n'impose aucune
  hauteur minimale aux éléments de liste — Ankh ne forçait les 40 px que sur les contrôles
  QtQuick. Ajout de `Metrics::ItemView_ItemMinHeight = 40` (source WinUI
  `ListViewItemMinHeight`), appliqué hors `QTableView`, dont les lignes suivent leur en-tête.

**Un vrai défaut de documentation, trouvé et corrigé**
- `docs/INSTALL.md` et `third_party/preparer.sh` conseillaient `xorg-x11-apps` et
  `python3-fontmake` sur Fedora : ces paquets n'existent pas sur Fedora 44. Ce sont `xcursorgen`
  et `fontmake`. Personne n'aurait pu suivre ces instructions.

## 2026-11-05, fin de journée — la CI est verte, et la voie des VM est établie

**Tous les jobs passent**, sur le dépôt, pas en local :

| Job | Résultat |
|---|---|
| Construire — Fedora 44 | vert |
| Construire — Arch | vert |
| Construire — Ubuntu 26.04 | vert |
| Construire — Documents et licences | vert |
| Banc — mesures et captures | vert, **aucun écart** |
| VM — ce que permet le runner | vert |

Le banc tourne donc à chaque PR : il construit le style, ouvre la galerie
sous Xvfb, relève ce que le style impose, le compare aux cibles de WinUI, et
joint les captures « avant / après ». Les mesures relevées **par la CI** sont
les mêmes qu'en local, Breeze en regard :

| Mesure | Windows 11 | Ankh DE | Breeze |
|---|---|---|---|
| Bouton | 32 px | **32** | 34 |
| Champ | 32 px | **32** | 31 |
| Case à cocher avec texte | 32 px | **32** | 21 |
| Élément de liste | 40 px | **40** | 23 |
| Barre de défilement | 12 px | **12** | 21 |
| Barre de progression | 3 px | **3** | 6 |
| Poignée du curseur | 18 px | **18** | 20 |
| Police | Selawik 14 px | **Selawik 14** | Selawik 14 |

### Quatre bugs de CI, tous réels

1. **Ubuntu** : la commande d'installation était `sh -c 'apt-get … -y'` suivie
   des paquets, qui devenaient des arguments de `sh` et non de `apt-get` :
   rien n'était installé.
2. **Ubuntu** : le paquet des en-têtes de frameworkintegration n'existe pas
   sous le nom `libkf6frameworkintegration-dev`. Sur Ubuntu 26.04 c'est
   **`libkf6style-dev`**. Le mauvais nom était aussi dans `docs/INSTALL.md`
   et dans `installer.sh`.
3. **Arch** : `gcc` n'y tire pas `make`.
4. **Ubuntu** : GitHub a exécuté les étapes avec `sh` (dash), qui ne connaît
   pas `done < <(…)`. `bash` est pourtant dans l'image : le shell d'un
   `run:` en conteneur n'est pas garanti, il faut le déclarer.

Et un cinquième, propre au conteneur : l'étape qui prouve le garde-fou
restaurait son fichier par `git checkout`, que git refuse dans un conteneur
(« detected dubious ownership », code 128).

### Les tests en VM sur GitHub : la réponse est oui

Le job `VM` ne teste pas encore Ankh DE : il **établit ce que le runner
permet**, parce qu'on ne bâtit pas un test sur une supposition. Relevé le
2026-11-05 sur `ubuntu-latest` :

- `/dev/kvm` **présent** (`crw-rw---- root:kvm`) ;
- **pas accessible en écriture** par l'utilisateur du runner : il faudra
  `sudo`, ou ajouter l'utilisateur au groupe `kvm` ;
- extensions de virtualisation du processeur **présentes** ;
- 4 cœurs, 15 Gio de mémoire, 86 Go de disque libre ;
- QEMU 8.2.2, qui **propose l'accélération kvm** ;
- **une VM accélérée démarre réellement** (SeaBIOS s'exécute sur le port
  série).

C'est donc la voie pour mesurer ce que le conteneur ne peut pas : la
décoration des fenêtres (lot 2), la barre des tâches (lot 4) et Démarrer
(lot 5).

### Le test en session dans un conteneur : échoué, et consigné

Avant la VM, j'ai essayé de faire tourner KWin dans le conteneur, ce qui
aurait été bien plus rapide. Les constats sont dans l'en-tête de
`bench/session.sh`, qui est gardé pour cela : `kwin_wayland --x11-display`
sort avec le code 1 sans écrire une ligne sous KWin 6.8.2, et aucun greffon
de backend n'est trouvable — Plasma 6.8 étant Wayland seul, le backend X11
imbriqué ne semble plus livré par Fedora. `kwin_x11`, encore en 6.7.5 chez
Fedora, n'apporte pas de binaire utilisable à côté de kwin 6.8.

## 2026-11-05, jour 1 du plan — la session et les polices

**Fait et vérifié** (job `Session et thème global` de la CI, vert) :

- **Ankh DE est une session.** `src/session/` livre `ankh-de.desktop` et le lanceur
  `ankh-de-session`. Il se choisit à l'écran de connexion comme Plasma ou GNOME. Il lance la
  session de Plasma — on ne remplace ni le compositeur, ni le gestionnaire de session, ni
  `plasmashell` (DE-001) — après avoir placé nos valeurs par défaut dans `XDG_CONFIG_DIRS` ;
- **les polices s'appliquent enfin.** Les cinq polices, celle des fenêtres inactives, les trois
  clés de rendu, l'accent qui suit le fond d'écran et le facteur d'animation sont relus un par
  un par `tests/session-et-theme.sh` ;
- **le réglage de l'utilisateur gagne** sur le nôtre : vérifié en posant une police dans
  `~/.config/kdeglobals` et en relisant.

**Deux pièges de plus, trouvés en écrivant le test** — et c'est bien pour cela qu'on l'écrit :

1. `ButtonsOnLeft` et `ButtonsOnRight` ne sont **jamais** écrits par `plasma-apply-lookandfeel`.
   La disposition des boutons de Windows 11 n'était donc pas appliquée. Elle passe dans la
   couche de la session ;
2. `widgetStyle` n'est écrit **que si Qt arrive à charger le greffon**. Installé ailleurs que
   dans `/usr` — par exemple `/usr/local`, le défaut de l'installateur — le style était perdu
   **en silence**. La session pose donc `QT_PLUGIN_PATH` sur son propre préfixe.

**Assaini** : le thème global ne garde que les clés dont on a vérifié qu'elles s'appliquent, et
ne désigne plus aucune pièce absente. Le banc mesure désormais la configuration **réellement
livrée**, au lieu d'une qu'il écrivait pour l'occasion.

**Reste `À VALIDER`** : que la session **démarre** vraiment. Elle n'a jamais été ouverte — cela
demande une VM, et c'est le jour 3 du plan.

## 2026-11-06, jours 3 et 4 — la décoration se mesure, et le style Plasma arrive

**Jour 3.** `bench/session-virtuelle.sh` ouvre un vrai KWin avec son backend `--virtual`, y
connecte la galerie en client Wayland, et demande la géométrie au **compositeur** — car sous
Wayland un client ignore la taille de sa décoration. Mesuré, sans VM :

| Jeton | Cible Windows 11 | Relevé |
|---|---|---|
| `fenetre.barre_de_titre.hauteur` | 32 px | **32** ✓ |
| `fenetre.bord.gauche` / `.droit` / `.bas` | aucun bord | **0** ✓ |
| `fenetre.boutons.gauche` / `.droite` | `M` / `IAX` | **conformes** ✓ |

Six des onze jetons du lot 2. La capture de l'écran virtuel, elle, **ne marche pas** :
`ScreenShot2` répond `NoReply` et KWin meurt sur un défaut de segmentation — rendu llvmpipe,
sans contexte graphique réel. Elle est donc derrière `ANKH_DE_CAPTURE=1`, et les cinq jetons
restants (rayon des coins, bouton Fermer, alignement du titre) attendent une VM.

**Jour 4, et le changement de méthode.** Sur ton cahier des charges, j'ai examiné les projets
qu'il cite. Trois constats :

- **KDE-Windows-Modern** est sous **GPL-3.0**, actif (2026-07), et son `ATTRIBUTION.md` est
  exemplaire. Il livre le thème Plasma, le menu Démarrer, les tâches, la zone système et
  l'horloge ;
- **Tidewater** est sous GPL-3.0 et très actif (2026-10) : référence pour le lot 6 ;
- **menu-11-next** déclare `GPL-2.0+` dans son `metadata.json` mais **n'a aucun fichier
  `LICENSE`** : gardé en référence, rien n'en est copié.

Le **style Plasma d'Ankh** (`ankh`, `ankh-clair`) est donc repris de KDE-Windows-Modern, à son
commit `7ef6bfe`, avec les accents de Windows 11 et les bleus de Breeze remplacés par les
violets d'Ankh. **Aucune règle n'a été contournée** : SPEC §5.6 interdit le **code** tiers mais
autorise les **images** et les **feuilles de style**, et un thème Plasma est fait de SVG.
`docs/UPSTREAMS.md` trace chaque reprise, sa nature et ses modifications.

Le thème global désigne maintenant `name=ankh`, et le test le vérifie.

**Ce que cela change pour la suite** : le menu Démarrer de KDE-Windows-Modern est du **QML**,
donc du code. Le reprendre demande une décision qui modifie SPEC §5.6 — elle est à prendre
avant le lot 5.

## 2026-11-06, le soir — la barre n'était pas la nôtre, et le harnais le taisait

Le menu Démarrer n'était pas « livré mais pas encore ouvert ». Il n'était **pas dans la barre**,
et la barre visible portait nos couleurs, nos icônes et notre thème Plasma par-dessus la
disposition de **Breeze**. C'est ce déguisement qui a tenu le défaut caché.

`kdeglobals [KDE] LookAndFeelPackage` n'était écrit nulle part dans le dépôt. Sans cette clé,
`shellcorona.cpp:1813` retombe sur `org.kde.breeze.desktop` et `shellcorona.cpp:1117` évalue la
disposition de Breeze. La clé vit maintenant dans `src/config/kdeglobals`, que la session place
dans `XDG_CONFIG_DIRS` : une session doit être juste par elle-même, sans dépendre d'une étape
d'installation ([DE-014](DECISIONS.md)).

**Ce que le passage en VM répond maintenant**, et chaque ligne vient d'une source différente :

| Question | Réponse | D'où elle vient |
|---|---|---|
| Quelle disposition a été évaluée ? | `…/org.ankh.de.desktop/…/-layout.js` | le journal de `plasmashell` |
| Qu'a dit notre disposition ? | `org.ankh.demarrer : installé`, idem horloge et bureau | ses propres `print()` |
| Qu'y a-t-il dans la barre ? | nos trois applets, plus `icontasks` et la zone système de Plasma | `evaluateScript` sur `plasmashell` |
| L'écran a-t-il changé à l'ouverture ? | 9,33 %, boîte 662×694 à x=314 sur 1280 | deux captures QEMU comparées |

**J'ai annoncé deux causes avant la bonne, et le mécanisme de l'erreur vaut mieux que la
correction.** `XDG_DATA_DIRS` ne manquait pas — le rapport affichait déjà
`/usr/local/share:/usr/share`. Et « le script n'a rien dit » ne voulait pas dire « le script n'a
pas tourné » : `print()` part dans `qCDebug(PLASMASHELL)`, catégorie `kde.plasmashell`, de
sévérité `Info` par défaut, donc **muette**. J'ai pris ce silence pour une preuve. S'y ajoutait
`qdbus6`, qui n'existe pas sur Fedora — c'est `qdbus-qt6` : toutes les requêtes échouaient en
silence et le rapport écrivait « non » à une question jamais posée.

**Trois constats du harnais s'affichaient sans faire échouer le passage** : les vérifications
clé par clé, la présence de l'applet et l'ouverture du menu. Un passage pouvait écrire
« ÉCHEC » à l'écran et se conclure en réussite. Les griefs sont maintenant rassemblés, et c'est
la fin du script qui décide du code de sortie — après avoir ramassé captures, rapport et
journaux, parce que c'est quand ça rate qu'ils servent.

**Deux assertions du harnais avaient elles-mêmes tort**, et ont échoué à leur premier passage
réel : `XDG_SESSION_DESKTOP` ne porte pas le nom du fichier de session (c'est `DESKTOP_SESSION`,
SDDM `Display.cpp:453` ; les deux autres reçoivent `DesktopNames`, donc `KDE`, que nous posons
exprès pour les portails), et la preuve de composition jugeait sur un cliché pris deux secondes
après le démarrage, tombant sur l'écran de chargement.

**Reconnaissance pour la suite**, les deux candidats clonés et inventoriés : Tidewater
(`4484377`) est **entièrement en QML**, sans C++ ni CMake, avec des identifiants préfixés
`tidewater.*` — rien à compiler, aucune collision. C'est la base retenue pour les lots 4, 6 et
7. Le détail, et ce que leur README ne dit pas, est dans [docs/UPSTREAMS.md](docs/UPSTREAMS.md).

## 2026-11-07 — les trois workflows passent sur un même SHA, et la barre est mesurée

`fbe7f47` : **Construire, Banc et VM — session réelle** passent tous les trois. C'est la
première fois, et c'est ce que les consignes exigent pour parler de pré-version stabilisée.

**Les 9 jetons du lot 4 sont mesurés et conformes** : hauteur 48, position `bottom`, non
flottante, alignement `center`, longueur `fill`, masquage `none`, décalage 0, marge sous la
barre 0, hauteur visible 48. Total : **27 sur 53**.

Les deux derniers ont coûté trois diagnostics, et le mécanisme vaut d'être retenu. Le relevé
annonçait « marge 800, hauteur 0 » :

1. *« le fond noir se confond avec la barre sombre »* — plausible, et faux : sur fond blanc, le
   même nombre.
2. *« le cliché est pris trop tôt »* — plausible aussi, et faux : 36 secondes n'y ont rien
   changé.
3. La capture a tranché. La barre **est** dessinée, mais elle est en **verre** : sur un fond
   uni, quel qu'il soit, elle prend sa couleur. Il n'y avait rien à voir à mesurer.

On mesure donc la **géométrie** en rendant la barre opaque le temps du cliché, puis on la
remet. Trois secondes ont suffi.

**Trois autres défauts corrigés dans la foulée**, tous du même genre — un instrument qui parle
dans le vide :

- `numpy` manquait dans le conteneur Fedora et dans l'invité : la dépendance a été **supprimée**
  (Pillow fait la rotation de teinte seul) plutôt qu'ajoutée partout. Écart avec l'image
  validée : 4/255 au plus ;
- Pillow manquait vraiment, et le contrôle des modules Python ajouté dans la foulée l'a nommé
  en deux secondes au lieu de vingt minutes ;
- les lignes `ANKH-PIECE` du script de session n'atteignaient aucun journal — SDDM les rangeait
  dans son propre fichier. Elles passent par `systemd-cat`, et le harnais regarde trois
  endroits.

**Phase A des consignes faite** : [CLAUDE.md §6](CLAUDE.md). Une seule
implémentation par responsabilité, aucun doublon. Et le constat qui comptait **à cette date** :
sur douze responsabilités, aucune interaction n'était testée. Ce n'est plus vrai du menu
Démarrer depuis `09e4950` — l'état courant est dans
[CLAUDE.md §6](CLAUDE.md), qui en est la source unique.

## 2026-11-07 — la barre devient native, et Ankh DE se construit enfin sur Ubuntu

Deux décisions le même jour, sur deux demandes du propriétaire, et elles se tenaient.

**[DE-016](DECISIONS.md) — la cible est Ubuntu 26.04 LTS, donc Plasma 6.6.** `CMakeLists.txt`
exigeait l'**égalité** avec 6.8. L'archive d'Ubuntu donne pour 26.04 `kdecoration 4:6.6.4` :
`./installer.sh` sortait en `FATAL_ERROR` **sur la machine cible**. Personne ne l'avait vu parce
que `construire.yml` passait `-DANKH_DE_PLASMA_NON_TESTE=ON` sur les trois distributions — le
garde-fou livré n'était jamais celui que la CI éprouvait. Le garde-fou vit désormais dans
`cmake/GardeVersionPlasma.cmake`, et `tests/garde-version.sh` en fait treize cas en `cmake -P`,
sans Qt ni kdecoration. Deux mutations prouvent qu'il peut échouer.

> Et son premier passage en CI a échoué pour une raison instructive : le test négatif ne
> resserrait que les **bornes**, si bien que `plasma=6.6` se retrouvait hors de sa propre plage
> et que c'était ce contrôle-là qui refusait, avec un autre message. Le cas est maintenant dans
> `tests/garde-version.sh`, pour que la CI ne soit plus la première à le voir.

**[DE-015](DECISIONS.md) — huit applets repris passent au natif.** Le relevé qui décide : la
barre portait huit applets qui ne sont pas de Plasma, et **un seul** avait été prouvé interactif.
Pire, pour faire place à `org.ankh.etat`, la disposition **masquait** les cinq applets natives de
la zone système : Ankh DE retirait le réglage du volume, du Wi-Fi, du Bluetooth et de la
luminosité pour les remplacer par un volet qui pilotait le matériel par `wpctl` et `nmcli`, et
dont aucune tuile n'avait jamais été pressée. Ce n'était pas une fonction manquante, c'était
**moins bien que Plasma nu**.

Deux de ces imports reposaient sur une valeur **fausse**, écrite de mémoire : l'horloge de Plasma
sait mettre la date **sous** l'heure (`dateDisplayFormat=BelowTime`, lu dans
`applets/digital-clock/main.xml`), et `iconSpacing` d'icontasks est un `Int`, pas une
énumération. Deux applets importés pour contourner des limites qui n'existaient pas. L'audit
complet est dans [DECISIONS.md, DE-015](DECISIONS.md).

Et un piège évité par le même réflexe : `org.kde.plasma.marginsseparator` aurait été plus propre
pour l'écart de 9 px, mais il **n'existe pas en Plasma 6.6** — 404 sur la branche `Plasma/6.6`,
200 sur `Plasma/6.8`. La cible est 6.6.

**Le harnais ouvre maintenant une VM Ubuntu** (`ANKH_VM_DISTRIB=ubuntu`, le défaut), et le
workflow en fait une matrice, Ubuntu d'abord, `fail-fast` à faux. `konsole`, `dolphin` et
`systemsettings` sont vérifiés par `command -v` **juste après leur installation** : le
2026-11-07, `konsole` figurait dans la liste et l'essai Alt+Tab concluait pourtant « konsole
lancé : NON » sans rien expliquer, parce que le lancement était enterré sous
`> /dev/null 2>&1 || true` trois cents lignes plus bas.

**Et la cible a répondu.** Passage `42397366933`, job Ubuntu : sur **Ubuntu 26.04.1 LTS,
Plasma 6.6**, `installer.sh` réussit, la session s'ouvre depuis SDDM, le compositeur dessine, et
**tous les réglages s'appliquent** — style `Ankh`, `Selawik 10.5`, `org.ankh.decoration`, icônes
`Fluent-Ankh`, style Plasma `ankh`, `LookAndFeelPackage=org.ankh.de.desktop`. C'est exactement ce
que DE-016 débloquait.

Le passage s'est pourtant conclu en **échec**, et deux fois par ma faute. D'abord
`plasmashell --version`, que j'avais substitué à `rpm -q` pour rendre le relevé générique : lancé
par ssh, sans affichage, il ne rend rien. Ensuite le contrôle des lignes vides du rapport, qui a
bien vu la ligne vide — c'était son travail — mais qui sortait en `exit 1` sur place, emportant
les étapes 8 à 13. Aucune vérification clé par clé, aucune interaction, aucune capture, pour une
ligne de rapport. Il grief désormais : le passage échoue toujours, mais après avoir tout appris.
C'était la règle que ce script s'était donnée, et cet endroit ne la suivait pas.

**Les documents ne racontent plus qu'une histoire.** `docs/ANTI_DOUBLONS.md` est la source unique
de l'état fonctionnel, et `ci/verifier-coherence.sh` §8 refuse qu'un autre document attribue une
interaction à un autre SHA. Éprouvé par mutation.

## 2026-11-08 — L'interface prend l'apparence de Windows 11, et les règles tiennent en un fichier

Le propriétaire a tranché : « tout ce que je veux c'est que l'interface ressemble **exactement**
à celle de Windows ». Ankh n'est pas jeté, il est **mis de côté** : la branche `ankh` porte
l'état du 2026-11-08 avant ce virage, et elle est figée. Les identifiants internes
(`org.ankh.*`, `Ankh.colors`, `Fluent-Ankh`) ne changent pas — les renommer casse un passage en
VM pour rien ([DE-017](DECISIONS.md)).

**Un seul document de règles.** Neuf fichiers se contredisaient : `ANKH-DE-SPEC.md`,
`docs/ANTI_DOUBLONS.md`, `docs/AUDIT.md`, `docs/SIMPLIFICATION.md` et cinq autres, 4 557 lignes
au total. Ils disaient à la fois « la géométrie de Windows, les couleurs d'Ankh » et
« ressembler à Windows 11 ». `CLAUDE.md` fait désormais 250 lignes et porte seul les règles,
l'ordre de choix (GARDER / CONFIGURER / ADAPTER / IMPORTER / CONSTRUIRE / DIFFÉRER), les cinq
états et le tableau de l'état fonctionnel. 29 liens morts ont été réécrits, et
`ci/verifier-liens.sh` refuse qu'un lien pointe dans le vide.

**Les couleurs viennent de la documentation de WinUI, pas des captures.** Une capture de
Windows 11 ne donne pas ses couleurs : Mica et l'acrylique prennent la teinte du fond d'écran.
Les 124 valeurs de `Ankh.colors` et `AnkhClair.colors` sont celles que Microsoft publie —
`SolidBackgroundFillColorBase` `#F3F3F3` en clair, `#202020` en sombre ; l'accent `#0078D4` en
clair, `#4CC2FF` en sombre. Ce qui est **opaque** se relève bien à l'image, et seulement
ça : le jaune des dossiers, `#ffcb52`, mesuré sur une capture.

**Le thème clair par défaut**, comme Windows 11 sorti de la boîte. Deux contrôles attendaient
encore le sombre ; c'est le dernier échec du banc qui l'a dit.

**Le menu Démarrer a la disposition de Windows 11** : la recherche en haut, une grille de
6 × 3 épingles, « Recommandé » dessous, l'utilisateur et l'alimentation en bas. Il avait la
forme de Windows 7 — une colonne de favoris à gauche, les lieux à droite — et personne ne
l'avait vu parce que personne n'avait regardé la capture.

**Ce que les captures ont trouvé et que les tests taisaient**, trois fois en trois jours :
la grille des épingles s'affichait **vide** (`Plasmoid.configuration` employé sans son import,
donc `cellWidth` à `NaN`) ; la barre se mesurait « 800 / 0 » sur un fond noir ; le menu de
Windows 7 passait pour celui de 11. Trois défauts qu'aucun test ne signalait. D'où
`tests/qml-imports.py`, et la mesure de la barre sur **magenta** — ni le noir ni le blanc ne
conviennent aux deux thèmes.

**Les garde-fous qui mentaient**, corrigés et éprouvés par mutation : un `grep` sans résultat
dans un tuyau sous `set -o pipefail` tuait le script **sans un mot** (troisième fois) ; un
garde-fou exigeait trois couleurs GTK dont deux supposées ; la recoloration ne regardait que
`*.css` et `*.rc` quand le contrôle regardait tout, et `gtk-2.0/gtkrc` n'a pas d'extension ;
le contrôle de désinstallation nommait huit pièces sans `AnkhClair.colors`, devenu le jeu par
défaut.

## Ce qui est vérifié, et ce qui ne l'est pas

> **Relu le 2026-11-06.** Ce tableau se lit au présent : trois de ses lignes étaient devenues
> fausses sans que rien ne le dise — l'installateur avait tourné, la session s'était ouverte, et
> les paquets avaient été construits. Les entrées datées plus haut gardent, elles, ce qui était
> vrai à leur date : c'est un journal, pas un état.


| Affirmation | État |
|---|---|
| Les mesures des lots 1 à 3 atteignent les cibles de Windows 11 | `MESURÉ` dans Ankh, en VM, sur **Fedora 44 seulement** ([run 39753444882](https://github.com/PatrickChoumi/Ankh/actions/runs/39753444882)) |
| Le code compile tel quel hors de l'image d'Ankh | **vérifié** le 2026-11-05, conteneur Fedora 44, contre Plasma 6.8 |
| Le thème global applique bien ses clés | **vérifié** le 2026-11-05 : il n'en recopie qu'un ensemble FIXE, onze des nôtres étaient ignorées en silence. Les polices, le rendu, l'accent et les boutons de titre sont passés dans la session ([DE-010](DECISIONS.md)) |
| `kdeglobals [KDE] LookAndFeelPackage` désigne notre thème | **vérifié en VM** le 2026-11-06 : le rapport lit `org.ankh.de.desktop`, et `plasmashell` journalise avoir évalué **notre** disposition ([DE-014](DECISIONS.md)) |
| `installer.sh` fonctionne sur Fedora | **vérifié** le 2026-11-06 : il installe dans une VM Fedora 44 neuve, et la session s'ouvre depuis l'écran de connexion (workflow `VM — session réelle`) |
| `installer.sh` fonctionne sur Arch et Ubuntu | **non vérifié** — la construction passe en conteneur, l'installation et la session non |
| `desinstaller.sh` ramène à l'état de départ | **non vérifié en VM** — il tourne sans erreur en conteneur ; personne n'a encore comparé l'avant et l'après dans une vraie session |
| La barre des tâches est celle d'Ankh | **oui**, vérifié en VM le 2026-11-06 : `org.ankh.demarrer`, `org.ankh.horloge` et `org.ankh.bureau` sont installés par notre disposition, qui le dit dans le journal. `icontasks` et la zone système restent ceux de Plasma, par repli assumé — c'est le lot 4 qui les reprendra |
| Le menu Démarrer **s'ouvre** | **oui**, vérifié en VM le 2026-11-06 : 9,33 % de l'écran change à l'ouverture, en une boîte de 662×694 centrée (x=314 sur 1280), donc pas Kickoff qui serait collé à gauche |
| Le paquet RPM construit | **vérifié** le 2026-11-06 : `rpmbuild` passe, et il a révélé deux défauts du `CMakeLists.txt` (un README installé dans `/usr/share/kwin/scripts`, un autre listé deux fois) |
| Les paquets Arch et Debian construisent | **non vérifié** — squelettes |
| `third_party/preparer.sh` fabrique police, curseurs et thème GTK | **vérifié** le 2026-11-05, de bout en bout |
| Les mesures du lot 3 sont conformes hors de l'image d'Ankh | **vérifié** le 2026-11-05 par `bench/captures.sh` |
| Le garde-fou des licences refuse un actif non déclaré ou un nom interdit | **testé** ici, sur deux violations plantées |
| Le CMake refuse une version de Plasma non suivie | **testé** ici, dans les trois cas (version suivie, autre version, autre version avec `-DANKH_DE_PLASMA_NON_TESTE=ON`) |
| `docs/FIDELITE.md` reste à jour avec `bench/jetons.toml` | **testé** ici (`bench/fidelite.py --verifier`) |
| Les workflows de CI font ce qu'ils annoncent | **vérifié** le 2026-11-05 : les six jobs passent sur le dépôt |
| Le code compile sur Arch et sur Ubuntu 26.04 | **vérifié** par la CI le 2026-11-05 |
| Une VM accélérée est possible sur un runner GitHub | **vérifié** le 2026-11-05 (job `VM`) |
| La décoration des fenêtres (lot 2) tient ses mesures | **non vérifié ici** — demande une session ; mesuré dans Ankh seulement |

**Rien de ce dépôt n'a encore tourné sur une machine.** Tant que le lot 0 n'est pas fini, la
seule preuve de fidélité est celle d'Ankh, sur Fedora.

> *Relu le 2026-11-07* : cette phrase était vraie quand elle a été écrite, et elle ne l'est plus
> depuis le 2026-11-06 — le dépôt s'installe dans une VM neuve et sa session s'ouvre depuis
> l'écran de connexion. Elle reste ici parce que c'est un journal : on n'y réécrit pas le passé.
> L'état courant est le tableau « Ce qui est vérifié, et ce qui ne l'est pas », plus bas.*

## Ce que je dois faire moi-même

- Créer le dépôt `Ankh-DE` sur GitHub et y pousser cette première version (les sessions Claude
  Code n'ont pas le droit de créer un dépôt).
- Choisir si le dépôt protège `main` par PR, comme Ankh.

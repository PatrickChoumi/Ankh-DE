# AVANCEMENT — Ankh DE

> Tout ce qui a été fait, et ce qui reste. Mis à jour à chaque compte rendu, comme dans Ankh
> (D-029). L'ordre des travaux est dans [ROADMAP.md](ROADMAP.md).

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
- `bench/` — le banc de mesure et ses 47 jetons.

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

## Ce qui est vérifié, et ce qui ne l'est pas

| Affirmation | État |
|---|---|
| Les mesures des lots 1 à 3 atteignent les cibles de Windows 11 | `MESURÉ` dans Ankh, en VM, sur **Fedora 44 seulement** ([run 39753444882](https://github.com/PatrickChoumi/Ankh/actions/runs/39753444882)) |
| Le code compile tel quel hors de l'image d'Ankh | **vérifié** le 2026-11-05, conteneur Fedora 44, contre Plasma 6.8 |
| Le thème global applique bien ses 20 clés | **non vérifié** — lot 0.7, et SPEC §7 question 1 |
| `installer.sh` fonctionne sur Fedora, Arch, Ubuntu | **non vérifié** — jamais lancé (il demande une session Plasma) |
| `desinstaller.sh` ramène à l'état de départ | **non vérifié** |
| `panel.lengthMode = "fill"` existe en Plasma 6.7 | `À VALIDER` — SPEC §7 question 2 |
| Les paquets (`.spec`, `PKGBUILD`, `debian/`) construisent | **non vérifié** — squelettes |
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

## Ce que je dois faire moi-même

- Créer le dépôt `Ankh-DE` sur GitHub et y pousser cette première version (les sessions Claude
  Code n'ont pas le droit de créer un dépôt).
- Choisir si le dépôt protège `main` par PR, comme Ankh.

# ROADMAP — Ankh DE, lot par lot

> Chaque lot a un **critère de fin vérifiable**. On ne passe pas au suivant tant qu'il n'est pas
> rempli. Chaque lot vit dans sa propre PR, avec ses mesures du banc et ses captures « avant »
> et « après » (DE-007).
>
> Les lots 1 à 10 sont ceux de **D-052** du dépôt [Ankh](https://github.com/PatrickChoumi/Ankh).
> Le lot 0 est propre à ce dépôt : il rend le tout autonome.

> **L'état fonctionnel de chaque responsabilité n'est PAS redit ici.** Il vit dans
> [docs/ANTI_DOUBLONS.md](docs/ANTI_DOUBLONS.md), qui en est la source unique, et
> `ci/verifier-coherence.sh` refuse qu'un document le contredise. Ce tableau dit où en est
> chaque LOT, pas ce que telle interaction prouve.

| Lot | Objectif | État au 2026-11-07 |
|---|---|---|
| **0** | **Autonomie** : le DE se compile, s'installe et se retire seul | **PARTIEL** — compile sur Fedora 44, Arch et Ubuntu 26.04 ; s'installe et sa session s'ouvre dans une VM Fedora. La VM **Ubuntu**, qui est la cible (DE-016), et le tour complet du désinstallateur restent à rendre |
| **1** | Fondations : police, tailles, couleurs, rendu, animations, curseurs | **FINI** — appliqué par la session (DE-010), vérifié en VM : `Selawik 10.5`, couleurs `Ankh`. 12 jetons conformes |
| **2** | Fenêtres : la décoration « Ankh » | **PARTIEL** — 6 jetons sur 11 par un vrai KWin : barre de titre **32 px**, bords à 0, boutons `M`/`IAX`. Les 5 autres demandent une capture que KWin refuse en backend virtuel. Et le chargement dans un KWin **6.6** n'est pas établi |
| **3** | Contrôles : style Qt, QtQuick de KDE, thème GTK | **FINI** — 12 jetons conformes, rejoués à chaque PR sans VM |
| **4** | Shell : style Plasma, barre, zone de notification, horloge, notifications | **PARTIEL** — les 9 jetons de la barre sont mesurés et conformes. Depuis **DE-015**, la barre est native sauf Démarrer : horloge, tâches, notifications, « Afficher le bureau » et l'écart de 9 px sont ceux de Plasma, habillés par le style `ankh` |
| **5** | Démarrer d'Ankh | **PARTIEL** — ouverture, focus clavier et recherche prouvés ; **le lancement réel d'une application reste à prouver**, et c'est lui qui décide si l'applet est gardé. La grille 6 × 3 d'épingles et « Recommandé » manquent au dessin |
| **6** | Paramètres rapides en un seul volet | **ABANDONNÉ pour 0.1 (DE-015)** — c'était « le plus fragile, trois modules privés, aucun appui amont ». Les quatre applets natives (réseau, Bluetooth, volume, luminosité) le remplacent dans la zone système. Écart de fidélité assumé : quatre icônes au lieu d'un volet |
| **7** | Alt+Tab, vue d'ensemble, déconnexion, verrouillage, sons, Windows+Z | **PARTIEL** — Alt+Tab passe au sélecteur natif de KWin (`thumbnail_grid`, DE-015) ; il n'a **jamais été montré à l'écran**. Vue d'ensemble : Meta+W natif, bouton **DEFER**. Verrouillage, déconnexion : jamais essayés |
| **8** | Applications : Dolphin, Configuration du système, Discover, Konsole, GTK, Flatpak, Electron | à faire — les trois premières sont installées dans la VM depuis le 2026-11-07, pas encore regardées |
| **9** | Icônes et curseurs au violet d'Ankh | **FINI** — curseurs au lot 1 ; thème d'icônes `Fluent-Ankh` recoloré, et bouton Démarrer au logo d'Ankh (DE-013) |
| **10** | Finitions : 125 et 150 %, thème clair, accessibilité, mesures obligatoires | à faire |

**Cible : Ubuntu 26.04 LTS, Plasma 6.6** (DE-016), plage éprouvée 6.6 à 6.8. Le choix n'est pas
cosmétique : jusqu'au 2026-11-07, le CMake exigeait 6.8 et Ankh DE **refusait de se construire**
sur cette cible.

**L'audit de simplification**, verdict par composant, est dans
[docs/SIMPLIFICATION.md](docs/SIMPLIFICATION.md).

**Les prochains lots ne demandent plus d'importer quoi que ce soit.** Ce paragraphe annonçait
Tidewater (`4484377`) comme base des lots 4, 6 et 7. **DE-015 a retiré les six pièces reprises**
le 2026-11-07 : pas une n'avait été prouvée interactive, et Plasma livre pour chacune un
équivalent natif qui marche. Ce qui reste à faire est du **test** et du **réglage**, pas de
l'intégration. Les deux pièces de KDE-Windows-Modern restent écartées pour les raisons déjà
nommées, et le relevé complet est dans [docs/UPSTREAMS.md](docs/UPSTREAMS.md).

**Compte des mesures : 27 jetons sur 53, mesurés ET conformes**, dont les 9 du lot 4. Le détail est dans
[docs/FIDELITE.md](docs/FIDELITE.md), généré depuis `bench/jetons.toml`.

**Ce qui livre quoi** : `bench/captures.sh` mesure le style sans VM, à chaque PR ;
`bench/session-virtuelle.sh` mesure la décoration par un KWin en backend `--virtual` ;
`bench/vm/essayer.sh` ouvre une vraie session dans une VM et vérifie tout le reste.

> **Le tableau qui suit est celui d'ORIGINE, arrêté au 2026-10-22.** Il n'est pas mis à jour :
> il dit d'où le projet part, et c'est son seul rôle. L'état courant est le tableau en tête de
> ce fichier.
>
> Deux défauts le rendaient trompeur jusqu'au 2026-11-07. Il annonçait les lots 4 à 10
> « à faire » alors que quatre d'entre eux avaient avancé — deux tableaux dans un même
> document se lisent tous les deux au présent. Et il avait **perdu sa ligne d'en-tête** : il
> commençait par un séparateur, donc il ne s'affichait même pas comme un tableau.

| Lot | Objectif | État au 2026-10-22 |
|---|---|---|
| **0** | **Autonomie** : le DE se compile, s'installe et se retire seul, sur trois distributions | **en cours** — la session est faite (jour 1) |
| **1** | Fondations : police, tailles, couleurs par couches, rendu, animations, curseurs | repris d'Ankh — `MESURÉ` en VM le 2026-10-20 |
| **2** | Fenêtres : la décoration « Ankh » | repris d'Ankh — `MESURÉ` en VM le 2026-10-22 |
| **3** | Contrôles : style Qt, QtQuick de KDE, thème GTK | repris d'Ankh — `MESURÉ` en VM le 2026-10-22 |
| **4** | Shell : style Plasma, barre collée de 48 px, zone de notification, horloge, notifications | à faire |
| **5** | Démarrer d'Ankh, à la disposition de Windows 11 | à faire |
| **6** | Paramètres rapides en un seul volet ; calendrier et notifications harmonisés | à faire |
| **7** | Alt+Tab, vue d'ensemble, déconnexion, écran de verrouillage, sons, dispositions par Windows+Z | à faire |
| **8** | Applications : Dolphin comme l'Explorateur, Configuration du système, Discover, Konsole, GTK, Flatpak, libadwaita, Electron | à faire |
| **9** | Icônes Fluent et curseurs, au violet d'Ankh | curseurs faits (lot 1) ; icônes à faire |
| **10** | Finitions : 125 et 150 %, thème clair au niveau du sombre, accessibilité, toutes les mesures obligatoires | à faire |

---

## Lot 0 — Autonomie

**Pourquoi** : dans Ankh, l'interface est compilée dans une étape du `Containerfile` et appliquée
en écrivant dans `/etc/xdg` et en modifiant les thèmes globaux de Fedora. Rien de cela ne marche
sur Arch ni sur Ubuntu (DE-002).

**Ce que fait le lot**

| # | Tâche | État |
|---|---|---|
| 0.1 | `CMakeLists.txt` à la racine : compile le style et la décoration, installe les thèmes, sans Containerfile | fait |
| 0.2 | Thème global `org.ankh.de.desktop` : porte tous les réglages, y compris la barre | fait |
| 0.3 | `third_party/preparer.sh` : police, curseurs, thème GTK, sans rien de Fedora | fait — **exécuté de bout en bout** le 2026-11-05 (Selawik, 47 curseurs, thème GTK) |
| 0.4 | `installer.sh` et `desinstaller.sh` : système ou dossier personnel, barre en option, retour arrière | fait |
| 0.5 | Banc de mesure porté | **fait pour le style** : `bench/galerie` + `bench/captures.sh` + `bench/rapport.py` mesurent et photographient sans VM ni Plasma ; toutes les mesures du lot 3 conformes. **Reste le shell** (décoration, barre, Démarrer), qui demande une session |
| 0.6 | CI : construction sur Fedora, Arch et Ubuntu, plus le banc | **fait et vert** le 2026-11-05 : les six jobs passent, le banc rejoue les mesures à chaque PR et joint les captures |
| 0.7 | Test en session : Plasma fraîche, thème appliqué, les clés relues, décoration mesurée | **fait** le 2026-11-06 : `bench/vm/essayer.sh` installe Ankh DE dans une VM Fedora 44 neuve, SDDM ouvre notre session, et les vérifications sont rejouées **dedans**. Le harnais a d'abord menti dans trois directions — voir [DE-014](DECISIONS.md) ; il échoue maintenant au lieu d'afficher « ÉCHEC » dans un passage vert |
| 0.8 | Paquets : `.spec` Fedora, `PKGBUILD` Arch, `debian/` Ubuntu | **RPM construit** le 2026-11-06 (`rpmbuild` passe, et a révélé deux défauts du `CMakeLists.txt`). `PKGBUILD` et `debian/` restent des squelettes non construits |
| 0.9 | Garde-fou de licence : la CI refuse un fichier dont la provenance n'est pas dans `LICENSES/` | fait — `ci/verifier-licences.sh`, testé sur deux violations plantées |

**Critère de fin** : sur les trois distributions, dans une VM, `./installer.sh` part d'une session
Plasma nue et donne un bureau d'Ankh DE dont les mesures des lots 1 à 3 sont **toutes conformes** ;
`./desinstaller.sh` ramène exactement à l'état de départ ; et les deux sont rejoués par la CI à
chaque PR.

---

## Lots 1 à 3 — repris d'Ankh

Le code est là et il est mesuré, **mais seulement sur Fedora 44, dans l'image d'Ankh**. Ce qui
reste à prouver dans ce dépôt :

| À prouver | Comment |
|---|---|
| Il compile avec les en-têtes de KDE d'Arch et d'Ubuntu | lot 0.6 |
| Il se charge dans une session Plasma non modifiée | lot 0.7 |
| Les mesures restent conformes hors de l'image d'Ankh | lot 0.5 |
| Selawik est trouvée par fontconfig sans le cache reconstruit par `dnf` | lot 0.7 — c'est le défaut qui a fait échouer le premier passage du lot 1 dans Ankh |

---

## Lots 4 à 10 — à faire

Le détail de chaque lot est dans [D-052](https://github.com/PatrickChoumi/Ankh/blob/main/DECISIONS.md),
section « Mise en œuvre : onze lots ». Résumé des pièces à écrire :

- **Lot 4** — `src/desktoptheme/ankh/` : nos SVG pour `dialogs/background`,
  `widgets/panel-background`, `widgets/tooltip` et `widgets/tasks` (le trait d'accent 16 × 3 sous
  l'application active). Le reste vient de Breeze (`FallbackTheme`). Plus la barre collée de 48 px
  (déjà dans le thème global), la zone de notification à 16 px, l'horloge sur deux lignes, les
  notifications en bas à droite.
  **Le 2026-11-06**, `org.ankh.taches` et `org.ankh.vuetaches` sont repris de Tidewater : la
  barre des tâches et le bouton « Vue des tâches », en QML, qui remplacent le repli sur
  `icontasks`. La zone système de Plasma est **gardée** — l'éteindre couperait les invites de
  mot de passe Wi-Fi et les touches de volume — mais les cinq icônes que notre volet d'état
  reprend passent derrière le chevron. Le **chevauchement zone système / horloge**
  vu sur la capture du 2026-11-06 — l'icône de réseau touchait le « 2 » de « 2:10 PM » — est
  réglé par `org.ankh.separateur`, 9 px sans trait.
  **Reste à mesurer** : la taille des icônes de la barre, leur espacement, l'écart que ce
  séparateur produit vraiment à l'écran, et `volet.rayon`.
- **Lot 5** — `org.ankh.demarrer`, repris de KDE-Windows-Modern. **Il s'ouvre**, vérifié en VM
  le 2026-11-06 (`a71432e`) : disposition d'Ankh évaluée, applet présent dans la barre, 9,48 %
  de l'écran qui change en une boîte centrée de 662×696 — donc pas Kickoff, qui serait collé à
  gauche.
  **Ce qui n'est pas vérifié** : qu'on puisse y taper une recherche, lancer une application,
  naviguer au clavier ou refermer par Échap. Le harnais ne sait pas encore cliquer — c'est
  `À VALIDER MANUELLEMENT`, et ce n'est pas la même chose que « testé ».
  **Ce qui manque au dessin** : la grille 6 × 3 d'épingles et la section « Recommandé ». La
  capture n'en montre qu'une seule, et une colonne de dossiers à la place du « Recommandé » —
  c'est le menu de KDE-Windows-Modern, pas encore celui de Windows 11.
  Dépend de `org.kde.plasma.private.kicker` : fragile (SPEC §4.3).
- **Lot 6** — **repris de Tidewater le 2026-11-06** (`org.ankh.etat`, `org.ankh.notifications`) :
  un seul volet (Wi-Fi, Bluetooth, volume, luminosité) et un centre de notifications, en QML,
  sans une ligne à compiler. Il appelle `wpctl`, `nmcli`, `rfkill`, `bluetoothctl` et `busctl` :
  l'installateur dit lesquels manquent. **Reste à vérifier en session** que chaque tuile
  répond vraiment — être dans la barre n'est pas répondre.
- *(l'ancien plan, pour mémoire)* `src/applets/org.ankh.parametres/` : un seul volet (Wi-Fi, Bluetooth, volume,
  luminosité), dérivé des applets de Plasma. Dépend de trois modules privés : fragile.
- **Lot 7** — **Alt+Tab repris de Tidewater le 2026-11-06** : `ankh-selecteur`, un paquet
  `KWin/WindowSwitcher` en QML qui montre des vignettes en rangées au lieu de la liste verticale
  de Breeze. `src/config/kwinrc` le désigne. **Piège, écrit dans aucun README amont** : KWin
  garde le code d'un sélecteur en mémoire, par nom de paquet, jusqu'à la déconnexion — une mise
  à jour ne prend donc qu'à la session suivante, et c'est dit dans `docs/INSTALL.md`.
  **Reste** : le script de dispositions par Windows+Z (l'idée du « Tiling Assistant » d'AnduinOS),
  la vue d'ensemble, la déconnexion et l'écran de verrouillage — ce dernier ne bougera qu'après
  un déverrouillage réel en VM (`contents/defaults` dit pourquoi).
- **Lot 8** — réglages par application, livrés comme fichiers de configuration par défaut.
- **Lot 9** — thème d'icônes Fluent recoloré, dans `third_party/preparer.sh` (le même mécanisme
  que les curseurs ; sa variante « violette » est en fait rose-magenta `#dc63ee` et doit être
  recolorée).
- **Lot 10** — hautes résolutions, thème clair, accessibilité (contrastes, focus au clavier,
  animations réduites), et les dix lots dans `lots_mesures_obligatoires` **et** dans `lots_complets` (`bench/jetons.toml`).

---

## Après le lot 10

| Point | Décision |
|---|---|
| Bascule d'Ankh sur Ankh DE | DE-009 ; demandera un D-055 dans Ankh |
| Variante « clone littéral de Windows 11 » | SPEC §7, question 5 |
| Paquets officiels (COPR, AUR, PPA) | SPEC §7, question 6 |
| Portage vers Plasma 6.8 (Wayland seul) | DE-008, `docs/REBASE.md` |

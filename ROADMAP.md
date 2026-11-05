# ROADMAP — Ankh DE, lot par lot

> Chaque lot a un **critère de fin vérifiable**. On ne passe pas au suivant tant qu'il n'est pas
> rempli. Chaque lot vit dans sa propre PR, avec ses mesures du banc et ses captures « avant »
> et « après » (DE-007).
>
> Les lots 1 à 10 sont ceux de **D-052** du dépôt [Ankh](https://github.com/PatrickChoumi/Ankh).
> Le lot 0 est propre à ce dépôt : il rend le tout autonome.

| Lot | Objectif | État |
|---|---|---|
| **0** | **Autonomie** : le DE se compile, s'installe et se retire seul, sur trois distributions | **en cours** |
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
| 0.7 | Test en session : Plasma fraîche, thème appliqué, les 20 clés relues, décoration mesurée | **à faire** — la voie est tranchée : une VM sur un runner GitHub, dont le job `VM` a établi la faisabilité (`/dev/kvm`, qemu 8.2.2, VM accélérée qui démarre). Le conteneur ne suffit pas : voir l'en-tête de `bench/session.sh` |
| 0.8 | Paquets : `.spec` Fedora, `PKGBUILD` Arch, `debian/` Ubuntu | squelettes écrits, non testés |
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
- **Lot 5** — `src/applets/org.ankh.demarrer/` : Démarrer en QML, dérivé de Kickoff. Recherche en
  haut, 6 × 3 épingles de 32 px, « Toutes les applications », « Recommandé », compte et
  alimentation en bas. Dépend de `org.kde.plasma.private.kicker` : fragile (SPEC §4.3).
- **Lot 6** — `src/applets/org.ankh.parametres/` : un seul volet (Wi-Fi, Bluetooth, volume,
  luminosité), dérivé des applets de Plasma. Dépend de trois modules privés : fragile.
- **Lot 7** — `src/kwin/` : script de dispositions par Windows+Z (l'idée du « Tiling Assistant »
  d'AnduinOS) ; Alt+Tab, vue d'ensemble, déconnexion et écran de verrouillage dans le thème global.
- **Lot 8** — réglages par application, livrés comme fichiers de configuration par défaut.
- **Lot 9** — thème d'icônes Fluent recoloré, dans `third_party/preparer.sh` (le même mécanisme
  que les curseurs ; sa variante « violette » est en fait rose-magenta `#dc63ee` et doit être
  recolorée).
- **Lot 10** — hautes résolutions, thème clair, accessibilité (contrastes, focus au clavier,
  animations réduites), et `lots_termines = [1,2,3,4,5,6,7,8,9,10]` dans `bench/jetons.toml`.

---

## Après le lot 10

| Point | Décision |
|---|---|
| Bascule d'Ankh sur Ankh DE | DE-009 ; demandera un D-055 dans Ankh |
| Variante « clone littéral de Windows 11 » | SPEC §7, question 5 |
| Paquets officiels (COPR, AUR, PPA) | SPEC §7, question 6 |
| Portage vers Plasma 6.8 (Wayland seul) | DE-008, `docs/REBASE.md` |

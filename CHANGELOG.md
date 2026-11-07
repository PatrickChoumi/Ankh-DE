# Journal des versions

## 0.1.0 — pré-version (2026-11-06)

Première version d'Ankh DE : une **session** qu'on choisit à l'écran de connexion, et qui donne
à KDE Plasma 6 les mesures et la typographie de Windows 11 sous l'identité d'Ankh.

### Ce qui est prouvé, et comment

Tout ce qui suit a été vérifié dans une **vraie machine virtuelle**, sur Fedora 44 et
Plasma 6.8.2, Ankh DE installé par son propre installateur et la session ouverte depuis l'écran
de connexion (workflow `VM — session réelle`).

- la session **s'ouvre** : `plasmashell` et `kwin_wayland` vivants, `ANKH_DE_SESSION=1` ;
- les réglages **s'appliquent** : style `Ankh`, couleurs `Ankh`, police `Selawik 10.5`,
  décoration `org.ankh.decoration`, icônes `Fluent-Ankh`, style Plasma `ankh` ;
- `XDG_CONFIG_DIRS` porte notre dossier **entre** celui de l'utilisateur et celui de la
  distribution : vos propres réglages gardent la priorité ;
- **fontconfig trouve Selawik** ;
- les vérifications clé par clé de `tests/session-et-theme.sh` passent *dans la session* — le
  compte est imprimé par le test et repris dans le rapport du passage, car il dépend des
  outils présents dans l'invité ; ce journal annonçait 46 quand le test en passait 47.

### Mesures

| | |
|---|---|
| Jetons mesurés | 18 à la rédaction de cette entrée ; **27 sur 53** depuis le 2026-11-07 (les 9 du lot 4) |
| Contrôles (lot 3) | 12, tous conformes, rejoués à chaque PR |
| Fenêtres (lot 2) | 6, dont la **barre de titre de 32 px** et les bords à 0 |

### Corrigé après la rédaction de cette entrée, le 2026-11-06

- **La barre des tâches n'était pas la nôtre.** `kdeglobals [KDE] LookAndFeelPackage` n'était
  écrit nulle part : `plasmashell` évaluait la disposition de **Breeze**, et aucun de nos applets
  n'entrait dans la barre. Nos couleurs, nos icônes et notre thème Plasma s'appliquaient
  par-dessus, ce qui rendait le défaut invisible — y compris sur la capture du bureau.
  Cause et conséquences : [DE-014](DECISIONS.md).
- **Trois constats du harnais de VM s'affichaient sans faire échouer le passage** : les
  vérifications clé par clé, la présence de l'applet et l'ouverture du menu. Un passage pouvait
  écrire « ÉCHEC » à l'écran et se conclure en réussite.
- **Six documents racontaient un état périmé** : la version de Plasma annoncée (6.7.x au lieu de
  6.8.x), l'interdiction du code tiers abrogée par DE-011, la session « jamais ouverte »,
  l'installateur « jamais exécuté », le compte des vérifications, et les lots 1, 2 et 3 déclarés
  terminés quand cinq jetons du lot 2 ne sont pas mesurés.

### Ce qui n'est pas encore là

- le **menu Démarrer est livré mais n'a pas été ouvert** : il dépend de modules privés de
  Plasma ; *(corrigé le 2026-11-06 : il s'ouvre, trois preuves indépendantes — voir la
  section « Corrigé après la rédaction de cette entrée »)* ;
- les paramètres rapides en un volet, les réglages par application, le 125 % et le 150 % ;
- le rayon des coins, la taille et la couleur du bouton Fermer, l'alignement du titre : non
  mesurés (la capture de l'écran virtuel fait planter KWin) ;
- les pièces dérivées de dépôts tiers ne sont pas dans le paquet : elles se fabriquent par
  `third_party/preparer.sh`.

### Distributions

| Distribution | Compile | Session éprouvée |
|---|---|---|
| Fedora 44 (Plasma 6.8.2) | oui | **oui, en VM** |
| Arch | oui | non essayé |
| Ubuntu 26.04 | oui | non essayé |

### Licence et marques

GPL-3.0-or-later. Aucun fichier de Microsoft n'est livré, et **aucun motif qui ressemble à un
logo de Microsoft** : le bouton Démarrer porte le logo d'Ankh (DE-013). Projet indépendant, non
affilié à Microsoft. Provenance de chaque reprise : [docs/UPSTREAMS.md](docs/UPSTREAMS.md).

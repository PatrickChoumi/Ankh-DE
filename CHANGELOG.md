# Journal des versions

## Non publié — 2026-11-07

### Changé — la barre devient native, sauf Démarrer ([DE-015](DECISIONS.md))

Huit applets repris sont remplacés par les applets **natives de Plasma**, habillées par notre
style Plasma, nos couleurs et nos icônes : `org.ankh.etat`, `org.ankh.notifications`,
`org.ankh.taches`, `org.ankh.vuetaches`, `org.ankh.separateur`, `org.ankh.horloge`,
`org.ankh.bureau` et `ankh-selecteur`. Un seul des huit avait été prouvé interactif, et il
reste : le menu Démarrer.

- **Corrigé, et c'est le point le plus important pour l'usage quotidien** : la disposition
  **masquait** les cinq applets natives de la zone système pour faire place au volet d'état. Ankh
  DE retirait donc le réglage du **volume**, du **Wi-Fi**, du **Bluetooth** et de la
  **luminosité**. Elles sont de retour, et un contrôle du harnais refuse qu'elles soient masquées
  à nouveau.
- **Gagné sans une ligne écrite** : un calendrier, un agenda et les fuseaux horaires (horloge
  native, date **sous** l'heure) ; les aperçus de fenêtres, les listes de sauts et l'indicateur
  audio (`icontasks`) ; une grille de grandes vignettes pour Alt+Tab (`thumbnail_grid`, livré par
  KWin).
- **Perdu, et c'est dit** : les paramètres rapides ne sont plus un volet unique mais quatre
  icônes dans la zone de notification ; il n'y a plus de bouton « Vue des tâches » (Meta+W).
- **Retiré** : 141 lignes de `third_party/preparer.sh`, le module QML partagé `ankh-de/qml`, le
  paquet du sélecteur Alt+Tab, et une dépendance réseau à la construction.

### Corrigé — Ankh DE refusait de se construire sur sa propre cible ([DE-016](DECISIONS.md))

`CMakeLists.txt` exigeait l'**égalité** avec Plasma 6.8. Ubuntu 26.04 livre `kdecoration 6.6.4` :
`./installer.sh` sortait en `FATAL_ERROR` sur la machine cible. La CI ne le voyait pas, parce
qu'elle passait `-DANKH_DE_PLASMA_NON_TESTE=ON` sur les trois distributions.

- la version prise en charge est une **plage**, 6.6 à 6.8, et la cible est **6.6** ;
- `construire.yml` ne passe plus d'échappatoire : le garde-fou livré est celui qu'on éprouve ;
- `tests/garde-version.sh` : treize cas, sans Qt ni kdecoration, éprouvés par mutation.

### Ajouté — les épreuves

- le harnais ouvre une VM **Ubuntu 26.04** (la cible) autant que Fedora 44, et le workflow en
  fait une matrice, Ubuntu d'abord ;
- un essai de **lancement réel** depuis Démarrer : taper `konsole`, Entrée, puis demander au
  système s'il tourne — le verdict vient de `pgrep`, pas d'un pourcentage de pixels ;
- `konsole`, `dolphin` et `systemsettings` vérifiés **là où on les installe** ;
- deux clics sur l'entrée de tâche, qui exercent `icontasks` dans les deux sens.

### Corrigé — les documents ne racontent plus qu'une histoire

[docs/ANTI_DOUBLONS.md](docs/ANTI_DOUBLONS.md) est la **source unique** de l'état fonctionnel.
`ci/verifier-coherence.sh` §8 refuse qu'un autre document attribue une interaction à un autre
SHA. Le 2026-11-07, cinq documents portaient cinq états différents du menu Démarrer.

### À valider

Que la décoration **se charge** dans un vrai KWin 6.6 ; que Démarrer lance réellement ; que les
tuiles natives répondent ; que le désinstallateur ramène à Plasma standard. **Compiler n'est pas
se charger**, et aucun de ces points n'est acquis à la date de cette entrée.

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

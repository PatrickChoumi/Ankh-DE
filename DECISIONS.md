# DECISIONS — Journal des décisions d'Ankh DE

> Même règle que le dépôt [Ankh](https://github.com/PatrickChoumi/Ankh) : chaque entrée porte
> **Statut**, **Contexte**, **Décision**, **Raisons**, **Alternatives rejetées** et
> **Vérification** (une source officielle, un test reproductible, ou une expérience réelle).
> On ne supprime jamais une entrée : une décision qui change donne une nouvelle entrée
> qui cite l'ancienne.
>
> Les décisions `D-xxx` citées ici sont celles d'Ankh, dans
> [son DECISIONS.md](https://github.com/PatrickChoumi/Ankh/blob/main/DECISIONS.md).
> Ankh DE naît de **D-052** (« Interface au pixel près, au niveau de Windows 11 ») et
> de **D-054** (« L'accent suit le fond d'écran »).

## Index

| ID | Décision | Statut |
|---|---|---|
| DE-001 | Ankh DE est une suite de thèmes et de shell posée sur KDE Plasma 6, indépendante de toute distribution | DÉCIDÉ |
| DE-002 | Tous les réglages vivent dans notre thème global, jamais dans `/etc/xdg` ni dans les thèmes de la distribution | DÉCIDÉ |
| DE-003 | Cible : la géométrie de Windows 11, les couleurs d'Ankh (reprend D-052) | DÉCIDÉ |
| DE-004 | La couleur d'accent suit le fond d'écran (reprend D-054) | DÉCIDÉ |
| DE-005 | Rien de Microsoft dans le dépôt : seules les mesures, publiées sous licence MIT | DÉCIDÉ |
| DE-006 | Dépôt public, sous GPL-3.0-or-later | DÉCIDÉ |
| DE-007 | Le banc de mesure est le critère d'acceptation de chaque lot | DÉCIDÉ |
| DE-008 | Le code dérivé de KDE est reporté à chaque version de Plasma, et la construction échoue tant que ce n'est pas fait | DÉCIDÉ |
| DE-009 | Ankh DE et Ankh restent deux dépôts séparés ; Ankh consommera Ankh DE plus tard | DÉCIDÉ |

---

## DE-001 — Ankh DE est une suite de thèmes et de shell posée sur KDE Plasma 6, indépendante de toute distribution

- **Statut** : DÉCIDÉ (2026-11-05), mon choix.
- **Contexte** : ma demande du 2026-11-05 : « un environnement de bureau qui ressemble trait
  pour trait à Windows 11 pour Linux », dans un dépôt à part, « du style que même un mec sur
  Ubuntu ou Arch peut installer le DE ».
  Trois formes étaient possibles :
  1. une suite de thèmes et de shell posée sur Plasma ;
  2. un vrai environnement de bureau écrit de zéro (compositeur Wayland, shell, toolkit) ;
  3. un shell Ankh en QML remplaçant `plasmashell`, sur KWin.
- **Décision** : la forme 1. Ankh DE est un ensemble de greffons, de thèmes et d'applets
  pour **KDE Plasma 6**, qui s'installe sur Fedora, Arch et Ubuntu sans différence.
  Il ne remplace ni le compositeur, ni le gestionnaire de session, ni `plasmashell`.
- **Raisons** :
  - la forme 2 n'est pas tenable : GNOME et KDE ont des centaines de contributeurs, et un
    compositeur Wayland complet, un shell et un toolkit représentent plusieurs années-personnes.
    Aucun environnement de bureau sérieux n'a été écrit seul ;
  - la forme 3 perd le filet de sécurité de Plasma (gestion des écrans, de l'énergie, des
    notifications, de l'accessibilité) et rend chaque version de KDE dangereuse ;
  - la forme 1 part d'un acquis : les lots 0 à 3 de D-052 sont écrits, et **mesurés en VM**
    (barre de titre de 32 px, bouton Fermer `#C42B1C` en 46×32, coins de 8,2 px, contrôles
    de 32 px, interrupteur de 40×20, barre de défilement de 12 px, Selawik en 14 px) ;
  - c'est la forme qu'ont prise tous les projets comparables qui durent : Klassy (décoration
    et style dérivés de Breeze, un seul mainteneur, vivant depuis Plasma 5) et AnduinOS (des
    extensions et des thèmes sur GNOME, pas un DE neuf).
- **Alternatives rejetées** : les formes 2 et 3 ci-dessus.
- **Limite assumée** : la fidélité est bornée par ce que Plasma expose. Ce qui reste hors de
  portée est listé dans [ANKH-DE-SPEC.md §4](ANKH-DE-SPEC.md#4-ce-qui-nest-pas-atteignable).
- **Vérification** : les mesures des lots 1 à 3, relevées en VM le 2026-10-22
  (runs [39753433287](https://github.com/PatrickChoumi/Ankh/actions/runs/39753433287) et
  [39753437837](https://github.com/PatrickChoumi/Ankh/actions/runs/39753437837) d'Ankh, vertes).
  Klassy : ses [notes de version](https://github.com/paulmcauley/klassy/releases) montrent le
  suivi de Breeze version par version, et le portage vers KDecoration3 en 6.3 (vérifié le 2026-11-05).

## DE-002 — Tous les réglages vivent dans notre thème global, jamais dans `/etc/xdg` ni dans les thèmes de la distribution

- **Statut** : DÉCIDÉ (2026-11-05).
- **Contexte** : dans Ankh, l'interface est appliquée en écrivant dans `/etc/xdg/kdeglobals`,
  `/etc/xdg/kwinrc`, `/etc/xdg/kcminputrc`, et en **modifiant sur place** les thèmes globaux de
  Fedora (`org.fedoraproject.fedoradark.desktop`) — voir `build_files/build.sh` d'Ankh, lignes
  569 à 760. C'est légitime pour une image immuable qu'on construit soi-même. C'est impossible
  ailleurs : Ubuntu et Arch n'ont pas ces thèmes, écrire dans `/etc/xdg` écrase les réglages de
  la distribution, et rien n'est réversible.
- **Décision** : Ankh DE livre **son propre thème global**, `org.ankh.de.desktop`
  (`src/lookandfeel/`). Son fichier `contents/defaults` porte la totalité des réglages :
  jeu de couleurs, polices et tailles, rendu des polices, style des contrôles, décoration des
  fenêtres, curseurs, icônes, facteur d'animation, style Plasma, Alt+Tab, écran de verrouillage
  et écran de chargement. Installer Ankh DE ne modifie **aucun** fichier de la distribution.
  - L'allumer : `plasma-apply-lookandfeel -a org.ankh.de.desktop`.
  - L'éteindre : réappliquer Breeze. Rien à désinstaller pour cela.
  - La barre des tâches de Windows 11 est une **option** (`--barre`) : elle demande
    `--resetLayout`, qui efface les barres existantes. Elle n'est jamais appliquée sans que
    l'utilisateur ait répondu « oui ».
- **Raisons** : c'est le mécanisme prévu par KDE pour exactement cet usage, il est le même sur
  toutes les distributions, il est réversible en un geste, et il n'exige pas les droits root
  pour être appliqué.
- **Alternatives rejetées** :
  - écrire dans `/etc/xdg` comme Ankh : écrase les réglages de la distribution, demande root,
    et n'est pas réversible ;
  - écrire dans `~/.config` à l'installation : invisible pour l'utilisateur, impossible à
    défaire proprement, et perdu au prochain changement de thème ;
  - un script de « patch » des thèmes de la distribution : casse à chaque mise à jour de
    celle-ci.
- **Vérification** : le format et les clés de `contents/defaults` sont ceux lus par
  `klookandfeelmanager.cpp` (`libklookandfeel`, plasma-workspace). `À VALIDER` en VM : qu'une
  session fraîche de Plasma 6 sur Fedora, Arch et Ubuntu prenne bien les 20 clés du fichier.
  C'est le premier test du lot 0 de ce dépôt.

## DE-003 — Cible : la géométrie de Windows 11, les couleurs d'Ankh (reprend D-052)

- **Statut** : DÉCIDÉ (2026-11-05), mon choix, confirmant celui du 2026-10-14 (D-052).
- **Contexte** : « trait pour trait » peut vouloir dire deux choses : un clone visuel complet
  (accent bleu `#0078D4`, gris de Windows), ou la rigueur de Windows 11 sous une autre identité.
- **Décision** : **toutes** les mesures, matières, animations et dispositions de Windows 11 sont
  reprises au pixel près ; **seules les couleurs** sont celles d'Ankh (graphite et violet),
  rangées par couches comme celles de Windows 11 (fenêtre, contenu, carte, contrôle, contour),
  en sombre et en clair. La référence complète est dans
  [ANKH-DE-SPEC.md §2](ANKH-DE-SPEC.md#2-la-référence-windows-11).
- **Raisons** : c'est la décision d'Ankh (D-052), et les lots 1 à 3 sont déjà construits ainsi :
  aucun travail à refaire. Un clone intégral n'apporterait que l'accent bleu et les gris neutres,
  au prix de l'identité du projet — et c'est précisément la part qui expose au risque de marque
  (DE-005).
- **Alternatives rejetées** :
  - clone littéral de Windows 11 ;
  - les deux au choix, par un réglage : faisable (les couleurs sont isolées dans
    `src/colors/`), mais double les captures et les mesures du banc à chaque lot. À reconsidérer
    quand les lots 4 à 10 seront faits.
- **Vérification** : `bench/jetons.toml`, 47 mesures, chacune avec sa cible, sa tolérance, sa
  source et son lot.

## DE-004 — La couleur d'accent suit le fond d'écran (reprend D-054)

- **Statut** : DÉCIDÉ (2026-11-05), reprise de D-054 (2026-10-16).
- **Décision** : `accentColorFromWallpaper=true`, comme l'accent « Automatique » de Windows 11 :
  le violet d'Ankh avec les fonds d'Ankh, la couleur dominante de l'image avec une autre.
  Les curseurs gardent leur anneau violet (ce sont des images figées), et le thème GTK garde le
  violet d'Ankh.
- **Conséquence connue** : KDE calcule la sélection des listes comme l'accent à 70 % sur le fond,
  là où Windows 11 remplit ses contrôles avec l'accent lui-même. Le style d'Ankh prend donc
  l'accent exact (`focusColor`) pour les boutons principaux, les cases, les boutons radio, le
  curseur, la barre de progression et l'interrupteur, et pose dessus du blanc ou du noir, le plus
  contrasté selon la luminance relative du W3C.
- **Vérification** : mis en œuvre et vérifié en VM le 2026-10-20 et le 2026-10-22 dans Ankh
  (D-052, lots 1 et 3).

## DE-005 — Rien de Microsoft dans le dépôt : seules les mesures, publiées sous licence MIT

- **Statut** : DÉCIDÉ (2026-11-05). **C'est une règle non négociable.**
- **Contexte** : le dépôt est public (DE-006). Les projets qui imitent Windows en réutilisant ses
  fichiers se font reprocher la marque et les actifs depuis des années — Linuxfx, puis Wubuntu,
  puis Winux. Aucune action en justice connue à ce jour, mais le reproche porte toujours sur les
  deux mêmes points : **les actifs de Microsoft** et **le nom « Windows »**.
- **Décision** :
  - **ne jamais** livrer, ni versionner, ni télécharger : la police Segoe UI ou Segoe Fluent
    Icons, les icônes de Windows, ses sons, ses curseurs, ses fonds d'écran, ses captures
    d'écran, son logo ;
  - ce qui est repris, c'est **la mesure** : les valeurs de WinUI, publiées par Microsoft sous
    licence MIT (<https://github.com/microsoft/microsoft-ui-xaml>), et sa documentation de
    conception. Chaque valeur de `bench/jetons.toml` cite son fichier et son commit ;
  - les pièces qui *ressemblent* viennent de projets libres tiers, avec leur licence :
    **Selawik** (le sosie de Segoe UI publié par Microsoft lui-même sous OFL 1.1),
    **Fluent-icon-theme** et **Fluent-gtk-theme** (GPL-3.0, de vinceliuice) ;
  - le nom, le logo et les couleurs sont ceux d'Ankh. Le dépôt ne se présente jamais comme un
    produit Microsoft, ni comme affilié à Microsoft, et n'emploie pas « Windows » dans son nom.
    Il dit ce qu'il est : un thème qui reprend les mesures de Windows 11.
- **Vérification** : un test de CI refuse toute PR qui ajoute un fichier de police, d'icône, de
  son ou d'image dont la provenance n'est pas déclarée dans `LICENSES/`.
  Licences relevées le 2026-11-05 : WinUI MIT, Selawik OFL 1.1, Fluent GPL-3.0.

## DE-006 — Dépôt public, sous GPL-3.0-or-later

- **Statut** : DÉCIDÉ (2026-11-05), mon choix (« Public dès maintenant »).
- **Contexte** : D-001 d'Ankh dit « pas de distribution publique ». Cette décision ne la
  contredit pas : **Ankh** (le système) reste mon OS personnel, non public ; **Ankh DE** (la
  suite de thèmes) est un projet distinct, public, utilisable sans Ankh.
- **Décision** : dépôt public, licence **GPL-3.0-or-later**.
- **Raisons** :
  - la licence est imposée, pas choisie : le style et la décoration dérivent de Breeze
    (GPL-2.0-or-later), et les curseurs et le thème GTK de Fluent (GPL-3.0). La seule licence
    compatible avec l'ensemble est GPL-3.0-or-later ;
  - public, le rebase à chaque version de Plasma peut être partagé — c'est le seul coût
    récurrent du projet (DE-008), et c'est ce qui tue les thèmes à mainteneur unique.
- **Risque assumé** : celui de DE-005, borné par ses règles.
- **Vérification** : en-têtes de licence conservés dans chaque fichier repris, et notices dans
  `LICENSES/`.

## DE-007 — Le banc de mesure est le critère d'acceptation de chaque lot

- **Statut** : DÉCIDÉ (2026-11-05), reprise du lot 0 de D-052.
- **Décision** : `bench/jetons.toml` porte la référence : 47 mesures, chacune avec sa cible
  Windows 11, sa tolérance, son unité, sa source et son lot. `lots_termines` liste les lots
  fusionnés. Une mesure dont le lot est terminé **fait échouer le test** si elle s'écarte de sa
  cible. Aucune PR de lot ne fusionne sans :
  1. ses mesures conformes dans la VM de test ;
  2. ses captures « avant » et « après », en sombre et en clair, à 100, 125 et 150 % ;
  3. mon accord.
- **Raisons** : « au pixel près » n'est une promesse tenable que si un programme la vérifie à
  chaque changement. À l'œil, on dérive.
- **Vérification** : le banc tourne dans Ankh depuis le 2026-10-15 ; au premier passage, il a
  relevé 7 mesures conformes, 27 écarts et 12 relevés, et les écarts se sont refermés lot par lot.

## DE-008 — Le code dérivé de KDE est reporté à chaque version de Plasma, et la construction échoue tant que ce n'est pas fait

- **Statut** : DÉCIDÉ (2026-11-05).
- **Contexte** : `src/style` et `src/decoration` sont des copies de Breeze 6.7.5 (commit
  `ca217f1`), renommées et modifiées. Plasma sort environ deux fois par an — 6.7 en juin 2026,
  6.8 le 14 octobre 2026 (dates du calendrier encore à l'état de brouillon sur la liste
  `plasma-devel`), et **6.8 supprime X11**. Chaque version peut changer l'API que ce code appelle :
  le passage de KDecoration2 à KDecoration3 a cassé les réglages de Klassy en 6.3.
- **Décision** :
  - la version de Breeze suivie est écrite dans `src/style/VERSION-BREEZE` et
    `src/decoration/VERSION-BREEZE`, avec son commit ;
  - la construction **échoue** si la version de Plasma installée n'est pas celle suivie, sauf
    `-DANKH_DE_PLASMA_NON_TESTE=ON`, qui l'autorise en l'affichant ;
  - `docs/REBASE.md` donne la procédure de report, à faire à chaque version ;
  - un test de CI hebdomadaire construit contre la version de Plasma de Fedora Rawhide et de
    Arch, pour prévenir avant la sortie.
- **Raisons** : un thème qui se charge à moitié est pire qu'un thème qui refuse de se charger.
  C'est déjà la règle d'Ankh (`ldd -r` sur le greffon, construction en échec si un symbole manque).
- **Vérification** : calendrier de Plasma relevé le 2026-11-05 sur la liste `plasma-devel`
  (6.7.0 le 2026-06-16, 6.8.0 le 14 ou le 20 octobre 2026, dates non définitives) — `À VALIDER`
  sur la page officielle du calendrier de KDE avant de s'y fier.

## DE-009 — Ankh DE et Ankh restent deux dépôts séparés ; Ankh consommera Ankh DE plus tard

- **Statut** : DÉCIDÉ (2026-11-05), mon choix (« un repo Ankh DE à part »).
- **Décision** : le code interface reste pour l'instant **dans les deux dépôts**. Ankh DE est la
  source de vérité pour l'interface ; Ankh garde sa copie tant que les lots en cours ne sont pas
  fusionnés.
- **Quand la bascule se fait** : quand le lot 3 d'Ankh sera fusionné et le lot 4 commencé. Le
  `Containerfile` d'Ankh récupérera alors Ankh DE à un commit figé, à la place de
  `build_files/style`, `build_files/decoration`, `build_files/qqc2` et `build_files/interface`.
  Cela demandera une nouvelle décision dans Ankh (D-055).
- **Risque pendant la double vie** : toute correction doit être portée des deux côtés. C'est
  voulu, mais c'est un coût réel : la bascule ne doit pas traîner.
- **Vérification** : `docs/ARCHITECTURE.md`, section « Rapport avec Ankh ».

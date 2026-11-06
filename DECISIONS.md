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
| DE-008 | La version de Plasma visée est un choix de release, pas une contrainte subie | DÉCIDÉ (réécrite le 2026-11-05 ; montée vers Plasma 6.8 faite le même jour) |
| DE-009 | Ankh DE et Ankh restent deux dépôts séparés ; Ankh consommera Ankh DE plus tard | DÉCIDÉ |
| DE-010 | Ankh DE livre sa propre session, qui porte ce que le thème global ne sait pas porter (corrige DE-002) | DÉCIDÉ |
| DE-011 | Reprendre le code libre existant plutôt que le réécrire (modifie ANKH-DE-SPEC §5.6) | DÉCIDÉ |
| DE-012 | Les sosies libres des dessins de Windows sont acceptés ; seuls les fichiers de Microsoft sont interdits (précise DE-005) | REMPLACÉE par DE-013 |
| DE-013 | Aucun motif qui ressemble à un logo de Windows : le bouton Démarrer porte le logo d'Ankh (remplace DE-012) | DÉCIDÉ |

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

- **Statut** : DÉCIDÉ (2026-11-05) — **son affirmation centrale s'est révélée fausse le jour même ; corrigée par [DE-010](#de-010--ankh-de-livre-sa-propre-session-qui-porte-ce-que-le-thème-global-ne-sait-pas-porter-corrige-de-002)**. La règle « ne rien écraser » reste entière ; c'est le « tous les réglages » qui est faux.
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

## DE-008 — La version de Plasma visée est un choix de release, pas une contrainte subie

- **Statut** : DÉCIDÉ (2026-11-05). **Remplace la rédaction initiale de DE-008** (2026-11-05),
  qui présentait le report sur une nouvelle version de Plasma comme une taxe imposée par KDE.
- **Contexte** : ma remarque du 2026-11-05 : « en ce qui concerne les mises à jour, il suffit de
  refaire le taff quand on veut sortir une nouvelle mise à jour. C'est nous qui faisons les mises
  à jour d'Ankh DE, pas KDE. »
  C'est exact, et ça change le cadre. KDE ne nous impose rien : une version d'Ankh DE vise **une**
  version de Plasma, et y reste bonne indéfiniment. Quand nous voulons sortir une version qui
  vise la suivante, nous refaisons le travail — au moment que nous choisissons.
  C'est d'ailleurs le modèle de KDE lui-même : Plasma 6.8 ne « suit » pas Qt, il vise une version
  de Qt, la déclare, et change quand il le décide.
- **Décision** :
  - chaque version d'Ankh DE **déclare** la version de Plasma qu'elle vise, dans
    `src/style/VERSION-BREEZE` et `src/decoration/VERSION-BREEZE` ;
  - la construction **échoue** contre une autre version, sauf `-DANKH_DE_PLASMA_NON_TESTE=ON`.
    Ce n'est pas un aveu de fragilité : c'est le même contrat qu'un paquet qui déclare ses
    dépendances. Un greffon à moitié chargé est pire qu'un greffon qui refuse de se charger ;
  - **monter de version est un travail planifié**, décrit dans [docs/REBASE.md](docs/REBASE.md),
    fait quand nous décidons de sortir une version. Entre deux, rien ne nous presse ;
  - un test hebdomadaire construit contre l'amont (Fedora Rawhide, Arch) pour que la montée ne
    soit jamais une surprise. **Il n'est pas bloquant** : il informe.
- **Première application, le 2026-11-05 — la montée vers Plasma 6.8**
  - Fedora 44 livre désormais **kdecoration 6.8.2**, c'est-à-dire Plasma 6.8, alors que le code
    vient de Breeze 6.7.5. Le garde-fou a refusé de construire, exactement comme prévu ;
  - le travail de montée s'est révélé **nul au niveau de l'API** : le code de Breeze 6.7.5
    compile tel quel contre Plasma 6.8.2, Qt 6.11.2 et KF6 6.31.0, sans erreur, avec un seul
    avertissement (`corners` inutilisé dans `ankhhelper.cpp`). `ldd -r` ne relève aucune
    bibliothèque ni aucun symbole manquant sur les deux greffons ;
  - les deux `VERSION-BREEZE` déclarent donc `plasma=6.8`, en gardant `tag=v6.7.5` : la source
    reste Breeze 6.7.5, c'est la **cible** qui change.
  - **Ce qui est vérifié, et ce qui ne l'est pas** : la compilation, l'édition de liens, le
    chargement du style par Qt et ses mesures le sont (banc, conteneur Fedora 44). La décoration
    des fenêtres n'est pas vérifiée contre 6.8 : elle demande une session avec KWin.
- **Alternatives rejetées** :
  - suivre l'amont en continu : impose son rythme, pour un bénéfice nul tant que personne ne
    tourne sur la nouvelle version ;
  - ne rien déclarer et espérer : c'est le greffon à moitié chargé.
- **Vérification** : garde-fou éprouvé dans les trois cas le 2026-11-05 (version visée : passe ;
  autre version : échec ; autre version avec l'option : avertit et continue). Montée vers 6.8
  faite et compilée le même jour.

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

## DE-010 — Ankh DE livre sa propre session, qui porte ce que le thème global ne sait pas porter (corrige DE-002)

- **Statut** : DÉCIDÉ (2026-11-05), après vérification.
- **Contexte** : DE-002 affirmait que `contents/defaults` portait « la totalité des réglages ».
  **C'est faux, et je l'ai vérifié le jour même** : après
  `plasma-apply-lookandfeel -a org.ankh.de.desktop`, `kreadconfig6 --group General --key font`
  rend une chaîne vide. L'outil ne recopie qu'un ensemble fixe de clés — couleurs, style des
  contrôles, icônes, curseur, décoration, style Plasma, écrans de chargement et de verrouillage,
  fond d'écran. Les paquets de référence le confirment : ni `org.kde.breezedark.desktop` ni
  `org.fedoraproject.fedoradark.desktop` ne contiennent de police.
  Onze de nos réglages étaient donc **silencieusement ignorés** : les cinq polices, la police
  des fenêtres inactives, les trois clés de rendu, l'accent qui suit le fond d'écran, et le
  facteur d'animation. C'est-à-dire tout le lot 1 hors couleurs et curseurs.
  Dans le même temps, une autre question restait ouverte : Ankh DE n'apparaît pas à l'écran de
  connexion, donc ce n'est pas « un environnement de bureau qu'on choisit ».
- **Décision** : **Ankh DE livre sa propre session**, et c'est elle qui porte le reste.
  - `/usr/share/wayland-sessions/ankh-de.desktop`, pour qu'Ankh DE se choisisse à l'écran de
    connexion comme n'importe quel environnement de bureau ;
  - un script `ankh-de-session` qui pose
    `XDG_CONFIG_DIRS=<nos valeurs par défaut>:$XDG_CONFIG_DIRS`, puis lance
    `startplasma-wayland`. Rien d'autre : on ne remplace ni le compositeur ni le shell (DE-001) ;
  - nos valeurs par défaut (polices, tailles, rendu, animations, accent) vivent dans un
    `kdeglobals` **à nous**, installé dans notre propre dossier. Elles passent **sous** les
    réglages de l'utilisateur, qui gardent la priorité, et **au-dessus** de ceux de la
    distribution. Aucun fichier d'autrui n'est touché : DE-002 reste donc respectée dans son
    esprit, qui était « ne rien écraser » ;
  - le thème global continue de porter ce qu'il sait porter. Les deux mécanismes se complètent.
- **Raisons** : c'est le seul moyen d'appliquer des polices sans écrire chez l'utilisateur ni
  dans `/etc/xdg` ; `XDG_CONFIG_DIRS` est le mécanisme standard de KConfig, pas un détour ; et
  il règle du même coup l'absence de session, qui était le reproche le plus concret qu'on
  pouvait faire au projet.
- **Alternatives rejetées** :
  - écrire les polices dans `~/.config/kdeglobals` à l'installation : écrase les réglages de
    l'utilisateur, et rien ne dit comment les lui rendre ;
  - livrer un `/etc/xdg/kdeglobals` : écrase ceux de la distribution, demande root, et casse
    les autres sessions de la machine ;
  - renoncer aux polices : c'est le lot 1, donc le socle de la fidélité.
- **Limite connue** : hors de la session d'Ankh DE — si l'utilisateur applique seulement le
  thème global depuis une session Plasma ordinaire — les polices et les animations ne
  s'appliquent pas. L'installateur doit le dire, et proposer de se connecter à la session
  d'Ankh DE.
- **Vérification** : `plasma-apply-lookandfeel -a` puis `kreadconfig6` avec la couche
  `kdedefaults` active, le 2026-11-05, conteneur Fedora 44 : `widgetStyle=Ankh`,
  `ColorScheme=Ankh`, `library=org.ankh.decoration`, `cursorTheme=Ankh-curseurs` relus ;
  `font` **vide**. La session elle-même est `À VALIDER` : elle se teste en VM (job `VM`).

## DE-011 — Reprendre le code libre existant plutôt que le réécrire (modifie ANKH-DE-SPEC §5.6)

- **Statut** : DÉCIDÉ (2026-11-06), ton choix, après ta question du même jour : « pourquoi ne pas
  juste s'appuyer sur le code source de KDE ou d'autres projets open source pour aller plus
  vite », puis ton autorisation explicite : « tu peux changer cette règle et t'appuyer sur tout
  l'open source que tu veux ».
- **Contexte** : ANKH-DE-SPEC §5.6 interdisait d'embarquer un projet tiers **comme code**
  (Klassy, Lightly, Menu11, KDE-Rounded-Corners), et n'autorisait que les **images** et les
  **feuilles de style**. Cette règle avait une bonne raison — chacun de ces projets a un seul
  mainteneur et doit être recompilé à chaque version de Plasma, soit notre propre problème en
  double — mais elle nous coûtait très cher : le menu Démarrer était chiffré à deux ou trois
  semaines d'écriture, alors qu'il existe, libre, sous une licence compatible.
- **Décision** : la règle devient une règle de **diligence**, pas d'interdiction.
  Reprendre du code tiers est **permis et même préféré** à le réécrire, à cinq conditions, toutes
  vérifiables :
  1. **Licence compatible avec GPL-3.0-or-later**, lue dans un **fichier de licence** du dépôt —
     une mention dans un fichier de métadonnées ne suffit pas (c'est le cas de `menu-11-next`,
     écarté pour cela) ;
  2. **commit figé**, jamais une branche ;
  3. **provenance tracée** dans `docs/UPSTREAMS.md` : source, commit, licence, **nature** (code
     ou images) et ce qu'on y a changé. Les notices et en-têtes amont sont conservés ;
  4. **rien de Microsoft** n'entre par cette porte : la reprise est relue avec le même garde-fou
     que le reste (DE-005), polices, sons, icônes et fonds compris ;
  5. **on ne reprend pas une pièce qui en écrase une de la distribution**. C'est pourquoi
     l'applet `icontasks` de KDE-Windows-Modern n'est pas repris : son identifiant est
     `org.kde.plasma.icontasks`, celui de l'applet standard de Plasma.
- **Ce que cela change tout de suite** : le menu Démarrer, l'horloge et « Afficher le bureau »
  de [KDE-Windows-Modern](https://github.com/Jeysef/KDE-Windows-Modern) (GPL-3.0, commit
  `7ef6bfe`) sont repris et renommés aux noms d'Ankh. Le lot 5 passe de deux ou trois semaines à
  deux jours.
- **Ce que cela ne change pas** : DE-001 (on ne remplace ni le compositeur, ni le gestionnaire
  de session, ni `plasmashell`), DE-005 (rien de Microsoft), DE-008 (une version visée), et la
  règle « une pièce qu'on ne sait pas retirer ne s'installe pas » (CLAUDE.md §3.8).
- **Risque assumé, et il est réel** : du code repris est du code à reporter à chaque version de
  Plasma, en plus du nôtre. Le menu Démarrer dépend de `org.kde.plasma.private.kicker` et de
  `…private.sessions`, modules **privés** : ils peuvent casser d'une version à l'autre. Le test
  hebdomadaire contre l'amont les surveille, et le README le dit à l'utilisateur.
- **Alternatives rejetées** : garder l'interdiction (coût : des mois d'écriture pour un résultat
  moins bon) ; dépendre des projets tiers à l'exécution plutôt que les reprendre (l'utilisateur
  devrait les installer lui-même, et nous ne maîtriserions plus la version).
- **Vérification** : `ci/verifier-licences.sh` pour les actifs ; `docs/UPSTREAMS.md` pour la
  provenance ; `tests/session-et-theme.sh` pour que chaque pièce installée existe là où Plasma
  la cherche.

## DE-012 — Les sosies libres des dessins de Windows sont acceptés ; seuls les fichiers de Microsoft sont interdits (précise DE-005)

- **Statut** : DÉCIDÉ (2026-11-06), ton choix.
- **Contexte** : la première capture d'une vraie session, le 2026-11-06, montrait un bouton
  Démarrer portant le quadrillage à quatre carreaux de Windows. Je l'ai remplacé par une icône
  dessinée pour le projet, au motif de DE-005. Ton arbitrage : garder celle qui est là.
- **La distinction qui tranche, et elle est réelle** : l'icône `start-here` de
  [Fluent-icon-theme](https://github.com/vinceliuice/Fluent-icon-theme) **n'est pas un fichier de
  Microsoft**. C'est un dessin **original**, de vinceliuice, publié sous **GPL-3.0**, qui
  *ressemble* au motif de Windows. C'est exactement la même nature que **Selawik** — un sosie
  libre de Segoe UI — que le projet emploie déjà depuis le lot 1, et que le thème **Fluent** tout
  entier, qui est un sosie libre de l'iconographie de Windows.
- **Décision** : DE-005 interdit les **fichiers de Microsoft** — ses polices, ses icônes, ses
  sons, ses curseurs, ses fonds d'écran, ses captures, son logo. Elle **n'interdit pas** les
  **redessins libres** de ces motifs, publiés sous une licence compatible par un tiers. Ceux-ci
  sont acceptés, au même titre que Selawik et que le reste de Fluent.
- **Ce que cela ne change pas** : aucun fichier venant de Microsoft n'entre, et le garde-fou
  `ci/verifier-licences.sh` reste en place. Le projet continue de se présenter comme indépendant
  et non affilié à Microsoft (README).
- **Risque assumé, et il est nommé** : un motif qui ressemble à une marque reste un risque
  d'habillage commercial, quelle que soit la licence du dessin. C'est le risque que le projet
  porte déjà pour l'ensemble du thème Fluent, et il est décrit dans
  [AUDIT.md §5](../AUDIT.md). Cette décision ne l'augmente pas : elle le rend explicite.
- **Vérification** : l'icône livrée est celle de Fluent, à son commit figé `c8a244f`, déclarée
  dans `LICENSES/README.md` comme le reste du thème.

## DE-013 — Aucun motif qui ressemble à un logo de Windows : le bouton Démarrer porte le logo d'Ankh (remplace DE-012)

- **Statut** : DÉCIDÉ (2026-11-06), ton choix, qui **remplace DE-012** du même jour.
- **Contexte** : DE-012 acceptait les redessins libres des motifs de Windows, au motif qu'un
  dessin de vinceliuice sous GPL-3.0 n'est pas un fichier de Microsoft. Tu as tranché autrement :
  « pas de logo Windows par exemple, ou qui y ressemble, mais tu peux utiliser des logos qui ne
  ressemblent pas à ceux de Windows, peut-être un original ou bien celui d'Ankh ».
- **Décision** : la règle ne porte plus seulement sur la **provenance** du fichier, mais sur
  **ce que le dessin montre**. Aucun motif reconnaissable comme un logo de Microsoft n'est
  livré, quelle que soit sa licence et quel qu'en soit l'auteur.
  Le bouton Démarrer porte **le logo d'Ankh** : le A au trait barré de violet, repris du dépôt
  [Ankh](https://github.com/PatrickChoumi/Ankh)
  (`build_files/files/usr/share/icons/hicolor/scalable/apps/ankh-logo.svg`). Les proportions
  d'origine sont conservées — sommet en pointe nette, pieds plats, traverse pleine — et le
  dessin est recalé pour une barre des tâches, avec **une version par taille** (16, 22,
  redimensionnable) : à 16 px, un trait à cheval sur deux pixels se délave.
- **Ce qui ne change pas** : le reste du thème Fluent, qui ne montre aucun logo mais une
  *grammaire* visuelle — formes, épaisseurs, arrondis. C'est la typographie de l'interface, pas
  une marque. Selawik reste également en place : c'est une police publiée par Microsoft sous
  OFL, pas un logo.
- **Comment c'est tenu** : `third_party/preparer.sh` remplace **toutes** les variantes de
  `start-here` du thème — `-kde`, `-kde-plasma`, `-symbolic`, à toutes les tailles — et **la
  construction échoue** si une seule n'est pas la nôtre. Le défaut d'origine n'avait été vu que
  sur la capture d'une vraie session : le contrôle automatique existe pour qu'il ne revienne pas.
- **Pourquoi DE-012 était quand même utile** : elle a nommé la distinction entre un fichier de
  Microsoft et un redessin libre, qui reste vraie et qui justifie Selawik et Fluent. Elle se
  trompait seulement sur l'endroit où tracer la limite.

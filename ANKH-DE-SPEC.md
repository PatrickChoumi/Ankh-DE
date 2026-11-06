# ANKH-DE-SPEC — Spécification d'Ankh DE

> Version 0.1 — 2026-11-05.
> Ce document dit **ce qu'Ankh DE doit être, et à quoi on le mesure**. C'est lui qui dicte le
> travail. Les choix sont dans [DECISIONS.md](DECISIONS.md) (`DE-xxx`), l'ordre des travaux dans
> [ROADMAP.md](ROADMAP.md), l'état dans [AVANCEMENT.md](AVANCEMENT.md).
>
> Il hérite du chantier **D-052** du dépôt [Ankh](https://github.com/PatrickChoumi/Ankh), dont
> les recherches (lues dans le code de WinUI et dans celui de Plasma, le 2026-10-14) sont
> reprises ici.

## Légende

| Marqueur | Signification |
|---|---|
| `DÉCIDÉ` | Choix acté, justifié dans DECISIONS.md |
| `À VALIDER` | Hypothèse non encore prouvée. Ne doit pas être traitée comme un fait |
| `À DÉCIDER` | Choix ouvert ; ce qui le débloque est indiqué |
| `MESURÉ` | Relevé par le banc dans la VM de test, avec le run qui le prouve |

---

## 1. En une phrase

Ankh DE donne à **KDE Plasma 6** la géométrie, la typographie, les matières, les animations et
la disposition de **Windows 11**, au pixel près et vérifiées par un programme, sous les couleurs
graphite et violet d'**Ankh** — et s'installe sur Fedora, Arch ou Ubuntu sans rien casser, et se
retire d'un geste (DE-001, DE-002, DE-003).

**Ce n'est pas** un environnement de bureau écrit de zéro, ni un clone de Windows 11, ni une
distribution. C'est une suite de thèmes, de greffons et d'applets pour Plasma.

---

## 2. La référence Windows 11

Toutes les valeurs sont à l'échelle 100 %, en pixels effectifs de Windows, et en `#AARRGGBB`
quand il s'agit d'une couleur. Chacune est lue dans une source publiée par Microsoft sous
licence MIT, ou dans sa documentation de conception (DE-005) : rien n'est repris d'un fichier de
Windows lui-même.

Sources, relevées le 2026-10-14 :
- **WinUI 3** — <https://github.com/microsoft/microsoft-ui-xaml>, licence MIT, dictionnaires
  `*_themeresources.xaml` et `controls/dev/CommonStyles` (commits `566a040`, `866ba81`, `09cfc8f`) ;
- **documentation** — <https://learn.microsoft.com/windows/apps/design/> ;
- **Windows Terminal** — <https://github.com/microsoft/terminal>, `MinMaxCloseControl.xaml`
  (commit `44b440b`), qui copie les boutons de la barre de titre du shell.

Le kit Figma de Microsoft n'est pas lisible par une machine : rien n'en vient.

### 2.1 Géométrie

| Quoi | Valeur | Source |
|---|---|---|
| Rayon des contrôles | 4 | `ControlCornerRadius`, `CornerRadius_themeresources.xaml` |
| Rayon des fenêtres, menus, volets, dialogues | 8 | `OverlayCornerRadius` |
| Rayon des infobulles | 4 | idem |
| Coins d'une fenêtre agrandie ou ancrée | carrés | page `signature-experiences/geometry` |
| Contour | 1 px | page `layering` |
| Tailles et marges | multiples de 4 | page `layering` |

### 2.2 Texte

| Rôle | Taille / interligne | Graisse |
|---|---|---|
| Légende | 12 / 16 | normale |
| Corps | 14 / 20 | normale |
| Sous-titre | 20 / 28 | semi-gras |
| Titre | 28 / 36 | semi-gras |
| Grand titre | 40 / 52 | semi-gras |
| Affichage | 68 / 92 | semi-gras |

Casse de phrase partout. Source : `TextBlock_themeresources.xaml`, page
`signature-experiences/typography`.

**Police** : Segoe UI Variable ne peut pas être livrée (DE-005). Ankh DE livre **Selawik**, son
sosie libre publié par Microsoft sous OFL 1.1, aux mêmes mesures. Limite assumée : Selawik n'est
plus suivie depuis 2023, son README signale qu'il lui manque le crénage de Segoe UI, et elle n'a
pas de semi-gras — un titre en semi-gras s'affiche en gras.

### 2.3 Couleurs, thème sombre de Windows 11

Relevées dans `Common_themeresources_any.xaml`. Ankh DE **ne les emploie pas** : il emploie les
siennes (§3). Elles figurent ici parce que la *structure par couches* est reprise.

| Rôle | Windows 11 sombre |
|---|---|
| Texte | `#FFFFFFFF` |
| Texte secondaire | `#C5FFFFFF` (77 %) |
| Texte tertiaire | `#87FFFFFF` |
| Texte désactivé | `#5DFFFFFF` |
| Fond des contrôles | `#0FFFFFFF`, survol `#15FFFFFF` |
| Cartes | `#0DFFFFFF` |
| Contours | `#12FFFFFF` |
| Fonds pleins | `#202020`, `#1C1C1C`, `#282828`, `#2C2C2C` |
| Voile des dialogues | `#4D000000` |

### 2.4 Matières

- **Mica** (fond des fenêtres) : teinte `#202020` à 80 % en sombre — `MicaController.h` ;
- **Acrylic** (volets passagers) : flou 30, grain 0,02, teinte `#2C2C2C` à 15 %, luminosité 0,96
  en sombre — `AcrylicBrush.h`, `AcrylicBrush_themeresources.xaml`.

### 2.5 Ombres

Élévation E = Z / 2 (`DropShadowRecipe.h`, page `develop/ui/shadows`).

| Surface | Ombre |
|---|---|
| Menus | flou 16, décalage 8, 26 % en sombre |
| Fenêtres et dialogues | ambiante (flou 21,3, décalage 2) + dirigée (flou 64, décalage 32), 37 % chacune en sombre |

### 2.6 Mouvement

Durées : **83, 167, 250 et 333 ms**. Courbe d'entrée : `cubic-bezier(0, 0, 0, 1)`.
Source : page `signature-experiences/motion`.

### 2.7 Contrôles

| Contrôle | Mesure |
|---|---|
| Bouton | 32 de haut, marges de 12 (bord compris) |
| Champ, liste déroulante, compteur | 32 de haut |
| Case à cocher, bouton radio | 20 ; 32 avec son texte |
| Interrupteur | 40 × 20 |
| Élément de navigation | 36 ; pastille d'accent 3 × 16 |
| Élément de liste | 40 |
| Barre de défilement | 8 de poignée, 12 au survol |
| Barre de progression | 3 |
| Curseur (slider) | rail 4, poignée 18 |
| Menu | éléments à 4 px des bords, colonne d'icône 28 |
| Infobulle | texte 12, largeur ≤ 320 |
| Dialogue | 320 à 548 de large, marge 24 |
| Focus | trait de 2, trait intérieur de 1 |

Source : fichiers des contrôles dans `CommonStyles`, page
`develop/input/guidelines-for-visualfeedback`.

### 2.8 Fenêtres

| Quoi | Mesure |
|---|---|
| Barre de titre | 32 de haut, couleur de la fenêtre |
| Icône | 16, à 16 px du bord |
| Titre | à gauche, 16 px après l'icône, en légende, coupé par « … » |
| Fenêtre inactive | icône et titre à 50 % |
| Boutons réduire / agrandir / fermer | 46 × 32, symboles 10 × 10 |
| Survol | voile léger (blanc à 6 % en sombre, noir à 4 % en clair) |
| Fermer, survolé | `#C42B1C`, symbole blanc |
| Bords visibles | aucun ; marge invisible de 8 px pour redimensionner |

Sources : pages `basics/titlebar-design` et `develop/title-bar` ; boutons copiés de Windows
Terminal.

### 2.9 Icônes

16 dans les menus, les barres de titre et la zone de notification ; 24 dans la barre des tâches ;
32 pour les épingles de Démarrer. Source : page `iconography/app-icon-construction`.

### 2.10 Barre des tâches et Démarrer — `À VALIDER`

**Microsoft ne publie presque aucune mesure de son shell.** Les valeurs ci-dessous sont
**observées**, pas sourcées, et marquées comme telles dans `bench/jetons.toml` :

| Quoi | Valeur observée |
|---|---|
| Hauteur de la barre | 48 |
| Boutons de la barre | ≈ 44 × 40 |
| Trait d'accent sous l'application active | 16 × 3 |
| Notifications | 364 de large |
| Démarrer | recherche en haut, 6 × 3 épingles, « Toutes les applications », « Recommandé », compte et alimentation en bas |

Valeurs confirmées par **AnduinOS** (GPL-3.0, <https://github.com/Anduin2017/AnduinOS>), une
Ubuntu faite pour ressembler à Windows 11 : barre de 48 px collée en bas, opacité 60 %, flou de
rayon 20, luminosité 0,8 ; 8 px autour des icônes ; zone de notification à 16 px ; trait sous
l'application active, tirets sous les autres.

---

## 3. L'identité d'Ankh

Seules les **couleurs** s'écartent de Windows 11 (DE-003). Chaque gris de Windows, de niveau L,
devient le graphite bleuté d'Ankh (L−4, L, L+7).

| Couche | Ankh sombre | Ankh clair | (Windows 11 sombre) |
|---|---|---|---|
| Fenêtre (Mica) | `28,32,39` | `#f3f4f6` | `#202020` |
| Barre de titre, en-têtes | idem fenêtre | idem fenêtre | idem fenêtre |
| Contenu (listes, champs) | `24,28,35` | blanc | `#1C1C1C` |
| Carte | `39,43,50` | `#fbfbfc` | `#2B2B2B` |
| Contrôle | `41,45,52` | `#fbfbfc` | `#2D2D2D` |
| Infobulle, volet passager | `40,44,51` | `#f9f9fa` | `#2C2C2C` |
| Texte | `#e6edf3` | — | `#FFFFFF` |
| Texte secondaire | `184,190,196` (77 %) | — | `#C5FFFFFF` |

**Accent** : violet `#8455f0` pour les sélections, violet du logo `#a78bfa` pour les liens, le
survol et le focus. En thème clair, `#7c3aed`. L'accent **suit le fond d'écran** (DE-004) ; les
fonds d'Ankh gardent le violet d'Ankh.

**Sombre par défaut.** Un thème clair existe, aussi soigné (lot 10).

**Curseurs** : Fluent blancs, anneau d'attente et flèches de redimensionnement au violet d'Ankh,
taille 24. **Icônes** : Fluent, dossiers au violet d'Ankh, avec Breeze pour celles qui manquent.
**Code et terminal** : JetBrains Mono.

---

## 4. Ce qui n'est pas atteignable

Honnêteté d'abord : « trait pour trait » s'arrête là où Plasma s'arrête. Ces points sont des
**limites assumées**, pas des bugs à corriger, et ils sont répétés dans le README pour que
personne ne soit déçu.

### 4.1 Impossible sans reprendre le code de KDE — *résolu, c'est ce que fait Ankh DE*

- le rayon de Breeze est une constante de 5 px (`Frame_FrameRadius` dans `kdecoration/breeze.h`
  et `kstyle/breezemetrics.h`) ;
- ses boutons de fenêtre sont ronds (`breezebutton.cpp`) ;
- ses barres de défilement sont larges (`ScrollBar_Extend` = 21).

C'est précisément la raison d'être de `src/style` et `src/decoration`.

### 4.2 Impossible tout court en Plasma 6.7 — `À VALIDER` à chaque version

| Quoi | Pourquoi |
|---|---|
| Contenu de l'OSD du volume | module QML compilé (`shell/osd.cpp`) |
| Largeur des notifications | `gridUnit * 18`, en dur (`applets/notifications/global/Globals.qml`) |
| Menu de disposition au survol du bouton « Agrandir » | rien de tel dans KWin. Contournement : Windows+flèches, et l'éditeur de tuiles (Windows+T) |
| Applications libadwaita (Bottles, ProtonPlus…) | ne reçoivent que la couleur d'accent, ramenée au violet d'Adwaita `#9141ac` (`adw-style-manager.c`, `adw-accent-color.c`) |

### 4.3 Fragile par nature

- **Démarrer et paramètres rapides** (lots 5 et 6) passent par des modules **privés** de Plasma
  (`org.kde.plasma.private.kicker`, `…private.volume`, `…private.bluetooth`,
  `…private.brightnesscontrolplugin`) : aucune garantie d'une version à l'autre. La CI le montre
  avant que l'utilisateur ne reçoive la mise à jour (DE-008).
- **Chrome, VS Code et les applications Electron** dessinent leur propre barre de titre.
- **Les applications GTK en Flatpak** ne voient pas le thème GTK installé sur le système.

---

## 5. Ce que je ne veux pas

1. **Aucun fichier de Microsoft** : ni police, ni icône, ni son, ni curseur, ni fond d'écran, ni
   capture d'écran, ni logo (DE-005).
2. **Pas de « Windows » dans le nom**, pas de prétention d'affiliation à Microsoft.
3. **Ne rien écraser** : ni `/etc/xdg`, ni les thèmes de la distribution, ni la configuration de
   l'utilisateur. Rien d'irréversible (DE-002).
4. **Pas de `curl | bash`** comme méthode d'installation.
5. **Pas de dépendance à un dépôt tiers** à l'exécution : tout ce qui vient d'ailleurs est pris à
   un commit figé, vérifié, à la construction.
6. **Reprendre le code libre existant est permis, et préféré à le réécrire** — à cinq
   conditions, toutes vérifiables (**DE-011**, qui remplace l'interdiction d'origine) : licence
   compatible GPL-3.0-or-later **portée par un fichier de licence** ; commit figé ; provenance
   tracée dans [docs/UPSTREAMS.md](docs/UPSTREAMS.md) avec sa nature et ses modifications ; rien
   de Microsoft ; et **aucune pièce qui en écrase une de la distribution**.
   Ce qui reste écarté l'est pour une raison nommée, pas par principe : `menu-11-next` (licence
   déclarée en métadonnées, sans fichier de licence), l'applet `icontasks` de KDE-Windows-Modern
   (il porte l'identifiant de l'applet standard de Plasma), PlasmaZones (exige Qt 6.10+).
7. **Pas de « au pixel près » sans mesure** : toute affirmation de fidélité qui n'est pas relevée
   par le banc est marquée `À VALIDER` (DE-007).
8. **Pas de X11 comme cible** : Plasma 6.8 le supprime. Ankh DE vise Wayland. X11 peut marcher,
   il n'est pas testé.

---

## 6. Prérequis

| Quoi | Version | Note |
|---|---|---|
| KDE Plasma | 6.7.x | version suivie ; voir `src/*/VERSION-BREEZE` et [docs/REBASE.md](docs/REBASE.md) |
| Qt | 6.6 ou plus | |
| KDE Frameworks | 6.0 ou plus | |
| Session | Wayland | X11 non testé (§5.8) |
| Distributions testées | Fedora 44, Arch, Ubuntu 26.04 | par la CI ; `À VALIDER` sur matériel réel |

---

## 7. Questions ouvertes

| # | Question | Statut |
|---|---|---|
| 1 | Les 20 clés de `contents/defaults` sont-elles toutes prises par une session fraîche, sur les trois distributions ? | `À VALIDER` — premier test du lot 0 |
| 2 | `panel.lengthMode = "fill"` existe-t-il dans le moteur de script de Plasma 6.7 ? | `À VALIDER` — lot 4 |
| 3 | Les 8 px autour des icônes de la barre : quelle clé exactement ? | `À DÉCIDER` — lot 4, à mesurer |
| 4 | Le thème clair doit-il aussi suivre le fond d'écran, ou garder le violet ? | `À DÉCIDER` — lot 10 |
| 5 | Faut-il la variante « clone littéral » de DE-003, par un réglage ? | `À DÉCIDER` — après le lot 10 |
| 6 | Paquets : COPR pour Fedora, AUR pour Arch, PPA pour Ubuntu — lesquels, et qui les tient ? | `À DÉCIDER` — après le lot 5 |

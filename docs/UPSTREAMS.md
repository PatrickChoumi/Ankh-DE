# UPSTREAMS — ce qu'Ankh DE reprend, et d'où

> Exigé par le cahier des charges (§5.10) : **une entrée par élément externe intégré**.
> Complète [LICENSES/README.md](../LICENSES/README.md), qui porte les licences ;
> ce fichier-ci porte la **provenance, la décision et les modifications**.
>
> Règle du dépôt ([DE-011](../DECISIONS.md), qui modifie ANKH-DE-SPEC.md §5.6) : **reprendre le
> code libre existant plutôt que le réécrire** — QML, C++, feuilles de style, images — à un
> **commit figé**, avec sa licence, et avec une entrée dans ce tableau. La colonne « Nature »
> dit ce qu'est chaque reprise.
>
> Jusqu'au 2026-11-06, ce paragraphe citait encore l'interdiction d'origine (« on n'embarque pas
> un projet tiers comme code ») alors que le menu Démarrer QML tiers était intégré depuis
> plusieurs commits : la règle vivait au passé dans le document censé la faire appliquer.
> `ci/verifier-licences.sh` ne regardait que la provenance, pas la cohérence de l'en-tête ;
> `ci/verifier-coherence.sh` surveille désormais cette phrase-ci aussi.

## Intégré

| Élément | Source | Commit | Licence | Nature | Décision et modifications |
|---|---|---|---|---|---|
| Style Qt `src/style/` | [KDE Breeze](https://invent.kde.org/plasma/breeze) | `ca217f1` (v6.7.5) | GPL-2.0-or-later | **code**, dérivé | Copié puis renommé pour cohabiter avec Breeze. Mesures de WinUI appliquées. Entrée `Metrics::ItemView_ItemMinHeight = 40` ajoutée le 2026-11-05 |
| Décoration `src/decoration/` | KDE Breeze, `kdecoration/` | `ca217f1` (v6.7.5) | GPL-2.0-or-later | **code**, dérivé | Barre de 32 px, boutons 46×32, coins de 8, ombres de Windows 11 |
| Jeux de couleurs `src/colors/` | Breeze, `colors/BreezeDark.colors` | 6.7.5 | LGPL-2.0-or-later | données | Mêmes rôles, couleurs d'Ankh rangées par couches |
| Gabarit de barre | [plasma-desktop](https://invent.kde.org/plasma/plasma-desktop), `layout-templates/…defaultPanel` | 6.7 | LGPL-2.0-or-later | code, dérivé | Barre collée de 48 px, centrée |
| Écran de chargement | Breeze, `lookandfeel/contents/splash/` | 6.7 | LGPL-2.0-or-later | code, dérivé | Couleurs d'Ankh, barre de 3 px sur les six étapes |
| **Style Plasma `ankh` / `ankh-clair`** | **[KDE-Windows-Modern](https://github.com/Jeysef/KDE-Windows-Modern)**, `plasma/desktoptheme/` | **`7ef6bfe`** (2026-07-19) | **GPL-3.0** | **images (SVG)** | **Repris le 2026-11-06.** Les accents de Windows 11 (`#4CC2FF`, `#60CDFF` en sombre ; `#0078D4` en clair) et les bleus de Breeze restés dans leur base (`#3DAEE9`, `#3DAEE6`, `#93CEE9`) sont remplacés par les violets d'Ankh. `metadata.json` réécrit à notre nom. 168 fichiers par thème |
| **Menu Démarrer `org.ankh.demarrer`** | **KDE-Windows-Modern**, `plasma/applets/…startmenu/` | **`7ef6bfe`** | **GPL-3.0** | **code (QML)** | **Repris le 2026-11-06 (DE-011).** 19 fichiers, QML pur, rien à compiler. Identifiant, domaine de configuration et nom affiché passés aux noms d'Ankh ; **l'auteur amont (Jeysef) est conservé** dans les métadonnées, et le test le vérifie. Dépend de `org.kde.plasma.private.kicker` et `…private.sessions` : modules **privés**, surveillés par le test hebdomadaire |
| **Horloge `org.ankh.horloge`** | KDE-Windows-Modern, `…digitalclock/` | `7ef6bfe` | GPL-3.0 | code (QML) | Idem. Dispose l'heure au-dessus de la date, ce que l'horloge de Plasma ne sait pas faire |
| **« Afficher le bureau » `org.ankh.bureau`** | KDE-Windows-Modern, `…showdesktop/` | `7ef6bfe` | GPL-3.0 | code (QML) | Idem. Aucun module privé |
| Police Selawik | [microsoft/Selawik](https://github.com/microsoft/Selawik) | `89362e8` | OFL 1.1 | données | Compilée depuis ses sources UFO, **sans modification** (nom réservé) |
| Curseurs | [Fluent-icon-theme](https://github.com/vinceliuice/Fluent-icon-theme), `cursors/` | `c8a244f` | GPL-3.0 | images | Variante blanche, bleu d'accent → violet d'Ankh |
| Icônes `Fluent-Ankh` | Fluent-icon-theme | `c8a244f` | GPL-3.0 | images | Variante « purple » (rose-magenta) recolorée en trois teintes |
| Thème GTK `Fluent-Ankh` | [Fluent-gtk-theme](https://github.com/vinceliuice/Fluent-gtk-theme) | `7a49a46` | GPL-3.0 | feuilles de style | Variante ronde et sans bord, violets d'Ankh |
| `org.ankh.etat` (lot 6) | [Tidewater](https://github.com/addition-official/tidewater), `plasmoids/status` | `4484377` | GPL-3.0-or-later | QML | Volet unique Wi-Fi / Bluetooth / volume / luminosité. Identifiant renommé, graine de couleur `#466fbd` → `#a78bfa`, épaisseur 52 → 48 px, Rubik → Selawik, police d'icônes forcée au repli Fluent-Ankh |
| `org.ankh.notifications` (lot 6) | idem, `plasmoids/notifications` | `4484377` | GPL-3.0-or-later | QML | Mêmes transformations |
| `org.ankh.taches` (lot 4) | idem, `plasmoids/tasks` | `4484377` | GPL-3.0-or-later | QML | Mêmes transformations. Lit la même clé `launchers` qu'`icontasks`, donc les épingles suivent |
| `org.ankh.vuetaches` (lot 4) | idem, `plasmoids/taskview` | `4484377` | GPL-3.0-or-later | QML | Mêmes transformations |
| `ankh-selecteur` (lot 7) | idem, `switcher/tidewater-switcher` | `4484377` | GPL-3.0-or-later | QML | Paquet `KWin/WindowSwitcher`, désigné par `src/config/kwinrc`. **Une mise à jour ne prend qu'à la déconnexion** : KWin garde le code en mémoire par nom de paquet |
| module QML partagé, et le `common/` de chaque applet repris | idem, `shared/` et `common/` | `4484377` | GPL-3.0-or-later | QML | Installé dans `share/ankh-de/qml` ; les applets l'atteignent par cinq niveaux relatifs, ce que `tests/session-et-theme.sh` résout vraiment plutôt que de le compter |

## Examiné, et écarté — avec la raison

| Projet | Licence | Pourquoi pas |
|---|---|---|
| [menu-11-next](https://github.com/Eisteed/menu-11-next) | `GPL-2.0+` **déclarée dans `metadata.json`**, mais **aucun fichier `LICENSE`** à la racine (relevé le 2026-11-06) | Gardé en **référence d'ergonomie**. Rien n'en est copié tant que la licence n'est pas portée par un fichier : une déclaration dans un fichier de métadonnées ne vaut pas le texte de la licence |
| [Klassy](https://github.com/paulmcauley/klassy), Lightly, KDE-Rounded-Corners | diverses | SPEC §5.6 : un seul mainteneur chacun, à recompiler à chaque version de Plasma — le même problème que le nôtre, en double |
| [PlasmaZones](https://github.com/fuddlesworth/PlasmaZones) | GPL-3.0-or-later | Exige **Qt 6.10+**, au-dessus de notre plancher (Qt 6.6+) : exclurait des distributions visées. À citer comme extension facultative |

## La reconnaissance qui a conduit à ces choix — 2026-11-06

Les deux candidats ont été **clonés et inventoriés**, pas lus de loin. Ce qui suit est relevé
dans les dépôts, aux commits indiqués.

### [Tidewater](https://github.com/addition-official/tidewater) — `4484377`, 2026-10-11, GPL-3.0

**C'est la base retenue, et elle est intégrée depuis le 2026-11-06.** La raison est nette : **aucune ligne de C++, aucun `CMakeLists.txt`**
dans tout le dépôt. Tout est QML et données. Donc rien à compiler, rien à reporter à chaque
version de Plasma, et le risque d'ABI qui nous coûte si cher sur le style et la décoration
n'existe pas ici. Ses onze identifiants sont tous préfixés `tidewater.*` : **aucune collision**
avec un applet de Plasma — l'inverse exact du problème d'`icontasks`.

| Pièce | Lignes QML | Lot | Ce qu'elle apporte |
|---|---|---|---|
| `plasmoids/status` | 870 (+ 276 de shell) | 6 | Le volet unique : Wi-Fi, Bluetooth, volume, luminosité |
| `plasmoids/notifications` | — | 6 et 10 | Centre de notifications |
| `switcher/tidewater-switcher` | 1 fichier | 7 | Alt+Tab en rangées. `KPackageStructure: KWin/WindowSwitcher` |
| `plasmoids/{tasks,clock,taskview,power,divider,workspaces,search}` | — | 4 | Les pièces de la barre |

**Ce qu'il faut savoir avant de reprendre, et qui n'est pas dans leur README :**

- le volet d'état **n'utilise aucun module QML de réseau** — il appelle `wpctl` (8 fois),
  `nmcli` (7), `rfkill` (6), `bluetoothctl` (5) et `busctl` (4) depuis
  `contents/code/helper.sh`. C'est pourquoi il ne dépend pas de
  `org.kde.plasma.networkmanagement`, **absent de notre VM Fedora** (relevé dans le journal du
  2026-11-06 : `plasma-welcome` s'en plaint). Avantage : aucune dépendance de module. Coût : ces
  cinq outils doivent exister, et l'installateur devra le vérifier par distribution ;
- **KWin garde le code d'un sélecteur Alt+Tab en mémoire, par nom de paquet, jusqu'à la
  déconnexion.** Leur `install.sh` contourne la chose en renommant le paquet avec une empreinte
  de son contenu (`tidewater-switcher-<sha1 court>`) et en pointant KWin dessus. Nous aurions
  buté exactement là, en croyant notre sélecteur non chargé ;
- ils développent et testent sur **Plasma 6.6**, nous visons 6.8. Comme tout est QML, le risque
  n'est pas l'ABI mais une API retirée : `org.kde.plasma.plasma5support` et
  `org.kde.plasma.private.volume` sont à vérifier en session avant toute reprise.

### [KDE-Windows-Modern](https://github.com/Jeysef/KDE-Windows-Modern) — `7ef6bfe`, 2026-07-19

Déjà la source de notre thème Plasma et de trois applets. Les deux pièces que l'on nous
conseille d'en tirer sont, mesure faite, les plus coûteuses du lot :

| Pièce | Identifiant déclaré | Volume | Décision |
|---|---|---|---|
| `icontasks` | **`org.kde.plasma.icontasks`** | 11 fichiers C++, 20 QML, 4 429 lignes | **Non.** L'identifiant est celui de l'applet standard de Plasma : le reprendre tel quel l'écraserait, ce que DE-011 interdit. Et il faut compiler |
| `systemtray` | *aucun* `Id` dans `metadata.json` (relevé le 2026-11-06) | 40 fichiers C++, 60 QML, 6 585 lignes | **Non pour l'instant.** C'est un fork du conteneur système de Plasma : du C++ couplé à l'ABI, et un conteneur **remplacé**. `tidewater.status` rend le même service en QML |

Les licences déclarées par leurs `metadata.json` ne sont pas uniformes : `startmenu` est en
`GPL-3.0-or-later`, mais `digitalclock`, `icontasks`, `showdesktop` et `systemtray` sont en
`GPL-2.0-or-later`. À reporter dans `LICENSES/` pièce par pièce, et non en bloc.

### Et plasma-workspace lui-même

Pour un comportement système, la source officielle a tranché deux questions que ni l'un ni
l'autre de ces projets n'aurait réglées, et elle l'a fait en quelques minutes de lecture :

- `shell/shellcorona.cpp` a donné la cause de la barre qui n'était pas la nôtre
  ([DE-014](../DECISIONS.md)) ;
- `shell/scripting/panel.h` expose `alignment`, `lengthMode`, `length`, `offset`, `hiding` et
  `opacity` en plus de `height`, `location` et `floating` que nous lisions déjà. Ces six-là
  n'étaient **pas** des jetons : elles le deviennent, et elles disent précisément ce qui fait une
  barre de Windows 11 — **centrée**, **pleine largeur**, **jamais masquée**. Attention à ne pas
  surestimer l'apport : les huit autres jetons du lot 4 étaient déjà lus ; ils revenaient vides à
  cause de la sonde cassée, pas faute d'être demandés ;
- `shell/scripting/containment.h` confirme `widgetIds` et `widgetById`, sur quoi repose notre
  sonde d'applets.

C'est la source à lire **avant** un projet tiers quand la question est « comment Plasma
fait-il ? ».

## Rappel de licence

KDE-Windows-Modern est lui-même dérivé de Win11OS-kde, Fluent-kde, OnzeMenuKDE, menu-11-next
et de plasma-workspace : son `ATTRIBUTION.md` est la source de ce tableau. Toute reprise
ultérieure doit le relire — et non se fier à celui-ci, qui en est une copie datée du 2026-11-06.

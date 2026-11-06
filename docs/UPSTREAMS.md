# UPSTREAMS — ce qu'Ankh DE reprend, et d'où

> Exigé par le cahier des charges (§5.10) : **une entrée par élément externe intégré**.
> Complète [LICENSES/README.md](../LICENSES/README.md), qui porte les licences ;
> ce fichier-ci porte la **provenance, la décision et les modifications**.
>
> Règle du dépôt ([ANKH-DE-SPEC.md §5.6](../ANKH-DE-SPEC.md)) : on n'embarque pas un projet
> tiers **comme code**. Les **images** et les **feuilles de style**, oui, à un commit figé,
> avec leur licence. La colonne « Nature » dit de quel côté tombe chaque reprise.

## Intégré

| Élément | Source | Commit | Licence | Nature | Décision et modifications |
|---|---|---|---|---|---|
| Style Qt `src/style/` | [KDE Breeze](https://invent.kde.org/plasma/breeze) | `ca217f1` (v6.7.5) | GPL-2.0-or-later | **code**, dérivé | Copié puis renommé pour cohabiter avec Breeze. Mesures de WinUI appliquées. Entrée `Metrics::ItemView_ItemMinHeight = 40` ajoutée le 2026-11-05 |
| Décoration `src/decoration/` | KDE Breeze, `kdecoration/` | `ca217f1` (v6.7.5) | GPL-2.0-or-later | **code**, dérivé | Barre de 32 px, boutons 46×32, coins de 8, ombres de Windows 11 |
| Jeux de couleurs `src/colors/` | Breeze, `colors/BreezeDark.colors` | 6.7.5 | LGPL-2.0-or-later | données | Mêmes rôles, couleurs d'Ankh rangées par couches |
| Gabarit de barre | [plasma-desktop](https://invent.kde.org/plasma/plasma-desktop), `layout-templates/…defaultPanel` | 6.7 | LGPL-2.0-or-later | code, dérivé | Barre collée de 48 px, centrée |
| Écran de chargement | Breeze, `lookandfeel/contents/splash/` | 6.7 | LGPL-2.0-or-later | code, dérivé | Couleurs d'Ankh, barre de 3 px sur les six étapes |
| **Style Plasma `ankh` / `ankh-clair`** | **[KDE-Windows-Modern](https://github.com/Jeysef/KDE-Windows-Modern)**, `plasma/desktoptheme/` | **`7ef6bfe`** (2026-07-19) | **GPL-3.0** | **images (SVG)** | **Repris le 2026-11-06.** Les accents de Windows 11 (`#4CC2FF`, `#60CDFF` en sombre ; `#0078D4` en clair) et les bleus de Breeze restés dans leur base (`#3DAEE9`, `#3DAEE6`, `#93CEE9`) sont remplacés par les violets d'Ankh. `metadata.json` réécrit à notre nom. 168 fichiers par thème |
| Police Selawik | [microsoft/Selawik](https://github.com/microsoft/Selawik) | `89362e8` | OFL 1.1 | données | Compilée depuis ses sources UFO, **sans modification** (nom réservé) |
| Curseurs | [Fluent-icon-theme](https://github.com/vinceliuice/Fluent-icon-theme), `cursors/` | `c8a244f` | GPL-3.0 | images | Variante blanche, bleu d'accent → violet d'Ankh |
| Icônes `Fluent-Ankh` | Fluent-icon-theme | `c8a244f` | GPL-3.0 | images | Variante « purple » (rose-magenta) recolorée en trois teintes |
| Thème GTK `Fluent-Ankh` | [Fluent-gtk-theme](https://github.com/vinceliuice/Fluent-gtk-theme) | `7a49a46` | GPL-3.0 | feuilles de style | Variante ronde et sans bord, violets d'Ankh |

## Examiné, et écarté — avec la raison

| Projet | Licence | Pourquoi pas |
|---|---|---|
| [menu-11-next](https://github.com/Eisteed/menu-11-next) | `GPL-2.0+` **déclarée dans `metadata.json`**, mais **aucun fichier `LICENSE`** à la racine (relevé le 2026-11-06) | Gardé en **référence d'ergonomie**. Rien n'en est copié tant que la licence n'est pas portée par un fichier : une déclaration dans un fichier de métadonnées ne vaut pas le texte de la licence |
| [Klassy](https://github.com/paulmcauley/klassy), Lightly, KDE-Rounded-Corners | diverses | SPEC §5.6 : un seul mainteneur chacun, à recompiler à chaque version de Plasma — le même problème que le nôtre, en double |
| [PlasmaZones](https://github.com/fuddlesworth/PlasmaZones) | GPL-3.0-or-later | Exige **Qt 6.10+**, au-dessus de notre plancher (Qt 6.6+) : exclurait des distributions visées. À citer comme extension facultative |

## À examiner pour les lots suivants

| Projet | Licence | Pour quoi |
|---|---|---|
| KDE-Windows-Modern, `plasma/applets/org.kde.windowsmodern.startmenu/` | GPL-3.0 | **Lot 5, le menu Démarrer.** 20 fichiers QML, Plasma 6.0+. C'est du **code** : sa reprise demande une décision qui modifie SPEC §5.6 |
| KDE-Windows-Modern, applets `icontasks`, `systemtray`, `digitalclock` | GPL-3.0 | Lot 4 avancé et lot 6 |
| [Tidewater](https://github.com/addition-official/tidewater) | GPL-3.0, actif (2026-10) | Lot 6 (paramètres rapides), lot 7 (Alt+Tab, aperçus) |

## Rappel de licence

KDE-Windows-Modern est lui-même dérivé de Win11OS-kde, Fluent-kde, OnzeMenuKDE, menu-11-next
et de plasma-workspace : son `ATTRIBUTION.md` est la source de ce tableau. Toute reprise
ultérieure doit le relire — et non se fier à celui-ci, qui en est une copie datée du 2026-11-06.

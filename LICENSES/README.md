# Provenance et licence de chaque pièce

> Règle du projet ([DE-005](../DECISIONS.md#de-005--rien-de-microsoft-dans-le-dépôt--seules-les-mesures-publiées-sous-licence-mit)) :
> **aucun fichier de Microsoft** n'est livré, versionné ni téléchargé. Seules les **mesures**
> sont reprises, de sources que Microsoft publie sous licence MIT. Tout fichier venu d'ailleurs
> est déclaré ici, à un commit figé, avec sa licence et son en-tête conservés.
>
> La CI refuse toute PR qui ajoute une police, une icône, un son ou une image dont la provenance
> n'est pas dans ce tableau (lot 0.9).

## Code repris

| Pièce | Source | Version / commit | Licence |
|---|---|---|---|
| `src/style/` | [KDE Breeze](https://invent.kde.org/plasma/breeze), dossiers `kstyle/`, `libbreezecommon/` et `kdecoration/breezesettingsdata.kcfg` | 6.7.5, commit `ca217f1` | GPL-2.0-or-later |
| `src/decoration/` | [KDE Breeze](https://invent.kde.org/plasma/breeze), dossiers `kdecoration/` et `libbreezecommon/` | 6.7.5, commit `ca217f1` | GPL-2.0-or-later |
| `src/colors/` | dérivé de `colors/BreezeDark.colors` de Breeze — mêmes rôles, couleurs d'Ankh | 6.7.5 | LGPL-2.0-or-later |
| `src/qqc2/` | adaptations de `org.kde.desktop` de [qqc2-desktop-style](https://invent.kde.org/frameworks/qqc2-desktop-style) | 6.31 | LGPL-2.0-or-later |
| `src/lookandfeel/.../layouts/` | dérivé de `layout-templates/org.kde.plasma.desktop.defaultPanel` de [plasma-desktop](https://invent.kde.org/plasma/plasma-desktop) | 6.7 | LGPL-2.0-or-later |

Tous ces fichiers gardent l'en-tête de licence de KDE. L'ensemble du dépôt est distribué sous
**GPL-3.0-or-later**, la seule licence compatible avec GPL-2.0-or-later et GPL-3.0 réunies.

## Pièces téléchargées à la construction

Aucune n'est versionnée ici : `third_party/preparer.sh` les récupère à un commit **figé et
vérifié**, puis les recolore.

| Pièce | Source | Commit | Licence | Ce qu'on en fait |
|---|---|---|---|---|
| Police Selawik | [microsoft/Selawik](https://github.com/microsoft/Selawik) | `89362e8` (2023-06-05) | OFL 1.1 | Compilée depuis ses sources UFO, **sans modification** : elle garde donc son nom réservé (« Reserved Font Name ») |
| Curseurs Fluent | [vinceliuice/Fluent-icon-theme](https://github.com/vinceliuice/Fluent-icon-theme), dossier `cursors` | `c8a244f` (2026-08-31) | GPL-3.0 | Variante blanche, bleu `#0078d4` et `#23e6fa` remplacés par le violet d'Ankh |
| Thème GTK Fluent | [vinceliuice/Fluent-gtk-theme](https://github.com/vinceliuice/Fluent-gtk-theme) | `7a49a46` (2026-08-18) | GPL-3.0 | Variante ronde et sans bord, violets Material remplacés par ceux d'Ankh |
| Icônes Fluent (lot 9) | [vinceliuice/Fluent-icon-theme](https://github.com/vinceliuice/Fluent-icon-theme) | à figer | GPL-3.0 | Dossiers recolorés au violet d'Ankh ; sa variante « purple » est en réalité rose-magenta `#dc63ee` |

## Mesures reprises

Ce sont des **valeurs**, pas des fichiers. Chacune est citée avec son fichier et son commit dans
[`bench/jetons.toml`](../bench/jetons.toml).

| Source | Commits relevés | Licence |
|---|---|---|
| [microsoft/microsoft-ui-xaml](https://github.com/microsoft/microsoft-ui-xaml) (WinUI 3) | `566a040`, `866ba81`, `09cfc8f` | MIT |
| [microsoft/terminal](https://github.com/microsoft/terminal), `MinMaxCloseControl.xaml` | `44b440b` | MIT |
| [learn.microsoft.com/windows/apps/design](https://learn.microsoft.com/windows/apps/design/) | relevé le 2026-10-14 | documentation — valeurs seules |

## Valeurs observées, non sourcées

Microsoft ne publie presque aucune mesure de son shell. Hauteur de la barre des tâches, taille de
ses boutons, largeur des notifications et disposition de Démarrer sont **observées**, et marquées
`À VALIDER` dans `bench/jetons.toml`. Elles sont corroborées par
[AnduinOS](https://github.com/Anduin2017/AnduinOS) (GPL-3.0), qui poursuit le même but sous GNOME.

## Marques

Windows et Windows 11 sont des marques de Microsoft Corporation. Ankh DE n'est ni affilié à
Microsoft, ni approuvé par Microsoft. Il n'emploie pas « Windows » dans son nom, ne se présente
pas comme un produit Microsoft, et ne distribue aucun fichier de Windows.

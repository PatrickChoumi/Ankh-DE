# FIDELITE — ce qui est mesuré, et ce qui ne l'est pas

> **Ce fichier est généré** par `bench/fidelite.py` depuis
> [`bench/jetons.toml`](../bench/jetons.toml). Ne pas le modifier à la main :
> la CI le régénère et refuse la PR s'il diffère.
>
> Une mesure dont le lot est **terminé** fait échouer le test en VM si elle s'écarte de
> sa cible (DE-007). Une mesure dont le lot n'est pas terminé est seulement relevée.
> Une mesure **sans cible** est un simple relevé : on la suit, on ne l'impose pas.

**47 mesures.** Lots terminés : 1, 2, 3.

## Lot 1 — fondations — **obligatoire**

| Mesure | Cible Windows 11 | Tolérance | Source |
|---|---|---|---|
| Police de l'interface (`police.famille`) | `Selawik` | — | Mon choix du 2026-10-15 : sosie libre de Segoe UI (D-052) |
| Taille du texte courant (`police.corps.px`) | 14 px | ± 0.5 px | WinUI CommonStyles/TextBlock_themeresources.xaml, BodyTextBlockFontSize |
| Taille des petits textes (légendes) (`police.legende.px`) | 12 px | ± 0.5 px | WinUI CommonStyles/TextBlock_themeresources.xaml, CaptionTextBlockFontSize |
| Hauteur d'une ligne de texte courant (`police.corps.interligne`) | *relevé* | — | Windows : 20 px pour un texte de 14 px (doc signature-experiences/typography) ; dépend de la police |
| Curseur de la souris (`curseur.theme`) | `Ankh-curseurs` | — | Mon choix du 2026-10-15 : curseurs Fluent blancs, anneau d'attente au violet d'Ankh, comme AnduinOS (D-052) |
| Taille du curseur (`curseur.taille`) | 24 px | ± 0 px | Taille de Plasma, gardée (D-052) |
| Facteur de durée des animations de KDE (`animations.facteur`) | *relevé* | — | Relevé ; les durées de Windows sont 83, 167, 250 et 333 ms (doc signature-experiences/motion) |
| Unité de grille de Kirigami (`kirigami.unite`) | *relevé* | — | Relevé (Kirigami.Units.gridUnit) ; Windows place tout sur une grille de 4 px |
| Fond des fenêtres (Dolphin) (`couleur.fenetre`) | *relevé* | — | Relevé ; couleurs d'Ankh (D-037) |
| Barre de titre de la fenêtre active (`couleur.barre_de_titre`) | *relevé* | — | Relevé ; couleurs d'Ankh (D-037) |

## Lot 2 — fenêtres — **obligatoire**

| Mesure | Cible Windows 11 | Tolérance | Source |
|---|---|---|---|
| Hauteur de la barre de titre (`fenetre.barre_de_titre.hauteur`) | 32 px | ± 0 px | WinUI TitleBar/TitleBar_themeresources.xaml, TitleBarCompactHeight ; doc basics/titlebar-design |
| Bord gauche de la décoration (`fenetre.bord.gauche`) | *relevé* | — | Relevé ; Windows : contour de 1 px (doc signature-experiences/layering) |
| Bord droit de la décoration (`fenetre.bord.droit`) | *relevé* | — | Relevé ; Windows : contour de 1 px (doc signature-experiences/layering) |
| Bord bas de la décoration (`fenetre.bord.bas`) | *relevé* | — | Relevé ; Windows : contour de 1 px (doc signature-experiences/layering) |
| Rayon des coins d'une fenêtre (`fenetre.coin.rayon`) | 8 px | ± 0.75 px | WinUI CommonStyles/CornerRadius_themeresources.xaml, OverlayCornerRadius |
| Place du titre (`fenetre.titre.alignement`) | `gauche` | — | Doc basics/titlebar-design : icône de 16 px à 16 px du bord, puis le titre |
| Boutons à gauche de la barre de titre (M : icône et menu de la fenêtre) (`fenetre.boutons.gauche`) | `M` | — | Doc basics/titlebar-design : l'icône de l'application, à gauche |
| Boutons à droite (I : réduire, A : agrandir, X : fermer) (`fenetre.boutons.droite`) | `IAX` | — | Doc basics/titlebar-design : réduire, agrandir, fermer |
| Largeur du bouton Fermer, au survol (`fenetre.fermer.largeur`) | 46 px | ± 1 px | Terminal src/cascadia/TerminalApp/MinMaxCloseControl.xaml (copie des boutons de Windows) |
| Hauteur du bouton Fermer, au survol (`fenetre.fermer.hauteur`) | 32 px | ± 1 px | Pleine hauteur de la barre de titre (doc basics/titlebar-design) |
| Couleur du bouton Fermer, au survol (`fenetre.fermer.couleur`) | `#c42b1c` | ± 16 | Terminal src/cascadia/TerminalApp/MinMaxCloseControl.xaml ; doc develop/title-bar |

## Lot 3 — contrôles — **obligatoire**

| Mesure | Cible Windows 11 | Tolérance | Source |
|---|---|---|---|
| Rayon des coins de Kirigami (applications QML) (`kirigami.rayon`) | *relevé* | — | Relevé (Kirigami.Units.cornerRadius) ; Windows : 4 pour les contrôles, 8 pour les volets |
| Hauteur d'un bouton (`controle.bouton.hauteur`) | 32 px | ± 0 px | WinUI CommonStyles/Button_themeresources.xaml : ButtonPadding 11,5,11,6, texte de 14 px, bordure de 1 |
| Rayon des coins d'un bouton (`controle.bouton.rayon`) | 4 px | ± 0.75 px | WinUI CommonStyles/CornerRadius_themeresources.xaml, ControlCornerRadius |
| Hauteur d'un champ de texte (`controle.champ.hauteur`) | 32 px | ± 0 px | WinUI dxaml/xcp/dxaml/themes/generic.xaml, TextControlThemeMinHeight |
| Rayon des coins d'un champ de texte (`controle.champ.rayon`) | 4 px | ± 0.75 px | WinUI CommonStyles/CornerRadius_themeresources.xaml, ControlCornerRadius |
| Hauteur d'une liste déroulante (`controle.liste_deroulante.hauteur`) | 32 px | ± 0 px | WinUI ComboBox/ComboBox_themeresources.xaml, ComboBoxMinHeight |
| Taille d'une case à cocher (`controle.case.taille`) | 20 px | ± 0 px | WinUI CommonStyles/CheckBox_themeresources.xaml, CheckBoxSize |
| Hauteur d'une case à cocher avec son texte (`controle.case.hauteur`) | 32 px | ± 0 px | WinUI CommonStyles/CheckBox_themeresources.xaml, CheckBoxHeight |
| Taille d'un bouton radio (`controle.radio.taille`) | 20 px | ± 0 px | WinUI CommonStyles/RadioButton_themeresources.xaml, OuterEllipse 20×20 |
| Largeur d'un interrupteur (`controle.interrupteur.largeur`) | 40 px | ± 0 px | WinUI CommonStyles/ToggleSwitch_themeresources.xaml, OuterBorder 40×20 |
| Hauteur d'un interrupteur (`controle.interrupteur.hauteur`) | 20 px | ± 0 px | WinUI CommonStyles/ToggleSwitch_themeresources.xaml, OuterBorder 40×20 |
| Poignée d'un curseur (slider) (`controle.curseur.poignee`) | 18 px | ± 0 px | WinUI CommonStyles/Slider_themeresources.xaml, SliderHorizontalThumbWidth |
| Épaisseur de la barre de progression dessinée (sans les marges de 8 px que KDE met au-dessus et au-dessous) (`controle.progression.hauteur`) | 3 px | ± 0 px | WinUI ProgressBar/ProgressBar_themeresources.xaml, ProgressBarMinHeight |
| Largeur d'une barre de défilement (`controle.defilement.largeur`) | 12 px | ± 0 px | WinUI CommonStyles/ScrollBar_themeresources.xaml, ScrollBarSize |
| Hauteur d'un élément de liste (`controle.liste.hauteur`) | 40 px | ± 0 px | WinUI CommonStyles/ListViewItem_themeresources.xaml, ListViewItemMinHeight |
| Hauteur d'un élément de menu (`controle.menu.element.hauteur`) | *relevé* | — | Relevé ; Windows : marges 11,4,11,5 à la souris, 11,8,11,9 au toucher (WinUI CommonStyles/MenuFlyout_themeresources.xaml) |
| Taille du texte des infobulles (`controle.infobulle.px`) | 12 px | ± 0.5 px | WinUI CommonStyles/ToolTip_themeresources.xaml, ToolTipContentThemeFontSize |

## Lot 4 — shell — relevé seulement

| Mesure | Cible Windows 11 | Tolérance | Source |
|---|---|---|---|
| Barre des tâches, sur fond noir (`couleur.barre`) | *relevé* | — | Relevé ; couleurs d'Ankh (D-037) |
| Hauteur de la barre des tâches (réglage) (`barre.hauteur`) | 48 px | ± 0 px | Observée sous Windows 11, sans source publiée (À VALIDER) ; mon choix du 2026-10-14 (D-052) |
| Hauteur visible de la barre des tâches (`barre.hauteur_visible`) | 48 px | ± 1 px | Comme barre.hauteur |
| Barre flottante (`barre.flottante`) | `non` | — | Mon choix du 2026-10-14 : collée, comme Windows 11 (D-052) |
| Espace sous la barre des tâches (`barre.marge_bas`) | 0 px | ± 0 px | Barre collée au bord (D-052) |
| Place de la barre des tâches (`barre.position`) | `bottom` | — | Windows 11 : en bas |
| Date de l'horloge (0 : selon la place, 1 : à côté, 2 : sous l'heure) (`barre.horloge.date`) | `2` | — | Windows 11 : heure et date sur deux lignes (D-052) |
| Rayon des coins du menu de Plasma (volet) (`volet.rayon`) | 8 px | ± 0.75 px | WinUI CommonStyles/CornerRadius_themeresources.xaml, OverlayCornerRadius |
| Place des notifications (`notifications.position`) | `BottomRight` | — | Windows 11 : en bas à droite (D-052) |

## Ce que le banc ne mesure pas

Par honnêteté, et parce que c'est la règle du projet (CLAUDE.md §3.9) : on ne dit pas
« au pixel près » d'une surface que le banc ne mesure pas.

- le **contenu** de l'OSD du volume et la **largeur** des notifications : en dur dans Plasma ;
- les applications **libadwaita**, **Electron**, et **GTK en Flatpak** ;
- les barres de titre dessinées par l'application (Chrome, VS Code) ;
- les mesures de Démarrer et des paramètres rapides tant que les lots 5 et 6 ne sont pas faits ;
- tout ce qui dépend du matériel réel : écrans à haute résolution multiples, VRR, HDR.

Voir [ANKH-DE-SPEC.md §4](../ANKH-DE-SPEC.md#4-ce-qui-nest-pas-atteignable).

# ARCHITECTURE — comment Ankh DE est agencé

## Le principe

Plasma est conçu pour être rhabillé. Ankh DE n'ajoute rien à cette architecture : il remplit
chacun des points d'extension que Plasma expose, et rien d'autre.

```text
┌──────────────────────────────────────────────────────────────────────────┐
│ THÈME GLOBAL  src/lookandfeel/org.ankh.de.desktop                        │
│ C'est l'interrupteur. Son fichier contents/defaults porte TOUS les       │
│ réglages ; son layouts/*.js porte la barre des tâches (en option).       │
│ Rien d'autre n'écrit de configuration (DE-002).                          │
└───────┬──────────────────────────────────────────────────────────────────┘
        │ désigne, par leur nom
        ▼
┌───────────────────────┬──────────────────────┬───────────────────────────┐
│ STYLE DES CONTRÔLES   │ DÉCORATION           │ STYLE PLASMA              │
│ src/style  (C++)      │ src/decoration (C++) │ src/desktoptheme (SVG)    │
│ QStyle Qt 6, dérivé   │ Greffon              │ Volets, barre, infobulles,│
│ de Breeze. Dessine    │ KDecoration3, dérivé │ trait d'accent sous       │
│ aussi les apps KDE en │ de Breeze. Barre de  │ l'app active. Le reste    │
│ QML, qui passent par  │ 32 px, boutons       │ vient de Breeze           │
│ org.kde.desktop       │ 46×32, coins de 8    │ (FallbackTheme).  LOT 4   │
│ (src/qqc2 les adapte) │                      │                           │
│ LOT 3                 │ LOT 2                │                           │
├───────────────────────┼──────────────────────┼───────────────────────────┤
│ COULEURS              │ APPLETS              │ SCRIPTS KWIN              │
│ src/colors (*.colors) │ src/applets (QML)    │ src/kwin (JS)             │
│ Gris de Windows 11    │ Démarrer    LOT 5    │ Dispositions par          │
│ rendus en graphite    │ Param. rapides LOT 6 │ Windows+Z         LOT 7   │
│ d'Ankh, par couches   │ Modules PRIVÉS de    │                           │
│ LOT 1                 │ Plasma : fragile     │                           │
├───────────────────────┴──────────────────────┴───────────────────────────┤
│ PIÈCES VENUES D'AILLEURS  third_party/preparer.sh                        │
│ Selawik (OFL), curseurs et thème GTK Fluent (GPL-3.0), icônes (lot 9).   │
│ Jamais versionnées : récupérées à un commit figé, vérifiées, recolorées  │
│ au violet d'Ankh. Déclarées dans LICENSES/.                              │
├──────────────────────────────────────────────────────────────────────────┤
│ RENDU DES POLICES  src/fontconfig/29-ankh-rendu.conf                     │
│ Niveaux de gris, contours légers. C'est fontconfig qui décide, pas KDE.  │
├──────────────────────────────────────────────────────────────────────────┤
│ BANC DE MESURE  bench/                                                   │
│ 47 jetons, leurs cibles et leurs sources. Mesure la session réelle en VM.│
│ docs/FIDELITE.md en est généré. Un écart sur un lot terminé = CI rouge.  │
└──────────────────────────────────────────────────────────────────────────┘
```

## Pourquoi le thème global, et pas `/etc/xdg`

C'est **la** différence avec Ankh, et c'est ce qui rend le DE installable ailleurs
([DE-002](../DECISIONS.md#de-002--tous-les-réglages-vivent-dans-notre-thème-global-jamais-dans-etcxdg-ni-dans-les-thèmes-de-la-distribution)).

| | Ankh (l'OS) | Ankh DE |
|---|---|---|
| Où vont les réglages | `/etc/xdg/kdeglobals`, `kwinrc`, `kcminputrc`, et **les thèmes globaux de Fedora, modifiés sur place** | le seul fichier `contents/defaults` de notre thème global |
| Marche sur Arch / Ubuntu | non : ces thèmes n'existent pas | oui : le mécanisme est le même partout |
| Droits root | oui | non, pour appliquer le thème |
| Réversible | non | oui : réappliquer Breeze |
| Écrase les réglages de la distribution | oui | non |

Le fichier est lu par `klookandfeelmanager.cpp` (`libklookandfeel` de plasma-workspace). Format :
`[<fichier de configuration>][<groupe>]`.

## Le compromis du code dérivé

`src/style` et `src/decoration` sont des **copies** de Breeze, renommées. Ce n'est pas élégant,
et c'est assumé : le rayon de Breeze est une constante de 5 px (`Frame_FrameRadius` dans
`kdecoration/breeze.h` et `kstyle/breezemetrics.h`), ses boutons de fenêtre sont ronds, ses barres
de défilement font 21 px. Aucun réglage n'y change rien. Les seules voies étaient de reprendre le
code, ou d'accepter l'allure de KDE.

**Le prix** : il faut reporter nos changements à chaque version de Plasma
([DE-008](../DECISIONS.md#de-008--le-code-dérivé-de-kde-est-reporté-à-chaque-version-de-plasma-et-la-construction-échoue-tant-que-ce-nest-pas-fait),
[docs/REBASE.md](REBASE.md)). C'est le coût récurrent du projet, et c'est ce qui tue les thèmes à
mainteneur unique. D'où la règle CLAUDE.md §3.13 : **rester le plus proche possible de
l'original**, et ne jamais modifier le code pour du confort qui n'atteint pas une mesure du banc.

## Rapport avec Ankh

[Ankh](https://github.com/PatrickChoumi/Ankh) est un OS personnel immuable (Fedora Atomic + bootc),
non public. Ankh DE est né de son chantier interface **D-052** et vit maintenant à part
([DE-009](../DECISIONS.md#de-009--ankh-de-et-ankh-restent-deux-dépôts-séparés--ankh-consommera-ankh-de-plus-tard)).

**Aujourd'hui** : le code interface existe des deux côtés. Ankh DE est la source de vérité ; Ankh
garde sa copie tant que ses lots en cours ne sont pas fusionnés. Toute correction doit être
portée deux fois — c'est un coût réel, voulu, mais qui ne doit pas durer.

**Plus tard** : le `Containerfile` d'Ankh récupérera Ankh DE à un commit figé, à la place de
`build_files/style`, `build_files/decoration`, `build_files/qqc2` et `build_files/interface`. Ankh
gardera ce qui lui est propre : ses fonds d'écran, son écran de démarrage, son écran de connexion,
son assistant, ses options d'installation. Cela demandera une décision D-055 dans Ankh.

**Ankh DE n'a pas besoin d'Ankh.** Il ne suppose ni bootc, ni Fedora, ni image immuable, et
n'installe aucune application.

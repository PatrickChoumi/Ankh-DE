# AUDIT DE SIMPLIFICATION — garder, configurer le natif, ou supprimer

> Demandé le **2026-11-07** par le propriétaire du projet, en ces termes : *« pour chaque
> composant actuel, déterminer s'il faut le garder, le remplacer par un composant Plasma natif,
> le configurer ou le supprimer »*. Appliqué le même jour : [DE-015](../DECISIONS.md) et
> [DE-016](../DECISIONS.md).
>
> Code audité : `6e78a61`, branche `simplification-plasma-6.6`.

## Le constat qui décide de tout

Le projet a dérivé de *« prendre KDE et changer son apparence »* vers *« développer des
composants »*. Le relevé le montre sans discussion. Au 2026-11-07, la barre portait **huit**
applets qui ne sont pas de Plasma. **Un seul** avait été prouvé interactif.

| | Composants | Prouvés interactifs |
|---|---|---|
| Couche d'identité (style, décoration, couleurs, police, icônes, curseurs, fond) | 7 | **mesurés** : 27 jetons conformes |
| Applets de la barre, repris d'ailleurs | 8 | **1** (`org.ankh.demarrer`) |

Autrement dit : **tout ce qui marche est l'habillage, et tout ce qui ne marchait pas était du
composant importé.** Ce n'est pas une coïncidence, c'est le coût de la confusion entre
« personnalisation visuelle » et « réécriture fonctionnelle ».

### Et une régression, pas seulement un manque

Le plus coûteux n'était pas qu'`org.ankh.etat` fût non éprouvé. C'est que pour lui faire place,
`org.kde.plasma.desktop-layout.js` **masquait** les cinq applets natives de la zone système :

```js
zone.writeConfig("hiddenItems", [
    "org.kde.plasma.networkmanagement", "org.kde.plasma.bluetooth",
    "org.kde.plasma.brightness", "org.kde.plasma.volume",
    "org.kde.plasma.notifications" ])
```

Ankh DE **retirait donc le réglage du volume, du Wi-Fi, du Bluetooth et de la luminosité** pour
les remplacer par un volet qui pilotait le matériel par `wpctl`, `nmcli`, `rfkill` et
`bluetoothctl`, et dont aucune tuile n'avait jamais été pressée. Ce n'était pas une fonction
manquante : c'était **moins bien que Plasma nu**.

---

## Le verdict, composant par composant

Quatre verdicts : **GARDER** (c'est l'identité d'Ankh, et c'est mesuré) · **CONFIGURER LE
NATIF** (Plasma le fait, on l'habille) · **SUPPRIMER** · **DEFER** (hors de 0.1).

### Ce qui est GARDÉ — l'identité, et elle est mesurée

| Composant | Pourquoi il reste |
|---|---|
| **Style Qt** `org.ankh.style` (dérivé de Breeze) | Aucun réglage de Plasma ne donne les rayons de 4 et 8 px, les contrôles de 32 px et les barres de défilement fines de WinUI. **12 jetons mesurés et conformes** |
| **Décoration** `org.ankh.decoration` (KDecoration3) | Barre de titre de 32 px, boutons 46×32, `#C42B1C` au survol du bouton Fermer. Aucune décoration native ne s'en approche. **6 jetons mesurés** |
| **Style Plasma** `ankh` / `ankh-clair` | C'est lui qui habille TOUTES les applets natives : le trait d'accent sous l'application active, le verre de la barre, les 168 SVG |
| **Couleurs** `Ankh` / `AnkhClair`, **Selawik**, **icônes** `Fluent-Ankh`, **curseurs**, **thème GTK** | L'identité graphique même. Rien à réutiliser : c'est le produit |
| **Fond d'écran** `Ankh-Prismes` | Porte l'accent violet dont dépend DE-004 |
| **Menu Démarrer** `org.ankh.demarrer` | **Le seul applet prouvé interactif** : il s'ouvre, prend le clavier sans clic, cherche, se referme sur Échap (`09e4950`). Kickoff n'a pas la disposition de Windows 11 — il reste le repli, jamais le parallèle |
| **La session** `ankh-de.desktop` | Porte ce que le thème global ne sait pas porter (DE-010) |

### Ce qui passe au NATIF — huit composants

| Retiré | Natif qui le remplace | Ce que le natif apporte en plus |
|---|---|---|
| `org.ankh.etat` (paramètres rapides) | `org.kde.plasma.{volume,networkmanagement,bluetooth,brightness}`, **démasquées** | les invites de mot de passe Wi-Fi, les touches multimédia du clavier, le réglage de luminosité — tout ce que le masquage coupait |
| `org.ankh.notifications` | `org.kde.plasma.notifications` | c'est l'interface du service de notifications de Plasma, pas une seconde interface posée devant |
| `org.ankh.taches` | `org.kde.plasma.icontasks` | groupement par programme, aperçus au survol, listes de sauts, glisser-déposer, indicateur audio. Ses défauts SONT ceux de Windows 11 : `groupingStrategy=1`, `minimizeActiveTaskOnClick=true` |
| `org.ankh.horloge` | `org.kde.plasma.digitalclock`, `dateDisplayFormat=BelowTime` | un calendrier, un agenda, les fuseaux horaires |
| `org.ankh.bureau` | `org.kde.plasma.showdesktop` | — (la pièce reprise ne faisait rien de plus) |
| `org.ankh.separateur` | `org.kde.plasma.panelspacer`, `expanding=false`, `length=9` | les 9 px exacts, par une clé **en pixels** |
| `ankh-selecteur` (Alt+Tab) | `thumbnail_grid`, livré par **KWin lui-même** | une grille de grandes vignettes — la forme de l'Alt+Tab de Windows 11 — mise à jour avec KWin |
| module QML partagé `ankh-de/qml` | *(rien)* | il n'existait que pour les applets ci-dessus |

### DEFER — hors de 0.1

| Composant | Décision |
|---|---|
| `org.ankh.vuetaches` (bouton Vue des tâches) | **Supprimé de 0.1.** Jamais prouvé, et son rôle face à l'effet Overview de KWin n'était pas établi : un bouton qui réimplémente un effet natif est le doublon qu'on refuse. La vue d'ensemble reste sur **Meta+W** (natif). Le bouton revient quand un essai prouvera qu'il appelle l'effet plutôt que de le refaire |

### Ce que Plasma fait, et qu'on n'a jamais touché

Réseau (NetworkManager), Bluetooth (BlueZ), audio (PipeWire), énergie et luminosité (PowerDevil),
recherche (KRunner), bureaux virtuels et pavage (KWin), effet Overview, verrouillage
(KScreenLocker), connexion (SDDM), fichiers (Dolphin), réglages (System Settings), terminal
(Konsole), capture (Spectacle), logithèque (Discover). **Aucun n'est remplacé ; tous sont
habillés.**

---

## Deux imports reposaient sur une valeur fausse

C'est la découverte la plus instructive de cet audit, et elle dit *pourquoi* la dérive a eu lieu.

| Ce que le dépôt affirmait | Ce que la source dit |
|---|---|
| « `BesideTime` met la date À CÔTÉ de l'heure, et c'est le mieux que son schéma propose » — et le commentaire se notait lui-même *« à revérifier »* | `applets/digital-clock/main.xml` de plasma-workspace : `dateDisplayFormat` offre **`BelowTime`**. L'horloge native met la date **sous** l'heure, exactement comme Windows 11 |
| « la clé `iconSpacing` d'icontasks est une énumération, pas des pixels » | `applets/taskmanager/main.xml` de plasma-desktop : `<entry name="iconSpacing" type="Int">`, défaut 1 |

**Deux applets ont été importés pour contourner des limites qui n'existaient pas.** La règle qui
en découle est dans `CLAUDE.md` §0.1 : *avant d'importer, ouvrir le `main.xml` de l'applet
natif.*

Et un piège évité par le même réflexe : `org.kde.plasma.marginsseparator` aurait été plus propre
que le `panelspacer` pour l'écart de 9 px — mais il **n'existe pas en Plasma 6.6** (404 sur la
branche `Plasma/6.6` de plasma-workspace, 200 sur `Plasma/6.8`), et 6.6 est la cible.

---

## Ce que la simplification coûte, et ce qu'elle rapporte

**Elle coûte** peu, et il faut le dire honnêtement :

- le bouton **Vue des tâches** disparaît de la barre (Meta+W le remplace) ;
- les paramètres rapides ne sont plus **un seul volet** comme dans Windows 11, mais quatre icônes
  dans la zone de notification. C'est le vrai écart de fidélité de cette décision, et il est
  assumé : quatre icônes qui marchent valent mieux qu'un volet qui ne répond pas.

**Elle rapporte** :

- **141 lignes** retirées de `third_party/preparer.sh`, et une dépendance réseau de moins ;
- **huit pièces de moins** à reporter à chaque version de Plasma (`CLAUDE.md` §3.13) ;
- le volume, le Wi-Fi, le Bluetooth et la luminosité **reviennent** ;
- un calendrier, un agenda, les fuseaux, les aperçus de fenêtres, les listes de sauts et
  l'indicateur audio **arrivent** sans une ligne écrite ;
- le risque du lot 6 — *« le plus fragile, trois modules privés, aucun appui amont »* — **n'existe
  plus** : il n'y a plus de lot 6 à écrire.

## Le rapport de réutilisation

L'objectif demandé était **80 % de réutilisation, 20 % de développement propre à Ankh**, comme
objectif de gestion de projet et non comme mesure du code. Après DE-015, par responsabilité :

| | Avant | Après |
|---|---|---|
| Responsabilités tenues par du natif configuré | 4 | **12** |
| Responsabilités tenues par un composant repris et adapté | 9 | **1** (Démarrer) |
| Responsabilités tenues par du code écrit ici | 2 (style, décoration) | 2 (style, décoration) |

## Ce qui reste à prouver

Cette décision **n'est pas validée** tant que la VM ne l'a pas confirmée. Dans l'ordre :

1. que la décoration **se charge** dans un vrai KWin **6.6** — compiler et se lier proprement est
   déjà acquis (`42392981929`), se charger ne l'est pas ;
2. que Démarrer **lance** réellement une application (Entrée après recherche) ;
3. que les tuiles natives répondent, et que la zone système ne masque plus rien de vital ;
4. que le désinstallateur ramène à Plasma standard, éprouvé en VM de bout en bout.

Tant qu'un de ces points manque, l'état s'écrit `PARTIEL`, jamais `FINI` (`CLAUDE.md` §0.2).

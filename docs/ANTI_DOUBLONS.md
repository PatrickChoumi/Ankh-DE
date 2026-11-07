# ANTI-DOUBLONS — ce qui existe déjà, et l'état fonctionnel d'Ankh DE

> **Ce fichier est la SOURCE UNIQUE de l'état fonctionnel.** README, ROADMAP, CLAUDE.md et
> AVANCEMENT ne doivent pas redire ce que telle interaction prouve : ils renvoient ici.
>
> La raison est un défaut constaté le 2026-11-07 : cinq documents portaient cinq états
> différents du menu Démarrer — le README le disait interactif, la ROADMAP disait l'inverse,
> AVANCEMENT disait qu'aucune interaction n'était testée. Chacun était vrai à sa date, et faux
> au présent. `ci/verifier-coherence.sh` compare désormais le SHA déclaré ci-dessous à celui que
> les autres documents citent.

<!-- PREUVE-COURANTE : ne pas modifier le format, ci/verifier-coherence.sh le lit -->
| | |
|---|---|
| **SHA des preuves d'interaction** | `09e4950` |
| **Passage** | `VM — session réelle`, 2026-11-07 |
| **Session** | Fedora 44, Plasma 6.8.2, Wayland, VM neuve, installée par `installer.sh`, ouverte depuis SDDM |
| **Code audité** | `6e78a61`, branche `simplification-plasma-6.6` |

### Ce que la cible Ubuntu a déjà établi

Passage `42397366933` du 2026-11-07, job **Ubuntu 26.04 — la cible**. Ce passage s'est conclu en
**échec**, et il faut le dire avant tout le reste : la cause était un défaut de MON harnais —
`plasmashell --version` ne rend rien lancé par ssh sans affichage, la ligne du rapport est restée
vide, et le contrôle des lignes vides a refusé le passage. Ce défaut n'a aucun rapport avec Ankh
DE. Les faits ci-dessous sont lus dans le journal du même passage, avant l'arrêt :

| Sur Ubuntu 26.04.1 LTS, Plasma 6.6 | |
|---|---|
| `installer.sh` | **réussit** — ce qui était impossible avant [DE-016](../DECISIONS.md) : le CMake exigeait 6.8 et sortait en `FATAL_ERROR` |
| La session | **s'ouvre** depuis SDDM : `DESKTOP_SESSION=ankh-de`, `XDG_CURRENT_DESKTOP=KDE`, type `wayland`, `ANKH_DE_SESSION=1` |
| Le compositeur | **dessine** : écart-type 38,1 sur 256 couleurs |
| Les réglages | **tous appliqués** : style `Ankh`, couleurs `Ankh`, `Selawik 10.5`, `org.ankh.decoration`, icônes `Fluent-Ankh`, style Plasma `ankh`, `LookAndFeelPackage=org.ankh.de.desktop`, Selawik vue par fontconfig |

Que le style `Ankh` soit **appliqué** veut dire que le greffon QStyle compilé contre KF 6.24 /
Qt 6.10 est celui que la session emploie. Ce qui reste non établi sur 6.6 : que le greffon de
**décoration** se charge dans KWin — la clé est écrite, et c'est tout ce qu'on sait. Les
vérifications clé par clé (étape 8) n'ont pas tourné, puisque le passage s'est arrêté avant.

> **Le code audité et le SHA des preuves DIFFÈRENT, et il faut le dire.** `6e78a61` retire huit
> applets repris au profit des applets natives de Plasma ([DE-015](../DECISIONS.md)) et porte la
> cible à Plasma 6.6 ([DE-016](../DECISIONS.md)). Ses propres preuves ne sont pas encore
> rendues : le tableau ci-dessous dit donc, pour chaque responsabilité, ce qui est établi **sur
> `09e4950`** et ce qui est seulement **attendu** sur `6e78a61`. Tant qu'un passage n'a pas
> tourné, « attendu » n'est pas « prouvé ».

## Comment lire ce document

Cinq états, et les confondre est l'erreur la plus coûteuse de ce projet :

| État | Ce qu'il veut dire | Ce qu'il NE prouve PAS |
|---|---|---|
| **présent** | les fichiers sont dans le dépôt | qu'ils sont installés |
| **installé** | `cmake --install` les a posés | qu'un applet est dans la barre |
| **chargé** | `plasmashell` l'a instancié dans le panneau | qu'il répond |
| **interactif** | une action a été déclenchée ET observée | qu'elle est juste |
| **validé** | mesuré ou comparé à sa cible | — |

Une compilation ne prouve pas qu'un greffon est chargé. Un applet installé ne prouve pas qu'il
est dans la barre. Une capture ne prouve pas qu'un bouton répond.

---

## 1. Qui tient quoi, et dans quel état

Depuis [DE-015](../DECISIONS.md) (2026-11-07), **une seule pièce de la barre nous appartient** :
le menu Démarrer. Les huit autres responsabilités sont tenues par les applets natives de Plasma,
habillées par notre style Plasma, nos couleurs et nos icônes. L'audit complet, avec le verdict
composant par composant, est dans [docs/SIMPLIFICATION.md](SIMPLIFICATION.md).

| Responsabilité | Implémentation **active** | Origine | État |
|---|---|---|---|
| Lanceur | `org.ankh.demarrer` | KDE-Windows-Modern `7ef6bfe` | **interactif** sur `09e4950` : s'ouvre, prend le clavier sans clic, cherche, se ferme sur Échap. **Le lancement réel d'une application reste attendu** |
| Gestionnaire de tâches | `org.kde.plasma.icontasks` | **natif** | attendu : chargé et interactif (deux clics, minimise puis rétablit) |
| Vue des tâches | *aucun bouton* — effet Overview de KWin sur Meta+W | **natif** | DEFER hors de 0.1 ([DE-015](../DECISIONS.md)) |
| Hôte de zone système | `org.kde.plasma.systemtray` | **natif** | attendu : chargé, et ne masquant **que** la cloche |
| Réseau, Bluetooth, volume, luminosité | `org.kde.plasma.{networkmanagement,bluetooth,volume,brightness}` | **natif** | attendu : **visibles**. Elles étaient MASQUÉES jusqu'au 2026-11-07 |
| Notifications (interface) | `org.kde.plasma.notifications` | **natif** | attendu : chargé, posé à droite de l'horloge |
| Notifications (service) | daemon de Plasma | natif | **aucun second service** |
| Horloge et calendrier | `org.kde.plasma.digitalclock`, `dateDisplayFormat=BelowTime` | **natif** | attendu : chargé, date sous l'heure. **Calendrier non essayé** |
| Afficher le bureau | `org.kde.plasma.showdesktop` | **natif** | attendu : chargé. **Restauration des fenêtres non essayée** |
| Écart de 9 px | `org.kde.plasma.panelspacer`, `expanding=false`, `length=9` | **natif** | attendu : chargé |
| Alt+Tab | `thumbnail_grid` | **natif (KWin)** | **jamais montré à l'écran.** Les trois passages qui l'ont tenté n'avaient pas de seconde fenêtre |
| Fond d'écran | `Ankh-Prismes` | AnduinOS `c659fae` | installé **et posé** sur `09e4950` |
| Style des contrôles | `org.ankh.style` | Breeze `ca217f1` | **validé** : 12 jetons conformes |
| Décoration des fenêtres | `org.ankh.decoration` | Breeze `ca217f1` | **validé** : 6 jetons sur 11. Se **charge** dans KWin 6.8 ; dans KWin **6.6**, non établi |
| Verrouillage | KScreenLocker | natif | **jamais essayé** |

**Un seul de chaque.** Aucune responsabilité n'a deux implémentations actives.

## 2. Les doublons que l'on évite, et pourquoi

| Doublon possible | Ce qu'on garde | Ce qu'on refuse, et la raison |
|---|---|---|
| Menu : Ankh / Kickoff / Tidewater `start` / menu-11-next | `org.ankh.demarrer` | Kickoff reste le **repli** si notre applet manque, jamais en parallèle. Tidewater `start` **non repris**. menu-11-next : **STUDY ONLY**, pas de fichier `LICENSE` à sa racine |
| Tâches : Tidewater `tasks` / Task Manager Plasma / KWM `icontasks` | `org.ankh.taches` | `icontasks` porte **`org.kde.plasma.icontasks`**, l'identifiant de l'applet standard : le reprendre l'écraserait. Plus 11 fichiers C++, 4 429 lignes. **Refusé** |
| Zone système : Plasma / fork KWM / Tidewater `status` | conteneur **natif** de Plasma | Le fork de KWM fait 40 fichiers C++ et 6 585 lignes et **remplace un conteneur système**. Refusé. `org.ankh.etat` ne le remplace pas : il l'accompagne |
| Paramètres rapides : Tidewater `status` / quicksettings-plasma / Material | `org.ankh.etat` | quicksettings-plasma : **STUDY ONLY** (pas de `LICENSE`). Material : doublon |
| Notifications : interface / daemon | interface seule | Le daemon reste celui de Plasma. **Un seul service** |
| Horloge : KWM / Tidewater `clock` / calendrier Plasma | `org.ankh.horloge` | Tidewater `clock` **non repris** |
| Alt+Tab : Tidewater / natif KWin | `ankh-selecteur` | `kwinrc` n'en désigne qu'un |
| Recherche : KRunner / Tidewater `search` / menu | celle du menu + KRunner | Tidewater `search` **non repris**. Pas d'indexeur maison |
| Aperçu : `taskview` / effet Overview de KWin | `org.ankh.vuetaches` | **Rôle à clarifier** : notre applet est un bouton, l'effet Overview est natif. À vérifier qu'il l'appelle plutôt que de le réimplémenter |
| Style Qt : QStyle d'Ankh / Kvantum | QStyle d'Ankh | Pas de second moteur |
| Décoration : KDecoration3 d'Ankh / Aurorae / ELEVEN | la nôtre | Pas de second greffon de fenêtre |

---

## 3. Ce que Plasma fait déjà, et qu'on ne réécrit pas

Réseau (NetworkManager), Bluetooth (BlueZ), audio (PipeWire), énergie et luminosité
(PowerDevil), recherche (KRunner), bureaux virtuels et pavage (KWin), effet Overview (KWin),
verrouillage (KScreenLocker), connexion (SDDM), fichiers (Dolphin), réglages (System Settings),
terminal (Konsole), capture (Spectacle), logithèque (Discover).

Notre volet d'état **pilote** ces services, il ne les double pas — mais par des **commandes**
(`wpctl`, `nmcli`, `rfkill`, `bluetoothctl`, `busctl`) et non par leurs modèles QML, parce que
c'est ainsi que Tidewater est écrit. L'installateur nomme les cinq outils manquants ; aucun
n'est bloquant.

> **Point à trancher plus tard** : passer aux modèles KDE serait plus robuste qu'un appel de
> commande, mais c'est une réécriture. Rien ne le justifie tant que les tuiles n'ont pas été
> essayées — et elles ne l'ont pas été.

---

## 4. Ce qui est vraiment absent

| Manque | Stratégie | Pourquoi pas autrement |
|---|---|---|
| Interactions jamais déclenchées (menu, tuiles, Alt+Tab, notifications) | **aucune reprise** — c'est du test, pas du code | Le harnais ne sait pas encore cliquer |
| 5 jetons du lot 2 (rayon des coins, bouton Fermer, alignement du titre) | mesure | `ScreenShot2` fait tomber KWin sur le backend virtuel |
| Grille 6 × 3 d'épingles et section « Recommandé » du menu | **ADAPT** `org.ankh.demarrer` | C'est de la conception sur un applet déjà repris, pas un import |
| Échelles 125 % et 150 %, multi-écran | test | — |
| Session sur Arch et Ubuntu | test | La construction passe, l'installation et la session non |
| Paquets Arch et Debian | packaging | Le RPM construit ; les deux autres sont des squelettes |

Rien dans cette liste ne demande d'importer un nouveau dépôt.

---

## 5. Ce que la réutilisation a évité d'écrire

| Repris | Au lieu d'écrire | Gain |
|---|---|---|
| QStyle et décoration, de Breeze `ca217f1` | un moteur de style Qt et un greffon KDecoration3 | des mois |
| Menu, horloge, « Afficher le bureau », thème Plasma, de KWM `7ef6bfe` | quatre applets QML et 168 SVG par thème | des semaines |
| Tâches, vue, état, notifications, séparateur, Alt+Tab, de Tidewater `4484377` | six composants QML, dont un volet système | des semaines, **sans une ligne de C++** |
| Icônes, curseurs, thème GTK, de vinceliuice | trois jeux complets | des mois |
| Police Selawik, de Microsoft (OFL) | un sosie de Segoe UI | — |
| Fond d'écran, d'AnduinOS `c659fae` | un fond original — **trois essais ratés avant d'y renoncer** | une journée perdue, et la leçon |

---

## 6. Ce qui reste à prouver — par ordre de coût

**P0 — levé le 2026-11-07 pour le menu.** Le harnais clique et tape désormais (QEMU
`input-send-event`). Le menu est **interactif** : il prend le clavier sans clic, cherche, et se
ferme sur Échap. Un clic sur la zone de droite ouvre un panneau — mais le repérage rend une
abscisse, pas un identifiant, donc **on ne sait pas lequel des applets a répondu**.

**P0 — reste entier pour les tuiles.** Wi-Fi, Bluetooth, volume, luminosité : aucune n'a été
pressée nommément. Notifications : jamais déclenchées. Alt+Tab : le sélecteur est installé et
désigné, mais l'essai n'a encore jamais eu deux fenêtres à lui montrer.

**P1.** Le rôle de `org.ankh.vuetaches` face à l'effet Overview natif n'est pas établi.

**P1.** Le désinstallateur restaure les barres (éprouvé hors session par `tests/barres.sh`),
mais le tour complet n'a jamais tourné dans une VM.

**P2.** Les cinq jetons du lot 2, les échelles, Arch et Ubuntu.

> **Jalon du 2026-11-07** : sur `fbe7f47`, **Construire, Banc et VM passent tous les trois sur
> le même SHA**, et les **9 jetons du lot 4** sont mesurés et conformes — dont les deux qui
> avaient été relevés faux. Total : **27 sur 53**. C'est la première fois que la définition de
> « pré-version stabilisée » est tenue sur les points 1, 2, 5 et 8 ; les points 3, 4, 6 et 7
> restent ouverts, et le point 3 (« le menu identifié sans ambiguïté ») l'est au sens
> interactif.

---

## 7. Tenue de ce document

Il est écrit à la main et daté. Il ne remplace ni [docs/UPSTREAMS.md](UPSTREAMS.md), qui porte
la provenance et les licences pièce par pièce, ni [AVANCEMENT.md](../AVANCEMENT.md), qui est le
journal. Quand une interaction est enfin testée, c'est ici que son état change — et dans le
même commit que la preuve.

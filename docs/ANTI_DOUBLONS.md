# ANTI-DOUBLONS — ce qui existe déjà, et ce qu'il ne faut pas réécrire

> Phase A de [docs/consignes/ANTI-DOUBLONS.md](consignes/ANTI-DOUBLONS.md).
> **Code audité : `c0ac092`**, branche `main`, 42 commits, local = `origin/main`.
>
> **Les preuves de session viennent d'un AUTRE SHA, et il faut le dire** : du passage en VM sur
> `e546e34` (2026-11-07), le dernier dont le rapport soit complet. Les commits suivants
> (`fbe7f47`, `c0ac092`) ne touchent **aucun applet** — ils corrigent le harnais de mesure et
> ajoutent des documents — mais tant que les trois workflows n'ont pas passé sur un seul et
> même SHA, ce document ne peut pas prétendre le contraire.
>
> Session de référence : **Fedora 44, Plasma 6.8.2, Wayland**, VM neuve, installée par
> `installer.sh` et ouverte depuis SDDM. 59 vérifications clé par clé passées dedans.

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

## 1. Ce qui est chargé dans la session, et par quoi

Relevé par `evaluateScript` sur `plasmashell`, dans l'ordre réel du panneau
(passage en VM sur `e546e34`) :

```
org.kde.plasma.panelspacer, org.ankh.demarrer, org.ankh.vuetaches, org.ankh.taches,
org.kde.plasma.panelspacer, org.kde.plasma.systemtray, org.ankh.separateur,
org.ankh.etat, org.ankh.horloge, org.ankh.notifications, org.ankh.bureau
```

| Responsabilité | Implémentation **active** | Origine | État |
|---|---|---|---|
| Lanceur | `org.ankh.demarrer` | KDE-Windows-Modern `7ef6bfe` | chargé ; **s'ouvre** (3 preuves) ; **non interactif** |
| Gestionnaire de tâches | `org.ankh.taches` | Tidewater `4484377` | chargé ; **non interactif** |
| Vue des tâches | `org.ankh.vuetaches` | Tidewater `4484377` | chargé ; **non interactif** |
| Hôte de zone système | `org.kde.plasma.systemtray` — **celui de Plasma** | natif | chargé ; repli assumé |
| Paramètres rapides | `org.ankh.etat` | Tidewater `4484377` | chargé ; **non interactif** |
| Notifications (interface) | `org.ankh.notifications` | Tidewater `4484377` | chargé ; **non interactif** |
| Notifications (service) | daemon de Plasma | natif | **aucun second service** — vérifié : notre applet est une interface |
| Horloge et calendrier | `org.ankh.horloge` | KDE-Windows-Modern `7ef6bfe` | chargé ; calendrier **non vérifié** |
| Afficher le bureau | `org.ankh.bureau` | KDE-Windows-Modern `7ef6bfe` | chargé ; **non interactif** |
| Séparateur | `org.ankh.separateur` | Tidewater `4484377` | chargé ; espacement **non mesuré** |
| Alt+Tab | `ankh-selecteur` | Tidewater `4484377` | installé et **désigné** par `kwinrc` ; **jamais déclenché** |
| Fond d'écran | `Ankh-Prismes` | AnduinOS `c659fae` | installé **et posé** |

**Un seul de chaque.** Aucune responsabilité n'a deux implémentations actives.

---

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

**P0.** Aucune interaction n'est testée. Le harnais observe la présence et l'ouverture, jamais
une réponse. C'est le plus gros écart entre ce que le dépôt montre et ce qu'il prouve.

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

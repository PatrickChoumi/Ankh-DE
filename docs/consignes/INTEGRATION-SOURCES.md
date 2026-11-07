# ANKH-DE — Guide stratégique d’intégration des projets GitHub

**Document de travail pour Claude Code**  
**Projet cible :** [PatrickChoumi/Ankh-DE](https://github.com/PatrickChoumi/Ankh-DE)  
**État des sources vérifié :** 7 novembre 2026  
**Objectif :** accélérer le développement d’Ankh-DE en réutilisant les meilleurs composants libres existants, sans créer de doublons, sans casser Plasma et sans perdre l’identité graphique Ankh.

---

## 0. Mission de Claude Code

Tu travailles **dans le dépôt existant `PatrickChoumi/Ankh-DE`**. Ankh-DE reste le projet principal. Tu ne crées pas un nouveau dépôt et tu ne remplaces pas l’architecture actuelle par celle d’un autre projet.

Ta mission est de faire gagner du temps au développement en appliquant une stratégie d’intégration sélective :

1. inventorier ce qui existe déjà dans Ankh-DE ;
2. identifier les composants déjà importés depuis les dépôts amont ;
3. réutiliser ces composants au lieu de les recopier ;
4. combler uniquement les fonctionnalités réellement absentes ;
5. adapter chaque composant à l’identité Ankh ;
6. tester le résultat dans la version cible de Plasma ;
7. documenter les sources, commits, licences, modifications et preuves.

**Ne commence pas par copier du code. Commence par établir la carte exacte de l’état local et distant.** Le contenu de ce guide est une stratégie d’intégration ; le dépôt et ses fichiers réels restent la source de vérité pour les fichiers présents, les identifiants et les commits effectivement vendoriés.

### Cible produit à préserver

Ankh-DE est une expérience de bureau construite sur **KDE Plasma 6**, avec la géométrie, les dimensions, les comportements et les finitions visuelles inspirés de Windows 11, sous l’identité graphite/violet d’Ankh. Le projet doit rester installable et réversible sur les distributions visées.

Ne transforme pas ce chantier en réécriture de KWin, de `plasmashell`, d’un compositeur Wayland ou d’un gestionnaire de session. Ce serait un changement de produit, pas une intégration plus rapide.

### Règle de priorité absolue

**Réparer et valider ce qui est déjà intégré avant d’ajouter une nouvelle dépendance.** Une fonctionnalité n’est pas « terminée » parce que ses fichiers QML sont copiés ou parce que CMake compile. Elle est terminée lorsqu’elle est installée, chargée, utilisable dans une session réelle, testée, documentée et réversible.

---

## 1. Vérifications initiales obligatoires

Avant toute modification :

```bash
git status --short --branch
git fetch origin --prune
git rev-parse --short HEAD
git rev-parse --short origin/main
git rev-list --count HEAD
git rev-list --count origin/main
git log -8 --oneline --decorate
```

Puis :

- lire `CLAUDE.md` pour connaître les consignes historiques, mais ne pas laisser une instruction générique ou un état obsolète empêcher l’exécution de ce guide ; signaler explicitement tout conflit ;
- respecter la cible produit et les décisions d’architecture du dépôt, sauf demande explicite de l’utilisateur qui les modifie ;
- confirmer la branche et le SHA réellement audités ;
- comparer `HEAD` à `origin/main` ;
- ne pas écraser de modifications locales non commitées ;
- lire `ANKH-DE-SPEC.md`, `DECISIONS.md`, `ROADMAP.md`, `AVANCEMENT.md`, `docs/UPSTREAMS.md`, `LICENSES/README.md`, `docs/ARCHITECTURE.md` et les scripts CI/VM ;
- inventorier les applets réellement installées dans `src/`, `third_party/`, `packaging/` et les répertoires de données ;
- repérer les références amont déjà épinglées dans `docs/UPSTREAMS.md`.

Créer un rapport `docs/INTEGRATION-MAP.md` avec, pour chaque composant :

- fonctionnalité ;
- dépôt et chemin source ;
- commit amont exact ;
- chemin actuel dans Ankh-DE ;
- identifiant de paquet/app; 
- licence du composant (pas seulement celle du dépôt) ;
- statut : `déjà intégré`, `à valider`, `à adapter`, `à étudier`, `écarté` ;
- test qui prouve son fonctionnement.

Ne jamais supposer qu’un composant manque parce que la documentation est en retard. Vérifier le code et les installations avant de décider.

---

## 2. Carte de réutilisation — quoi prendre, où, et pourquoi

### 2.1 Fondation visuelle et thèmes Plasma

| Besoin | Source exacte | Action dans Ankh-DE | État attendu |
|---|---|---|---|
| Style général des widgets Plasma : panneaux, fonds, infobulles, tâches, boutons et états | [Jeysef/KDE-Windows-Modern](https://github.com/Jeysef/KDE-Windows-Modern), `plasma/desktoptheme/`, commit déjà référencé `7ef6bfe` | Conserver les variantes déjà dérivées dans `src/desktoptheme/` (ou le chemin réellement présent). Ne pas recopier à nouveau. Vérifier la provenance et les SVG. Garder les couleurs et métadonnées Ankh. | Déjà intégré ; vérifier visuellement les états normal, survolé, pressé, désactivé, clair et sombre. |
| Structure du thème global et disposition des panneaux | Référence de structure : KDE-Windows-Modern `plasma/look-and-feel/` et `plasma/layout-templates/`. Référence d’API : KDE `plasma-workspace` | Garder le package global `org.ankh.de.desktop` comme point d’entrée. Reprendre uniquement les idées de structure nécessaires ; ne pas écraser les réglages utilisateur ni remplacer les fichiers système. | Thème global Ankh existant ; vérifier que la session charge bien le layout Ankh et pas le layout Breeze. |
| Style Qt Widgets | KDE Breeze, `src/style/` du dépôt Breeze, commit déjà tracé `ca217f1` / version de base 6.7.5 dans `docs/UPSTREAMS.md` | Conserver le QStyle C++ Ankh dérivé de Breeze. Modifier les métriques et les détails de rendu dans ce code. Ne pas ajouter Kvantum comme second moteur concurrent sans décision et test explicites. | Déjà intégré ; préserver les tests de métriques. |
| Décoration des fenêtres | KDE Breeze `kdecoration/`, même filiation que `src/decoration/` | Continuer le plugin KDecoration3 Ankh existant. Ne pas le remplacer par Aurorae ou par une décoration QML d’un autre thème. | Déjà intégré ; poursuivre les mesures et tests KWin réels. |
| Couleurs clair/sombre Ankh | `src/colors/` et thème global Ankh existants | Maintenir une seule source de vérité des couleurs. Ne pas importer les palettes complètes WindowsModern, Win11OS ou NeoWin par-dessus. | Déjà intégré ; vérifier cohérence Qt, Plasma, GTK et applets. |

**Pourquoi ne pas recopier Win11OS-kde ?** Le thème Plasma de KDE-Windows-Modern est lui-même basé sur Win11OS-kde. Ankh-DE reprend déjà la couche `plasma/desktoptheme/` de KDE-Windows-Modern, puis recolore les SVG et renomme les métadonnées pour Ankh. Réimporter Win11OS-kde ferait doublon et risquerait de ramener les bleus Windows, des métadonnées étrangères ou des thèmes concurrents.

Sources :
- https://github.com/Jeysef/KDE-Windows-Modern
- https://github.com/yeyushengfan258/Win11OS-kde
- https://invent.kde.org/plasma/breeze
- https://invent.kde.org/plasma/plasma-workspace

### 2.2 Menu Démarrer

| Besoin | Source exacte | Action dans Ankh-DE | État attendu |
|---|---|---|---|
| Menu Démarrer Ankh | KDE-Windows-Modern, `plasma/applets/…startmenu/`, commit `7ef6bfe` | Conserver le plasmoid déjà repris sous l’identifiant `org.ankh.demarrer`. Préserver l’auteur amont, la licence et la provenance. Adapter seulement le logo, les couleurs, la police, les rayons et les dimensions Ankh. | Déjà intégré ; tester l’ouverture réelle, la recherche, les favoris, toutes les applications, les actions d’alimentation et le focus clavier. |
| Recherche et ergonomie du menu | [Eisteed/menu-11-next](https://github.com/Eisteed/menu-11-next), dépôt complet comme référence UX uniquement | Étudier les vues Liste/Grille/Catégories, tri, navigation clavier, dossiers, applications épinglées, fichiers récents et mode calculatrice. Ne pas copier de code tant que l’absence d’un fichier `LICENSE` complet et la provenance de chaque fichier ne sont pas résolues. | Référence de conception ; aucune seconde implémentation du menu. |
| Recherche système depuis le menu | Tidewater `plasmoids/search` (commit à examiner ; ne pas supposer qu’il est déjà intégré) | Comparer les capacités à la recherche du menu Ankh. Reprendre seulement une fonction manquante, si elle n’est pas déjà fournie par KRunner ou le menu actuel. | À étudier après validation fonctionnelle du menu existant. |

**Ne crée pas un deuxième menu Démarrer.** Le menu actuel vient de KDE-Windows-Modern. `menu-11-next` est une référence ergonomique, pas un composant à fusionner en parallèle. Le dépôt Ankh-DE indique qu’il a été écarté comme source de code faute de fichier de licence à la racine ; respecte cette décision tant que cette question n’est pas résolue.

Sources :
- https://github.com/Jeysef/KDE-Windows-Modern
- https://github.com/Eisteed/menu-11-next
- https://github.com/adhec/OnzeMenuKDE

### 2.3 Barre des tâches et aperçu des fenêtres

| Besoin | Source exacte | Action dans Ankh-DE | État attendu |
|---|---|---|---|
| Gestionnaire de tâches / applications ouvertes | Tidewater, `plasmoids/tasks/`, commit déjà inscrit `4484377` | Utiliser le composant déjà vendorié sous `org.ankh.taches`. Vérifier lancement, fenêtre active, fenêtres multiples, épingles, clic droit, activation et fermeture. | Déjà intégré ; priorité à la validation fonctionnelle et aux mesures. |
| Vue/aperçu des fenêtres | Tidewater, `plasmoids/taskview/`, commit `4484377` | Conserver le composant existant `org.ankh.vuetaches`. Tester l’aperçu, le passage à la fenêtre choisie, plusieurs bureaux et plusieurs écrans. | Déjà intégré ; compléter les tests. |
| Espace entre groupes d’icônes | Tidewater, `plasmoids/divider/`, commit `4484377` | Conserver `org.ankh.separateur`, déjà adapté pour rendre son trait transparent. Vérifier seulement son espacement réel et les différentes échelles. | Déjà intégré ; mesurer. |
| Disposition de la barre | Ankh `org.ankh.de.desktop` + API officielle Plasma | Garder une barre de 48 px, centrée, pleine largeur et visible selon la spécification. Valider `alignment`, `lengthMode`, `length`, `offset`, `hiding`, `opacity`, `height`, `location` et `floating`. | Déjà configuré en partie ; les jetons non mesurés doivent être ajoutés au banc. |
| Prévisualisation au survol / fermeture des fenêtres | KDE-Windows-Modern `plasma/applets/…icontasks/` comme référence de comportement ; Tidewater `plasmoids/tasks/` comme implémentation actuelle | Ne pas importer `icontasks` maintenant : il utilise l’identifiant système `org.kde.plasma.icontasks`, comprend du C++ et créerait un conflit/une charge de maintenance. Étudier les interactions et compléter le plasmoid Tidewater déjà adapté. | À améliorer dans le composant existant, pas par remplacement complet. |

**Ne pas importer `icontasks` de KDE-Windows-Modern sans une décision technique distincte.** L’audit amont d’Ankh-DE relève 11 fichiers C++, 20 QML et 4 429 lignes, avec un identifiant qui est celui de l’applet standard Plasma. Ce n’est pas une petite copie QML.

### 2.4 Paramètres rapides, zone système et notifications

| Besoin | Source exacte | Action dans Ankh-DE | État attendu |
|---|---|---|---|
| Volet rapide Wi-Fi, Bluetooth, volume, luminosité | Tidewater, `plasmoids/status/`, commit `4484377` | Conserver le composant adapté `org.ankh.etat`. Tester chaque contrôle sur Fedora/Plasma 6.8.2 : état, activation, erreur, absence de matériel et absence de commande. | Déjà intégré ; tests fonctionnels à compléter. |
| Centre de notifications | Tidewater, `plasmoids/notifications/`, commit `4484377` | Conserver `org.ankh.notifications`. Tester notification entrante, groupement, fermeture, effacement, Ne pas déranger et clic vers l’application. | Déjà intégré ; tester et harmoniser. |
| Zone système / indicateurs | Conteneur System Tray standard de Plasma, habillé par le style Ankh ; KDE-Windows-Modern `systemtray/` comme référence visuelle uniquement | Garder le conteneur natif Plasma pour la première version. Ne pas importer le fork C++ `systemtray` de KDE-Windows-Modern : l’audit l’estime à 40 fichiers C++, 60 QML et 6 585 lignes, avec remplacement d’un conteneur système. | Repli natif assumé ; améliorer l’apparence via les styles et composants exposés. |
| Calendrier et horloge | KDE-Windows-Modern `…digitalclock/` déjà repris sous `org.ankh.horloge`; Tidewater `plasmoids/clock/` comme référence alternative | Garder l’horloge Ankh actuelle. N’étudier Tidewater clock que si un besoin utilisateur concret manque (calendrier, format, secondes). Ne pas installer deux horloges. | Déjà intégré ; tester calendrier et formats. |
| Commandes système | Tidewater `plasmoids/status/contents/code/helper.sh` | Réutiliser les appels déjà intégrés et auditer leur gestion d’erreur. Vérifier les outils `nmcli`, `wpctl`, `rfkill`, `bluetoothctl` et `busctl` dans l’installateur et le runtime. | Dépendances à contrôler par distribution ; aucune commande ne doit faire échouer tout le bureau si un périphérique manque. |

**Point de compatibilité majeur :** Tidewater a été développé et testé par son auteur sur Plasma 6.6 ; Ankh-DE vise Plasma 6.8.x. Le fait que Tidewater soit essentiellement QML évite un build C++/ABI, mais ne garantit pas la compatibilité des API Plasma privées. Tester en session les imports `org.kde.plasma.plasma5support` et `org.kde.plasma.private.volume` avant toute déclaration de compatibilité.

### 2.5 Alt+Tab, bureaux virtuels et actions de session

| Besoin | Source exacte | Action dans Ankh-DE | État attendu |
|---|---|---|---|
| Sélecteur Alt+Tab | Tidewater, `switcher/tidewater-switcher/`, commit `4484377` | Conserver le package déjà adapté `ankh-selecteur` de type `KPackageStructure: KWin/WindowSwitcher`, configuré dans `src/config/kwinrc`. Tester sélection, annulation, fermeture, 1/2/plusieurs écrans et fenêtres nombreuses. | Déjà intégré selon `docs/UPSTREAMS.md` ; tests session à établir. |
| Bureaux virtuels / workspace pills | Tidewater, `plasmoids/workspaces/` | Étudier puis reprendre uniquement si la barre actuelle ne fournit pas le comportement recherché. Tester les interactions avec KWin et le nombre de bureaux. | À étudier ; ne pas recopier sans inventaire. |
| Menu d’alimentation | Tidewater, `plasmoids/power/` | Comparer à l’interface d’alimentation existante de Plasma. Réutiliser les actions/UX manquantes sans remplacer les mécanismes de session et sans exécuter de commandes privilégiées depuis QML. | À étudier après stabilité du shell. |
| Vue d’ensemble | Tidewater et API KWin/Plasma officielles | Vérifier d’abord les fonctions natives de KWin (`Overview`, bureaux virtuels, raccourcis). Ne créer un applet que si le comportement visuel manque réellement. | À étudier ; privilégier les API publiques. |
| Verrouillage et écran de connexion | KScreenLocker/SDDM de la distribution ; KDE-Windows-Modern comme référence visuelle seulement | Garder les composants système natifs. Ne pas embarquer le fork Plasma Login Manager ni le shell lockscreen externe dans la première livraison. Le verrouillage/déverrouillage doit être validé avant tout changement. | Hors priorité ; ne pas compromettre l’authentification. |

**Attention au sélecteur KWin :** KWin peut garder le code du paquet par nom en mémoire jusqu’à la déconnexion. Lorsqu’un changement du switcher ne semble pas appliqué, ne conclus pas immédiatement à un échec de code : valide le cycle de déconnexion/reconnexion, ou applique la stratégie d’empreinte de paquet si elle est justifiée et documentée.

### 2.6 Applications et cohérence visuelle

| Besoin | Source exacte | Action dans Ankh-DE | État attendu |
|---|---|---|---|
| Dolphin, Discover, Konsole, System Settings (Qt Widgets) | QStyle Ankh dérivé de Breeze dans `src/style/`, palette Ankh et icônes Fluent-Ankh | Ne pas appliquer un thème Kvantum concurrent. Tester chaque application avec le QStyle Ankh : boutons, champs, menus, listes, barres latérales, états focus/disabled et densité. | Base existante ; couverture de tests à élargir. |
| Applications QtQuick/Kirigami | Adaptations `src/qqc2/` et thème Plasma Ankh | Vérifier les contrôles QtQuick réels : dialogues, menus, champs, interrupteurs, listes et navigation clavier. | Base existante ; inventaire des apps à tester. |
| Applications GTK | `Fluent-gtk-theme` déjà adapté sous `Fluent-Ankh` | Conserver ce thème et tester GTK3/GTK4. Ne pas copier Fluent-kde pour régler un problème GTK. | Déjà intégré ; tester les variantes clair/sombre. |
| Flatpak GTK | Documentation Flatpak/portails et thème installé au bon emplacement utilisateur | Déterminer les limites réelles d’accès au thème dans les sandboxes. Ne pas promettre une couverture complète tant que chaque cas n’est pas testé. | À valider. |
| Electron / Chromium | Paramètres natifs de chaque application et règles CSD | Ne pas chercher à contrôler toutes les barres de titre depuis Plasma. Documenter les applications qui dessinent leurs propres contrôles. | Limite à documenter ; traitement par application si utile. |
| Icônes et curseurs | `Fluent-icon-theme` déjà repris et recoloré sous `Fluent-Ankh` | Compléter seulement les icônes manquantes en conservant `index.theme`, héritage et attribution. Tester les IDs KDE, Flatpak et MIME. | Déjà intégré ; compléter les trous identifiés par test. |

---

## 3. Dépôts amont : décision d’utilisation

### A. Sources à exploiter directement (composants déjà présents)

#### 1. KDE-Windows-Modern — source principale du look Windows 11

Dépôt : https://github.com/Jeysef/KDE-Windows-Modern  
Référence Ankh actuelle : `7ef6bfe`.

**Déjà repris dans Ankh-DE :**

- `plasma/desktoptheme/` → thèmes Plasma `ankh` et `ankh-clair` ;
- `plasma/applets/…startmenu/` → `org.ankh.demarrer` ;
- `plasma/applets/…digitalclock/` → `org.ankh.horloge` ;
- `plasma/applets/…showdesktop/` → `org.ankh.bureau`.

**À consulter mais ne pas importer maintenant :**

- `plasma/layout-templates/` : référence de disposition de panneau ; comparer au layout Ankh existant ;
- `plasma/applets/…icontasks/` : références d’aperçu/gestion des fenêtres, mais implémentation C++ lourde et collision d’identifiant ;
- `plasma/applets/…systemtray/` : référence visuelle uniquement, fork de conteneur système lourd ;
- `plasma/shells/org.kde.windowsmodern.lockscreen/` et le boot greeter : hors périmètre de la première stabilisation ;
- `Kvantum/` : ne pas installer en parallèle du QStyle Ankh sans décision formelle.

**Ne jamais exécuter son installateur global `install.sh` sur une machine de développement Ankh.** Il applique de nombreux réglages et peut remplacer la disposition du bureau. Cloner le dépôt pour lecture, extraire uniquement les composants autorisés et les intégrer via le packaging Ankh.

#### 2. Tidewater — source principale des interactions du shell

Dépôt : https://github.com/addition-official/tidewater  
Référence Ankh actuelle : `4484377` dans `docs/UPSTREAMS.md`.

**Déjà repris dans Ankh-DE :**

- `plasmoids/status/` → `org.ankh.etat` ;
- `plasmoids/notifications/` → `org.ankh.notifications` ;
- `plasmoids/tasks/` → `org.ankh.taches` ;
- `plasmoids/taskview/` → `org.ankh.vuetaches` ;
- `plasmoids/divider/` → `org.ankh.separateur` ;
- `switcher/tidewater-switcher/` → `ankh-selecteur` ;
- `shared/` et `common/` → module QML partagé installé dans `share/ankh-de/qml`.

**À étudier éventuellement :**

- `plasmoids/workspaces/` : indicateurs/bascule des bureaux ;
- `plasmoids/power/` : menu d’alimentation ;
- `plasmoids/search/` : recherche si le menu actuel ne suffit pas ;
- `plasmoids/clock/` : seulement si le calendrier/horloge Ankh manque d’une fonction.

Ces éléments doivent être audités au commit précis choisi ; ne pas supposer qu’ils sont compatibles parce que les autres applets le sont. La version amont documente Plasma 6.6/Wayland, alors qu’Ankh teste Plasma 6.8.2.

**À ne pas reprendre :** son `install.sh`, `uninstall.sh`, son panneau complet, son thème de couleurs par défaut, ses polices Rubik/Material Symbols ou sa disposition complète. Ankh possède déjà son installateur, sa session, sa charte et son layout. Réutiliser des widgets ne veut pas dire reprendre la distribution de configuration Tidewater.

#### 3. KDE officiel — vérité technique pour les API Plasma

Dépôts :

- https://invent.kde.org/plasma/plasma-workspace
- https://invent.kde.org/plasma/plasma-desktop
- https://invent.kde.org/plasma/breeze
- https://develop.kde.org/docs/plasma/widget/setup/
- https://develop.kde.org/docs/plasma/widget/properties/
- https://develop.kde.org/docs/plasma/widget/porting_kf6/

**À consulter avant tout projet tiers dès qu’il s’agit d’un comportement Plasma :**

- `plasma-workspace/shell/shellcorona.cpp` : chargement des dispositions et comportement de la session ;
- `plasma-workspace/shell/scripting/panel.h` : propriétés et mesures de panneaux ;
- `plasma-workspace/shell/scripting/containment.h` : widgets, IDs et API des containments ;
- code upstream des notifications, du System Tray, des bureaux virtuels et du gestionnaire de tâches pour comprendre les API publiques et les points d’extension.

**Ne fork pas un composant KDE officiel juste pour changer son apparence.** Utilise les extensions, les thèmes, les applets et les scripts de disposition quand ils suffisent. Si un fork devient inévitable, crée une décision dédiée, mesure le coût de rebase et documente l’API/ABI concernée.

### B. Sources à garder comme références, pas comme imports

| Dépôt | Ce qu’il apporte | Décision pour Ankh-DE |
|---|---|---|
| [Win11OS-kde](https://github.com/yeyushengfan258/Win11OS-kde) | Base du thème Plasma, Aurorae, Kvantum, color schemes, look-and-feel, SDDM | Ne pas réimporter : sa couche Plasma est déjà présente indirectement via KDE-Windows-Modern. Consulter uniquement pour comparer des assets manquants. |
| [Fluent-kde](https://github.com/vinceliuice/Fluent-kde) | Aurorae, Kvantum, thème Plasma, color schemes | Référence de langage visuel uniquement. Le QStyle C++ Ankh est le moteur Qt principal ; n’ajoute pas Kvantum comme deuxième style global. Le thème Fluent GTK et les icônes et curseurs sont déjà gérés séparément. |
| [ELEVEN](https://github.com/innerpulsenet/ELEVEN) | Thèmes sombre, Aero Glass, Carbon Glass, décoration QML KWin, splash, icônes et curseurs | Référence pour blur, transparence, matériaux et splash. Ne remplace pas `src/decoration/` : les mécanismes de décoration ne sont pas interchangeables sans portage. Vérifier les licences Breeze des ressources qu’il embarque. |
| [NeoWin](https://github.com/TuxLux40/NeoWin) | Commutation claire/sombre automatique, palettes et expérience globale | Étudier seulement l’usage du mécanisme KDE `AutomaticLookAndFeel` si Ankh veut un changement automatique clair/sombre. Ne pas prendre son layout de panneau macOS/GNOME. Ne pas reprendre les échantillons audio Windows : le README signale que Microsoft en conserve les droits. Examiner séparément les icônes AGPL avant toute redistribution. |
| [Menu 11 Next](https://github.com/Eisteed/menu-11-next) | Ergonomie du menu : dossiers, tri, navigation clavier, commandes, calculatrice | Référence UX seulement. Le dépôt Ankh note l’absence d’un fichier `LICENSE` à la racine au moment de son audit ; ne pas copier le code tant que la licence/provenance n’est pas clarifiée. |
| [AnduinOS](https://github.com/Anduin2017/AnduinOS) | Ressources de wallpaper Fluent-building | `Ankh-Prismes` est déjà dérivé et documenté dans `docs/UPSTREAMS.md`. Ne pas réimporter l’original ni les composants GNOME. |
| [Klassy](https://github.com/ekaaty/klassy) | Référence technique QStyle/KDecoration et réglages détaillés | À lire pour comprendre les options de décoration et les réglages possibles, pas à fusionner : Ankh possède déjà son fork Breeze et doit éviter un second plugin C++ de fenêtre à maintenir. |

---

## 4. Ordre d’exécution recommandé

### Phase 0 — Audit, inventaire et état de référence

1. Vérifier le vrai HEAD local et `origin/main`.
2. Faire l’inventaire des applets installables et des composants vendoriés.
3. Vérifier tous les commits amont déjà documentés.
4. Comparer les fichiers du dépôt et `docs/UPSTREAMS.md`.
5. Lister les doublons d’identifiants KPackage, les doublons de fonctionnalités et les dépendances manquantes.
6. Créer un état de référence : Build, tests unitaires, bench, VM session réelle et captures.

**Livrable :** `docs/INTEGRATION-MAP.md` à jour. Aucun nouveau composant n’est importé pendant cette phase.

### Phase 1 — Stabiliser les intégrations déjà faites

Ordre exact :

1. Menu `org.ankh.demarrer` : ouverture réelle, recherche, favoris, toutes les applications, navigation clavier et actions d’alimentation.
2. Barre : `org.ankh.taches`, `org.ankh.vuetaches`, `org.ankh.horloge`, `org.ankh.bureau`, `org.ankh.separateur` ; lancer plusieurs applications, épingler, basculer, fermer et tester plusieurs fenêtres d’une même application.
3. Paramètres rapides `org.ankh.etat` : Wi-Fi, Ethernet, Bluetooth, volume, microphone, luminosité, Do Not Disturb si présent, erreurs et matériel absent.
4. Notifications `org.ankh.notifications` : arrivée, groupement, effacement, DND, activation de l’application source.
5. Alt+Tab `ankh-selecteur` : fenêtre suivante/précédente, aperçu, validation, annulation, multi-écran ; déconnexion/reconnexion après changement du paquet.
6. Zone système native Plasma : vérifier réseau, son, batterie, Bluetooth, presse-papiers, périphériques et extensions de tray.

Pour chaque widget, vérifier le `metadata.json`, l’identifiant unique, `KPackageStructure`, la version minimale Plasma, les imports QML, les chemins relatifs vers `shared/` et les erreurs dans `journalctl --user`.

### Phase 2 — Terminer la barre et les interactions du bureau

1. Mesurer la barre : hauteur, position, centrage, largeur, flottement, masquage, transparence, espacement et alignement.
2. Corriger seulement les mesures qui échouent réellement.
3. Évaluer `plasmoids/workspaces/` de Tidewater si les bureaux virtuels manquent visuellement.
4. Évaluer `plasmoids/power/` si le menu d’alimentation est incomplet.
5. Ne pas importer une deuxième recherche si le Start Menu actuel couvre déjà ce besoin.

### Phase 3 — Applications

Tester d’abord les composants Ankh existants avant d’ajouter un autre thème :

- Dolphin ;
- Konsole ;
- Discover ;
- System Settings ;
- Kate ;
- applications GTK3 et GTK4 ;
- Flatpak GTK ;
- Electron/Chromium.

Pour chaque application, enregistrer une capture et les écarts. Distinguer les applications Qt Widgets, QtQuick/Kirigami, GTK, libadwaita et Electron : elles ne partagent pas toutes le même moteur de thème.

### Phase 4 — Finitions et distribution

1. Échelles 100 %, 125 %, 150 % et 200 % ; multi-écrans avec DPI différents.
2. Thème sombre et clair ; changement de wallpaper et accent dynamique.
3. Focus clavier, contraste, tailles de cibles, lecteurs d’écran et navigation.
4. Installation, mise à niveau, désinstallation et restauration.
5. Build et test dans chaque distribution réellement revendiquée.
6. Générer les manifestes de dépendances, notices de licences et captures de release.

---

## 5. Règles d’intégration du code tiers

Pour chaque composant copié ou modifié :

1. **Épingler un commit exact**, jamais dépendre de `main` au moment du build.
2. Conserver le copyright, l’auteur original, la licence et les fichiers d’attribution.
3. Documenter le chemin amont exact et le chemin local exact.
4. Renommer les IDs KPackage et les domaines de configuration pour éviter les collisions, sauf si une intégration exige expressément de préserver un ID système — auquel cas ne pas la faire sans décision explicite.
5. Ne pas modifier le sens d’une licence ni supprimer les notices.
6. Maintenir un patch minimal et lisible ; privilégier un dossier vendorié et un patch explicite plutôt qu’une copie opaque.
7. Ne jamais importer un installateur amont qui réécrit la configuration de l’utilisateur ou qui remplace des composants système.
8. Auditer les scripts shell : aucun `sudo` caché, aucune suppression destructive, aucune modification globale non réversible.
9. Vérifier les API privées Plasma, les dépendances système et les commandes externes.
10. Ajouter au moins un test automatisé ou une vérification reproductible par fonctionnalité.

### Licences : contrôles indispensables

- Le dépôt Ankh-DE est déclaré GPL-3.0-or-later ; cela ne dispense pas de suivre la licence de chaque composant embarqué.
- KDE-Windows-Modern est GPL-3.0, mais son `ATTRIBUTION.md` liste des composants amont et des licences pièce par pièce. Reprendre les notices correspondantes.
- Tidewater est GPL-3.0-or-later selon son dépôt et le relevé d’Ankh ; conserver son attribution et les notices de fichiers.
- Fluent-kde et Win11OS-kde sont GPL-3.0 ; vérifier les sous-composants et les fichiers de licence.
- ELEVEN inclut des ressources Breeze qui restent sous leurs licences KDE respectives ; ne pas tout requalifier automatiquement sous GPL-3.0-or-later.
- NeoWin contient des icônes AGPL-3.0 et des sons Windows dont les droits restent à Microsoft : ne pas copier ces sons.
- `menu-11-next` déclare GPL-2.0+ dans `metadata.json`, mais Ankh a relevé l’absence de texte `LICENSE` à la racine : maintenir le statut « référence seulement » jusqu’à résolution.
- La police Selawik reste sous OFL 1.1 ; respecter son nom réservé et les obligations OFL.

En cas de doute juridique sur un fichier, ne le copie pas : note le point dans `docs/UPSTREAMS.md` et propose une alternative libre déjà disponible.

---

## 6. Tests d’acceptation obligatoires

Une feature ne peut passer en `FINI` que si toutes les cases qui la concernent sont prouvées :

### Tests de build et paquet

- build propre dans l’environnement cible ;
- installation des fichiers au bon chemin ;
- manifestes KPackage correctement installés ;
- absence de collision de IDs ;
- aucune dépendance runtime non documentée ;
- désinstallation sans résidus ni modification de Plasma standard.

### Tests de session Plasma réelle

- la session Ankh démarre depuis le gestionnaire de connexion ;
- `ANKH_DE_SESSION=1` est présent ;
- le bon thème, le bon layout et la bonne décoration sont effectivement chargés ;
- le journal confirme l’évaluation du layout Ankh ;
- chaque widget attendu est réellement instancié ;
- les interactions sont déclenchées et observées (pas seulement la présence des fichiers) ;
- les captures montrent les composants réellement ouverts ;
- aucune erreur QML, module manquant ou crash n’apparaît dans les journaux.

### Tests de robustesse

- redémarrage de `plasmashell` ;
- déconnexion/reconnexion ;
- session fraîche ;
- configuration utilisateur déjà existante ;
- absence des commandes facultatives ;
- matériel non présent (pas de Bluetooth, pas de batterie, etc.) ;
- un et deux écrans ;
- échelles 100 %, 125 % et 150 % ;
- thème sombre et clair.

### Règle CI

Tout contrôle échoué doit renvoyer un code de sortie non nul. Interdiction de transformer un échec en succès via un `|| echo`, un `|| true`, une assertion non bloquante ou un script qui imprime `ÉCHEC` puis termine en code 0.

Le rapport de VM doit exposer le SHA du test, le nombre de checks réussis/échoués, les dépendances détectées, les captures et les logs utiles.

---

## 7. Priorités fonctionnelles — ce qu’il reste à faire, pas à recopier

### P0 — Fiabilité et cohérence

- Vérifier les résultats Build, Banc et VM sur un même SHA.
- Corriger les contrôles de CI qui peuvent masquer un échec.
- Synchroniser README, ROADMAP, AVANCEMENT, AUDIT et UPSTREAMS avec les preuves actuelles.
- Vérifier que chaque intégration Tidewater/KDE-Windows-Modern est réellement fonctionnelle sur la version cible de Plasma.

### P1 — Shell complet

- Finaliser les neuf mesures de barre encore annoncées dans la roadmap si elles ne sont pas déjà mesurées.
- Tester les tâches, l’aperçu des fenêtres, le séparateur, le System Tray natif et les interactions multi-écrans.
- Tester le volet d’état Wi-Fi/Bluetooth/volume/luminosité.
- Tester le centre de notifications.
- Tester Alt+Tab.

### P2 — Couverture des applications et finitions

- harmoniser les applications Qt/QtQuick/GTK ;
- traiter les cas Flatpak/Electron avec leurs limites documentées ;
- tester 125/150 % et multi-écran ;
- améliorer les thèmes clair/sombre et les animations ;
- vérifier focus, contraste, navigation clavier et accessibilité.

### P3 — Distribution

- test d’installation et de désinstallation par distribution ;
- tests de mise à niveau d’une ancienne version ;
- paquets reproductibles ;
- notes de version et guide de dépannage.

---

## 8. Ce que Claude Code ne doit PAS faire

- Ne pas créer un nouveau projet à côté d’Ankh-DE.
- Ne pas remplacer `plasmashell`, KWin, le gestionnaire de session ou le compositeur.
- Ne pas recopier l’intégralité de KDE-Windows-Modern ou Tidewater.
- Ne pas intégrer une deuxième barre, un deuxième menu Démarrer, une deuxième horloge ou un deuxième gestionnaire de tâches.
- Ne pas importer `icontasks` de KDE-Windows-Modern sans résoudre explicitement le conflit d’ID et le coût de C++.
- Ne pas importer le `systemtray` C++ de KDE-Windows-Modern dans le sprint actuel.
- Ne pas installer globalement le thème Fluent-kde/Kvantum en parallèle du QStyle Ankh.
- Ne pas remplacer la décoration KDecoration3 Ankh par Aurorae/ELEVEN sans étude comparative et décision dédiée.
- Ne pas importer les sons Microsoft de NeoWin, les logos ou autres ressources propriétaires.
- Ne pas faire passer une fonctionnalité en `FINI` sur la seule base d’une compilation ou d’un screenshot statique.
- Ne pas mettre à jour les commits amont automatiquement sans audit des différences et révision de licence.
- Ne pas supprimer ou écraser les modifications locales de l’utilisateur.

---

## 9. Livrables demandés à Claude Code

À la fin de ce travail, fournir :

1. `docs/INTEGRATION-MAP.md` : tableau complet des sources, chemins, commits, licences et statuts ;
2. un rapport d’audit indiquant les composants déjà intégrés, les composants réellement manquants et les doublons supprimés/évités ;
3. les corrections de code réellement nécessaires, limitées aux priorités P0/P1 ;
4. les tests exécutés avec leur commande, leur SHA, le résultat et les éventuels logs ;
5. les captures issues de la VM de session réelle ;
6. la mise à jour de `UPSTREAMS.md`, `LICENSES/`, `ROADMAP.md`, `AVANCEMENT.md` et du README si des preuves nouvelles le justifient ;
7. une liste explicite des points non résolus, sans les présenter comme terminés.

### Format du compte rendu final

Présente les résultats dans cet ordre :

- **SHA audité** et état de travail Git ;
- **fonctionnalités réutilisées** (source + chemin + commit) ;
- **fonctionnalités déjà intégrées et validées** ;
- **fonctionnalités intégrées mais pas encore validées** ;
- **nouvelles modifications réalisées** ;
- **tests exécutés et résultats** ;
- **licences et dépendances vérifiées** ;
- **écarts restants classés P0/P1/P2** ;
- **prochaine tâche recommandée**.

Ne donne pas un pourcentage de progression arbitraire. Si un pourcentage est demandé, définis les critères de finition, attribue un poids aux lots et explique le calcul. Distingue toujours « code présent », « installé », « chargé », « interactif » et « validé ».

---

## 10. Références officielles et dépôts

### Dépôt principal

- [Ankh-DE](https://github.com/PatrickChoumi/Ankh-DE)
- [Spécification](https://github.com/PatrickChoumi/Ankh-DE/blob/main/ANKH-DE-SPEC.md)
- [Décisions](https://github.com/PatrickChoumi/Ankh-DE/blob/main/DECISIONS.md)
- [Roadmap](https://github.com/PatrickChoumi/Ankh-DE/blob/main/ROADMAP.md)
- [Avancement](https://github.com/PatrickChoumi/Ankh-DE/blob/main/AVANCEMENT.md)
- [Provenance des composants](https://github.com/PatrickChoumi/Ankh-DE/blob/main/docs/UPSTREAMS.md)

### Sources de composants

- [KDE-Windows-Modern](https://github.com/Jeysef/KDE-Windows-Modern)
- [Tidewater](https://github.com/addition-official/tidewater)
- [Win11OS-kde](https://github.com/yeyushengfan258/Win11OS-kde)
- [Fluent-kde](https://github.com/vinceliuice/Fluent-kde)
- [Fluent-icon-theme](https://github.com/vinceliuice/Fluent-icon-theme)
- [Fluent-gtk-theme](https://github.com/vinceliuice/Fluent-gtk-theme)
- [ELEVEN](https://github.com/innerpulsenet/ELEVEN)
- [NeoWin](https://github.com/TuxLux40/NeoWin)
- [Menu 11 Next](https://github.com/Eisteed/menu-11-next)
- [AnduinOS](https://github.com/Anduin2017/AnduinOS)
- [Klassy](https://github.com/ekaaty/klassy)

### Documentation KDE

- [Créer un plasmoid](https://develop.kde.org/docs/plasma/widget/setup/)
- [Propriétés et metadata d’un widget Plasma](https://develop.kde.org/docs/plasma/widget/properties/)
- [Portage des plasmoids vers KF6 / Plasma 6](https://develop.kde.org/docs/plasma/widget/porting_kf6/)
- [Code source Plasma Workspace](https://invent.kde.org/plasma/plasma-workspace)
- [Code source Plasma Desktop](https://invent.kde.org/plasma/plasma-desktop)
- [Code source Breeze](https://invent.kde.org/plasma/breeze)

---

## Instruction finale

**Travaille intelligemment : Ankh-DE possède déjà beaucoup de composants venus des bons dépôts. Le gain de vitesse ne viendra pas d’une nouvelle copie, mais de la réutilisation correcte, de la suppression des doublons, de l’adaptation visuelle Ankh et de tests qui prouvent le fonctionnement réel.**

Commence par l’inventaire, puis stabilise les composants vendoriés. N’ajoute un nouveau morceau de code que si tu peux démontrer qu’une fonctionnalité manque réellement et que le composant choisi est meilleur que ce qui est déjà présent.

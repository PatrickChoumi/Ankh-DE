# ANKH-DE — Audit anti-doublons et stratégie de réutilisation

**Document de pilotage destiné à Claude Code**  
**Date de référence de la recherche : 7 novembre 2026**  
**Dépôt principal :** <https://github.com/PatrickChoumi/Ankh-DE>  
**Objectif :** accélérer Ankh-DE en réutilisant les fonctionnalités déjà présentes dans Ankh-DE, KDE Plasma et les dépôts open source compatibles, au lieu de les réécrire.

---

## 0. Mission impérative

Tu travailles **dans le dépôt Ankh-DE existant**. Ankh-DE reste le projet principal, son identité, son architecture et son historique doivent être préservés.

Ta mission n'est pas de créer un nouveau desktop environment, un nouveau shell complet, un nouveau gestionnaire de fenêtres ou une nouvelle distribution. Ankh-DE est une expérience de bureau personnalisée construite sur KDE Plasma 6 : géométrie, disposition, composants visuels et comportements inspirés de Windows 11, avec l'identité graphique propre à Ankh (graphite/violet, logo et identité Ankh).

Le principe directeur est :

> **Ne développe pas une fonctionnalité avant d'avoir prouvé qu'elle n'existe ni dans Ankh-DE, ni dans KDE Plasma, ni dans un composant open source réutilisable et compatible.**

Pour chaque fonctionnalité, choisis exactement une stratégie principale :

1. **KEEP** — le composant est déjà présent et correctement utilisé : ne pas le réécrire.
2. **CONFIGURE** — KDE fournit déjà la fonction : configurer, exposer et styliser le composant natif.
3. **ADAPT** — un composant externe est déjà intégré ou très proche : adapter le code existant, sans importer un deuxième composant concurrent.
4. **IMPORT** — un composant externe précis manque réellement : importer uniquement les fichiers nécessaires après audit de licence, dépendances, API et compatibilité.
5. **BUILD** — aucune solution satisfaisante n'existe : développer la fonctionnalité dans Ankh-DE.
6. **DEFER** — la fonction est hors périmètre, risquée ou non prioritaire : ne pas la développer dans cette version.

Ne choisis jamais BUILD par défaut.

---

## 1. Avant toute modification : établir l'état réel du dépôt

Le nombre de commits communiqué par le propriétaire peut être différent de celui affiché par l'index GitHub. Ne déduis pas le contenu du dernier commit du seul compteur affiché sur le site.

Exécute d'abord :

```bash
git fetch --all --prune
git status --short --branch
git rev-parse --show-toplevel
git rev-parse HEAD
git log -1 --format='%h %cs %s'
git rev-list --count HEAD
git rev-list --count origin/main 2>/dev/null || true
git log --oneline --decorate -15
```

Règles :

- Ne supprime, ne nettoie et ne réinitialise aucune modification locale.
- Ne lance jamais `git reset --hard`, `git clean -fd`, ni une commande destructive pour « repartir proprement ».
- Si le worktree contient des modifications, identifie-les et préserve-les.
- Vérifie si la branche courante est derrière ou devant `origin/main`.
- Toute conclusion de cet audit doit citer le SHA exact examiné.
- Ne prétends pas qu'un commit est testé si le workflow correspondant ne porte pas exactement ce SHA.

Lis ensuite les documents réellement présents dans le dépôt :

- `CLAUDE.md`
- `ANKH-DE-SPEC.md` ou le document de spécification équivalent
- `DECISIONS.md` et les décisions `DE-*`
- `ROADMAP.md`
- `AVANCEMENT.md`
- `AUDIT.md`
- `README.md`
- `FIDELITE.md` ou `docs/FIDELITE.md`
- `docs/UPSTREAMS.md`
- `docs/INSTALL.md`
- les scripts de préparation, installation, désinstallation et les workflows CI

Si les noms ou chemins diffèrent, découvre les fichiers réellement présents. Ne crée pas de doublons documentaires juste parce qu'un chemin attendu n'existe pas.

**Hiérarchie des décisions :** repère les décisions les plus récentes et explicites. Si `CLAUDE.md`, la spécification, `DECISIONS.md`, la roadmap et le code se contredisent, ne choisis pas silencieusement une version : consigne la contradiction, détermine quelle décision l'a remplacée, puis corrige les documents concernés en conservant l'historique utile.

---

## 2. Résultat de la recherche : ce qui est déjà disponible

Cette section est un inventaire initial de recherche, pas une autorisation de copier aveuglément. Vérifie chaque élément dans le code actuel, sur son commit amont et dans une session Plasma correspondant à la version ciblée par Ankh-DE.

### 2.1 KDE Plasma fournit déjà une grande partie du bureau

| Fonction | Composant KDE déjà disponible | Conséquence pour Ankh-DE |
|---|---|---|
| Barre/panneau | Plasma Panel / `plasmashell` | Garder le panneau Plasma et le configurer. Ne pas créer une seconde couche de panneau sans décision d'architecture. |
| Lanceur d'applications | Application Launcher / Kickoff et autres applets de lancement | Ankh a déjà son menu repris de KDE-Windows-Modern. Ne pas ajouter un second menu. |
| Liste des fenêtres / tâches | Task Manager / Task Manager Library de `plasma-workspace` | Réutiliser les modèles et API natifs si besoin. Ne pas réécrire l'énumération des fenêtres. |
| Zone système | Plasma System Tray et Status Notifier Items (SNI) | Garder le conteneur système natif, sauf décision explicite et justification technique. |
| Horloge et calendrier | Digital Clock et popup calendrier Plasma | Ankh a déjà repris une horloge. Ne pas ajouter un deuxième calendrier/horloge. |
| Notifications | Service et modèles de notifications Plasma | Personnaliser le centre visuel, mais ne pas démarrer un deuxième daemon de notification. |
| Recherche d'applications/fichiers/actions | KRunner et ses runners | Réutiliser KRunner/runners. Ne pas écrire un indexeur global ou un moteur de recherche parallèle. |
| Aperçu des fenêtres / Overview | Effet Overview de KWin | Déclencher/configurer l'effet natif. Ne pas réimplémenter l'effet complet. |
| Alt+Tab | Sélecteur de fenêtres KWin, personnalisable en QML | Utiliser l'API KWin. Ankh a déjà importé un switcher Tidewater : ne pas en ajouter un deuxième. |
| Bureaux virtuels | KWin | Configurer et présenter les bureaux natifs. Ne pas créer un gestionnaire de bureaux concurrent. |
| Tiling / Snap de base | Fonctions de disposition de fenêtres KWin/Plasma | Tester les possibilités de la version cible avant de programmer un snapper maison. |
| Audio / volume | Plasma Audio Volume / PipeWire / modèles KDE | Piloter les services existants, ne pas créer un gestionnaire audio. |
| Wi-Fi / réseau | Plasma Network Management / NetworkManager | Utiliser le modèle/service existant autant que possible. Éviter un second contrôleur réseau. |
| Bluetooth | BlueZ / BluezQt et intégration Plasma | Réutiliser les interfaces existantes. Éviter de gérer Bluetooth parallèlement par polling. |
| Luminosité / énergie | PowerDevil, UPower et services système | Réutiliser ces services. Ne pas développer un gestionnaire de batterie/énergie. |
| Paramètres système | KDE System Settings et ses KCM | Configurer, ordonner, masquer/exposer et styliser les KCM existants. Ne pas écrire une seconde application de paramètres. |
| Explorateur de fichiers | Dolphin | Personnaliser son apparence, ses raccourcis, sa barre d'outils et son panneau latéral. Ne pas réécrire un explorateur. |
| Applications et paquets | Discover, PackageKit et gestionnaires natifs de distribution | Ne pas développer une boutique d'applications Ankh. |
| Terminal | Konsole | Personnaliser le profil, le thème et les raccourcis. Ne pas créer un terminal. |
| Capture d'écran | Spectacle | Utiliser l'application et ses raccourcis. |
| Verrouillage de session | KScreenLocker | Personnaliser l'expérience sans remplacer le mécanisme de sécurité. |
| Écran de connexion | SDDM (si utilisé par la distribution) | Fournir un thème SDDM, pas un gestionnaire de connexion concurrent. |

Références officielles à consulter :

- Plasma Workspace : <https://invent.kde.org/plasma/plasma-workspace>
- KWin : <https://invent.kde.org/plasma/kwin>
- Plasma Desktop : <https://invent.kde.org/plasma/plasma-desktop>
- KRunner : <https://develop.kde.org/docs/plasma/krunner/>
- Documentation KWin / switcher : <https://develop.kde.org/docs/plasma/kwin/>
- Dolphin : <https://invent.kde.org/system/dolphin>
- PowerDevil : <https://invent.kde.org/plasma/powerdevil>
- KDE System Settings : <https://invent.kde.org/plasma/systemsettings>

### 2.2 Ce qu'Ankh-DE a déjà repris ou déclaré intégré

Vérifie les fichiers présents et leur utilisation effective ; une source dans `third_party/` ne prouve pas que le widget est chargé dans la session.

| Élément | Source connue dans le projet | Action attendue |
|---|---|---|
| Style Plasma clair/sombre Ankh | KDE-Windows-Modern, commit amont documenté `7ef6bfe` | Garder, tester les deux thèmes, corriger les détails Ankh. |
| Menu Démarrer Ankh | Applet Start Menu de KDE-Windows-Modern, QML | Garder ; prouver qu'il est chargé et qu'il s'ouvre réellement. |
| Horloge / calendrier | Applet Digital Clock de KDE-Windows-Modern | Garder ; vérifier calendrier, formats et affichage. |
| Afficher le bureau | Applet Show Desktop de KDE-Windows-Modern | Garder ; vérifier son comportement avec fenêtres et bureaux virtuels. |
| Tâches / barre | Tidewater `plasmoids/tasks` si effectivement branché | Vérifier l'usage dans la disposition active. Ne pas recopier un autre task manager avant audit. |
| Vue des tâches | Tidewater `plasmoids/taskview` | Vérifier le rôle exact : ne pas confondre avec l'effet Overview natif de KWin. |
| Paramètres rapides | Tidewater `plasmoids/status` | Garder une seule implémentation ; valider Wi-Fi, Bluetooth, volume, luminosité et états réels. |
| Centre de notifications | Tidewater `plasmoids/notifications` | Vérifier s'il s'agit d'un centre visuel branché sur le service Plasma ou d'un daemon concurrent. Un seul service de notifications doit rester actif. |
| Alt+Tab | Tidewater `switcher/tidewater-switcher`, renommé côté Ankh (référence `ankh-selecteur` à confirmer) | Garder un seul switcher KWin. Tester clavier, fenêtres, multi-écran et retour à la configuration native. |
| Séparateur | Tidewater `plasmoids/divider` | Garder seulement si la disposition active l'utilise. |
| Ressources Fluent | Icônes, curseurs et style GTK documentés dans `UPSTREAMS.md` | Garder les ressources qui servent réellement ; ne pas réimporter le pack complet. |
| Style Qt / décoration | Base Breeze adaptée dans Ankh-DE | Garder la base ; ne pas ajouter une deuxième couche Kvantum/Qt qui entre en conflit sans test comparatif. |

**Point de contrôle essentiel :** le README, la roadmap et `UPSTREAMS.md` ont pu évoluer à des moments différents. Compare leurs affirmations avec :

- la disposition réellement installée (`layout.js`, fichiers Look-and-Feel ou équivalents) ;
- les noms d'applets et leurs métadonnées ;
- les fichiers effectivement installés ;
- la liste d'applets du panel dans une session VM ;
- le journal de `plasmashell` ;
- une preuve fonctionnelle et visuelle.

Ne considère pas `org.ankh.taches`, `org.ankh.vuetaches`, `org.ankh.etat` ou `org.ankh.notifications` comme actifs simplement parce que les dossiers existent.

---

## 3. Cartographie détaillée des dépôts externes

### 3.1 KDE-Windows-Modern — source principale pour le thème et les applets déjà repris

Dépôt : <https://github.com/Jeysef/KDE-Windows-Modern>  
Commit précédemment épinglé dans la documentation Ankh : `7ef6bfe` (à re-vérifier dans `docs/UPSTREAMS.md`).  
Licence annoncée par le dépôt : GPL-3.0 ; vérifier aussi chaque composant, ses métadonnées et ses ressources.

**À conserver / vérifier dans Ankh :**

- thème Plasma et SVG clair/sombre ;
- applet Start Menu ;
- applet Digital Clock ;
- applet Show Desktop ;
- éventuellement des réglages visuels de panneau, de couleurs ou de Look-and-Feel après comparaison avec le profil Ankh.

**À étudier, mais ne pas importer automatiquement :**

- `icontasks` / icônes de tâches en C++ ;
- System Tray C++ personnalisé ;
- décoration Aurorae ;
- Kvantum ;
- SDDM / écran de connexion ;
- lock screen ;
- pack d'icônes complet et fonds d'écran.

**Pourquoi ne pas importer `icontasks` directement ?**

L'inventaire Ankh précédent a signalé un conflit potentiel d'identifiant avec l'applet Plasma Task Manager et une forte dépendance au code C++/ABI Plasma. Le projet a également choisi Tidewater pour les tâches. Ne réintroduis pas le conflit sans preuve que le problème a été résolu en amont et qu'il n'existe pas déjà un task manager Ankh actif.

**Pourquoi ne pas importer le System Tray C++ de ce dépôt directement ?**

Il s'agit d'un fork conséquent du conteneur système Plasma. Il peut remplacer ou dupliquer la zone système native et recouvrir les fonctions de l'applet Tidewater `status`. Conserve d'abord le System Tray Plasma natif et utilise l'applet Ankh/Tidewater pour l'expérience de paramètres rapides. N'envisage le fork que si un besoin Windows 11 précis n'est pas réalisable avec le conteneur natif et les widgets existants.

### 3.2 Tidewater — principale source d'interactions déjà intégrée

Dépôt : <https://github.com/addition-official/tidewater>  
Commit amont précédemment épinglé dans Ankh : `4484377` (à re-vérifier dans `docs/UPSTREAMS.md`).  
Licence déclarée : GPL-3.0-or-later. Vérifier le fichier de licence exact et les notices des dépendances.

**Composants que la documentation Ankh déclare déjà repris :**

| Chemin amont | Rôle | Décision |
|---|---|---|
| `plasmoids/status/` | Paramètres rapides : réseau, Bluetooth, volume, luminosité et états | Déjà repris : tester et améliorer, ne pas refaire. |
| `plasmoids/notifications/` | Centre de notifications | Déjà repris : valider intégration au service Plasma. |
| `plasmoids/tasks/` | Liste des fenêtres / tâches | Déjà repris selon UPSTREAMS : vérifier qu'il est réellement dans le panel actif. |
| `plasmoids/taskview/` | Vue des tâches / fenêtres | Déjà repris : vérifier sa distinction avec KWin Overview. |
| `plasmoids/divider/` | Séparateur de panneau | Déjà repris : vérifier le layout. |
| `switcher/tidewater-switcher/` | Sélecteur Alt+Tab | Déjà repris : tester avec KWin et le package/cache. |
| `common/` et `shared/` | Modules QML et paramètres partagés | Vérifier les import paths, les doublons et les dépendances nécessaires. |

**Composants Tidewater à examiner avant tout nouveau développement :**

- `plasmoids/power/` : actions d'alimentation et raccourcis. Comparer à PowerDevil et aux actions de session Plasma ; réutiliser le backend natif plutôt que gérer soi-même l'arrêt/suspension.
- `plasmoids/workspaces/` : sélecteur de bureaux. Comparer aux bureaux virtuels KWin et à l'applet native ; ne pas créer un second modèle de bureaux.
- `plasmoids/search/` : interface de recherche. Comparer à KRunner ; si la fonction est déjà assurée, brancher l'interface sur KRunner au lieu de développer un indexeur.
- `plasmoids/start/` : ne pas importer par défaut, car Ankh possède déjà le Start Menu de KDE-Windows-Modern.
- `plasmoids/clock/` : ne pas importer par défaut, car Ankh possède déjà le Digital Clock de KDE-Windows-Modern.
- `layout.js` : utiliser comme référence de structure uniquement. Ne pas écraser le layout Ankh complet.

**Limites et tests obligatoires :**

- Vérifier le fonctionnement sur la version Plasma 6 ciblée par Ankh, notamment les changements éventuels entre Plasma 6.6, 6.7 et 6.8.
- Vérifier les dépendances de chaque applet et helper ; ne pas supposer que `nmcli`, `rfkill`, `bluetoothctl`, `wpctl` ou `busctl` sont présents sur toutes les distributions.
- Vérifier la fréquence de polling, l'état réel des contrôles et la gestion des erreurs de commandes.
- Tester Wayland, multi-écran, mise à l'échelle, changement de thème et sortie de veille.
- Le switcher KWin peut nécessiter une invalidation de cache ou une nouvelle session après mise à jour : documenter et tester ce comportement.

### 3.3 KDE Plasma officiel — source privilégiée pour les services et modèles système

Dépôts de référence :

- <https://invent.kde.org/plasma/plasma-workspace>
- <https://invent.kde.org/plasma/plasma-desktop>
- <https://invent.kde.org/plasma/kwin>
- <https://invent.kde.org/plasma/powerdevil>
- <https://invent.kde.org/plasma/systemsettings>
- <https://invent.kde.org/system/dolphin>

**À réutiliser conceptuellement ou via API officielle :**

- modèles de fenêtres et de tâches ;
- système de notification Plasma ;
- modèles réseau, Bluetooth et audio accessibles à la version cible ;
- KRunner et ses runners ;
- API KWin de sélecteur de fenêtres ;
- effet Overview KWin ;
- bureaux virtuels et tiling KWin ;
- PowerDevil/UPower ;
- KCM de System Settings ;
- fonctions et panneaux Dolphin.

**Ne copie pas des classes internes KDE au hasard.** Préfère les API publiques et documentées. Si l'utilisation d'un module QML `org.kde.plasma.private.*` est inévitable, déclare-le comme dépendance privée, fixe une version cible, crée un test de compatibilité et prévois une solution de repli.

### 3.4 Quick Settings Plasma — référence d'implémentation, pas une source de code autorisée à ce stade

Dépôt : <https://github.com/luciotorelli/quicksettings-plasma>

Le projet illustre une approche avancée pour le réseau, le Bluetooth, l'audio, la luminosité, Night Light, Keep Awake et les profils d'énergie, avec des modèles et services KDE/DBus.

**Décision : STUDY ONLY.** La recherche précédente n'a pas trouvé de fichier `LICENSE` à la racine (URL `LICENSE` renvoyant 404). N'importe pas de code tant que le titulaire n'a pas confirmé explicitement une licence de réutilisation compatible.

Utilise-le uniquement pour comparer :

- comment obtenir des états en direct ;
- comment relier les contrôles aux services Plasma/DBus ;
- comment gérer les erreurs et l'absence de matériel ;
- comment éviter le polling shell inutile.

Ankh possède déjà `org.ankh.etat` issu de Tidewater : ne crée pas un deuxième quick settings applet.

### 3.5 PlasmaZones — option avancée, pas une dépendance centrale

Dépôt : <https://github.com/fuddlesworth/PlasmaZones>

Fonction : zones personnalisées de placement des fenêtres, tiling/auto-tiling et automatismes Wayland.

**Décision : DEFER / option externe.** Le projet a des exigences Qt/KF plus élevées que le plancher historique d'Ankh (des versions récentes indiquent notamment Qt 6.10 et KF 6.26). Vérifie les exigences exactes du tag choisi avant de le recommander.

Pour la version actuelle :

1. teste d'abord le tiling intégré à KWin ;
2. documente les dispositions disponibles ;
3. ne développe un Snap Layout Ankh que si les fonctionnalités natives ne satisfont pas la spécification ;
4. propose PlasmaZones comme extension facultative si la plateforme de l'utilisateur est compatible.

Ne relève pas le minimum de dépendances d'Ankh uniquement pour ajouter une fonction facultative.

### 3.6 NextKDE — référence d'architecture, pas de code à fusionner

Dépôt : <https://github.com/NextKde/NextKde>

NextKDE utilise Quickshell et une architecture de shell plus autonome. Son orientation visuelle est différente (plutôt macOS/Liquid Glass) et son modèle runtime n'est pas celui des applets Plasma classiques.

**Décision : STUDY ONLY.** Étudier éventuellement : séparation des services, gestion des paramètres, notifications, organisation QML. Ne pas importer son shell ni faire migrer Ankh vers Quickshell dans le cadre de cette tâche.

### 3.7 Projets secondaires à ne pas intégrer pour l'instant

| Projet | Raison de ne pas l'intégrer |
|---|---|
| `Eisteed/menu-11-next` — <https://github.com/Eisteed/menu-11-next> | Deuxième lanceur alors qu'Ankh possède déjà un menu ; licence et notices à revérifier avant toute reprise. Inspiration UX uniquement. |
| `venespana/KDE-Control-Center` — <https://github.com/venespana/kde-control-center> | Projet exploratoire/précoce ; System Settings et KCM existent déjà. |
| `venterum/KDE-Material-Quick-Settings` — <https://github.com/venterum/KDE-Material-Quick-Settings> | Doublon du quick settings Tidewater et retours de bugs d'état/synchronisation ; ne pas ajouter un deuxième applet. |
| `burninc0de/kde-filtered-taskbar` — <https://github.com/burninc0de/kde-filtered-taskbar> | Doublon du gestionnaire de tâches Tidewater/Plasma ; dépendances internes et logique de polling à éviter. |
| `Dreb1n/custom-calendar-widget` — <https://github.com/Dreb1n/custom-calendar-widget> | Doublon de Digital Clock et du calendrier Plasma déjà repris. Inspiration de réglages seulement. |
| `aeroshell-desktop/vistathemeplasma` — <https://github.com/aeroshell-desktop/vistathemeplasma> | Cible Windows Vista, remplace des widgets natifs et n'apporte pas de valeur claire à la direction Windows 11 d'Ankh. |
| `furkann-ahmet/4ztexDock` — <https://github.com/furkann-ahmet/4ztexDock> | Dock/taskbar layer-shell alternatif, projet expérimental et modèle différent ; risque de doubler Plasma Panel. Licence et maintenance à vérifier. |
| `innerpulsenet/ELEVEN` — <https://github.com/innerpulsenet/ELEVEN> | Référence visuelle Aero/Glass ; pas nécessaire d'importer un thème de fenêtres concurrent si KDecoration3 Ankh est déjà la base. |
| `TuxLux40/NeoWin` — <https://github.com/TuxLux40/NeoWin> | Référence de thème clair/sombre et de cohérence ; ne pas ajouter un gestionnaire de thème concurrent à Look-and-Feel/Color Schemes. |

---

## 4. Matrice anti-doublons : décision par fonctionnalité

Utilise cette matrice comme hypothèse de départ, puis renseigne son état réel après inspection du code et de la session.

| Fonctionnalité souhaitée | Ce qui existe déjà | Choix recommandé | Ne pas faire |
|---|---|---|---|
| Menu Démarrer | Applet KWM déjà reprise ; alternatives Kickoff et Tidewater Start | KEEP/ADAPT le menu Ankh actuel | Importer Menu 11 Next ou Tidewater Start en parallèle |
| Recherche depuis le menu | KRunner et runners KDE ; certaines fonctions de recherche Tidewater | CONFIGURE KRunner / réutiliser runners | Construire un indexeur fichier/applications maison |
| Barre des tâches | Task Manager Plasma ; Tidewater `tasks` repris ; KWM `icontasks` disponible | Vérifier le widget réellement actif puis choisir une seule implémentation | Installer deux gestionnaires de tâches ou l'Applet KWM avec identifiant en collision |
| Zone système | System Tray Plasma natif | CONFIGURE/styliser le conteneur natif | Importer le fork System Tray KWM sans nécessité prouvée |
| Paramètres rapides | Tidewater `status` repris | KEEP/ADAPT et valider les backends | Importer Quick Settings Plasma/Material en deuxième widget |
| Notifications | Daemon/modèle natif Plasma + Tidewater `notifications` | Un seul service Plasma, un seul centre visuel Ankh | Développer un deuxième daemon ou écouter les notifications en double |
| Horloge/calendrier | KWM Digital Clock + popup Plasma | KEEP et styliser | Ajouter Custom Calendar Clock ou Tidewater Clock en parallèle |
| Bouton Afficher le bureau | KWM Show Desktop repris ; fonction Plasma native | KEEP | Écrire un deuxième script de minimisation globale |
| Aperçu / Overview | Effet Overview KWin ; Tidewater `taskview` | CONFIGURE KWin et clarifier le rôle de `taskview` | Réécrire l'effet Overview complet |
| Alt+Tab | Switcher KWin natif + Tidewater switcher repris | KEEP/ADAPT le switcher Ankh | Installer un deuxième switcher ou intercepter Alt+Tab dans un autre daemon |
| Bureaux virtuels | KWin natif ; applet Plasma et Tidewater workspaces | CONFIGURE KWin, ajouter une UI seulement si absente | Créer un moteur de bureaux virtuels Ankh |
| Snap / tiling | KWin possède des fonctions de tiling ; PlasmaZones pour zones avancées | CONFIGURE KWin, PlasmaZones en option | Construire un daemon de snap avant tests des fonctions KWin |
| Wi-Fi | NetworkManager / Plasma NM ; Tidewater status | Piloter le backend existant | Maintenir une connexion réseau séparée dans Ankh |
| Bluetooth | BlueZ / BluezQt ; Tidewater status | Piloter le service existant | Gérer des appareils avec une logique concurrente ou seulement `rfkill` |
| Volume / sorties audio | PipeWire + Plasma PA ; Tidewater status | Utiliser les contrôles/modèles audio disponibles | Créer un mixer ou daemon audio Ankh |
| Luminosité / énergie | PowerDevil / UPower ; Tidewater status | Utiliser les services disponibles | Ajouter un poller qui concurrence PowerDevil |
| Recherche système | KRunner | CONFIGURE runners et apparence | Créer recherche et indexation globales depuis zéro |
| Explorateur de fichiers | Dolphin | CONFIGURE/style/toolbar/sidebar | Créer un explorateur de fichiers propriétaire |
| Paramètres système | System Settings + KCM | Personnaliser thème, catégories, raccourcis et pages | Réécrire tous les panneaux de réglages |
| Écran de verrouillage | KScreenLocker | Thème/configuration | Remplacer le mécanisme de verrouillage |
| Connexion | SDDM (selon distro) | Thème SDDM séparé et réversible | Installer un login manager propriétaire |
| Terminal | Konsole | Profil Ankh | Réécrire un terminal |
| App store | Discover / outils de paquet de la distro | Styliser et configurer | Créer une boutique Ankh |
| Capture d'écran | Spectacle | Raccourcis et apparence | Créer un outil capture concurrent |
| Profils clair/sombre | Look-and-Feel, Color Schemes, Plasma Style ; références NeoWin/KWM | Un seul mécanisme de changement cohérent | Deux démons qui modifient les couleurs simultanément |
| Icônes/curseurs | Fluent déjà intégré et thèmes KDE | Compléter les manques précis | Réimporter plusieurs packs entiers concurrents |
| Effets transparence/flou | KWin et effets Plasma | Configurer KWin, mesurer les coûts GPU | Ajouter un compositeur ou un moteur d'effets séparé |

---

## 5. Audit obligatoire : ce qui est dans le dépôt n'est pas forcément actif

Avant d'écrire du code, crée une matrice d'inventaire avec au minimum les colonnes suivantes :

| Capacité | Source amont | Fichiers présents dans Ankh | Déclarée dans le layout | Installée | Chargée dans session | Test fonctionnel | Décision |
|---|---|---|---|---|---|---|---|

Inspecte, selon l'arborescence réelle :

- `third_party/` et les éventuels sous-modules/vendor directories ;
- `src/applets/`, `src/plasmoids/`, `src/lookandfeel/` ;
- fichiers de layout Plasma/Look-and-Feel (`layout.js`, `contents/layouts/`, etc.) ;
- métadonnées `metadata.json`, `metadata.desktop`, `qmldir` ;
- scripts d'installation, de préparation et de désinstallation ;
- chemins d'installation sous `/usr/share/plasma/plasmoids` et les chemins utilisateur ;
- identifiants d'applets et import paths QML ;
- raccourcis globaux et raccourcis KWin ;
- services DBus et commandes shell exécutées par les widgets ;
- tests CI, tests statiques, tests VM et captures.

Commandes utiles (adapte les chemins après inspection) :

```bash
# Recherche des identifiants Ankh et des applets Plasma
rg -n 'org\.ankh\.|org\.kde\.plasma\.' .

# Recherche des widgets mentionnés dans les docs
rg -n -i 'start|launcher|kickoff|task|icontasks|systemtray|notification|status|quick|switcher|overview|search|clock|workspace' \
  src docs tests bench third_party 2>/dev/null

# Recherche des imports QML privés et de dépendances
rg -n 'org\.kde\.plasma\.private|import org\.kde\.plasma|Qt\.createQmlObject|DBus|D-Bus' \
  src third_party tests 2>/dev/null

# Recherche de commandes externes / polling
rg -n 'nmcli|rfkill|bluetoothctl|wpctl|busctl|qdbus|notify-send|sleep|while true|Timer' \
  src third_party 2>/dev/null

# Recherche des raccourcis concurrents
rg -n 'Alt\+Tab|Meta\+Tab|Meta\+T|Overview|Switch|KGlobalAccel|shortcut' \
  src config docs 2>/dev/null
```

Ne considère pas qu'une correspondance textuelle prouve qu'un composant est actif. Inspecte le code, les métadonnées et la disposition réellement chargée.

### 5.1 Vérifications runtime minimales

Dans une VM propre correspondant exactement à la version Plasma/Qt cible :

1. Installer Ankh avec l'installateur officiel.
2. Démarrer la session Ankh depuis le gestionnaire de connexion.
3. Capturer le panel complet et relever les identifiants d'applets.
4. Ouvrir le menu Démarrer et vérifier qu'il s'agit bien de `org.ankh.demarrer`, pas de Kickoff.
5. Ouvrir les paramètres rapides et vérifier états et actions réels.
6. Déclencher une notification d'une application ; vérifier qu'elle apparaît une seule fois.
7. Vérifier la zone système et les Status Notifier Items.
8. Ouvrir plusieurs fenêtres, changer de bureau, tester Alt+Tab et Overview.
9. Tester le volume, les sorties audio, Bluetooth et Wi-Fi avec et sans matériel disponible.
10. Vérifier l'horloge, le calendrier et le changement d'heure/date.
11. Tester Dolphin, System Settings, Discover et Konsole.
12. Fermer la session, redémarrer, reprendre après veille et vérifier les états.
13. Désinstaller Ankh et prouver que la session Plasma initiale et ses panneaux sont restaurés.

Une compilation réussie ne prouve pas qu'un widget est chargé. Une applet installée ne prouve pas qu'elle est utilisée. Une capture statique ne prouve pas qu'un bouton fonctionne.

---

## 6. Règles d'intégration : accélérer sans créer une dette technique

### 6.1 Une seule implémentation par responsabilité

Il ne doit y avoir qu'un seul :

- lanceur par défaut dans le panel ;
- gestionnaire de tâches dans le panel ;
- hôte System Tray ;
- contrôleur de notifications ;
- horloge principale ;
- switcher Alt+Tab actif ;
- moteur de recherche de système ;
- gestionnaire de profils clair/sombre ;
- gestionnaire réseau et énergie.

Une UI Ankh personnalisée peut remplacer l'apparence d'une fonction native, mais elle ne doit pas démarrer un deuxième service pour la même responsabilité.

### 6.2 Importer le minimum utile

Pour chaque composant externe retenu :

1. Épingler le dépôt et le commit exact.
2. Identifier la licence du dépôt **et celle du sous-répertoire/composant**.
3. Lire les `LICENSE`, `COPYING`, `NOTICE`, métadonnées et en-têtes de fichiers.
4. Copier uniquement les fichiers nécessaires à la fonctionnalité.
5. Préserver attribution et notices.
6. Renommer les IDs et espaces de noms Ankh proprement, sans casser DBus, QML ou les tests.
7. Documenter chaque modification locale dans `docs/UPSTREAMS.md`.
8. Garder un diff ou un patch de provenance facile à comparer avec l'amont.
9. Ajouter un test d'installation, de chargement et de fonctionnement.
10. Documenter le moyen de mettre à jour le composant depuis son amont.

Ne copie pas un dépôt entier simplement parce qu'il contient une fonction intéressante.

### 6.3 Licences et provenance

- Ne copie jamais du code sans licence vérifiable.
- Si la licence est absente ou ambiguë, classe la source `STUDY ONLY`.
- Vérifie la licence du composant précis, pas seulement le badge GitHub du dépôt.
- Préserve les mentions d'auteur et les conditions de redistribution.
- N'intègre pas d'assets propriétaires Windows (logos, sons, icônes ou ressources Microsoft) sans droit explicite.
- Les formes et comportements inspirés de Windows peuvent être recréés avec des ressources originales.
- Vérifie la compatibilité entre GPL-2.0+, GPL-3.0 et GPL-3.0-or-later au cas par cas ; ne suppose pas que tous les composants d'un projet ont la même licence.

### 6.4 Compatibilité Plasma/Qt

Déclare clairement :

- version Plasma minimale et version testée ;
- versions Qt/KF minimales ;
- Wayland/X11 pris en charge ;
- API publiques utilisées ;
- dépendances privées (`org.kde.plasma.private.*`) éventuelles ;
- commandes externes requises ;
- différences de comportement entre distributions.

Ne relève pas le minimum Qt/KF pour une fonction facultative sans décision explicite. Préfère les API publiques ; les API privées doivent avoir un test dédié et un plan de compatibilité.

### 6.5 Fiabilité des tests

- Chaque test bloquant doit sortir avec un code non nul en cas d'échec.
- N'utilise pas `|| true` pour cacher un échec.
- Ne transforme pas un test manquant en succès.
- Ne déclare pas « session validée » à partir d'une simple compilation.
- Les workflows Build, Banc et VM doivent correspondre au même SHA pour déclarer une version stable.
- Enregistre logs, captures et rapports avec le SHA testé.
- Les assertions visuelles doivent comparer les images/mesures et signaler les tolérances non respectées.

---

## 7. Ordre de travail obligatoire

Claude Code doit avancer dans cet ordre. Ne saute pas à une phase suivante si la phase précédente révèle un blocage P0.

### Phase A — Audit anti-doublons (aucune nouvelle fonctionnalité)

Livrables :

- inventaire des composants présents dans Ankh-DE ;
- liste des widgets actifs dans le layout ;
- correspondance avec les fonctions natives Plasma ;
- correspondance avec les dépôts amont ;
- licences et commits épinglés ;
- fonctionnalités véritablement manquantes ;
- liste des doublons/anciens composants non utilisés.

Créer ou actualiser `docs/ANTI_DOUBLONS.md` avec la matrice complète.

### Phase B — Réparer et prouver les fondations

Ordre :

1. Corriger les échecs CI en cours.
2. Vérifier l'installation et la session.
3. Prouver le menu Démarrer personnalisé.
4. Prouver quelle implémentation de task manager est active.
5. Prouver quelle implémentation de System Tray est active.
6. Prouver les paramètres rapides et les notifications.
7. Prouver le switcher Alt+Tab et Overview.
8. Vérifier désinstallation et restauration.

Aucun nouveau composant ne doit être importé pendant que les tests de ces fondations échouent.

### Phase C — Compléter uniquement ce qui manque

À partir de la matrice :

- si Tidewater a déjà le composant et qu'il n'est pas chargé, connecter et tester le composant existant ;
- si Plasma a le service, le configurer et créer seulement l'UI Ankh nécessaire ;
- si une API KDE manque, chercher d'abord une API publique ;
- si aucun composant ne répond au besoin, développer le minimum dans Ankh-DE.

Priorités fonctionnelles suggérées :

1. barre et zone système cohérentes ;
2. centre de notifications et paramètres rapides fiables ;
3. Alt+Tab / Overview / bureaux virtuels ;
4. intégration Dolphin et System Settings ;
5. échelle 125/150 %, multi-écran, accessibilité et thèmes clair/sombre.

### Phase D — Finitions et publication

- tests propres Fedora/Ubuntu/Arch selon le périmètre de la version ;
- paquets réellement installés et désinstallés ;
- cohérence des icônes, typographie, animations et ombres ;
- absence de doublons d'applets ;
- documentation exacte ;
- notes de version et crédits upstream.

---

## 8. Définition de « terminé » pour chaque fonctionnalité

Une fonctionnalité ne peut être marquée `DONE` que si tous les critères applicables sont remplis :

- [ ] Le composant exact et son propriétaire sont identifiés.
- [ ] La licence et la provenance sont documentées.
- [ ] Une seule implémentation est activée.
- [ ] L'installation fonctionne depuis une VM propre.
- [ ] Le composant apparaît dans la session Ankh.
- [ ] Son interaction principale fonctionne réellement.
- [ ] Les erreurs et l'absence de périphérique sont gérées.
- [ ] Il fonctionne après redémarrage et reprise de session.
- [ ] Il fonctionne à l'échelle d'affichage visée et sur un second écran si applicable.
- [ ] Les tests automatisés échouent réellement en cas de régression.
- [ ] La désinstallation/restauration ne laisse pas de panneau, raccourci ou configuration cassée.
- [ ] README, roadmap, journal et UPSTREAMS sont synchronisés.

Si un seul critère essentiel manque, marque la fonction `PARTIAL`, `INTEGRATED-UNVERIFIED` ou `BLOCKED`, pas `DONE`.

---

## 9. Format de rapport final exigé de Claude Code

Après l'audit et chaque phase, fournis un rapport structuré comme suit :

### A. État exact du dépôt

- branche ;
- HEAD SHA ;
- nombre de commits local et distant ;
- modifications locales préservées ;
- version Plasma/Qt réellement testée.

### B. Tableau anti-doublons

| Fonction | Présent dans Ankh | Natif KDE | Dépôt externe | Chargé en session | Action | Preuve |
|---|---|---|---|---|---|---|

### C. Travail évité

Indique quelles fonctionnalités n'ont pas été réécrites grâce à KDE ou aux dépôts existants, et pourquoi.

### D. Modifications réalisées

Pour chaque fichier : chemin, raison, source amont, commit, licence, comportement modifié.

### E. Tests

- commandes exécutées ;
- SHA exact testé ;
- résultat Build ;
- résultat Banc ;
- résultat VM ;
- captures/logs ;
- tests échoués et cause démontrée.

### F. Restant à faire

Sépare :

- bugs bloquants ;
- intégrations déjà disponibles mais non connectées ;
- fonctionnalités réellement absentes ;
- améliorations facultatives.

### G. Décision de la prochaine étape

Recommande une seule prochaine tâche prioritaire, avec la raison et les critères de fin.

---

## 10. Prompt d'exécution à utiliser

Claude Code, réalise maintenant l'audit anti-doublons décrit dans ce document directement dans le dépôt Ankh-DE.

Commence par vérifier l'état Git et lire les décisions et la spécification courantes. Ensuite, inspecte le code Ankh, les layouts Plasma, les métadonnées des applets, les scripts, les tests et les sources tierces déjà intégrées.

**Ne commence pas par coder une nouvelle fonctionnalité.** Établis d'abord la matrice complète de ce qui existe dans Ankh-DE, de ce que Plasma fournit nativement, de ce que les dépôts externes fournissent déjà, et de ce qui est effectivement chargé et testé dans la session Ankh.

Recherche spécialement les doublons entre :

- menu Ankh / Kickoff / Tidewater Start / Menu 11 Next ;
- Tidewater tasks / Task Manager Plasma / KDE-Windows-Modern icontasks ;
- System Tray Plasma / KDE-Windows-Modern System Tray / Tidewater status ;
- Tidewater status / Quick Settings Plasma / Material Quick Settings ;
- Tidewater notifications / Notification Manager Plasma ;
- KWM Digital Clock / Tidewater Clock / calendrier Plasma / Custom Calendar Widget ;
- Tidewater switcher / switcher KWin natif / autres Alt+Tab ;
- Tidewater taskview / KWin Overview ;
- KRunner / recherche Tidewater / recherche Menu Start ;
- Dolphin / tout explorateur de fichiers envisagé ;
- System Settings/KCM / tout panneau de paramètres envisagé ;
- KWin tiling / PlasmaZones / snapper maison ;
- PowerDevil / UPower / contrôle énergie Tidewater.

Pour chaque cas, donne les chemins de fichiers exacts, l'ID d'applet exact, le commit amont, la licence, les dépendances, l'état dans le layout, l'état en runtime et les tests disponibles. Ne suppose rien à partir du nom du dossier.

Après la cartographie, corrige les documentations contradictoires et les tests qui masquent des échecs. N'importe un composant que si la matrice prouve qu'il manque, que sa licence autorise la reprise et qu'il est compatible avec la cible Plasma/Qt d'Ankh.

Préserve toutes les modifications locales. Ne remplace pas l'architecture du projet. Ne remplace pas `plasmashell`, KWin, le gestionnaire de session ou les services système. Ne fais pas de grand refactoring non nécessaire.

À la fin, livre `docs/ANTI_DOUBLONS.md`, un rapport clair et les tests exécutés. Si une information ne peut pas être prouvée, marque-la explicitement `NON VÉRIFIÉE` au lieu de la présenter comme terminée.

---

## 11. Sources de recherche à consulter

Ces liens sont des points de départ pour l'audit. Vérifie le contenu actuel, les branches, tags, commits et licences avant de copier du code.

### Dépôts Ankh et sources déjà retenues

- Ankh-DE : <https://github.com/PatrickChoumi/Ankh-DE>
- KDE-Windows-Modern : <https://github.com/Jeysef/KDE-Windows-Modern>
- Tidewater : <https://github.com/addition-official/tidewater>
- Fluent KDE : <https://github.com/vinceliuice/Fluent-kde>
- Win11OS-kde : <https://github.com/yeyushengfan258/Win11OS-kde>
- NeoWin : <https://github.com/TuxLux40/NeoWin>
- ELEVEN : <https://github.com/innerpulsenet/ELEVEN>

### KDE natif

- Plasma Workspace : <https://invent.kde.org/plasma/plasma-workspace>
- Plasma Desktop : <https://invent.kde.org/plasma/plasma-desktop>
- KWin : <https://invent.kde.org/plasma/kwin>
- PowerDevil : <https://invent.kde.org/plasma/powerdevil>
- System Settings : <https://invent.kde.org/plasma/systemsettings>
- Dolphin : <https://invent.kde.org/system/dolphin>
- KRunner documentation : <https://develop.kde.org/docs/plasma/krunner/>
- KDE Developer documentation : <https://develop.kde.org/docs/plasma/>

### Sources à étudier avec restrictions

- Quick Settings Plasma : <https://github.com/luciotorelli/quicksettings-plasma> — pas de copie de code sans licence vérifiable.
- PlasmaZones : <https://github.com/fuddlesworth/PlasmaZones> — extension facultative, vérifier Qt/KF minimum.
- NextKDE : <https://github.com/NextKde/NextKde> — architecture seulement, pas de fusion de shell.
- Menu 11 Next : <https://github.com/Eisteed/menu-11-next> — inspiration ergonomique, pas de deuxième lanceur.
- KDE Material Quick Settings : <https://github.com/venterum/KDE-Material-Quick-Settings> — doublon à éviter.
- KDE Filtered Taskbar : <https://github.com/burninc0de/kde-filtered-taskbar> — doublon à éviter.
- Custom Calendar Widget : <https://github.com/Dreb1n/custom-calendar-widget> — doublon à éviter.
- 4ztexDock : <https://github.com/furkann-ahmet/4ztexDock> — architecture alternative expérimentale, ne pas intégrer dans le panel Plasma.

---

**Règle finale : Ankh-DE doit être une intégration cohérente des meilleures capacités déjà disponibles, pas une collection de copies de projets. Le meilleur code à écrire est souvent celui qu'on évite d'écrire parce qu'un composant KDE fiable ou un composant amont déjà intégré fait déjà le travail.**

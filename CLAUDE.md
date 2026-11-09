# CLAUDE.md — le seul document de règles d'Ankh DE

> **Ce fichier fait foi, et lui seul.** Aucun autre document ne porte de règle,
> d'état fonctionnel ni de priorité. S'il manque quelque chose ici, c'est ici
> qu'on l'ajoute.
>
> Pourquoi cette règle existe : le 2026-11-08, dix-huit documents portaient
> **4 557 lignes** de consignes qui se contredisaient — une règle corrigée
> depuis trois jours répétée à quatorze endroits, huit applets retirés encore
> présentés comme actifs à une soixantaine d'endroits, trois fichiers se
> déclarant chacun « l'état courant », et un guide affirmant qu'il primait sur
> celui-ci pendant que celui-ci affirmait l'inverse. Neuf fichiers ont été
> supprimés et leurs règles encore vraies sont ici.

| Je cherche… | Où |
|---|---|
| Les règles, l'état, l'ordre des travaux | **ce fichier** |
| Pourquoi un choix a été fait, et ce qu'il a remplacé | [DECISIONS.md](DECISIONS.md) — historique, jamais réécrit |
| Ce qui a été fait, daté | [AVANCEMENT.md](AVANCEMENT.md) — journal |
| D'où vient chaque pièce reprise, et sous quelle licence | [docs/UPSTREAMS.md](docs/UPSTREAMS.md), [LICENSES/](LICENSES/) |
| Installer, désinstaller, dépanner | [docs/INSTALL.md](docs/INSTALL.md) |
| Les mesures | [bench/jetons.toml](bench/jetons.toml) → [docs/FIDELITE.md](docs/FIDELITE.md) (généré) |
| Reporter sur une nouvelle version de Plasma | [docs/REBASE.md](docs/REBASE.md) |

---

## 1. Ce qu'est Ankh DE

**Prendre KDE Plasma 6 et lui donner l'apparence de Windows 11.** Rien de plus.

- Ce n'est **pas** un bureau écrit de zéro : ni compositeur, ni gestionnaire de
  session, ni `plasmashell` ne sont remplacés.
- Ce n'est **pas** une distribution, et **pas** un produit de Microsoft.
- Une seule pièce de la barre nous appartient : le **menu Démarrer**. Tout le
  reste est natif, habillé.
- **Cible : Ubuntu 26.04 LTS, Plasma 6.6.** Plage éprouvée **6.6 à 6.8**,
  Wayland.

> **Le nom du projet reste « Ankh DE », mais l'apparence visée est celle de
> Windows 11, sans identité Ankh.** Ce n'est pas une contradiction : l'identité
> graphite et violet est **figée sur la branche `ankh`** et reviendra plus tard
> comme variante. Sur la branche de travail, aucun violet.

---

## 2. L'ordre de choix — et BUILD n'est jamais le défaut

| | |
|---|---|
| **KEEP** | c'est déjà là et correct — ne pas y toucher |
| **CONFIGURE** | KDE le fournit — configurer, exposer, habiller le natif |
| **ADAPT** | un composant repris en est proche — l'adapter, sans en importer un second |
| **IMPORT** | la fonction manque VRAIMENT — le minimum, après audit de licence |
| **BUILD** | rien ne convient — écrire, et seulement là |
| **DEFER** | hors périmètre — ne pas faire dans cette version |

> **Avant d'importer : ouvrir le `main.xml` de l'applet natif.** Deux applets
> ont été importés le 2026-11-06 sur la foi de valeurs fausses écrites de
> mémoire — l'horloge de Plasma sait mettre la date sous l'heure
> (`dateDisplayFormat=BelowTime`) et `iconSpacing` est un entier, pas une
> énumération. Les deux ont été retirés le lendemain (DE-015).

## 3. Les cinq états, qu'il ne faut jamais confondre

**présent** → **installé** → **chargé** → **interactif** → **validé**

Une compilation ne prouve pas qu'un greffon est chargé. Un applet installé ne
prouve pas qu'il est dans la barre. Une capture ne prouve pas qu'un bouton
répond. **Et un test vert ne prouve pas qu'on voit quelque chose à l'écran** :
le 2026-11-08, le menu s'ouvrait, prenait le clavier, cherchait et lançait une
application — avec une grille d'épingles **vide**. Tant qu'un critère manque,
on écrit `PARTIEL` ou `BLOQUÉ`, jamais `FINI`.

## 4. Une seule implémentation par responsabilité

Un seul lanceur, un seul gestionnaire de tâches, un seul hôte de zone système,
un seul contrôleur de notifications, une seule horloge, un seul sélecteur
Alt+Tab, un seul moteur de recherche, un seul gestionnaire réseau et énergie.

Une interface peut remplacer l'**apparence** d'une fonction native ; elle ne
démarre jamais un second service pour la même responsabilité.

---

## 5. Règles non négociables

### Périmètre
1. Ne remplacer ni le compositeur, ni le gestionnaire de session, ni
   `plasmashell`.
2. Ne pas ajouter une deuxième barre, un deuxième menu, une deuxième horloge.
3. Reprendre du code libre est **permis et préféré** à le réécrire — mais
   **après** avoir prouvé que Plasma ne fournit pas déjà la fonction. Cinq
   conditions, toutes vérifiables : licence compatible GPL-3.0-or-later
   **portée par un fichier**, commit figé, provenance dans
   [docs/UPSTREAMS.md](docs/UPSTREAMS.md) avec ses modifications, rien de
   Microsoft, et **aucune pièce qui en écrase une de la distribution**.
4. Écartés pour une raison nommée : `menu-11-next` (licence en métadonnées,
   sans fichier), `icontasks` de KDE-Windows-Modern (il porte l'identifiant de
   l'applet standard), PlasmaZones (exige Qt 6.10+).

### Microsoft : ce qui est interdit, et ce qui ne l'est pas
5. **Interdit : tout fichier dont Microsoft ne donne pas le droit de
   redistribution** — la police Segoe UI, les icônes de Windows, ses sons, ses
   curseurs, ses fonds d'écran, ses captures, et **son logo**, qui est une
   marque déposée.
6. **Autorisé : ce que Microsoft publie sous licence libre, et les mesures.**
   La police **Selawik** est publiée par Microsoft sous **OFL 1.1** : elle est
   livrée, compilée depuis ses sources, nom réservé respecté. Les **mesures**
   (tailles, rayons, couleurs) sont des faits, pas des fichiers : elles se
   reprennent, avec leur source citée dans `bench/jetons.toml`.
   *Cette distinction remplace la formule « aucun fichier de Microsoft,
   jamais : police… », qui interdisait littéralement la Selawik que le dépôt
   livre depuis le lot 1.*
7. Le projet ne se présente jamais comme affilié à Microsoft et n'emploie pas
   « Windows » dans son nom.

### Ne rien casser
8. Les réglages vivent dans le thème global **et** dans `src/config/`, que la
   session place dans `XDG_CONFIG_DIRS` — parce que
   `plasma-apply-lookandfeel` ne recopie qu'un ensemble FIXE de clés et
   ignore les autres **en silence** (DE-010, qui corrige DE-002). Jamais
   d'écriture dans `/etc/xdg`, jamais de modification d'un thème de la
   distribution.
9. Toute action qui efface la configuration de l'utilisateur est **en option**
   et **confirmée**.
10. `desinstaller.sh` doit ramener à l'état de départ. Une pièce qu'on ne sait
    pas retirer ne s'installe pas.

### Mesure
11. Une affirmation de fidélité sans mesure du banc s'écrit `À VALIDER`. Une
    valeur de Windows 11 ne s'écrit jamais de mémoire : elle se lit dans une
    source publiée, citée dans `bench/jetons.toml`.
12. **La preuve est proportionnée au changement** : une correction de texte
    n'en demande aucune ; un changement visible demande une capture ; un
    changement de mesure demande le banc. *L'ancienne règle exigeait des
    captures en clair et sombre à 100, 125 et 150 % pour toute PR de lot —
    alors que le banc ne tourne qu'à 100 %. Elle était intenable, et trois
    lots étaient marqués FINI sans l'avoir suivie.*

### Code
13. `set -euo pipefail` dans chaque script. Jamais `|| true` sur un verdict.
14. Le code dérivé de Breeze reste aussi proche de l'original que possible :
    chaque écart rend le report plus coûteux.
15. La construction échoue si une bibliothèque ou un symbole manque
    (`ldd -r`), et si un texte qu'on remplace dans un fichier amont a changé.

### CI, sans exception
16. Tout contrôle qui échoue **sort en code non nul**. Interdit : une
    assertion non bloquante, un script qui imprime « ÉCHEC » puis sort en 0.
17. **Un garde-fou qu'on ne peut pas faire échouer ne garde rien.** Tout
    nouveau contrôle est éprouvé par **mutation** : on réintroduit le défaut,
    et on vérifie qu'il crie. Ce dépôt a écrit trois contrôles qui ne
    pouvaient pas échouer.
18. Une version n'est « stabilisée » que si **Construire, Banc et VM passent
    sur le MÊME SHA**.

---

## 6. État — qui tient quoi, et ce qui est prouvé

Dernières preuves : passage VM `42569636275` du 2026-11-09, **Ubuntu 26.04.1
LTS, Plasma 6.6.6**, session ouverte depuis SDDM. Un échec sur un essai
n'efface pas les essais qui ont réussi avant lui.

Ce passage a ramené les échecs de **8 à 1** sur la cible et de **6 à 2** sur
Fedora. L'unique échec d'Ubuntu est **de l'instrument, pas du produit**, et
il le dit lui-même : « plasmashell déclare 1 barre(s) mais l'image est
uniforme après 120 s ». La barre existe ; c'est la capture QEMU qui ne la
voit pas.

| Responsabilité | Implémentation | État |
|---|---|---|
| Lanceur | `org.ankh.demarrer` (KDE-Windows-Modern `7ef6bfe`) | **interactif** : s'ouvre, prend le clavier sans clic, cherche, **lance** (`pgrep` le confirme), se ferme sur Échap. **Disposition de Windows 11 VUE à l'écran** le 2026-11-08 : recherche en haut, grille d'épingles, utilisateur et alimentation en bas |
| Gestionnaire de tâches | `org.kde.plasma.icontasks` — natif | **interactif** : un clic minimise, un second rétablit |
| Zone système | `org.kde.plasma.systemtray` — natif | chargé ; ne masque **que** la cloche |
| Réseau, Bluetooth, volume, luminosité | applets natives | **visibles** ; aucune tuile pressée nommément |
| Notifications | `org.kde.plasma.notifications` — natif | **interactif** : une notification envoyée s'affiche |
| « Ne pas déranger » | service de Plasma | **non éprouvé** : le serveur ne se déclare pas inhibé après écriture de `plasmanotifyrc`, donc l'essai négatif ne prouverait rien |
| Horloge et calendrier | `org.kde.plasma.digitalclock` — natif | **interactif** : un panneau s'ouvre. Date **sous** l'heure, **sans secondes** — vérifié clé par clé et à l'écran |
| Afficher le bureau | `org.kde.plasma.showdesktop` — natif | **interactif** : masque et rétablit les fenêtres |
| Alt+Tab | `thumbnail_grid` — natif (KWin) | **interactif** sur Ubuntu 26.04 / Plasma 6.6 : le sélecteur change **45,07 %** de l'écran. Il fallait passer par le raccourci global de KWin, et non par « Alt maintenu » injecté par QEMU — c'est l'injection qui était en cause, pas la pièce |
| Vue des tâches | effet Overview de KWin (Meta+W) | **DEFER** hors de 0.1 |
| Style des contrôles | `org.ankh.style` (Breeze `ca217f1`) | **validé** : 12 jetons conformes, banc vert |
| Décoration | `org.ankh.decoration` (Breeze `ca217f1`) | 6 jetons sur 11. Chargement dans KWin **6.6** non établi |
| Couleurs | `Ankh.colors` / `AnkhClair.colors` | **validé** : valeurs de WinUI, **clair par défaut**, vu à l'écran le 2026-11-08 |
| Verrouillage | KScreenLocker — natif | **interactif** sur Ubuntu : l'écran se verrouille (**96,83 %**) et se déverrouille (**96,83 %**). Sur Fedora, le déverrouillage reste à 0,00 % — logind y refuse `unlock-session` |
| Désinstallation | `desinstaller.sh` | **validée sur Ubuntu** : les neuf pièces nommées disparaissent, le thème global revient à Breeze, une session **neuve** se rouvre (PID différent) et le style d'Ankh n'est plus appliqué. Sur Fedora, aucune session ne se rouvre en 180 s après le redémarrage de SDDM — **non tenu**, et c'est un vrai défaut à chercher |
| Fond d'écran | `Ankh-Prismes` (AnduinOS `c659fae`) | installé et posé, paire clair / sombre |

**27 jetons sur 53** mesurés et conformes : 12 contrôles, 6 fenêtres, 9 barre.

**Ce qui n'est pas prouvé** : les tuiles réseau / Bluetooth / volume /
luminosité nommément (le repérage rend une abscisse, pas un identifiant),
« Ne pas déranger » (le serveur de Plasma ne se déclare pas inhibé après
écriture de `plasmanotifyrc`, donc l'essai négatif ne prouverait rien), le
chargement de la décoration par KWin (demandé à KWin depuis `33a36c6`, pas
encore observé), Arch, les échelles 125 % et 150 %.

**Ce qui est cassé sur Fedora 44 / Plasma 6.8, et pas sur la cible** : le
déverrouillage, et la réouverture d'une session après désinstallation. Les
deux sont à chercher — mais aucun ne touche Ubuntu 26.04, qui est la cible
de 0.1.

**Ce qu'on ne fera pas**, et la raison : la **barre de menu globale** et la
**barre des tâches flottante** de KDE-Windows-Modern. Ses captures sont plus
finies que les nôtres, mais ce sont celles de macOS, et son menu Démarrer a
la forme de Windows 7 — colonne de catégories à gauche, barre d'actions en
bas. On lui emprunte sa finition, jamais sa disposition.

---

## 7. Ordre des travaux

1. **L'apparence de Windows 11 par défaut** — retirer la recoloration violette
   de `preparer.sh`, schémas de couleurs depuis WinUI, **clair par défaut**,
   glyphe neutre pour le bouton Démarrer.
2. **Le menu Démarrer** — recherche en haut, grille 6 × 3, section
   « Recommandé » (2 × 3, ~40 % de la hauteur utile), bas avec utilisateur à
   gauche et alimentation à droite. Mesures : **642 × 726** à 100 %, icône
   d'épingle **32 px**.
3. **Les défauts résiduels** — secondes de l'horloge, Alt+Tab, « Ne pas
   déranger », mesure de la barre.
4. **Éprouver** — désinstallation en VM, Arch, échelles 125 et 150 %.

---

## 8. Méthode de travail

### Avant d'agir
- Lire ce fichier. Il suffit.
- Pour un choix d'architecture : présenter les options **et une
  recommandation**. Le propriétaire tranche, puis la décision est écrite dans
  DECISIONS.md.

### Pendant
- Ne citer comme fait que ce qui est vérifié, avec sa source. Distinguer « lu
  dans la doc », « relevé par le banc » et « supposé ».
- **Regarder les captures.** Trois défauts en deux jours ne se voyaient qu'à
  l'image, aucun test ne les signalait : la barre mesurée à 800/0 parce
  qu'elle est en verre, un menu de Windows 7 pris pour un menu de Windows 11,
  et une grille d'épingles vide.
- Une décision qui change une règle corrige **ce fichier**, dans le même
  commit.

### Git
- Branche dédiée, pas de force-push. Un commit par changement cohérent,
  message en français, qui dit **pourquoi**.

### Après
- Rendre compte de : ce qui a changé (avec le commit), ce qui est vérifié, ce
  qui reste `À VALIDER`, et ce que le propriétaire doit faire lui-même.
- Mettre à jour le §6 de ce fichier et [AVANCEMENT.md](AVANCEMENT.md).
- Joindre les captures. Si une capture manque, dire pourquoi.

## 9. Construire et essayer

```bash
./third_party/preparer.sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc)"
./installer.sh --utilisateur    # essayer sans toucher au système
./desinstaller.sh               # tout défaire
```

Contrôles locaux avant tout envoi :

```bash
./tests/garde-version.sh && ./tests/barres.sh && ./ci/verifier-coherence.sh
python3 tests/ordre-des-fonctions.py $(git ls-files '*.sh')
python3 tests/qml-imports.py $(git ls-files 'src/**/*.qml')
shellcheck -x -i SC2154,SC2034 $(git ls-files '*.sh')
```

**Langue du projet** : français. `README.en.md` est la seule pièce en anglais.

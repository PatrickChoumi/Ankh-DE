# CLAUDE.md — Guide du projet Ankh DE

> Claude Code lit ce fichier au début de chaque session. Il fixe **les règles, la méthode et
> l'état**. Les détails vivent ailleurs et ne sont pas recopiés ici.
>
> | Je cherche… | Fichier |
> |---|---|
> | Ce qu'Ankh DE doit être, la référence Windows 11, les limites, la liste NON | [ANKH-DE-SPEC.md](ANKH-DE-SPEC.md) |
> | Chaque choix, ses raisons, ses sources et ses tests (`DE-xxx`) | [DECISIONS.md](DECISIONS.md) |
> | L'ordre des travaux, lot par lot | [ROADMAP.md](ROADMAP.md) |
> | Ce qui est fait, et ce qui n'est pas vérifié | [AVANCEMENT.md](AVANCEMENT.md) |
> | **Tout ce qui manque, et le plan d'une semaine** | [AUDIT.md](AUDIT.md) |
> | Comment reporter sur une nouvelle version de Plasma | [docs/REBASE.md](docs/REBASE.md) |
> | Comment c'est agencé, et le rapport avec Ankh | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
>
> En cas de contradiction : **DECISIONS.md fait foi pour les choix**, **ANKH-DE-SPEC.md pour la
> cible**. Ce fichier est alors à corriger.

---

## 1. Ankh DE en cinq lignes

- Une suite de thèmes, de greffons et d'applets pour **KDE Plasma 6**, qui lui donne la géométrie
  de Windows 11 sous les couleurs d'Ankh (DE-001, DE-003).
- **Pas** un environnement de bureau écrit de zéro, **pas** un clone de Windows, **pas** une
  distribution.
- Installable sur Fedora, Arch et Ubuntu, sans toucher à un seul fichier de la distribution, et
  réversible d'un geste (DE-002).
- « Au pixel près » n'est dit que de ce que **le banc mesure** (DE-007). Le reste est `À VALIDER`.
- Rien de Microsoft dans le dépôt : seules les mesures, publiées sous licence MIT (DE-005).

## 2. État actuel

- **Lot en cours : 0 — Autonomie.** Son tableau est dans
  [ROADMAP.md](ROADMAP.md#lot-0--autonomie). Fait et **éprouvé en conteneur Fedora 44** :
  CMake, thème global, `preparer.sh`, garde-fous, et le banc du style (`bench/captures.sh`),
  dont toutes les mesures du lot 3 sont conformes. Reste : le test en session (0.7, décoration,
  barre, Démarrer) et les paquets (0.8).
- **Lots 1 et 3 mesurés ici**, dans ce dépôt, par `bench/captures.sh`. Le **lot 2** (décoration
  des fenêtres) ne l'est pas : il demande une session avec KWin.
- Ne jamais présenter une mesure d'Ankh comme une mesure d'Ankh DE : citer le dépôt et le run.
- **Version de Plasma visée : 6.8** (`src/*/VERSION-BREEZE`). La source reste Breeze 6.7.5, qui
  compile tel quel contre 6.8. Monter de version est **notre** décision de release, pas une
  contrainte de KDE (DE-008).
- **Langue du projet** : français (documents, commits, échanges). `README.en.md` est la seule
  pièce en anglais, parce que le public visé ne lit pas forcément le français.

> Mettre cette section à jour à chaque changement de lot.

## 3. Règles non négociables

Elles ne se contournent pas. Si une règle bloque, on ouvre une décision dans DECISIONS.md.

### Périmètre
1. On ne remplace ni le compositeur, ni le gestionnaire de session, ni `plasmashell` (DE-001).
2. On n'embarque pas un projet tiers **comme code** (Klassy, Lightly, Menu11,
   KDE-Rounded-Corners). Des **images** et des **feuilles de style** tierces, oui, à un commit
   figé et avec leur licence (SPEC §5.6).

### Licence et actifs
3. **Aucun fichier de Microsoft**, jamais : police, icône, son, curseur, fond d'écran, capture,
   logo. Seules les **mesures** sont reprises, de sources MIT, chacune citée avec son commit
   (DE-005).
4. Tout fichier venu d'ailleurs est déclaré dans `LICENSES/`, et son en-tête de licence est
   conservé tel quel.
5. Le projet ne se présente jamais comme affilié à Microsoft, et n'emploie pas « Windows » dans
   son nom.

### Ne rien casser
6. Les réglages vivent **uniquement** dans `src/lookandfeel/org.ankh.de.desktop/contents/defaults`.
   Jamais d'écriture dans `/etc/xdg`, jamais de modification d'un thème de la distribution, jamais
   d'écriture silencieuse dans `~/.config` (DE-002).
7. Toute action qui efface la configuration de l'utilisateur — en pratique `--resetLayout`, qui
   remplace ses barres — est **en option** et **confirmée** par une question.
8. `desinstaller.sh` doit ramener à l'état de départ. Une pièce qu'on ne sait pas retirer ne
   s'installe pas.

### Mesure
9. Une affirmation de fidélité sans mesure du banc est marquée `À VALIDER`. On ne dit pas « au
   pixel près » d'une surface que le banc ne mesure pas (DE-007).
10. Une mesure d'Ankh n'est pas une mesure d'Ankh DE : citer le dépôt et le run.
11. Aucune PR de lot ne fusionne sans ses mesures conformes, ses captures avant/après (sombre et
    clair, 100/125/150 %) et mon accord.

### Code
12. `set -euo pipefail` dans chaque script. Jamais `|| true` pour masquer une erreur. Une
    construction qui rencontre un problème **échoue**.
13. Le code dérivé de KDE reste aussi proche de l'original que possible : chaque écart rend le
    report plus coûteux (DE-008, `docs/REBASE.md`). Un changement de confort qui n'atteint pas une
    mesure de `bench/jetons.toml` ne se fait pas.
14. La construction échoue si une bibliothèque ou un symbole manque (`ldd -r`), et si un texte
    qu'on remplace dans un fichier de KDE a changé en amont — plutôt que de laisser un contrôle
    à moitié adapté.

## 4. Règles de travail pour Claude Code

### Avant d'agir
- Lire les `DE-xxx` et les sections de la SPEC concernées.
- Vérifier que le **lot en cours** (§2) autorise la tâche.
- Ne jamais inventer une réponse à une question ouverte (SPEC §7) : la poser.
- Pour un choix d'architecture : présenter les options **et une recommandation**. C'est moi qui
  tranche, puis la décision est écrite dans DECISIONS.md.

### Pendant
- Ne citer comme fait que ce qui est vérifié, avec sa source ou son test. Distinguer « lu dans la
  doc », « relevé par le banc » et « supposé ».
- Une valeur de Windows 11 ne s'écrit jamais de mémoire : elle se lit dans WinUI, et son commit
  est cité dans `bench/jetons.toml`.
- DECISIONS.md : on ne supprime pas une entrée ; une décision qui change en cite l'ancienne ;
  l'index reste à jour.

### Git
- Travailler sur une branche dédiée. Pas de push direct sur `main`, pas de force-push.
- Claude commite et pousse sur la branche de travail sans demander. Un commit par changement
  cohérent, message en français, qui dit **pourquoi**.

### Après
- Rendre compte de : ce qui a changé (avec le commit), ce qui est vérifié, ce qui reste
  `À VALIDER`, et ce que **je** dois faire moi-même (VM, machine réelle, dépôt).
- Mettre à jour [AVANCEMENT.md](AVANCEMENT.md).
- Joindre les captures du banc. Si une capture manque, dire pourquoi.
- Claude ne peut pas tester sur ma machine. Le dire, plutôt que de présenter un résultat non
  testé comme acquis.

## 5. Déroulé type d'une tâche

1. **Comprendre** : quel lot ? quelles décisions, quelles mesures de `jetons.toml` ?
2. **Vérifier** : aucune question ouverte bloquante, aucune décision `À DÉCIDER` nécessaire.
3. **Proposer**, si la tâche touche l'architecture. J'arbitre, on écrit la décision.
4. **Réaliser** sur une branche, sans contourner le §3.
5. **Mesurer** : le banc, la CI, la VM. Noter ce qui n'a pas pu être mesuré.
6. **Rendre compte** (§4).

## 6. Construire et essayer

```bash
./third_party/preparer.sh      # police, curseurs, thème GTK (une fois)
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc)"
```

Pour essayer sans toucher au système : `./installer.sh --utilisateur`, puis se reconnecter.
Pour tout défaire : `./desinstaller.sh`.

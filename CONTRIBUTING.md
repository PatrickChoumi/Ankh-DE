# Contribuer à Ankh DE

Les documents du projet sont en français ; les issues et les PR en anglais sont bienvenues.
*Project documents are in French; issues and pull requests in English are welcome.*

## La seule règle qui compte

**Une affirmation de fidélité sans mesure du banc n'est pas acceptée**
([DE-007](DECISIONS.md#de-007--le-banc-de-mesure-est-le-critère-dacceptation-de-chaque-lot)).

« Ça ressemble plus à Windows 11 » n'est pas un argument. Ce qui est un argument : une mesure de
[`bench/jetons.toml`](bench/jetons.toml) qui passe de « écart » à « conforme », avec le run qui le
montre. Et si la mesure n'existe pas encore, la PR commence par l'ajouter — **avec sa source**
(fichier et commit de WinUI, ou page de la documentation de Microsoft).

## Où l'aide est la plus utile

1. **Le rebase sur chaque version de Plasma** ([docs/REBASE.md](docs/REBASE.md)). C'est le seul
   coût récurrent, et c'est ce qui tue les projets de ce genre. Plasma 6.8 supprime X11 : le
   portage est à faire.
2. **Faire marcher le lot 0 sur Arch et Ubuntu** : le code n'a été construit que sur Fedora 44.
   Voir [ROADMAP.md](ROADMAP.md#lot-0--autonomie).
3. **Les lots 4 à 10** : le shell, Démarrer, les paramètres rapides. Le détail est dans
   [ROADMAP.md](ROADMAP.md).
4. **Les paquets** : COPR, AUR, PPA. Les squelettes sont dans `packaging/`, aucun n'est testé.

## Ce qui sera refusé

- **Un fichier de Microsoft**, quel qu'il soit : police, icône, son, curseur, fond d'écran,
  capture d'écran, logo
  ([DE-005](DECISIONS.md#de-005--rien-de-microsoft-dans-le-dépôt--seules-les-mesures-publiées-sous-licence-mit)).
  La CI le refuse aussi.
- **Un écart dans le code dérivé de Breeze** qui n'atteint aucune mesure du banc : chaque écart
  rend le rebase plus coûteux (CLAUDE.md §3.13).
- **Une écriture de configuration hors du thème global** : pas de `/etc/xdg`, pas de modification
  d'un thème de la distribution, pas d'écriture silencieuse dans `~/.config`
  ([DE-002](DECISIONS.md#de-002--tous-les-réglages-vivent-dans-notre-thème-global-jamais-dans-etcxdg-ni-dans-les-thèmes-de-la-distribution)).
- **Une action irréversible** non confirmée par l'utilisateur.
- **Un projet tiers embarqué comme code** (Klassy, Lightly, Menu11…). Des images et des feuilles
  de style tierces, oui, à un commit figé et déclarées dans `LICENSES/`.
- `|| true` pour masquer une erreur, ou un script sans `set -euo pipefail`.

## Une PR de lot

1. une branche par lot ;
2. les mesures du lot **conformes** dans la VM de test ;
3. les captures « avant » et « après », en sombre et en clair, à 100, 125 et 150 % ;
4. `bench/jetons.toml` à jour : le numéro du lot ajouté à `lots_termines`, les mesures atteintes ;
5. `python3 bench/fidelite.py` relancé (la CI refuse la PR si `docs/FIDELITE.md` diffère) ;
6. `AVANCEMENT.md` mis à jour : ce qui est vérifié, et ce qui ne l'est pas.

## Construire

```bash
./third_party/preparer.sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc)"
./installer.sh --utilisateur    # essayer sans toucher au système
```

## Licence

En contribuant, vous acceptez que votre contribution soit distribuée sous **GPL-3.0-or-later**
([DE-006](DECISIONS.md#de-006--dépôt-public-sous-gpl-30-or-later)).

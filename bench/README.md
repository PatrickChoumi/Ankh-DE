# Le banc de mesure

> C'est lui qui rend « au pixel près » vérifiable plutôt que décoratif
> ([DE-007](../DECISIONS.md#de-007--le-banc-de-mesure-est-le-critère-dacceptation-de-chaque-lot)).

| Fichier | Rôle |
|---|---|
| `jetons.toml` | **La référence** : 47 mesures, chacune avec sa cible Windows 11, sa tolérance, son unité, sa source et son lot. `lots_mesures_obligatoires` dit lesquelles font échouer le test ; `lots_complets` dit quels lots n'ont plus de jeton à mesurer — les deux ne se confondent pas |
| `fidelite.py` | Génère [`../docs/FIDELITE.md`](../docs/FIDELITE.md) depuis `jetons.toml`. La CI refuse la PR si le fichier versionné diffère : le tableau de fidélité ne peut donc pas mentir |
| `mesurer.py` | Mesure sur les captures : rayon des coins (aire manquante à l'angle, r²(1 − π/4) pour un quart de cercle), taille et couleur du bouton Fermer survolé, hauteur et couleur de la barre des tâches. Sans module tiers |
| `banc.sh` | Pilote la session dans la VM : lit les réglages, place les fenêtres, ouvre la galerie, prend les captures, écrit `ui-rapport.md` |
| `org.ankh.banc/` | La galerie des contrôles : un widget Plasma qui montre chaque contrôle et écrit dans le journal la police et les tailles que le style lui donne (`implicitHeight`, indicateurs) |

## État : `banc.sh` ne tourne pas encore ici

`banc.sh` et `org.ankh.banc/` viennent du dépôt [Ankh](https://github.com/PatrickChoumi/Ankh)
(`tests/vm/banc/`), où ils sont pilotés par son banc d'essai en VM : ils attendent les fonctions
`vm_copier` et `launch_in_session` de `tests/vm/run.sh`, la variable `$repo`, et le compte de test
`ankhvm`. **Rien de cela n'existe dans ce dépôt.**

Le porter sur une VM Plasma nue est la tâche **0.5** du
[lot 0](../ROADMAP.md#lot-0--autonomie). Tant qu'elle n'est pas faite :

- `jetons.toml`, `fidelite.py` et `mesurer.py` sont utilisables tels quels ;
- les mesures citées dans le README et dans `AVANCEMENT.md` sont celles **d'Ankh**, relevées sur
  **Fedora 44 seulement**, avec le run qui les prouve. Ce ne sont pas des mesures d'Ankh DE
  (CLAUDE.md §3.10).

## Ce qui est mesuré, et comment

La partie délicate est le **rayon des coins** : il se déduit de l'aire manquante à l'angle sur
l'image. Vérifié sur des images de synthèse dans Ankh le 2026-10-15 : retrouvé à 0,2 px près sans
contour, à 0,5 px près avec un contour clair, mais **sous-estimé d'environ 1 px** avec un contour
plus sombre que le fond de la fenêtre. Les captures se font sur un fond d'écran noir, pour que
l'ombre (noire) ne compte pas.

## Régénérer le tableau de fidélité

```bash
python3 bench/fidelite.py              # écrit docs/FIDELITE.md
python3 bench/fidelite.py --verifier   # ce que fait la CI
```

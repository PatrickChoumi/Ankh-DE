# REBASE — reporter Ankh DE sur une nouvelle version de Plasma

> C'est **le seul coût récurrent du projet**, et la raison pour laquelle les thèmes à mainteneur
> unique meurent ([DE-008](../DECISIONS.md#de-008--le-code-dérivé-de-kde-est-reporté-à-chaque-version-de-plasma-et-la-construction-échoue-tant-que-ce-nest-pas-fait)).
> À faire à chaque version de Plasma, avant qu'elle n'arrive chez les utilisateurs.

## Le calendrier de Plasma

Plasma sort environ **deux fois par an**. Relevé le 2026-11-05 sur la liste `plasma-devel`
(brouillons, **non définitifs** — à confirmer sur la page officielle du calendrier de KDE
avant de s'y fier) :

| Version | Date annoncée | Conséquence pour nous |
|---|---|---|
| 6.7.0 | 2026-06-16 | version actuellement suivie. **Dernière avec X11** |
| 6.8.0 | 2026-10-14 ou le 20 (les sources divergent) | **Wayland seul.** Portage à prévoir |

Précédent utile : le passage de **KDecoration2 à KDecoration3** en Plasma 6.3 a cassé les réglages
de [Klassy](https://github.com/paulmcauley/klassy/releases), un projet au même modèle que le
nôtre. Une version mineure peut suffire à casser un greffon.

## Ce qui est suivi

| Fichier | Contenu |
|---|---|
| `src/style/VERSION-BREEZE` | dépôt, tag, commit et version de Plasma dont `src/style` est dérivé |
| `src/decoration/VERSION-BREEZE` | idem pour la décoration |

La construction **échoue** si la version de Plasma installée n'est pas celle suivie. Pour passer
outre en connaissance de cause : `-DANKH_DE_PLASMA_NON_TESTE=ON`.

## La procédure

1. **Lire le journal de Breeze** entre le commit suivi et le nouveau tag :
   ```bash
   git -C /chemin/vers/breeze log --oneline ca217f1..v6.8.0 -- kstyle libbreezecommon kdecoration
   ```
2. **Relever les changements d'API** : symboles disparus, signatures changées, fichiers
   `.kcfg` modifiés. Les changements de KDecoration et de `KStyle` sont les plus coûteux.
3. **Reporter**, fichier par fichier. Nos fichiers portent le nom `ankh*` au lieu de `breeze*` :
   un `diff` direct ne marche pas, il faut comparer le fichier d'origine renommé.
   **Chaque écart que nous avons introduit est documenté** : c'est pourquoi la règle
   CLAUDE.md §3.13 interdit les écarts qui n'atteignent pas une mesure du banc. Moins d'écarts,
   report moins coûteux.
4. **Mettre à jour les deux `VERSION-BREEZE`.**
5. **Construire** : la CI vérifie que `ldd -r` passe, qu'aucun symbole ne manque, et que les
   textes remplacés dans les fichiers de KDE (`src/qqc2/adapter.py`) existent toujours — sinon
   elle échoue, plutôt que de laisser un contrôle à moitié adapté.
6. **Mesurer en VM** : toutes les mesures des lots terminés doivent rester conformes
   ([docs/FIDELITE.md](FIDELITE.md)). Un écart nouveau est une régression, pas une tolérance à
   élargir.
7. **Vérifier les modules privés** : Démarrer (lot 5) et les paramètres rapides (lot 6)
   dépendent de `org.kde.plasma.private.kicker`, `…private.volume`, `…private.bluetooth` et
   `…private.brightnesscontrolplugin`. Ce sont eux qui cassent le plus souvent.
8. **Rendre compte** dans `AVANCEMENT.md`, et dans une entrée `DE-xxx` si l'API a forcé un choix.

## Prévenir avant la sortie

Un test de CI hebdomadaire construit contre la version de Plasma de **Fedora Rawhide** et de
**Arch**, qui prennent les nouvelles versions avant tout le monde. Il n'est pas bloquant : il
prévient.

## Si le report est impossible

Mieux vaut un thème qui **refuse de se charger** qu'un thème à moitié chargé. Dans ce cas :
1. épingler la dernière version de Plasma qui marche dans le README, visiblement ;
2. ouvrir une issue qui dit exactement ce qui casse, avec le symbole ou le fichier en cause ;
3. ne pas publier de paquet pour la nouvelle version de Plasma.

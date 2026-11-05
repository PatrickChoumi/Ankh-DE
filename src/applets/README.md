# Applets — lots 5 et 6

Vide pour l'instant.

| À écrire | Lot | Ce que c'est |
|---|---|---|
| `org.ankh.demarrer/` | 5 | Démarrer, en QML, dérivé de Kickoff : recherche en haut, 6 × 3 épingles de 32 px, « Toutes les applications », « Recommandé », compte et alimentation en bas |
| `org.ankh.parametres/` | 6 | Les paramètres rapides en **un seul volet** : Wi-Fi, Bluetooth, volume, luminosité |

**Avertissement** : les deux dépendent de modules **privés** de Plasma
(`org.kde.plasma.private.kicker`, `…private.volume`, `…private.bluetooth`,
`…private.brightnesscontrolplugin`). Aucune garantie d'une version à l'autre : c'est la partie la
plus fragile du projet ([ANKH-DE-SPEC.md §4.3](../../ANKH-DE-SPEC.md#43-fragile-par-nature)).
C'est aussi ce que le test hebdomadaire contre l'amont surveille en premier
([docs/REBASE.md](../../docs/REBASE.md)).

Tant que `org.ankh.demarrer` n'existe pas, le thème global retombe sur Kickoff : son
`layouts/*.js` l'essaie, et attrape l'échec.

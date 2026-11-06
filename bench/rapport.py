#!/usr/bin/env python3
"""Compare les mesures relevées aux cibles de Windows 11 et écrit le rapport.

    bench/rapport.py <dossier de sortie>

Lit les `mesures-*.json` écrits par la galerie, les compare à
`bench/jetons.toml`, écrit `rapport.md` et rend un code d'erreur si une
mesure d'un lot TERMINÉ s'écarte de sa cible (DE-007).

Sans module tiers : tomllib est dans la bibliothèque standard.
"""
from __future__ import annotations

import json
import sys
import tomllib
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent


def charger_jetons() -> tuple[dict[str, dict], set[int]]:
    d = tomllib.loads((RACINE / "bench" / "jetons.toml").read_text(encoding="utf-8"))
    return {m["id"]: m for m in d["mesure"]}, set(d.get("lots_mesures_obligatoires", []))


def comparer(jeton: dict, valeur) -> tuple[str, str]:
    """Rend (état, écart lisible). État : conforme, ECART, relevé."""
    cible = jeton.get("cible")
    if cible is None:
        return "relevé", ""
    if isinstance(cible, str):
        if str(valeur) == cible:
            return "conforme", ""
        return "ECART", f"attendu `{cible}`"
    try:
        v = float(valeur)
    except (TypeError, ValueError):
        return "ECART", f"valeur illisible : {valeur!r}"
    tol = float(jeton.get("tolerance") or 0)
    diff = v - float(cible)
    if abs(diff) <= tol:
        return "conforme", ""
    return "ECART", f"{diff:+g}"


def main() -> int:
    sortie = Path(sys.argv[1] if len(sys.argv) > 1 else RACINE / "bench" / "sortie")
    jetons, termines = charger_jetons()

    releves: dict[str, dict] = {}
    for f in sorted(sortie.glob("mesures-*.json")):
        releves[f.stem.removeprefix("mesures-")] = json.loads(f.read_text(encoding="utf-8"))
    if not releves:
        print(f"Aucun mesures-*.json dans {sortie}", file=sys.stderr)
        return 1

    # Les colonnes : un relevé par thème et par style.
    colonnes = sorted(releves)
    # Les identifiants mesurés par la galerie, dans l'ordre de jetons.toml
    # puis les surnuméraires (que la galerie mesure sans qu'ils soient une cible).
    vus = {k for r in releves.values() for k in r}
    ids = [i for i in jetons if i in vus] + sorted(vus - set(jetons))

    lignes = [
        "# Rapport du banc — style des contrôles",
        "",
        "> Écrit par `bench/rapport.py`, depuis les mesures de la galerie",
        "> (`bench/galerie`) relevées sous Xvfb par `bench/captures.sh`.",
        "> Les cibles viennent de [`bench/jetons.toml`](jetons.toml).",
        ">",
        "> Les colonnes `*-breeze` sont le « avant » : Breeze, aux mêmes couleurs,",
        "> pour que la comparaison ne porte que sur le style.",
        "",
        "| Mesure | Cible Win11 | " + " | ".join(colonnes) + " | Lot |",
        "|---|---|" + "---|" * len(colonnes) + "---|",
    ]

    echecs: list[str] = []
    for i in ids:
        j = jetons.get(i, {})
        cible = j.get("cible")
        unite = j.get("unite", "")
        cible_txt = "*relevé*" if cible is None else (f"`{cible}`" if isinstance(cible, str) else f"{cible} {unite}".strip())
        if i not in jetons:
            cible_txt = "*hors jetons*"
        cellules = []
        for c in colonnes:
            if i not in releves[c]:
                cellules.append("—")
                continue
            v = releves[c][i]
            etat, ecart = comparer(j, v) if i in jetons else ("relevé", "")
            marque = {"conforme": "✓", "ECART": "✗", "relevé": "·"}[etat]
            cellules.append(f"{marque} {v}" + (f" ({ecart})" if ecart else ""))
            # Un écart ne fait échouer que sur le style d'Ankh, et que si les
            # mesures du lot sont obligatoires : Breeze est le « avant », il a
            # le droit d'être loin.
            if etat == "ECART" and c.endswith("-ankh") and j.get("lot") in termines:
                echecs.append(f"{i} [{c}] : {v} au lieu de {cible} ({ecart})")
        lot = j.get("lot", "—")
        lignes.append(f"| `{i}` | {cible_txt} | " + " | ".join(cellules) + f" | {lot} |")

    lignes += [
        "",
        f"**Lots dont les mesures relevées sont obligatoires** : "
        + (", ".join(str(n) for n in sorted(termines)) or "aucun"),
        "",
        "Légende : ✓ conforme · ✗ écart · · relevé seulement (pas de cible).",
        "",
        "## Ce que ce rapport NE dit pas",
        "",
        "La galerie ne dépend que de Qt Widgets : elle mesure le **style des",
        "contrôles**, et rien d'autre. Restent à mesurer en VM, avec Plasma :",
        "la décoration des fenêtres (lot 2), la barre des tâches, Démarrer, les",
        "notifications, les rayons des coins (qui se mesurent sur l'image), et",
        "les contrôles QtQuick de KDE.",
    ]
    (sortie / "rapport.md").write_text("\n".join(lignes) + "\n", encoding="utf-8")
    print(f"{sortie / 'rapport.md'} écrit.")

    conformes = sum(1 for l in lignes if "| ✓ " in l or "| ✓" in l)
    print(f"  colonnes : {', '.join(colonnes)}")
    if echecs:
        print(f"\n{len(echecs)} écart(s) sur une mesure obligatoire, dans le style d'Ankh :", file=sys.stderr)
        for e in echecs:
            print(f"  {e}", file=sys.stderr)
        return 1
    print("  aucun écart sur une mesure obligatoire.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

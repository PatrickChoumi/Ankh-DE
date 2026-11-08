#!/usr/bin/env python3
"""Fabrique docs/FIDELITE.md depuis bench/jetons.toml (DE-007).

Le tableau de fidélité n'est jamais écrit à la main : il est généré depuis la
référence, pour qu'il ne puisse pas mentir. La CI le régénère et refuse la PR
si le fichier versionné diffère.

Sans module tiers : tomllib est dans la bibliothèque standard depuis Python 3.11.
"""
from __future__ import annotations

import sys
import tomllib
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
JETONS = RACINE / "bench" / "jetons.toml"
SORTIE = RACINE / "docs" / "FIDELITE.md"

TITRES = {
    0: "Lot 0 — autonomie",
    1: "Lot 1 — fondations",
    2: "Lot 2 — fenêtres",
    3: "Lot 3 — contrôles",
    4: "Lot 4 — shell",
    5: "Lot 5 — Démarrer",
    6: "Lot 6 — paramètres rapides",
    7: "Lot 7 — Alt+Tab, déconnexion, verrouillage",
    8: "Lot 8 — applications",
    9: "Lot 9 — icônes et curseurs",
    10: "Lot 10 — finitions",
}


def rendre() -> str:
    donnees = tomllib.loads(JETONS.read_text(encoding="utf-8"))
    mesures = donnees["mesure"]
    obligatoires = set(donnees.get("lots_mesures_obligatoires", []))
    complets = set(donnees.get("lots_complets", []))

    lignes = [
        "# FIDELITE — ce qui est mesuré, et ce qui ne l'est pas",
        "",
        "> **Ce fichier est généré** par `bench/fidelite.py` depuis",
        "> [`bench/jetons.toml`](../bench/jetons.toml). Ne pas le modifier à la main :",
        "> la CI le régénère et refuse la PR s'il diffère.",
        ">",
        "> **Obligatoire** et **complet** ne sont pas la même chose. Une mesure d'un lot",
        "> *obligatoire* fait échouer le test si elle s'écarte de sa cible (DE-007) ; un lot",
        "> *complet* est un lot dont il ne reste aucun jeton à mesurer. Un lot en cours est",
        "> normalement obligatoire sans être complet — et ce document a déclaré les lots 1, 2",
        "> et 3 « terminés » jusqu'au 2026-11-06, alors que cinq jetons du lot 2 ne sont pas",
        "> mesurés. Une mesure **sans cible** est un simple relevé : on la suit, on ne l'impose",
        "> pas.",
        ">",
        "> **ATTENTION, contresens déjà commis.** Dans la colonne « cible », *relevé* qualifie LE",
        "> JETON — il n'a pas de valeur de Windows 11 à atteindre — et ne dit RIEN de l'état d'un",
        "> lot. Le 2026-11-07, un audit a lu « relevé » comme « le lot 4 n'est que relevé ».",
        "> L'état des lots est dans ROADMAP.md ; l'état fonctionnel dans docs/ANTI_DOUBLONS.md.",
        "",
        f"**{len(mesures)} mesures.** Mesures obligatoires, lots : "
        + (", ".join(str(n) for n in sorted(obligatoires)) if obligatoires else "aucun")
        + ". Lots complets : "
        + (", ".join(str(n) for n in sorted(complets)) if complets else "aucun")
        + ".",
        "",
    ]

    for lot in sorted({m["lot"] for m in mesures}):
        if lot in complets:
            etat = "**complet**, mesures obligatoires"
        elif lot in obligatoires:
            etat = "**mesures obligatoires**, lot en cours"
        else:
            etat = "relevé seulement"
        lignes += [
            f"## {TITRES.get(lot, f'Lot {lot}')} — {etat}",
            "",
            "| Mesure | Cible Windows 11 | Tolérance | Source |",
            "|---|---|---|---|",
        ]
        for m in (x for x in mesures if x["lot"] == lot):
            unite = m.get("unite", "")
            cible = m.get("cible")
            if cible is None:
                cible_txt = "*relevé*"
            elif unite and not isinstance(cible, str):
                cible_txt = f"{cible} {unite}"
            else:
                cible_txt = f"`{cible}`" if isinstance(cible, str) else str(cible)
            tol = m.get("tolerance")
            tol_txt = f"± {tol} {unite}".strip() if tol is not None else "—"
            source = m["source"].replace("|", r"\|")
            lignes.append(f"| {m['libelle']} (`{m['id']}`) | {cible_txt} | {tol_txt} | {source} |")
        lignes.append("")

    lignes += [
        "## Ce que le banc ne mesure pas",
        "",
        "Par honnêteté, et parce que c'est la règle du projet (CLAUDE.md §3.9) : on ne dit pas",
        "« au pixel près » d'une surface que le banc ne mesure pas.",
        "",
        "- le **contenu** de l'OSD du volume et la **largeur** des notifications : en dur dans Plasma ;",
        "- les applications **libadwaita**, **Electron**, et **GTK en Flatpak** ;",
        "- les barres de titre dessinées par l'application (Chrome, VS Code) ;",
        "- les mesures de Démarrer et des paramètres rapides tant que les lots 5 et 6 ne sont pas faits ;",
        "- tout ce qui dépend du matériel réel : écrans à haute résolution multiples, VRR, HDR.",
        "",
        "Voir [CLAUDE.md §1](../CLAUDE.md).",
    ]
    return "\n".join(lignes) + "\n"


def main() -> int:
    texte = rendre()
    if "--verifier" in sys.argv:
        if not SORTIE.exists() or SORTIE.read_text(encoding="utf-8") != texte:
            print(
                "docs/FIDELITE.md n'est pas à jour avec bench/jetons.toml.\n"
                "Lancez : python3 bench/fidelite.py",
                file=sys.stderr,
            )
            return 1
        print("docs/FIDELITE.md est à jour.")
        return 0
    SORTIE.write_text(texte, encoding="utf-8")
    print(f"{SORTIE.relative_to(RACINE)} écrit ({len(texte.splitlines())} lignes).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

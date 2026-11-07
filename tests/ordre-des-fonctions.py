#!/usr/bin/env python3
"""Refuse qu'un script shell appelle une de ses fonctions AVANT de la définir.

Bash définit les fonctions à l'exécution : un appel placé plus haut que sa
définition ne donne pas une erreur de syntaxe — « bash -n » passe — mais un
« command not found » au moment où la ligne est atteinte.

Le 2026-11-07, bench/vm/essayer.sh a perdu un passage en VM complet pour
cette seule raison : version_plasma_invite() était définie ligne 492 et
appelée ligne 280. Vingt minutes de machine pour une faute d'ordre que rien
ne contrôlait.

Usage : tests/ordre-des-fonctions.py fichier.sh [...]
"""
import re
import sys

DEFINITION = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*\(\)\s*\{")
# Un appel de fonction occupe toujours une position de COMMANDE : début de
# ligne, ou juste après « ; », « | », « && », « || », « ( », « $( », « { ».
# Chercher le nom n'importe où dans la ligne donnait des faux positifs sur la
# prose des commentaires — « le nom change à chaque compilation » était pris
# pour un appel à la fonction change().
COMMANDE = re.compile(
    r"(?:^|[;&|(){}]|&&|\|\||\$\()\s*([A-Za-z_][A-Za-z0-9_]*)"
)


def sans_commentaire(ligne):
    """Retire le commentaire de fin, en respectant les guillemets."""
    dehors = True
    guillemet = ""
    for i, c in enumerate(ligne):
        if dehors and c in "\"'":
            dehors, guillemet = False, c
        elif not dehors and c == guillemet:
            dehors, guillemet = True, ""
        elif dehors and c == "#" and (i == 0 or ligne[i - 1] in " \t"):
            return ligne[:i]
    return ligne


def analyser(chemin):
    with open(chemin, encoding="utf-8") as f:
        lignes = f.read().split("\n")

    definitions = {}
    for n, ligne in enumerate(lignes, 1):
        m = DEFINITION.match(ligne)
        if m and m.group(1) not in definitions:
            definitions[m.group(1)] = n
    if not definitions:
        return []

    fautes = []
    # Suivre les accolades d'un script shell est sans espoir : « ${x} »,
    # « awk '{...}' », du JSON et des sed en contiennent. Le premier jet de ce
    # fichier comptait les accolades et une définition d'UNE SEULE ligne
    # (« grief() { ...; } ») laissait un « { » non refermé : la profondeur
    # restait coincée à 1, tout le reste du script était pris pour l'intérieur
    # d'une fonction, et le contrôle ne contrôlait plus RIEN. Il annonçait
    # « aucun appel avant définition » sur un fichier où la faute était là.
    #
    # Règle retenue, qui est la convention de ce dépôt et qui se vérifie :
    # une fonction multi-ligne se referme par un « } » SEUL en début de ligne.
    # Une définition dont la ligne contient déjà son « } » est une
    # définition d'une seule ligne, et on n'entre pas.
    dedans = False
    for n, ligne in enumerate(lignes, 1):
        nue = ligne.strip()
        if not nue or nue.startswith("#"):
            continue
        if dedans:
            if ligne.rstrip() == "}":
                dedans = False
            continue
        m = DEFINITION.match(ligne)
        if m:
            # « f() { ... } » tient sur une ligne si elle porte son « } ».
            apres = ligne[ligne.index("{") + 1:]
            if "}" not in apres:
                dedans = True
            continue
        for mot in COMMANDE.findall(sans_commentaire(ligne)):
            if mot in definitions and definitions[mot] > n:
                fautes.append((chemin, n, mot, definitions[mot]))
                break
    return fautes


def main():
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2
    toutes = []
    for chemin in sys.argv[1:]:
        toutes.extend(analyser(chemin))
    if toutes:
        for chemin, n, mot, ou in toutes:
            print(
                f"  ECHEC {chemin}:{n} appelle « {mot} », définie seulement ligne {ou}",
                file=sys.stderr,
            )
        print(
            f"\n{len(toutes)} appel(s) avant définition. Bash ne les voit pas à la",
            file=sys.stderr,
        )
        print("syntaxe : il échoue en « command not found » à l'exécution.", file=sys.stderr)
        return 1
    print(f"Ordre des fonctions : {len(sys.argv) - 1} fichier(s), aucun appel avant définition.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

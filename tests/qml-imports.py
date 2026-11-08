#!/usr/bin/env python3
"""Refuse un fichier QML qui emploie un module qu'il n'importe pas.

QML ne se plaint pas à la construction : un identifiant non résolu rend
« undefined », la liaison qui s'en sert donne NaN ou rien, et l'élément
s'affiche VIDE. Aucune erreur, aucun échec de test — juste un trou à
l'écran, qu'on ne voit qu'en regardant une capture.

Le 2026-11-08, src/demarrer/PinnedPage.qml lisait
« Plasmoid.configuration.numberColumns » sans importer
« org.kde.plasma.plasmoid ». Résultat : cellWidth = NaN, et le menu
Démarrer s'est affiché à la bonne taille, avec sa barre de recherche et son
bouton, mais SANS UNE SEULE ICÔNE. Vingt minutes de VM pour l'apprendre, et
seulement parce que quelqu'un a ouvert l'image.

Usage : tests/qml-imports.py fichier.qml [...]
"""
import re
import sys

# Identifiant employé -> fragment qui doit figurer dans un « import ».
# On ne couvre que les modules que ce dépôt emploie : un contrôle qui
# prétend tout couvrir et n'en couvre qu'une partie est pire qu'un contrôle
# dont on connaît le périmètre.
MODULES = {
    "Plasmoid": "org.kde.plasma.plasmoid",
    "Kirigami": "org.kde.kirigami",
    "PlasmaComponents3": "org.kde.plasma.components",
    "PlasmaCore": "org.kde.plasma.core",
    "PlasmaExtras": "org.kde.plasma.extras",
    "Plasma5Support": "org.kde.plasma.plasma5support",
    "KItemModels": "org.kde.kitemmodels",
    "KCoreAddons": "org.kde.coreaddons",
    "KWindowSystem": "org.kde.kwindowsystem",
}

# « // » en début de ligne, et /* … */ : on ne juge pas les commentaires.
def sans_commentaires(source):
    source = re.sub(r"/\*.*?\*/", "", source, flags=re.S)
    return "\n".join(
        ligne for ligne in source.split("\n") if not ligne.lstrip().startswith("//")
    )


def analyser(chemin):
    with open(chemin, encoding="utf-8") as f:
        brut = f.read()
    code = sans_commentaires(brut)
    imports = "\n".join(
        ligne for ligne in code.split("\n") if ligne.lstrip().startswith("import ")
    )
    fautes = []
    for identifiant, module in MODULES.items():
        # L'identifiant employé comme préfixe : « Kirigami.Units », ou seul
        # comme « Plasmoid.configuration ».
        if not re.search(r"\b%s\s*\." % re.escape(identifiant), code):
            continue
        if module in imports or re.search(
            r"\bas\s+%s\b" % re.escape(identifiant), imports
        ):
            continue
        fautes.append((chemin, identifiant, module))
    return fautes


def main():
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2
    toutes = []
    for chemin in sys.argv[1:]:
        toutes.extend(analyser(chemin))
    if toutes:
        for chemin, identifiant, module in toutes:
            print(
                f"  ECHEC {chemin} emploie « {identifiant}. » sans importer "
                f"« {module} » : il vaudra undefined, en silence",
                file=sys.stderr,
            )
        return 1
    print(f"Imports QML : {len(sys.argv) - 1} fichier(s), aucun module employé sans import.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

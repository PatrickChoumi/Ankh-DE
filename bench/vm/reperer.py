#!/usr/bin/env python3
"""Repère les applets de la barre, pour savoir où cliquer.

    reperer.py <capture.ppm> <hauteur de la barre en px>

Écrit sur une ligne l'abscisse du centre de chaque amas, de gauche à droite.

Pourquoi ce fichier existe
--------------------------
Le harnais sait depuis le 2026-11-07 injecter des clics par QEMU. Encore
faut-il savoir OÙ cliquer. Plasma n'expose pas la géométrie d'un applet par
son moteur de script : `shell/scripting/containment.h` donne les
identifiants et `panel.h` la taille du panneau, jamais la place d'un widget
dedans.

On la lit donc sur l'image. Dans la bande du bas, les applets sont des amas
de pixels qui tranchent sur le fond du panneau ; entre eux, des colonnes
vides. On projette la bande sur son axe horizontal, on seuille, et chaque
groupe de colonnes pleines est un applet.

Ce n'est pas une mesure de fidélité : c'est un repérage, et il n'a pas
besoin d'être au pixel près — un clic au centre d'un amas tombe dans
l'applet. Ce qu'il doit être, c'est HONNÊTE : s'il ne trouve rien, il
n'écrit rien, pour que l'appelant sache qu'il ne sait pas plutôt que de
cliquer dans le vide.
"""

from __future__ import annotations

import sys

from PIL import Image

# Un amas plus étroit que cela est du bruit : un bord, un pixel isolé.
LARGEUR_MINIMALE = 6
# Deux amas séparés par moins que cela sont le même applet (une icône et
# son trait d'activité, par exemple).
ECART_MINIMAL = 8


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__.strip(), file=sys.stderr)
        return 2

    image = Image.open(sys.argv[1]).convert("RGB")
    hauteur_barre = int(sys.argv[2])
    largeur, hauteur = image.size
    bande = image.crop((0, max(0, hauteur - hauteur_barre), largeur, hauteur))

    # Le fond du panneau : la couleur la plus fréquente de la bande. Un
    # panneau est très majoritairement vide, donc c'est la bonne référence —
    # et cela marche que le panneau soit clair, sombre ou en verre.
    couleurs = bande.getcolors(largeur * hauteur_barre)
    if not couleurs:
        return 0
    fond = max(couleurs)[1]

    # Projection : pour chaque colonne, combien de pixels s'écartent du fond.
    pixels = bande.load()
    plein = []
    for x in range(largeur):
        n = 0
        for y in range(bande.size[1]):
            r, g, b = pixels[x, y]
            if abs(r - fond[0]) + abs(g - fond[1]) + abs(b - fond[2]) > 40:
                n += 1
        plein.append(n > 1)

    # Regroupement en amas, avec fusion des amas trop proches.
    amas: list[list[int]] = []
    debut = None
    for x, p in enumerate(plein + [False]):
        if p and debut is None:
            debut = x
        elif not p and debut is not None:
            if amas and debut - amas[-1][1] < ECART_MINIMAL:
                amas[-1][1] = x
            else:
                amas.append([debut, x])
            debut = None

    centres = [(a + b) // 2 for a, b in amas if b - a >= LARGEUR_MINIMALE]
    if centres:
        print(" ".join(str(c) for c in centres))
    return 0


if __name__ == "__main__":
    sys.exit(main())

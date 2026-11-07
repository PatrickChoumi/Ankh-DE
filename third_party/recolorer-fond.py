#!/usr/bin/env python3
"""Fait passer un fond d'écran du bleu de Fluent aux violets d'Ankh.

    recolorer-fond.py <source> <destination> [tour en degrés] [saturation]

Par défaut : tour de +52° et saturation × 0,85.

Pourquoi ces deux nombres
-------------------------
Relevé sur les images d'origine : leurs teintes dominantes sont à 210° et
220°, le bleu de Windows. Les violets d'Ankh sont à 255° (`#a78bfa`) et 258°
(`#8455f0`). Un tour de +52° amène donc les premières sur les seconds.

La saturation DESCEND, et c'est le point qui décide de tout. Essayé le
2026-11-07, quatre réglages côte à côte : à saturation inchangée le résultat
est un indigo électrique qui n'a rien d'Ankh ; au-delà de +58° il glisse vers
le magenta ; sous × 0,70 il se délave. × 0,85 donne le lavande du dépôt.

C'est une rotation de TEINTE, pas un filtre : les valeurs — donc le modelé
des facettes, les arêtes, la profondeur — sont conservées. C'est ce qui
permet de reprendre une image qu'on n'a pas dessinée sans l'abîmer.

Pourquoi ce fichier n'importe que Pillow
----------------------------------------
Sa première version employait numpy, et elle a cassé la CI et la VM le
2026-11-07 : `ModuleNotFoundError: No module named 'numpy'` dans le conteneur
Fedora comme dans l'invité. Une pièce fabriquée à l'installation ne doit
dépendre que de ce qui est DÉJÀ exigé — et Pillow l'est, le banc s'en sert.

Pillow fait le travail seul : son mode « HSV » donne trois bandes de 0 à 255,
et `Image.point()` applique une table de correspondance à chacune. Une
rotation de teinte devient une addition modulo 256 sur la bande H, et la
saturation une multiplication sur la bande S. Pas de boucle sur les pixels :
les tables sont appliquées en C.
"""

from __future__ import annotations

import sys

from PIL import Image


def recolorer(source: str, destination: str, tour: float, saturation: float) -> None:
    image = Image.open(source).convert("RGB")

    # En HSV de Pillow, la teinte couvre 0–255 pour 0–360°.
    decalage = round(tour * 256.0 / 360.0)

    h, s, v = image.convert("HSV").split()
    h = h.point(lambda t, d=decalage: (t + d) % 256)
    s = s.point(lambda t, k=saturation: min(255, int(t * k + 0.5)))

    Image.merge("HSV", (h, s, v)).convert("RGB").save(destination, optimize=True)


def main() -> int:
    if not 3 <= len(sys.argv) <= 5:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    tour = float(sys.argv[3]) if len(sys.argv) > 3 else 52.0
    saturation = float(sys.argv[4]) if len(sys.argv) > 4 else 0.85
    recolorer(sys.argv[1], sys.argv[2], tour, saturation)
    return 0


if __name__ == "__main__":
    sys.exit(main())

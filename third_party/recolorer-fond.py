#!/usr/bin/env python3
"""Fait passer un fond d'écran du bleu de Fluent aux violets d'Ankh.

    recolorer-fond.py <source> <destination> [tour] [saturation]

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
des facettes, les arêtes, la profondeur — sont conservées intactes. C'est ce
qui permet de reprendre une image qu'on n'a pas dessinée sans l'abîmer.
"""

from __future__ import annotations

import sys

import numpy as np
from PIL import Image


def recolorer(source: str, destination: str, tour: float, saturation: float) -> None:
    image = Image.open(source).convert("RGB")
    a = np.asarray(image, dtype=np.float64) / 255.0

    mx = a.max(2)
    mn = a.min(2)
    d = mx - mn
    v = mx
    s = np.where(mx > 0, d / np.where(mx > 0, mx, 1.0), 0.0)

    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    nz = d > 1e-9
    h = np.zeros_like(mx)
    h = np.where(nz & (mx == r), ((g - b) / np.where(nz, d, 1.0)) % 6, h)
    h = np.where(nz & (mx == g), (b - r) / np.where(nz, d, 1.0) + 2, h)
    h = np.where(nz & (mx == b), (r - g) / np.where(nz, d, 1.0) + 4, h)
    h = (h * 60.0 + tour) % 360.0
    s = np.clip(s * saturation, 0.0, 1.0)

    c = v * s
    x2 = c * (1 - np.abs((h / 60.0) % 2 - 1))
    m = v - c
    z = np.zeros_like(h)
    seg = (h // 60).astype(int) % 6
    choix = [seg == i for i in range(6)]
    rr = np.select(choix, [c, x2, z, z, x2, c])
    gg = np.select(choix, [x2, c, c, x2, z, z])
    bb = np.select(choix, [z, z, x2, c, c, x2])

    sortie = np.clip(np.stack([rr + m, gg + m, bb + m], -1), 0.0, 1.0)
    Image.fromarray((sortie * 255 + 0.5).astype(np.uint8)).save(destination, optimize=True)


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

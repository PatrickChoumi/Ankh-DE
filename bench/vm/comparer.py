#!/usr/bin/env python3
"""Dit, en chiffres, si quelque chose s'est ouvert à l'écran.

  comparer.py avant.ppm apres.ppm

Rend une ligne : « <pixels changés> <x> <y> <largeur> <hauteur> <part en %> »
ou « 0 0 0 0 0 0.00 » si les deux images sont identiques.

Pourquoi ce script existe
-------------------------
Le 2026-11-06, le harnais écrivait « vm-demarrer-ouvert.png » quelle que
soit l'issue. Les trois captures du passage étaient octet pour octet
identiques : le fichier s'appelait « menu ouvert » et montrait un bureau
vide. Un nom de fichier n'est pas une preuve.

Comparer les octets ne suffit pas non plus : l'horloge de la barre change de
minute et deux captures d'un écran immobile peuvent différer pour cette
seule raison. On mesure donc l'AMPLEUR du changement. Un menu Démarrer qui
s'ouvre couvre une grande part de l'écran et donne une boîte englobante
haute ; une minute qui passe change quelques dizaines de pixels dans un coin
de la barre. Les deux ne se confondent pas.

Le seuil de décision reste à l'appelant : ce script ne fait que mesurer.
"""

import sys

from PIL import Image, ImageChops


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__.strip(), file=sys.stderr)
        return 2

    avant = Image.open(sys.argv[1]).convert("RGB")
    apres = Image.open(sys.argv[2]).convert("RGB")
    if avant.size != apres.size:
        print(
            f"Les deux captures n'ont pas la même taille : "
            f"{avant.size} puis {apres.size}",
            file=sys.stderr,
        )
        return 3

    ecart = ImageChops.difference(avant, apres).convert("L")
    # Seuil de 16 sur 255 : on ignore le bruit de compression et les
    # dégradés qui bougent d'un cran, on garde ce qui est visible.
    masque = ecart.point(lambda v: 255 if v > 16 else 0)

    changes = sum(masque.histogram()[1:])
    boite = masque.getbbox()
    total = avant.size[0] * avant.size[1]
    part = 100.0 * changes / total if total else 0.0

    if boite is None:
        print("0 0 0 0 0 0.00")
    else:
        x0, y0, x1, y1 = boite
        print(f"{changes} {x0} {y0} {x1 - x0} {y1 - y0} {part:.2f}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

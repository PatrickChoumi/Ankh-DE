#!/usr/bin/env python3
"""Photographie l'écran virtuel de KWin, par org.kde.KWin.ScreenShot2.

    bench/capture-kwin.py <sortie.png>

KWin envoie l'image brute dans un tube : il faut lui passer un descripteur
de fichier, ce que qdbus ne sait pas faire. D'où ce script.

Il ne demande que python3-dbus et Pillow.
"""
from __future__ import annotations

import os
import sys

# QImage::Format -> (mode Pillow, ordre des octets)
# Ce sont les valeurs de Qt, pas des noms : KWin rend un entier.
FORMATS = {
    4: ("BGRX", "RGB32"),                  # QImage::Format_RGB32
    5: ("BGRA", "ARGB32"),                 # QImage::Format_ARGB32
    6: ("BGRa", "ARGB32_Premultiplied"),   # QImage::Format_ARGB32_Premultiplied
}


def main() -> int:
    if len(sys.argv) < 2:
        print("usage : capture-kwin.py <sortie.png>", file=sys.stderr)
        return 2
    cible = sys.argv[1]

    try:
        import dbus
        from PIL import Image
    except ImportError as e:
        print(f"module manquant : {e.name} (python3-dbus, python3-pillow)", file=sys.stderr)
        return 3

    bus = dbus.SessionBus()
    objet = bus.get_object("org.kde.KWin.ScreenShot2", "/org/kde/KWin/ScreenShot2")
    iface = dbus.Interface(objet, "org.kde.KWin.ScreenShot2")

    lecture, ecriture = os.pipe()
    try:
        resultats = iface.CaptureWorkspace(
            {"include-cursor": dbus.Boolean(False)}, dbus.types.UnixFd(ecriture)
        )
    except dbus.DBusException as e:
        os.close(lecture)
        os.close(ecriture)
        print(f"ScreenShot2 refuse : {e.get_dbus_name()}", file=sys.stderr)
        return 4
    os.close(ecriture)

    morceaux = []
    while True:
        bloc = os.read(lecture, 1 << 20)
        if not bloc:
            break
        morceaux.append(bloc)
    os.close(lecture)
    brut = b"".join(morceaux)

    meta = {str(k): int(v) for k, v in resultats.items() if str(k) in
            ("width", "height", "stride", "format")}
    largeur, hauteur = meta["width"], meta["height"]
    stride, fmt = meta["stride"], meta["format"]
    if fmt not in FORMATS:
        print(f"format QImage inconnu : {fmt}", file=sys.stderr)
        return 5
    mode_brut, nom = FORMATS[fmt]

    attendu = stride * hauteur
    if len(brut) < attendu:
        print(f"image tronquée : {len(brut)} octets pour {attendu}", file=sys.stderr)
        return 6

    image = Image.frombytes("RGBA", (largeur, hauteur), brut[:attendu], "raw", mode_brut, stride)
    image.convert("RGB").save(cible)
    print(f"{cible} : {largeur}x{hauteur}, {nom}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

# Scripts KWin — lot 7

Vide pour l'instant. Y va le script des **dispositions d'ancrage par Windows+Z**, l'idée reprise
du « Tiling Assistant » d'[AnduinOS](https://github.com/Anduin2017/AnduinOS).

Ce n'est **pas** le menu de disposition qui apparaît au survol du bouton « Agrandir » de
Windows 11 : KWin n'a rien pour accrocher ce survol, et c'est une limite assumée
([ANKH-DE-SPEC.md §4.2](../../ANKH-DE-SPEC.md#42-impossible-tout-court-en-plasma-67--à-valider-à-chaque-version)).
On a Windows+flèches et l'éditeur de tuiles (Windows+T).

Le CMake de la racine installe ce dossier dans `share/kwin/scripts` dès qu'il contient
quelque chose.

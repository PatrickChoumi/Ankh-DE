# Scripts KWin — lot 7

Vide pour l'instant. Y va le script des **dispositions d'ancrage par Windows+Z**, l'idée reprise
du « Tiling Assistant » d'[AnduinOS](https://github.com/Anduin2017/AnduinOS).

Ce n'est **pas** le menu de disposition qui apparaît au survol du bouton « Agrandir » de
Windows 11 : KWin n'a rien pour accrocher ce survol, et c'est une limite assumée
([CLAUDE.md §1](../../CLAUDE.md)).
On a Windows+flèches et l'éditeur de tuiles (Windows+T).

Le CMake de la racine installe ce dossier dans `share/kwin/scripts` dès qu'il contient
quelque chose.

# AVANCEMENT — Ankh DE

> Tout ce qui a été fait, et ce qui reste. Mis à jour à chaque compte rendu, comme dans Ankh
> (D-029). L'ordre des travaux est dans [ROADMAP.md](ROADMAP.md).

## 2026-11-05 — Création du dépôt (lot 0, en cours)

**Décidé** (après mes quatre arbitrages du jour) :
- DE-001 : une suite de thèmes et de shell sur Plasma 6, pas un DE écrit de zéro ;
- DE-003 : la géométrie de Windows 11, les couleurs d'Ankh ;
- DE-006 : dépôt public, GPL-3.0-or-later ;
- DE-009 : dépôt séparé d'Ankh ; Ankh le consommera plus tard.

**Écrit**
- `ANKH-DE-SPEC.md` : la référence Windows 11 (géométrie, texte, couleurs, matières, ombres,
  mouvement, contrôles, fenêtres, icônes, shell), l'identité d'Ankh, les limites, la liste NON ;
- `DECISIONS.md` : DE-001 à DE-009 ;
- `ROADMAP.md` : le lot 0 et les lots 1 à 10 ;
- `CLAUDE.md` : les règles de travail.

**Code repris d'Ankh, tel quel** (le report sur Breeze en dépend) :
- `src/style/` — le style Qt, 23 335 lignes de C++ avec la décoration, dérivé de Breeze 6.7.5 ;
- `src/decoration/` — la décoration KDecoration3 ;
- `src/qqc2/` — les adaptations des contrôles QtQuick de KDE ;
- `src/colors/` — `Ankh.colors` et `AnkhClair.colors` ;
- `src/fontconfig/29-ankh-rendu.conf` — niveaux de gris, contours légers ;
- `bench/` — le banc de mesure et ses 47 jetons.

**Écrit pour l'autonomie** (ce qu'Ankh faisait dans son `Containerfile` et son `build.sh`) :
- `CMakeLists.txt` à la racine : compile et installe tout, avec les en-têtes de KDE de n'importe
  quelle distribution ;
- `src/lookandfeel/org.ankh.de.desktop/` : **la pièce nouvelle**. Son `contents/defaults` porte
  les 20 réglages du DE, et son `layouts/*.js` la barre des tâches de Windows 11. Plus aucun
  fichier de la distribution n'est touché (DE-002) ;
- `third_party/preparer.sh` : Selawik, curseurs et thème GTK, sans rien de Fedora ;
- `installer.sh` / `desinstaller.sh` : installation système ou dans le dossier personnel, barre en
  option et confirmée, retour arrière complet.

## Ce qui est vérifié, et ce qui ne l'est pas

| Affirmation | État |
|---|---|
| Les mesures des lots 1 à 3 atteignent les cibles de Windows 11 | `MESURÉ` dans Ankh, en VM, sur **Fedora 44 seulement** ([run 39753444882](https://github.com/PatrickChoumi/Ankh/actions/runs/39753444882)) |
| Le code compile tel quel hors de l'image d'Ankh | **non vérifié** — lot 0.6 |
| Le thème global applique bien ses 20 clés | **non vérifié** — lot 0.7, et SPEC §7 question 1 |
| `installer.sh` fonctionne sur Fedora, Arch, Ubuntu | **non vérifié** — jamais lancé |
| `desinstaller.sh` ramène à l'état de départ | **non vérifié** |
| `panel.lengthMode = "fill"` existe en Plasma 6.7 | `À VALIDER` — SPEC §7 question 2 |
| Les paquets (`.spec`, `PKGBUILD`, `debian/`) construisent | **non vérifié** — squelettes |

**Rien de ce dépôt n'a encore tourné sur une machine.** Tant que le lot 0 n'est pas fini, la
seule preuve de fidélité est celle d'Ankh, sur Fedora.

## Ce que je dois faire moi-même

- Créer le dépôt `Ankh-DE` sur GitHub et y pousser cette première version (les sessions Claude
  Code n'ont pas le droit de créer un dépôt).
- Choisir si le dépôt protège `main` par PR, comme Ankh.

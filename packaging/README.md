# Paquets

> **Aucun de ces fichiers n'a été construit ni testé** (ROADMAP, lot 0.8). Ce sont des squelettes
> honnêtes : ils disent ce qu'il faut, pas qu'ils marchent.

| Dossier | Cible | État |
|---|---|---|
| `fedora/` | `.spec` pour Fedora, à pousser dans un COPR | squelette |
| `arch/` | `PKGBUILD` pour l'AUR | squelette |
| `debian/` | Ubuntu et Debian, à pousser dans un PPA | squelette |

## Deux choses à savoir avant de faire un paquet

1. **Les pièces tierces ne peuvent pas être construites hors réseau.** `third_party/preparer.sh`
   télécharge Selawik, les curseurs et le thème GTK à des commits figés. Les règles de la plupart
   des distributions interdisent de télécharger pendant la construction d'un paquet. Deux voies :
   - **sous-paquets séparés** (`ankh-de-fonts`, `ankh-de-cursors`, `ankh-de-gtk`) avec les
     archives amont en `Source:`, chacune à son commit ;
   - **ou** ne pas les empaqueter, et dépendre des paquets existants de la distribution là où ils
     existent.
   C'est la question 6 de [CLAUDE.md §1](../CLAUDE.md), `À DÉCIDER`.
2. **Le paquet ne doit pas appliquer le thème.** Installer les fichiers, oui ; écrire la
   configuration de l'utilisateur, jamais
   ([DE-002](../DECISIONS.md#de-002--tous-les-réglages-vivent-dans-notre-thème-global-jamais-dans-etcxdg-ni-dans-les-thèmes-de-la-distribution)).
   L'utilisateur applique « Ankh DE » dans la page « Thème global » de la configuration du
   système, ou par `plasma-apply-lookandfeel`.
3. **Le paquet doit dépendre d'une version précise de Plasma.** `src/*/VERSION-BREEZE` dit
   laquelle. Un paquet qui s'installe sur une autre version livre un greffon qui peut se charger
   à moitié ([DE-008](../DECISIONS.md#de-008--le-code-dérivé-de-kde-est-reporté-à-chaque-version-de-plasma-et-la-construction-échoue-tant-que-ce-nest-pas-fait)).

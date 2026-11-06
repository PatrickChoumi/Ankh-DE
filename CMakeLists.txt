# Ankh DE — la géométrie de Windows 11, les couleurs d'Ankh, sur KDE Plasma.
#
# Ce fichier remplace l'étape « outils » du Containerfile d'Ankh : ici, le DE
# se compile et s'installe seul, avec les en-têtes de KDE de n'importe quelle
# distribution (DE-001). Les pièces qui ne se compilent pas — police Selawik,
# curseurs, icônes et thème GTK — sont fabriquées par third_party/preparer.sh,
# puis installées par ce même CMake si elles sont présentes.
cmake_minimum_required(VERSION 3.22)

project(ankh-de
    VERSION 0.1.0
    DESCRIPTION "Windows 11 geometry, Ankh colours, on KDE Plasma"
    LANGUAGES CXX
)

find_package(ECM 6.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
include(KDEInstallDirs)
include(FeatureSummary)

option(ANKH_DE_STYLE       "Compiler le style des contrôles (lot 3)"      ON)
option(ANKH_DE_DECORATION  "Compiler la décoration des fenêtres (lot 2)"  ON)
option(ANKH_DE_DATA        "Installer les thèmes et les réglages"         ON)
option(ANKH_DE_SESSION     "Installer la session (DE-010)"                ON)
option(ANKH_DE_PLASMA_NON_TESTE
    "Construire malgré une version de Plasma non suivie (DE-008)"         OFF)

# --- Garde-fou de version (DE-008) ---------------------------------------
# src/style et src/decoration sont des copies de Breeze, renommées. Une
# nouvelle version de Plasma peut changer l'API qu'elles appellent : le
# passage de KDecoration2 à KDecoration3 avait cassé les réglages de Klassy,
# un projet au même modèle. Mieux vaut refuser de construire que livrer un
# greffon à moitié chargé.
#
# La version de kdecoration suit celle de Plasma : elles sont publiées
# ensemble. C'est le seul signal fiable dans un conteneur de construction,
# où plasmashell n'est pas installé.
file(READ "${CMAKE_CURRENT_SOURCE_DIR}/src/decoration/VERSION-BREEZE" ANKH_DE_SUIVI)
string(REGEX MATCH "plasma=([0-9]+\.[0-9]+)" _ "${ANKH_DE_SUIVI}")
set(ANKH_DE_PLASMA_SUIVI "${CMAKE_MATCH_1}")
if(NOT ANKH_DE_PLASMA_SUIVI)
    message(FATAL_ERROR "src/decoration/VERSION-BREEZE ne dit pas quelle version de Plasma est suivie.")
endif()

find_package(KDecoration3 QUIET)
if(KDecoration3_FOUND AND KDecoration3_VERSION)
    string(REGEX MATCH "^[0-9]+\.[0-9]+" ANKH_DE_PLASMA_TROUVE "${KDecoration3_VERSION}")
    if(NOT ANKH_DE_PLASMA_TROUVE VERSION_EQUAL ANKH_DE_PLASMA_SUIVI)
        set(ANKH_DE_MESSAGE
            "Plasma ${ANKH_DE_PLASMA_TROUVE} est installé (kdecoration ${KDecoration3_VERSION}), "
            "mais Ankh DE suit Plasma ${ANKH_DE_PLASMA_SUIVI} "
            "(src/*/VERSION-BREEZE). Le style et la décoration dérivent du code de "
            "cette version : ils peuvent ne pas se charger, ou se charger à moitié.\n"
            "  Pour reporter le code : docs/REBASE.md\n"
            "  Pour construire quand même : -DANKH_DE_PLASMA_NON_TESTE=ON")
        if(ANKH_DE_PLASMA_NON_TESTE)
            message(WARNING ${ANKH_DE_MESSAGE})
        else()
            message(FATAL_ERROR ${ANKH_DE_MESSAGE})
        endif()
    else()
        message(STATUS "Plasma ${ANKH_DE_PLASMA_TROUVE} : la version suivie.")
    endif()
elseif(ANKH_DE_DECORATION)
    message(STATUS
        "kdecoration introuvable pour l'instant : la version de Plasma sera "
        "vérifiée par src/decoration.")
endif()

# --- Code compilé ---------------------------------------------------------
if(ANKH_DE_STYLE)
    add_subdirectory(src/style)
endif()
if(ANKH_DE_DECORATION)
    add_subdirectory(src/decoration)
endif()

# --- La session (DE-010) --------------------------------------------------
# C'est elle qui fait d'Ankh DE un environnement de bureau qu'on CHOISIT à
# l'écran de connexion, et non un thème qu'on applique depuis Plasma. Et
# c'est elle qui porte les polices, le rendu, les animations et l'accent, que
# le thème global ne sait pas porter (vérifié le 2026-11-05).
if(ANKH_DE_SESSION)
    set(ANKH_DE_BINDIR "${CMAKE_INSTALL_PREFIX}/${KDE_INSTALL_BINDIR}")
    set(ANKH_DE_CONFIGDIR "${CMAKE_INSTALL_PREFIX}/${KDE_INSTALL_DATADIR}/ankh-de/config")
    set(ANKH_DE_VERSION "${PROJECT_VERSION}")
    # KDE_INSTALL_QTPLUGINDIR peut être absolu ou relatif au préfixe.
    if(IS_ABSOLUTE "${KDE_INSTALL_QTPLUGINDIR}")
        set(ANKH_DE_PLUGINDIR "${KDE_INSTALL_QTPLUGINDIR}")
    else()
        set(ANKH_DE_PLUGINDIR "${CMAKE_INSTALL_PREFIX}/${KDE_INSTALL_QTPLUGINDIR}")
    endif()

    configure_file(src/session/ankh-de-session.in
                   ${CMAKE_CURRENT_BINARY_DIR}/ankh-de-session @ONLY)
    configure_file(src/session/ankh-de.desktop.in
                   ${CMAKE_CURRENT_BINARY_DIR}/ankh-de.desktop @ONLY)

    install(PROGRAMS ${CMAKE_CURRENT_BINARY_DIR}/ankh-de-session
            DESTINATION ${KDE_INSTALL_BINDIR})
    # Plasma 6.8 est Wayland seul (ANKH-DE-SPEC §5.8) : pas de session X11.
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/ankh-de.desktop
            DESTINATION ${KDE_INSTALL_DATADIR}/wayland-sessions)

    # La couche de valeurs par défaut que la session place dans
    # XDG_CONFIG_DIRS. Elle n'est jamais copiée chez l'utilisateur.
    install(FILES src/config/kdeglobals src/config/kwinrc
            DESTINATION ${KDE_INSTALL_DATADIR}/ankh-de/config)
endif()

# --- Thèmes et réglages ---------------------------------------------------
if(ANKH_DE_DATA)
    # Jeux de couleurs (lot 1)
    install(FILES
        src/colors/Ankh.colors
        src/colors/AnkhClair.colors
        DESTINATION ${KDE_INSTALL_DATADIR}/color-schemes
    )

    # Thème global : il porte TOUS les réglages par défaut du DE. C'est lui
    # qu'on applique pour « allumer » Ankh DE, et Breeze qu'on réapplique
    # pour l'éteindre.
    install(DIRECTORY src/lookandfeel/org.ankh.de.desktop
        DESTINATION ${KDE_INSTALL_DATADIR}/plasma/look-and-feel
    )

    # Rendu des polices : niveaux de gris, contours légers. C'est fontconfig
    # qui décide, pas KDE : sans ce fichier, Qt prend la disposition des
    # sous-pixels annoncée par l'écran.
    install(FILES src/fontconfig/29-ankh-rendu.conf
        DESTINATION ${KDE_INSTALL_SYSCONFDIR}/fonts/conf.d
    )

    set(ANKH_DE_PREPARE "${CMAKE_CURRENT_SOURCE_DIR}/third_party/sortie")

    # Style Plasma (lot 4), applets (lots 5 et 6) et scripts KWin (lot 7) :
    # installés dès qu'ils existent, pour que les lots arrivent sans toucher
    # à ce fichier.
    # Styles Plasma : ceux que src/desktoptheme/ porte en propre, et ceux
    # que third_party/preparer.sh fabrique (lot 4, dérivés de
    # KDE-Windows-Modern — des SVG, pas du code : SPEC §5.6 les autorise).
    file(GLOB ANKH_DE_DESKTOPTHEME "${CMAKE_CURRENT_SOURCE_DIR}/src/desktoptheme/*")
    if(ANKH_DE_DESKTOPTHEME)
        install(DIRECTORY src/desktoptheme/
            DESTINATION ${KDE_INSTALL_DATADIR}/plasma/desktoptheme
            PATTERN "README.md" EXCLUDE
        )
    endif()
    if(EXISTS "${ANKH_DE_PREPARE}/desktoptheme")
        install(DIRECTORY "${ANKH_DE_PREPARE}/desktoptheme/"
            DESTINATION ${KDE_INSTALL_DATADIR}/plasma/desktoptheme
        )
    else()
        message(STATUS "Ankh DE : style Plasma absent ; lancer third_party/preparer.sh")
    endif()
    file(GLOB ANKH_DE_APPLETS "${CMAKE_CURRENT_SOURCE_DIR}/src/applets/*")
    if(ANKH_DE_APPLETS)
        install(DIRECTORY src/applets/
            DESTINATION ${KDE_INSTALL_DATADIR}/plasma/plasmoids
        )
    endif()
    file(GLOB ANKH_DE_KWIN "${CMAKE_CURRENT_SOURCE_DIR}/src/kwin/*")
    if(ANKH_DE_KWIN)
        install(DIRECTORY src/kwin/
            DESTINATION ${KDE_INSTALL_DATADIR}/kwin/scripts
        )
    endif()

    # Résultat de third_party/preparer.sh, s'il a été lancé : police,
    # curseurs, icônes et thème GTK. Absents, l'installation reste valable,
    # mais le DE retombe sur les polices, curseurs et icônes de la
    # distribution — et le banc le signalera.
    if(EXISTS "${ANKH_DE_PREPARE}/polices/selawik")
        install(DIRECTORY "${ANKH_DE_PREPARE}/polices/selawik"
            DESTINATION ${KDE_INSTALL_DATADIR}/fonts
        )
    endif()
    # Tout le contenu de icones/ : les thèmes visibles, ET les dossiers
    # CACHÉS (.Fluent-Ankh-base…) qui portent l'essentiel des dessins. Sans
    # eux, les liens relatifs des thèmes pointent dans le vide.
    if(EXISTS "${ANKH_DE_PREPARE}/icones")
        install(DIRECTORY "${ANKH_DE_PREPARE}/icones/"
            DESTINATION ${KDE_INSTALL_DATADIR}/icons
            USE_SOURCE_PERMISSIONS
        )
    else()
        # Le dire, plutôt que de laisser un if(EXISTS) qui ne se vérifie jamais.
        message(STATUS "Ankh DE : third_party/sortie/icones est absent ; "
                       "lancer third_party/preparer.sh")
    endif()
    if(EXISTS "${ANKH_DE_PREPARE}/themes/Fluent-Ankh")
        install(DIRECTORY "${ANKH_DE_PREPARE}/themes/Fluent-Ankh"
            DESTINATION ${KDE_INSTALL_DATADIR}/themes
        )
    endif()
endif()

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)

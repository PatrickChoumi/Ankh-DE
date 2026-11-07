# Garde-fou de version de Plasma (DE-008, DE-016).
#
# Extrait de CMakeLists.txt pour une raison de test : ici, il s'éprouve en
# « cmake -P », sans Qt, sans KF6 et sans kdecoration installés
# (tests/garde-version.sh). Tant qu'il vivait au milieu du CMake principal,
# la seule façon de l'essayer était de configurer tout le projet — donc on ne
# l'essayait pas, et la CI le contournait avec -DANKH_DE_PLASMA_NON_TESTE=ON.
#
# ankh_de_lire_plage(<fichier>) remplit, chez l'appelant :
#   ANKH_DE_PLASMA_VISE  la version visée en premier (« plasma= »)
#   ANKH_DE_PLASMA_MIN   borne basse de la plage éprouvée
#   ANKH_DE_PLASMA_MAX   borne haute
#
# ankh_de_garde_version(<trouvee> <version_kdecoration> <non_teste>) refuse,
# ou avertit si <non_teste> est vrai.

function(ankh_de_lire_plage fichier)
    if(NOT EXISTS "${fichier}")
        message(FATAL_ERROR "${fichier} est introuvable : impossible de savoir quelles versions de Plasma sont prises en charge.")
    endif()
    file(READ "${fichier}" contenu)
    set(vise "")
    set(borne_min "")
    set(borne_max "")
    if(contenu MATCHES "plasma=([0-9]+\\.[0-9]+)")
        set(vise "${CMAKE_MATCH_1}")
    endif()
    if(contenu MATCHES "plasma_min=([0-9]+\\.[0-9]+)")
        set(borne_min "${CMAKE_MATCH_1}")
    endif()
    if(contenu MATCHES "plasma_max=([0-9]+\\.[0-9]+)")
        set(borne_max "${CMAKE_MATCH_1}")
    endif()
    if(NOT vise OR NOT borne_min OR NOT borne_max)
        message(FATAL_ERROR
            "${fichier} ne dit pas quelles versions de Plasma sont prises en "
            "charge : il faut « plasma= », « plasma_min= » et « plasma_max= ».")
    endif()
    # Une plage à l'envers passerait inaperçue et accepterait tout.
    if(borne_min VERSION_GREATER borne_max)
        message(FATAL_ERROR
            "${fichier} donne une plage à l'envers : plasma_min=${borne_min} "
            "est plus grand que plasma_max=${borne_max}.")
    endif()
    # La cible doit être DANS sa propre plage, sinon la plage ne veut rien dire.
    if(vise VERSION_LESS borne_min OR vise VERSION_GREATER borne_max)
        message(FATAL_ERROR
            "${fichier} vise Plasma ${vise}, hors de sa propre plage éprouvée "
            "(${borne_min} à ${borne_max}).")
    endif()
    set(ANKH_DE_PLASMA_VISE "${vise}" PARENT_SCOPE)
    set(ANKH_DE_PLASMA_MIN "${borne_min}" PARENT_SCOPE)
    set(ANKH_DE_PLASMA_MAX "${borne_max}" PARENT_SCOPE)
endfunction()

function(ankh_de_garde_version trouvee version_kdecoration non_teste)
    if(trouvee VERSION_LESS ANKH_DE_PLASMA_MIN
            OR trouvee VERSION_GREATER ANKH_DE_PLASMA_MAX)
        set(dit
            "Plasma ${trouvee} est installé (kdecoration ${version_kdecoration}), "
            "mais Ankh DE n'est éprouvé que de Plasma ${ANKH_DE_PLASMA_MIN} à "
            "${ANKH_DE_PLASMA_MAX} (src/*/VERSION-BREEZE, DE-016). Le style et la "
            "décoration dérivent du code de Breeze 6.7.5 : hors de cette plage, ils "
            "peuvent ne pas se charger, ou se charger à moitié.\n"
            "  Pour reporter le code : docs/REBASE.md\n"
            "  Pour construire quand même : -DANKH_DE_PLASMA_NON_TESTE=ON")
        if(non_teste)
            message(WARNING ${dit})
        else()
            message(FATAL_ERROR ${dit})
        endif()
    elseif(trouvee VERSION_EQUAL ANKH_DE_PLASMA_VISE)
        message(STATUS "Plasma ${trouvee} : la version visée en premier.")
    else()
        message(STATUS
            "Plasma ${trouvee} : dans la plage éprouvée "
            "(${ANKH_DE_PLASMA_MIN} à ${ANKH_DE_PLASMA_MAX}), la cible étant "
            "${ANKH_DE_PLASMA_VISE}.")
    endif()
endfunction()

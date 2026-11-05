# Galerie des contrôles : outil du banc, jamais installée.
cmake_minimum_required(VERSION 3.22)
project(ankh-de-galerie LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.6 REQUIRED COMPONENTS Core Gui Widgets)
# La galerie applique elle-même le jeu de couleurs et la police de
# kdeglobals, comme le fait plasma-integration dans une vraie session.
# Les composants sont cherchés un par un : le paquet parapluie « KF6 »
# demande le chemin de modules d'ECM, dont cet outil n'a pas besoin.
find_package(KF6ColorScheme 6.0 REQUIRED)
find_package(KF6Config 6.0 REQUIRED)

add_executable(galerie galerie.cpp)
target_link_libraries(galerie PRIVATE
    Qt6::Core Qt6::Gui Qt6::Widgets
    KF6::ColorScheme KF6::ConfigCore
)

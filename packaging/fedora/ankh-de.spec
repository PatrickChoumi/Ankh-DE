# Squelette NON TESTÉ (packaging/README.md).
# Les pièces tierces (police, curseurs, thème GTK) ne sont PAS dans ce paquet :
# elles demandent un téléchargement, interdit pendant une construction Fedora.
# Voir packaging/README.md, point 1.
Name:           ankh-de
Version:        0.1.0
Release:        1%{?dist}
Summary:        Windows 11 geometry, Ankh colours, on KDE Plasma 6
Summary(fr):    La géométrie de Windows 11, les couleurs d'Ankh, sur KDE Plasma 6

# GPL-3.0-or-later : imposée par Breeze (GPL-2.0-or-later) et Fluent (GPL-3.0).
License:        GPL-3.0-or-later
URL:            https://github.com/PatrickChoumi/Ankh-DE
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  extra-cmake-modules
BuildRequires:  cmake(Qt6Core) cmake(Qt6Gui) cmake(Qt6Widgets) cmake(Qt6DBus) cmake(Qt6Quick)
BuildRequires:  cmake(KF6Config) cmake(KF6CoreAddons) cmake(KF6GuiAddons)
BuildRequires:  cmake(KF6IconThemes) cmake(KF6WindowSystem) cmake(KF6ColorScheme)
BuildRequires:  cmake(KF6FrameworkIntegration)
BuildRequires:  cmake(KDecoration3)

# DE-008 : le greffon dérive du code d'une version précise de Plasma.
Requires:       plasma-workspace >= 6.7
Requires:       plasma-workspace < 6.8
Requires:       breeze-common

Recommends:     %{name}-fonts
Recommends:     %{name}-cursors
Recommends:     %{name}-gtk

%description
Ankh DE gives KDE Plasma 6 the metrics, typography, materials, motion and shell
layout of Windows 11, checked by a measurement bench, in the graphite and
violet identity of Ankh.

It is not a desktop environment written from scratch, not a Windows 11 clone,
and not affiliated with Microsoft: no Windows file is shipped. Only the
measurements are reused, from sources Microsoft publishes under the MIT licence.

%prep
%autosetup -n Ankh-DE-%{version}

%build
# Les pièces tierces ne sont pas construites ici : pas de réseau.
%cmake -DANKH_DE_STYLE:BOOL=ON -DANKH_DE_DECORATION:BOOL=ON -DANKH_DE_DATA:BOOL=ON
%cmake_build

%install
%cmake_install

%files
%license LICENSE
%doc README.md README.en.md ANKH-DE-SPEC.md DECISIONS.md ROADMAP.md LICENSES/README.md
%{_qt6_plugindir}/styles/ankh6.so
%{_qt6_plugindir}/org.kde.kdecoration3/org.ankh.decoration.so
%{_datadir}/kstyle/themes/ankh.themerc
%{_datadir}/color-schemes/Ankh.colors
%{_datadir}/color-schemes/AnkhClair.colors
%{_datadir}/plasma/look-and-feel/org.ankh.de.desktop/
%{_sysconfdir}/fonts/conf.d/29-ankh-rendu.conf

%changelog
* Thu Nov 05 2026 Patrick Choumi - 0.1.0-1
- Première version : lot 0 (autonomie) en cours, lots 1 à 3 repris d'Ankh.

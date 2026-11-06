# Paquet Fedora d'Ankh DE.
#
# Périmètre de la v0.1, et il est assumé : ce paquet livre tout ce qui se
# construit depuis NOS sources — le style Qt, la décoration des fenêtres, la
# session, les jeux de couleurs, le thème global, l'écran de chargement et
# le rendu des polices.
#
# Il ne livre PAS les pièces dérivées de dépôts tiers (police Selawik,
# curseurs, icônes, thème GTK, style Plasma) : elles se fabriquent par
# third_party/preparer.sh, qui télécharge, ce que les règles de Fedora
# interdisent pendant une construction. Elles feront des sous-paquets, avec
# leurs archives amont en Source:, quand chaque pin aura sa somme de
# contrôle (AUDIT.md §2.3). Le script accepte déjà ANKH_DE_SOURCES pour
# travailler hors réseau.
Name:           ankh-de
Version:        0.1.0
Release:        1%{?dist}
Summary:        Windows 11 geometry, Ankh colours, on KDE Plasma 6
Summary(fr):    La géométrie de Windows 11, les couleurs d'Ankh, sur KDE Plasma 6

# Imposée par les sources reprises : Breeze est en GPL-2.0-or-later,
# Fluent et KDE-Windows-Modern en GPL-3.0.
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

# DE-008 : une version d'Ankh DE vise UNE version de Plasma. Un greffon
# chargé à moitié est pire qu'un greffon qui refuse de se charger.
Requires:       plasma-workspace >= 6.8
Requires:       plasma-workspace < 6.9
# DE-010 : la session lance celle de Plasma après avoir posé ses valeurs
# par défaut. Sans startplasma-wayland, elle ne peut pas s'ouvrir.
Requires:       plasma-workspace-wayland
# Le style et la décoration retombent sur Breeze pour ce qu'ils ne dessinent pas.
Requires:       breeze-common

%description
Ankh DE gives KDE Plasma 6 the metrics, typography and window geometry of
Windows 11, checked by a measurement bench, in the graphite and violet
identity of Ankh. It ships its own session, so it is chosen at the login
screen like any desktop environment.

It is not a desktop environment written from scratch, not a Windows 11
clone, and not affiliated with Microsoft: no Windows file is shipped, and no
mark resembling a Microsoft logo. Only measurements are reused, from sources
Microsoft publishes under the MIT licence.

%description -l fr
Ankh DE donne à KDE Plasma 6 les mesures, la typographie et la géométrie des
fenêtres de Windows 11, vérifiées par un banc de mesure, sous l'identité
graphite et violet d'Ankh. Il livre sa propre session : on le choisit à
l'écran de connexion comme n'importe quel environnement de bureau.

%prep
%autosetup -n Ankh-DE-%{version}

%build
# Pas de réseau pendant la construction : les pièces tierces ne sont pas
# fabriquées ici (voir l'en-tête).
%cmake -DANKH_DE_STYLE:BOOL=ON \
       -DANKH_DE_DECORATION:BOOL=ON \
       -DANKH_DE_DATA:BOOL=ON \
       -DANKH_DE_SESSION:BOOL=ON
%cmake_build

%install
%cmake_install

%check
# Le greffon doit trouver toutes ses bibliothèques et tous ses symboles :
# un style à moitié chargé se voit mal et se diagnostique mal.
for greffon in %{buildroot}%{_qt6_plugindir}/styles/ankh6.so \
               %{buildroot}%{_qt6_plugindir}/org.kde.kdecoration3/org.ankh.decoration.so; do
    test -f "${greffon}"
done
# Aucun marqueur de configuration ne doit subsister dans la session.
! grep -q '@[A-Z_]*@' %{buildroot}%{_bindir}/ankh-de-session

%files
%license LICENSE
%doc README.md README.en.md ANKH-DE-SPEC.md DECISIONS.md ROADMAP.md AUDIT.md CHANGELOG.md
%doc docs/UPSTREAMS.md
%{_qt6_plugindir}/styles/ankh6.so
%{_qt6_plugindir}/org.kde.kdecoration3/org.ankh.decoration.so
%{_datadir}/kstyle/themes/ankh.themerc
%{_datadir}/color-schemes/Ankh.colors
%{_datadir}/color-schemes/AnkhClair.colors
%{_datadir}/plasma/look-and-feel/org.ankh.de.desktop/
%{_datadir}/wayland-sessions/ankh-de.desktop
%{_datadir}/ankh-de/
%{_bindir}/ankh-de-session
%{_sysconfdir}/fonts/conf.d/29-ankh-rendu.conf

%changelog
* Fri Nov 06 2026 Patrick Choumi - 0.1.0-1
- Première version : session, style, décoration, couleurs, thème global,
  écran de chargement. Les pièces dérivées de dépôts tiers restent à
  empaqueter.

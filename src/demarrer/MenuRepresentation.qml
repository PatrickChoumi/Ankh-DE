/***************************************************************************
 *   License: GPL-3.0-or-later
 *   Author: Jeysef
 *
 *   StartAllBack-style two-column start menu shell:
 *     ┌──────────────────────────────┬─────────────────┐
 *     │  Pinned / All apps (left)    │  User avatar    │
 *     │                              ├─────────────────┤
 *     │  vertical list of apps       │  System         │
 *     │                              │  locations      │
 *     ├──────────────────────────────┴─────────────────┤
 *     │  [Search programs and files...]  [Shut down >] │
 *     └────────────────────────────────────────────────┘
 *
 *   Pages live in pages/, shared components in components/.
 *   Keyboard input is handled by a single top-level handler on rootItem
 *   so any printable character appends to the search field regardless
 *   of which page or child widget currently holds focus.
 ***************************************************************************/

/*
 * Ankh DE : ce fichier remplace celui de KDE-Windows-Modern (GPL-3.0,
 * 7ef6bfe). On ne touche QUE l'arbre visuel — les modèles, le lancement
 * (« model.trigger »), le placement du popup (« popupPosition ») et la
 * bascule « leftColumnState » sont prouvés en session et restent intacts.
 *
 * Ce qui change, et pourquoi : l'amont dessine le menu de Windows 7 — deux
 * colonnes, « Places » à droite, recherche en bas. Windows 11 est une seule
 * colonne : recherche en haut, grille d'épingles, « Recommandé », puis
 * l'utilisateur à gauche et l'alimentation à droite. Mesures : 642 x 726 à
 * l'échelle 100 %, épingles 6 x 3, icône de 32 px.
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kitemmodels 1.0 as KItemModels
import org.kde.coreaddons as KCoreAddons
import org.kde.plasma.private.kicker 0.1 as Kicker

import "components"
import "pages"
import "code/tools.js" as Tools
import "code/theme.js" as Theme

Item {
    id: main

    onVisibleChanged: {
        root.visible = !root.visible
    }

    Plasmoid.status: root.visible ? PlasmaCore.Types.RequiresAttentionStatus : PlasmaCore.Types.PassiveStatus

    PlasmaCore.Dialog {
        id: root

        objectName: "popupWindow"
        flags: Qt.WindowStaysOnTopHint
        // Sans type explicite, libplasma bascule ce dialogue en Dock
        // (dialog.cpp, applyType) et un panneau ne reçoit pas le clavier.
        type: PlasmaCore.Dialog.AppletPopup
        location: PlasmaCore.Types.Floating
        hideOnWindowDeactivate: true

        // Opaque mode forces the solid dialog background variant; otherwise
        // let the desktop theme choose between default/translucent.
        backgroundHints: Plasmoid.configuration.menuTranslucency === Theme.menuTranslucencyOpaque
                         ? PlasmaCore.Dialog.SolidBackground
                         : PlasmaCore.Dialog.StandardBackground

        property bool searching: bottomBarContent.searchText !== ""

        // Left-column state: 0 = pinned, 1 = all apps, 2 = search results
        property int leftColumnState: 0

        onSearchingChanged: {
            if (searching) {
                leftColumnState = 2;
                // Reset scroll position when entering search mode.
                searchPage.resultsView.contentY = 0;
                searchPage.resultsView.currentIndex = 0;
            } else {
                leftColumnState = 0;
            }
        }

        onVisibleChanged: {
            if (visible) {
                reposition();
                reset();
            } else {
                leftColumnState = 0;
                sharedContextMenu.close();
                powerMenu.close();
            }
        }

        onHeightChanged: if (visible) reposition()
        onWidthChanged: if (visible) reposition()

        function reposition() {
            var pos = popupPosition(width, height);
            x = pos.x; y = pos.y;
        }

        function toggle() {
            main.visible = !main.visible
        }

        function reset() {
            bottomBarContent.searchText = "";
            leftColumnState = 0;
            // Reset the search filter pills to "All".
            searchPage.resultsView.singleRunner = "";
            // Defer focus until the dialog has finished laying out.
            Qt.callLater(bottomBarContent.focusSearch);
        }

        function closeMenu() {
            root.visible = false;
        }

        function popupPosition(width, height) {
            var screen = kicker.screenGeometry;
            var appletTopLeft = parent.mapToGlobal(0, 0);
            var horizMidPoint = screen.x + (screen.width / 2);
            var vertMidPoint = screen.y + (screen.height / 2);
            var offset = Kirigami.Units.smallSpacing;

            var menuPos = Plasmoid.configuration.displayPosition;

            if (menuPos === 1) {
                // Center of screen
                return Qt.point(horizMidPoint - width / 2, vertMidPoint - height / 2);
            } else if (menuPos === 2) {
                // Center-bottom (above panel)
                return Qt.point(horizMidPoint - width / 2,
                                screen.y + screen.height - height - kicker.height - offset);
            } else if (menuPos === 3) {
                // Left-bottom (above panel, left-aligned)
                return Qt.point(screen.x + offset,
                                screen.y + screen.height - height - kicker.height - offset);
            } else {
                // menuPos 0 — follow panel: center horizontally over the
                // start button, sit flush against the panel's top edge.
                var centerX = appletTopLeft.x + (kicker.width / 2) - (width / 2);
                centerX = Math.max(screen.x + offset,
                                   Math.min(centerX, screen.x + screen.width - width - offset));
                switch (Plasmoid.location) {
                case PlasmaCore.Types.BottomEdge:
                    return Qt.point(centerX, screen.y + screen.height - height - kicker.height - offset);
                case PlasmaCore.Types.TopEdge:
                    return Qt.point(centerX, screen.y + kicker.height + offset);
                case PlasmaCore.Types.LeftEdge:
                    return Qt.point(appletTopLeft.x + kicker.width + offset,
                                    Math.max(screen.y + offset,
                                             Math.min(appletTopLeft.y + (kicker.height / 2) - (height / 2),
                                                      screen.y + screen.height - height - offset)));
                case PlasmaCore.Types.RightEdge:
                    return Qt.point(appletTopLeft.x - width - offset,
                                    Math.max(screen.y + offset,
                                             Math.min(appletTopLeft.y + (kicker.height / 2) - (height / 2),
                                                      screen.y + screen.height - height - offset)));
                default:
                    return Qt.point(centerX, screen.y + screen.height - height - kicker.height - offset);
                }
            }
        }

        FocusScope {
            id: rootItem

            // 642 x 726 : les mesures du menu de Windows 11 à 100 %,
            // rapportées à gridUnit pour suivre les échelles.
            readonly property int recommendedHeight: Math.round(Kirigami.Units.gridUnit * 11)

            width: Math.round(642 * (Kirigami.Units.gridUnit / 18))
            height: Math.round(726 * (Kirigami.Units.gridUnit / 18))
            focus: true

            // Note: do NOT auto-redirect to the search field here.
            // onFocusChanged fires when any child calls forceActiveFocus(),
            // and stealing focus back makes it impossible to type from lists.
            // Initial search focus is handled by reset().

            Plasma5Support.DataSource {
                id: executable
                engine: "executable"
                connectedSources: []

                onNewData: function (source, data) {
                    disconnectSource(source);
                }

                function exec(cmd) {
                    connectSource(cmd);
                }
            }

            KCoreAddons.KUser { id: kuser }

            KItemModels.KSortFilterProxyModel {
                id: sortedAppsModel

                sortRoleName: {
                    var m = Plasmoid.configuration.allAppsSortMode;
                    if (m === 4) return "description";
                    if (m === 2 || m === 3) return "url";
                    return "display";
                }
                sortOrder: {
                    var m = Plasmoid.configuration.allAppsSortMode;
                    return (m === 1 || m === 3) ? Qt.DescendingOrder : Qt.AscendingOrder;
                }

                // Map a proxy row through to the source model so delegates
                // can call view.model.trigger(index, ...) uniformly whether
                // the model is the favorites model or this sorted proxy.
                function trigger(row, actionId, argument) {
                    var srcIdx = mapToSource(index(row, 0));
                    if (srcIdx.valid && sourceModel) {
                        return sourceModel.trigger(srcIdx.row, actionId, argument);
                    }
                    return false;
                }

                property var favoritesModel: sourceModel ? sourceModel.favoritesModel : null
            }

            // « Recommandé » : le modèle d'usage récent de Kicker, déclaré
            // directement. findRowModel() ne peut PAS le trouver — les
            // lignes « récents » du RootModel ne reçoivent jamais de
            // setDescription(). Ses défauts, AppsAndDocs + Recent, sont
            // exactement ce que montre Windows 11.
            Kicker.RecentUsageModel { id: recommendedModel }

            // ── Une seule colonne, comme Windows 11 (DE-017) ─────────────
            //
            // L'amont posait ici un RowLayout à DEUX colonnes : une liste
            // d'épingles à gauche, une colonne « Places » à droite, et la
            // recherche tout en bas. C'est la forme de Windows 7. Relevé le
            // 2026-11-08 sur une capture de session réelle, puis comparé aux
            // captures de Windows 11 fournies par le propriétaire.
            ColumnLayout {
                id: mainColumn
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: bottomBar.top
                anchors.topMargin: Kirigami.Units.gridUnit
                anchors.bottomMargin: Kirigami.Units.gridUnit
                anchors.leftMargin: Kirigami.Units.gridUnit
                anchors.rightMargin: Kirigami.Units.gridUnit
                spacing: Kirigami.Units.largeSpacing

                // 1. La recherche, EN HAUT. Le composant garde son nom et son
                //    id : pages/SearchPage.qml, que nous ne remplaçons pas,
                //    atteint « bottomBarContent » par son nom.
                BottomBar {
                    id: bottomBarContent
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight


                    onSearchTextChanged: {
                        // Explicitly push the query to Milou ResultsView.
                        searchPage.resultsView.queryString = bottomBarContent.searchText;
                        // Reset scroll to top on new query — only when
                        // the search page is active to avoid warnings
                        // from setting properties on a non-visible view.
                        if (root.leftColumnState === 2) {
                            searchPage.resultsView.contentY = 0;
                            searchPage.resultsView.currentIndex = 0;
                        }
                    }
                    onSearchFocusResults: rootItem.focusActivePageResults()
                    onSearchNavUp: {
                        if (root.leftColumnState === 0) pinnedPage.navigateUp();
                        else if (root.leftColumnState === 1) allAppsPage.navigateUp();
                        else if (root.leftColumnState === 2) searchPage.navigateUp();
                    }
                    onSearchNavDown: {
                        if (root.leftColumnState === 0) pinnedPage.navigateDown();
                        else if (root.leftColumnState === 1) allAppsPage.navigateDown();
                        else if (root.leftColumnState === 2) searchPage.navigateDown();
                    }
                    onSearchActivateFirstResult: {
                        rootItem.activateCurrentItem();
                    }
                    onSearchEscapePressed: {
                        if (bottomBarContent.searchText !== "") {
                            bottomBarContent.searchText = "";
                        } else {
                            root.closeMenu();
                        }
                    }
                    onTabOut: rootItem.focusActivePageResults()
                }

                // 2. Les pages, dans un SLOT. SearchPage pose
                //    « width: parent.width » et « height: parent.height » :
                //    cela ne tenait que parce qu'elle était seule visible
                //    dans sa colonne. Partageant maintenant la colonne avec
                //    la recherche, elle entrerait en boucle de liaison. Le
                //    slot rend « parent.height » juste, et SearchPage reste
                //    intacte.
                Item {
                    id: pageSlot
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    PinnedPage {
                        id: pinnedPage
                        anchors.fill: parent
                        visible: root.leftColumnState === 0
                        onShowAllAppsRequested: {
                            root.leftColumnState = 1;
                        }
                        onKeyNavUpFromList: bottomBarContent.focusSearch()
                    }

                    AllAppsPage {
                        id: allAppsPage
                        anchors.fill: parent
                        visible: root.leftColumnState === 1
                        onBackRequested: {
                            root.leftColumnState = 0;
                        }
                        onKeyNavUpFromList: bottomBarContent.focusSearch()
                    }

                    SearchPage {
                        id: searchPage
                        anchors.fill: parent
                        visible: root.leftColumnState === 2
                        onContextMenuRequested: function(actions, x, y, context) {
                            var pos = searchPage.mapToItem(sharedContextMenu, x, y)
                            sharedContextMenu.open(actions, pos.x, pos.y, context)
                        }
                    }
                }

                // 3. « Recommandé ». Sur la capture de Windows 11, cette
                //    section occupe près de 40 % de la hauteur utile — ce
                //    n'est pas un bandeau.
                ColumnLayout {
                    id: recommendedSection
                    Layout.fillWidth: true
                    Layout.preferredHeight: rootItem.recommendedHeight
                    Layout.fillHeight: false
                    visible: root.leftColumnState === 0 && recommendedModel.count > 0
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents3.Label {
                        text: i18n("Recommended")
                        color: Kirigami.Theme.textColor
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.95
                        font.weight: Font.DemiBold
                        Layout.leftMargin: Kirigami.Units.smallSpacing
                    }

                    ListView {
                        id: recommendedList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: recommendedModel
                        clip: true
                        currentIndex: -1
                        spacing: Math.round(Kirigami.Units.smallSpacing / 2)
                        boundsBehavior: Flickable.StopAtBounds

                        PlasmaComponents3.ScrollBar.vertical: PlasmaComponents3.ScrollBar {
                            policy: PlasmaComponents3.ScrollBar.AsNeeded
                        }

                        delegate: ListItemDelegate {
                            iconSize: Kirigami.Units.iconSizes.smallMedium
                            showDescription: true
                        }
                    }
                }
            }

            // ── Barre du bas : utilisateur à gauche, alimentation à droite
            Rectangle {
                id: bottomBar
                width: parent.width
                height: bottomRow.implicitHeight + Kirigami.Units.gridUnit
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Kirigami.Units.gridUnit
                anchors.left: parent.left
                anchors.leftMargin: Kirigami.Units.gridUnit
                anchors.right: parent.right
                anchors.rightMargin: Kirigami.Units.gridUnit
                Kirigami.Theme.colorSet: Kirigami.Theme.Header
                Kirigami.Theme.inherit: false
                color: "transparent"

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                    color: Kirigami.Theme.textColor
                    opacity: Theme.separatorOpacity
                }

                RowLayout {
                    id: bottomRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Kirigami.Units.largeSpacing

                    Item {
                        id: avatarArea
                        Layout.alignment: Qt.AlignVCenter
                        width: Kirigami.Units.iconSizes.medium
                        height: width

                        Image {
                            id: userAvatar
                            anchors.fill: parent
                            source: {
                                var faceUrl = kuser.faceIconUrl.toString()
                                if (faceUrl !== "") return faceUrl
                                return "file:///usr/share/icons/breeze/apps/48/kuser.svg"
                            }
                            cache: false
                            fillMode: Image.PreserveAspectCrop
                            visible: source !== ""
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: avatarArea.width
                                    height: avatarArea.height
                                    radius: avatarArea.width / 2
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                                                   Kirigami.Theme.textColor.g,
                                                   Kirigami.Theme.textColor.b, Theme.buttonBorderOpacity)
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: executable.exec("systemsettings kcm_users")
                        }
                    }

                    PlasmaComponents3.Label {
                        id: userNameLabel
                        text: kuser.fullName !== "" ? kuser.fullName : kuser.loginName
                        color: Kirigami.Theme.textColor
                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: false
                    }

                    Item { Layout.fillWidth: true }

                    PowerButton {
                        id: powerButton
                        Layout.alignment: Qt.AlignVCenter
                        onMenuRequested: {
                            powerMenu.visualParent = powerButton;
                            powerMenu.open();
                        }
                        onShutdownRequested: powerMenu.triggerShutdown()
                    }
                }
            }

            // ── Power options popup (in-dialog, not a separate window) ────
            ShutdownMenu {
                id: powerMenu
                anchors.fill: parent
                onClosed: {
                    bottomBarContent.focusSearch();
                }
            }

            // ── Shared context menu for list delegates ─────────────────────
            ContextMenu {
                id: sharedContextMenu
                anchors.fill: parent
                onActionTriggered: function(actionId, argument, context) {
                    rootItem.handleContextAction(actionId, argument, context)
                }
            }

            function handleContextAction(actionId, argument, context) {
                // Milou runner actions: invoke the named action on the
                // current match via ResultsView.runAction().
                if (actionId === "_milou_runner_action" && context && context.kind === "milou") {
                    if (argument && typeof argument.actionIndex !== "undefined") {
                        searchPage.resultsView.currentIndex = argument.matchIndex
                        searchPage.resultsView.runAction(argument.actionIndex)
                    }
                    return
                }

                // "Open" fallback for results with no runner actions
                // (e.g. plain app launches from krunner_services).
                if (actionId === "_milou_open" && context && context.kind === "milou") {
                    if (argument) {
                        searchPage.resultsView.currentIndex = argument.matchIndex
                        searchPage.resultsView.runCurrentIndex(null)
                    }
                    return
                }

                var model = context ? (context.resolvedModel || context.model) : null;
                var idx = context ? (context.resolvedIndex !== undefined ? context.resolvedIndex : context.index) : -1;
                var close = (Tools.triggerAction(model, idx, actionId, argument) === true);
                if (close) {
                    root.closeMenu();
                }
            }

            function focusActivePageResults() {
                if (root.leftColumnState === 0) {
                    pinnedPage.tryActivate(0);
                } else if (root.leftColumnState === 1) {
                    allAppsPage.tryActivate(0);
                } else {
                    searchPage.tryActivate(0, 0);
                }
            }

            function activateCurrentItem() {
                if (root.leftColumnState === 0) {
                    pinnedPage.activateCurrent();
                } else if (root.leftColumnState === 1) {
                    allAppsPage.activateCurrent();
                } else if (root.leftColumnState === 2) {
                    searchPage.activateCurrent();
                }
            }

            // Lookup map for search-result context menus.  Built by the
            // hidden appLookupMap ListView below as delegates are
            // instantiated — this is the only reliable way to access model
            // roles by name in QML (QAbstractItemModel doesn't expose
            // roleNames() to the QML side).  Keyed by display name.
            property var _appLookupMap: ({})

            // Rebuild the lookup map when the source model changes.
            // Returns { favoriteId, url, actionList } or null.
            function lookupAppByDisplayName(displayName) {
                if (!displayName) return null;
                return rootItem._appLookupMap[displayName] || null;
            }

            // Lookup map for search-result context menus.  Uses a Repeater
            // (not ListView) because Repeater creates ALL delegates eagerly —
            // ListView only creates delegates in/near the visible viewport,
            // which fails for off-screen helpers.  Each delegate writes its
            // model roles into the map on creation.
            Column {
                x: -9999
                y: -9999
                width: 0
                height: 0
                visible: true

                Repeater {
                    model: sortedAppsModel
                    delegate: Item {
                        Component.onCompleted: {
                            var name = (model.display !== undefined) ? model.display : "";
                            if (name !== "") {
                                rootItem._appLookupMap[name] = {
                                    favoriteId: (model.favoriteId !== undefined) ? model.favoriteId : "",
                                    url: (model.url !== undefined) ? model.url : "",
                                    actionList: (model.actionList !== undefined) ? model.actionList : null
                                };
                            }
                        }
                    }
                }
            }

            // ── Single global keyboard handler ─────────────────────────────
            //
            // Registered once on rootItem. Any printable character typed
            // anywhere in the menu appends to the search field and switches
            // to the search page. Escape/Backspace route to search or close.
            // Navigation keys (Tab, arrows, Enter) are left for children to
            // handle, and only reach here if no child consumed them.
            Keys.onPressed: event => {

                // Ctrl+digit launches a pinned favorite (1..9).
                if (event.modifiers === Qt.ControlModifier) {
                    var digit = event.key - Qt.Key_1;
                    if (digit >= 0 && digit <= 8) {
                        var count = globalFavorites.count;
                        if (digit < count) {
                            event.accepted = true;
                            globalFavorites.trigger(digit, "", null);
                            root.closeMenu();
                        }
                        return;
                    }
                }

                // Ignore pure modifier presses.
                if (event.key === Qt.Key_Shift || event.key === Qt.Key_Control
                        || event.key === Qt.Key_Alt || event.key === Qt.Key_Meta
                        || event.key === Qt.Key_AltGr) {
                    return;
                }

                // Let Tab/Backtab navigate the focus chain normally.
                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    return;
                }

                if (event.key === Qt.Key_Escape) {
                    event.accepted = true;
                    if (root.searching) {
                        reset();
                    } else if (root.leftColumnState === 1) {
                        root.leftColumnState = 0;
                        bottomBarContent.focusSearch();
                    } else {
                        root.closeMenu();
                    }
                    return;
                }

                // Backspace from a list: delete last search char.
                if (event.key === Qt.Key_Backspace) {
                    event.accepted = true;
                    bottomBarContent.searchText = bottomBarContent.searchText.slice(0, -1);
                    return;
                }

                // Arrow / Enter / Page / Home / End are navigation: let the
                // focused child handle them.
                if (event.key === Qt.Key_Up || event.key === Qt.Key_Down
                        || event.key === Qt.Key_Left || event.key === Qt.Key_Right
                        || event.key === Qt.Key_Enter || event.key === Qt.Key_Return
                        || event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown
                        || event.key === Qt.Key_Home || event.key === Qt.Key_End) {
                    return;
                }

                // Any other printable character: append directly to the
                // searchText property (aliased to the TextField's text).
                // This works regardless of which item has focus — no need
                // to steal focus or guard on activeFocus.  The onTextChanged
                // → onSearchingChanged chain handles the page switch.
                // When the search field itself has focus it handles its own
                // input natively and this handler never fires.
                if (event.text !== "" && event.text !== "\t"
                        && !(event.modifiers & Qt.ControlModifier)) {
                    event.accepted = true;
                    bottomBarContent.searchText = bottomBarContent.searchText + event.text;
                }
            }
        }

        function setModels() {
            pinnedPage.favoritesList.model = globalFavorites;
            sortedAppsModel.sourceModel = findRowModel(rootModel, "KICKER_ALL_MODEL");
            allAppsPage.allAppsList.model = sortedAppsModel;
        }

        // Locate a rootModel child row by its description.  The Kicker
        // models expose "description" as a Q_PROPERTY (not a data role),
        // so we read it off the model returned by modelForRow().
        function findRowModel(parentModel, description) {
            if (!parentModel) return null;
            for (var i = 0; i < parentModel.rowCount(); i++) {
                var m = parentModel.modelForRow(i);
                if (m && m.description === description) {
                    return m;
                }
            }
            return null;
        }

        Component.onCompleted: {
            rootModel.refreshed.connect(setModels);
            reset();
            rootModel.refresh();
        }
    }
}

import QtQuick 2.15
import QtGraphicalEffects 1.0
import QtMultimedia 5.9
import QtQml.Models 2.10
import SortFilterProxyModel 0.2

import "Components"

import "./settings.js" as Settings
import "./utils.js" as Utils

FocusScope {
    id: root

    FontLoader { id: homeFont; source: "assets/fonts/Comfortaa-Light.ttf" }

    FontLoader { id: fontawesome; source: "assets/fonts/Fontawesome.otf" }
    FontLoader { id: titleFont; source: "assets/fonts/SourceSansPro-Bold.ttf" }
    FontLoader { id: subtitleFont; source: "assets/fonts/OpenSans-Bold.ttf" }
    FontLoader { id: bodyFont; source: "assets/fonts/OpenSans-Semibold.ttf" }

    SoundEffect { id: sfxNav; source: "assets/sfx/navigation.wav" }
    SoundEffect { id: sfxBack; source: "assets/sfx/back.wav" }
    SoundEffect { id: sfxAccept; source: "assets/sfx/accept.wav" }
    SoundEffect { id: sfxToggle; source: "assets/sfx/toggle.wav" }

    readonly property alias allGames: allGames
    AllGames { id: allGames }

    property var settingsMetadata: Settings.metadata;

    property var stateHistory: []

    property var currentCollection: api.collections.get(0)
    property int currentCollectionIndex: 0

    onCurrentCollectionChanged: savedGameIndex = 0;

    property var selectedGame
    property var selectedGameHistory: []

    property int savedGameIndex: 0;

    property bool filterByFavorites: false
    property bool filterByBookmarks: false

    property var orderBy: ['title', 'developer', 'publisher', 'genre', 'releaseYear', 'players', 'rating', 'lastPlayed']
    property int orderByIndex: 0
    property int orderByDirection: Qt.AscendingOrder

    readonly property bool gameItemTitleEnabled: api.memory.get('settings.global.titleEnabled')
    readonly property real gameItemTitlePadding: gameItemTitleEnabled ? vpx(api.memory.get('settings.global.titleFontSize') * 0.25) : 0
    readonly property real gameItemTitleHeight: gameItemTitleEnabled ? vpx(api.memory.get('settings.global.titleFontSize')) : 0

    readonly property real gameItemTitleMargin: gameItemTitleEnabled ? gameItemTitleHeight + (api.memory.get('settings.global.borderEnabled') ? vpx(api.memory.get('settings.global.borderWidth')) : 0) + gameItemTitlePadding * 3 : 0

    property bool gameItemPlayVideoPreview: false

    Timer {
        id: gameItemVideoPreviewDebouncer

        interval: api.memory.get('settings.global.videoPreviewDelay')
        onTriggered: { gameItemPlayVideoPreview = true; }

        function debounce() {
            if (api.memory.get('settings.global.previewEnabled')) {
                gameItemVideoPreviewDebouncer.restart();
            } else {
                gameItemVideoPreviewDebouncer.stop();
            }

            gameItemPlayVideoPreview = false;
        }
    }

    states: [
        State { name: 'showcaseView'; PropertyChanges { target: contentLoader; sourceComponent: showcaseViewComponent } },
        State { name: 'gameDetailsView'; PropertyChanges { target: contentLoader; sourceComponent: showcaseViewComponent } },
        State { name: 'settingsView'; PropertyChanges { target: contentLoader; sourceComponent: settingsViewComponent } }
    ]

    state: 'showcaseView'

    Background {
        anchors.fill: parent

        source: contentLoader.game ? contentLoader.game.assets.screenshot || '' : ''

        Image {
            id: loadingIndicator

            anchors.centerIn: parent
            source: loadingIndicator.visible ? 'assets/loading-spinner.png' : ''
            asynchronous: false
            smooth: true

            RotationAnimator on rotation {
                loops: Animator.Infinite;
                from: 0;
                to: 360;
                duration: 1000

                running: loadingIndicator.visible
            }

            visible: opacity > 0
            opacity: contentLoader.status === Loader.Loading ? 1 : 0
            Behavior on opacity { SequentialAnimation { NumberAnimation { duration: 300; from: 1 } } }
        }
    }

    Component { id: settingsViewComponent; SettingsView { anchors.fill: parent; focus: true } }

    Component {
        id: showcaseViewComponent;

        FocusScope {
            anchors.fill: parent
            focus: true

            readonly property var game: (root.state === 'showcaseView' ? showcaseView.game : gameDetailsView.game)

            ShowcaseView {
                id: showcaseView

                anchors.fill: parent
                focus: root.state === 'showcaseView'

                visible: opacity > 0
                opacity: focus ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300; from: 0 } }
            }

            GameDetailsView {
                id: gameDetailsView

                anchors.fill: parent
                focus: root.state === 'gameDetailsView'

                game: root.selectedGame

                visible: opacity > 0
                opacity: focus ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300; from: 0 } }
            }
        }
    }

    Loader {
        id: contentLoader
        readonly property var game: item.game

        anchors.fill: parent

        asynchronous: true

        opacity: contentLoader.status === Loader.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300; from: 0 } }

        focus: true
    }

    Component.onCompleted: {
        reloadSettings();
    }

    Keys.onPressed: {
        if (event.isAutoRepeat) {
            return;
        }

        if (api.keys.isCancel(event)) {
            event.accepted = previousScreen();
        }
    }

    function reloadSettings(overwrite = false) {
        for (const [categoryKey, category] of Object.entries(settingsMetadata)) {
            for (const [settingKey, setting] of Object.entries(category)) {
                const key = `settings.${categoryKey}.${settingKey}`;

                if ((!api.memory.has(key) || overwrite) && setting.defaultValue != undefined) {
                    api.memory.set(key, setting.defaultValue);
                }
            }
        };
    }

    function previousScreen() {
        if (stateHistory.length > 0) {
            sfxBack.play();
            root.state = stateHistory.pop();

            if (selectedGameHistory.length > 0) {
                selectedGame = selectedGameHistory.pop();
            }

            return true;
        }


        return false;
    }

    function toGamesView() {
        sfxAccept.play();
        stateHistory.push(root.state);
        root.state = 'gamesView';
    }

    function toSettingsView() {
        sfxAccept.play();
        stateHistory.push(root.state);
        root.state = 'settingsView';
    }

    function toGameDetailsView(game) {
        sfxAccept.play();

        if (selectedGame) {
            selectedGameHistory.push(selectedGame);
        }

        selectedGame = game;

        stateHistory.push(root.state);
        root.state = 'gameDetailsView';
    }

    function toggleBookmarks(game) {
        const key = `database.bookmarks.${game.collections.get(0).shortName}.${game.title}`;
        api.memory.set(key, !(api.memory.get(key) ?? false));
        game.onFavoriteChanged();
    }

    function getPrecision(a) {
        if (!isFinite(a)) {
            return 0;
        }

        var e = 1, p = 0;
        while (Math.round(a * e) / e !== a) {
            e *= 10;
            p++;
        }

        return p;
    }

    function capitalizeFirstLetter([ first, ...rest ], locale = 'en-US') {
        return first.toLocaleUpperCase(locale) + rest.join('');
    }
}

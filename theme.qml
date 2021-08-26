import QtQuick 2.0
import QtGraphicalEffects 1.0
import QtMultimedia 5.9
import QtQml.Models 2.10

import "Components"

import "./utils.js" as Utils

FocusScope {
    id: root

    FontLoader { id: titleFont; source: "assets/fonts/SourceSansPro-Bold.ttf" }
    FontLoader { id: subtitleFont; source: "assets/fonts/OpenSans-Bold.ttf" }
    FontLoader { id: bodyFont; source: "assets/fonts/OpenSans-Semibold.ttf" }

    SoundEffect { id: sfxNav; source: "assets/sfx/navigation.wav" }
    SoundEffect { id: sfxBack; source: "assets/sfx/back.wav" }
    SoundEffect { id: sfxAccept; source: "assets/sfx/accept.wav" }
    SoundEffect { id: sfxToggle; source: "assets/sfx/toggle.wav" }

    property var settingsMetadata: ({
        game: {
            gameViewColumns: { name: 'Number of Columns', default: 3, type: 'int', min: 1 },

            art: {
                name: 'Art',
                default: 0,
                values: ['screenshot', 'boxFront', 'boxBack', 'boxSpine', 'boxFull', 'cartridge', 'marquee', 'bezel', 'panel', 'cabinetLeft', 'cabinetRight', 'tile', 'banner', 'steam', 'poster', 'background', 'titlescreen'],
                type: 'array'
            },

            aspectRatioNative: { name: 'Aspect Ratio - Use Native', default: false, type: 'bool' },
            aspectRatioWidth: { name: 'Aspect Ratio - Width', default: 9.2, delta: 0.1, min: 0.1, type: 'real' },
            aspectRatioHeight: { name: 'Aspect Ratio - Height', default: 4.3, delta: 0.1, min: 0.1, type: 'real' },

            previewEnabled: { name: 'Video Preview - Enabled', default: true, type: 'bool' },
            previewVolume: { name: 'Video Preview - Volume', default: 0.0, delta: 0.1, min: 0.0, type: 'real' },

            borderAnimated: { name: 'Border - Animate', default: true, type: 'bool' },
            borderColor1: { name: 'Border - Color 1', default: '#FFC85C', type: 'string' },
            borderColor2: { name: 'Border - Color 2', default: '#ECECEC', type: 'string' },
            borderWidth: { name: 'Border - Width', default: 5, min: 0, type: 'int', },

            cornerRadius: { name: 'Border - Corner Radius', default: 5, min: 0, type: 'int' },

            scale: { name: 'Scale', default: 0.95, delta: 0.01, min: 0.01, max: 1.0, type: 'real' },
            scaleSelected: { name: 'Scale - Selected', default: 1.0, delta: 0.01, min: 0.01, type: 'real' },


            logoScale: { name: 'Logo - Scale', default: 0.75, delta: 0.01, min: 0.01, type: 'real' },
            logoScaleSelected: { name: 'Logo - Scale - Selected', default: 0.85, delta: 0.01, min: 0.01, type: 'real' },
            logoVisible: { name: 'Logo - Visible', default: true, type: 'bool' },
            previewLogoVisible: { name: 'Logo - Visible - Video Preview', default: true, type: 'bool' },
            logoFontSize: { name: 'Logo - Font Size', default: 20, min: 1, type: 'int' },

            letterNavOpacity: { name: 'Jump to Letter - Background Opacity', default: 0.8, delta: 0.01, min: 0.0, max: 1.0, type: 'real' },
            letterNavSize: { name: 'Jump to Letter - Size', default: 200, type: 'int' },
            letterNavPauseDuration: { name: 'Jump to Letter - Pause Duration (Milliseconds)', default: 400, delta: 50, min: 0, type: 'int' },
            letterNavFadeDuration: { name: 'Jump to Letter - Fade Duration (Milliseconds)', default: 400, delta: 50, min: 0, type: 'int' },
        },
        gameDetails: {
            previewEnabled: { name: 'Video Preview - Enabled', default: true, type: 'bool' },
            previewVolume: { name: 'Video Preview - Volume', default: 0.0, delta: 0.1, min: 0.0, type: 'real' },
        },
        theme: {
            backgroundColor: { name: 'Background Color', default: '#13161B', type: 'string' },
            accentColor: { name: 'Accent Color', default: '#FFC85C', type: 'string' },
            textColor: { name: 'Text Color', default: '#ECECEC', type: 'string' },

            // backgroundColor: { name: 'Background Color', default: '#262A53', type: 'string' },
            // accentColor: { name: 'Accent Color', default: '#FFA0A0', type: 'string' },
            // textColor: { name: 'Text Color', default: '#FFE3E3', type: 'string' },
            leftMargin: { name: 'Screen Padding - Left', default: 60, min: 0, type: 'int' },
            rightMargin: { name: 'Screen Padding - Right', default: 60, min: 0, type: 'int' },
        },
        performance: {
            artImageResolution: { name: 'Art - Image Resolution', default: 0, values: ['Native', 'Scaled'], type: 'array' },
            artImageCaching: { name: 'Art - Image Caching', default: false, type: 'bool' },
            artImageSmoothing: { name: 'Art - Image Smoothing', default: false, type: 'bool' },
            artDropShadow: { name: 'Art - Drop Shadow', default: false, type: 'bool' },

            logoImageResolution: { name: 'Logo - Image Resolution', default: 0, values: ['Native', 'Scaled'], type: 'array' },
            logoImageCaching: { name: 'Logo - Image Caching', default: false, type: 'bool' },
            logoImageSmoothing: { name: 'Logo - Image Smoothing', default: false, type: 'bool' },
            logoDropShadow: { name: 'Logo - Drop Shadow', default: false, type: 'bool' }
        }
    });

    property var stateHistory: []

    property var currentCollection: api.collections.get(0)
    property int currentCollectionIndex: 0

    onCurrentCollectionChanged: savedGameIndex = 0;

    property var selectedGame
    property var selectedGameHistory: []

    property int savedGameIndex: 0;

    property bool filterByFavorites: false
    property bool filterByBookmarks: false

    states: [
        State { name: 'gamesView'; PropertyChanges { target: loader; sourceComponent: gamesView } },
        State { name: 'settingsView'; PropertyChanges { target: loader; sourceComponent: settingsView } },
        State { name: 'gameDetailsView'; PropertyChanges { target: loader; sourceComponent: gameDetailsView } }
    ]

    state: 'gamesView'

    Rectangle {
        anchors.fill: parent
        color: api.memory.get('settings.theme.backgroundColor')
    }

    Component {
        id: gamesView
        GamesView { focus: true }
    }

    Component {
        id: settingsView
        SettingsView { focus: true }
    }

    Component {
        id: gameDetailsView
        GameDetailsView { focus: true }
    }

    Loader {
        id: loader
        anchors.fill: parent

        focus: true
        asynchronous: true
    }

    Component.onCompleted: {
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
        for (const [categoryKey, category] of Object.entries(this.metadata)) {
            for (const [settingKey, setting] of Object.entries(category)) {
                const key = `settings.${categoryKey}.${settingKey}`;

                if (!api.memory.has(key) || overwrite) {
                    api.memory.set(key, setting.default);
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
        stateHistory.push(root.state);
        root.state = 'gameDetailsView';

        if (selectedGame) {
            selectedGameHistory.push(selectedGame);
        }

        selectedGame = game;
    }

    function toggleBookmarks(collection, game) {
        const key = `database.bookmarks.${collection.shortName}.${game.title}`;
        api.memory.set(key, !(api.memory.get(key) ?? false));
    }
}

import QtQuick 2.0
import QtQuick.Layouts 1.11

FocusScope {
    id: root
    anchors.fill: parent

    property var categories: []

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

    function capitalize(str) {
        const capitalizeFirstLetter = ([ first, ...rest ], locale = 'en-US') => first.toLocaleUpperCase(locale) + rest.join('')
        return capitalizeFirstLetter(str).split(/([A-Z]?[^A-Z]*)/g).join(' ');
    }

    Component.onCompleted: {
        root.categories = Object.keys(settings).map(k => ({
            name: capitalize(k),
            settings: Object.values(settings[k])
        }));
    }

    Component.onDestruction: {
        loadSettings();
    }

    Item {
        id: header

        anchors {
            top: parent.top; left: parent.left; right: parent.right
        }

        anchors.leftMargin: headerLeftMargin
        anchors.rightMargin: headerRightMargin

        height: vpx(75)

        Rectangle {
            id: titleBackground

            color: settings.theme.accentColor.value

            width: title.width + vpx(80)
            height: header.height
        }

        Text {
            id: title

            height: header.height - vpx(30)
            anchors.centerIn: titleBackground

            text: 'Settings'

            font.family: titleFont.name
            font.pixelSize: vpx(36)
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: settings.theme.backgroundColor.value
        }
    }

    property real rowHeight: vpx(50)

    ListView {
        id: categoriesListView

        focus: true
        anchors {
            top: header.bottom; bottom: parent.bottom; left: header.left;
            topMargin: vpx(20)
        }

        width: parent.width / 5.0

        model: root.categories
        delegate: Item {
            width: ListView.view.width; height: rowHeight

            property bool selected: ListView.isCurrentItem

            Text {
                text: modelData.name
                color: settings.theme.textColor.value
                font.family: subtitleFont.name
                font.pixelSize: vpx(24)
                verticalAlignment: Text.AlignVCenter
                opacity: selected ? 1 : 0.2
                
                height: parent.height

                anchors.left: parent.left
                anchors.leftMargin: vpx(5)
            }
        }

        Keys.onPressed: {
            if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                sfxAccept.play();
                settingsListView.focus = true;

                event.accepted = true;
            }
        }
    }

    ListView {
        id: settingsListView

        model: root.categories[categoriesListView.currentIndex].settings

        anchors {
            top: categoriesListView.top; bottom: parent.bottom; left: categoriesListView.right; right: header.right
        }

        preferredHighlightBegin: settingsListView.height / 2 - rowHeight
        preferredHighlightEnd: settingsListView.height / 2
        highlightRangeMode: ListView.ApplyRange
        highlightMoveDuration: 100
        clip: true

        delegate: FocusScope {
            property bool selected: ListView.isCurrentItem && settingsListView.focus
            property var value: api.memory.get(modelData.name)

            width: ListView.view.width; height: rowHeight

            Text {
                id: settingsName

                text: modelData.name
                color: settings.theme.textColor.value
                font.family: subtitleFont.name
                font.pixelSize: vpx(20)
                verticalAlignment: Text.AlignVCenter
                opacity: selected ? 1 : 0.2

                height: parent.height
                anchors.left: parent.left
                anchors.leftMargin: vpx(5)
            }

            Text {
                id: settingsValue

                text: value
                color: settings.theme.textColor.value
                font.family: subtitleFont.name
                font.pixelSize: vpx(20)
                verticalAlignment: Text.AlignVCenter
                opacity: selected ? 1.0 : 0.2

                height: parent.height
                anchors.right: parent.right
                anchors.rightMargin: vpx(5)
            }

            Keys.onLeftPressed: {
                event.accepted = true;
                sfxToggle.play();
                decrementSettingValue();
            }

            Keys.onRightPressed: {
                event.accepted = true;
                sfxToggle.play();
                incrementSettingValue();
            }

            Keys.onPressed: {
                if (event.isAutoRepeat) {
                    return;
                }

                if (api.keys.isAccept(event)) {
                    event.accepted = true;
                    sfxToggle.play();
                    incrementSettingValue();
                }

                if (api.keys.isCancel(event)) {
                    event.accepted = true;
                    sfxBack.play();
                    categoriesListView.focus = true;
                }
            }

            function incrementSettingValue() {
                switch (modelData.type) {
                    case 'bool':
                        api.memory.set(modelData.name, !value);
                        break;
                    case 'int':
                        api.memory.set(modelData.name, parseInt(value) + 1);
                        break;
                    case 'real':
                        api.memory.set(modelData.name, (parseFloat(value) + parseFloat(modelData.delta)).toFixed(getPrecision(modelData.delta)));
                        break;
                }

            }

            function decrementSettingValue() {
                switch (modelData.type) {
                    case 'bool':
                        api.memory.set(modelData.name, !value);
                        break;
                    case 'int':
                        api.memory.set(modelData.name, parseInt(value) - 1);
                        break;
                    case 'real':
                        api.memory.set(modelData.name, (parseFloat(value) - parseFloat(modelData.delta)).toFixed(getPrecision(modelData.delta)));
                        break;
                }
            }
        }

        Keys.onUpPressed: { sfxNav.play(); decrementCurrentIndex() }
        Keys.onDownPressed: { sfxNav.play(); incrementCurrentIndex() }

        
    }
}
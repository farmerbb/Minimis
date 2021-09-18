import QtQuick 2.0
import QtQuick.Layouts 1.11

FocusScope {
    id: root
    anchors.fill: parent

    property var categories: []
    property var currentCategory: categories[categoriesListView.currentIndex]

    function capitalize(str) {
        return capitalizeFirstLetter(str).split(/([A-Z]?[^A-Z]*)/g).join(' ');
    }

    Component.onCompleted: {
        root.categories = Object.entries(settingsMetadata).map(([categoryKey, category]) => ({
            key: categoryKey,
            value: Object.entries(category).map(([settingKey, setting]) => ({
                key: settingKey,
                value: setting
            }))
        }));
    }

    GamesViewHeader {
        id: header
        text: 'Settings'
        titleOnly: true
    }

    property real rowHeight: vpx(50)

    ListView {
        id: categoriesListView

        focus: true
        anchors {
            top: header.bottom; bottom: parent.bottom; left: header.left;
            topMargin: vpx(20); leftMargin: vpx(api.memory.get('settings.theme.leftMargin'))
        }

        width: parent.width / 5.0
        keyNavigationWraps: true

        model: categories
        delegate: Item {
            width: ListView.view.width; height: rowHeight

            property bool selected: ListView.isCurrentItem

            Text {
                text: capitalize(modelData.key)
                color: api.memory.get('settings.theme.textColor')
                font.family: subtitleFont.name
                font.pixelSize: vpx(22)
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

        Keys.onUpPressed: { sfxNav.play(); decrementCurrentIndex() }
        Keys.onDownPressed: { sfxNav.play(); incrementCurrentIndex() }
    }

    ListView {
        id: settingsListView

        model: currentCategory.value

        anchors {
            top: categoriesListView.top; bottom: parent.bottom; left: categoriesListView.right; right: header.right;
            rightMargin: vpx(api.memory.get('settings.theme.rightMargin'))
        }

        preferredHighlightBegin: 0
        preferredHighlightEnd: settingsListView.height / 2
        highlightRangeMode: ListView.StrictlyEnforceRange 
        highlightMoveDuration: 300
        clip: true

        keyNavigationWraps: true

        delegate: FocusScope {
            readonly property bool selected: ListView.isCurrentItem && settingsListView.focus

            readonly property string settingKey: `settings.${currentCategory.key}.${modelData.key}`
            readonly property string parentSettingKey: modelData.value.parent != null ? `settings.${currentCategory.key}.${modelData.value.parent}` : ''

            readonly property bool isEnabled: (!(settingMetadata && settingMetadata.isEnabled) || settingMetadata.isEnabled())
            readonly property bool isExpanded: !parentSettingKey || api.memory.get(parentSettingKey)

            property var settingMetadata: settingsMetadata[currentCategory.key][modelData.key]
            property var value: api.memory.get(settingKey)

            width: ListView.view.width
            height: isExpanded ? rowHeight : 0

            opacity: isExpanded ? (isEnabled ? 1 : 0.33) : 0

            Behavior on height { NumberAnimation { duration: 300 } }
            Behavior on opacity { NumberAnimation { duration: 300 } }

            Text {
                id: settingsName

                text: settingMetadata.name
                color: api.memory.get('settings.theme.textColor')
                font.family: subtitleFont.name
                font.pixelSize: vpx(20)
                verticalAlignment: Text.AlignVCenter
                opacity: selected ? 1 : 0.2

                height: parent.height
                anchors.left: parent.left
                anchors.leftMargin: vpx(5) + ((settingMetadata.inset || 0) * vpx(25))
            }

            Text {
                id: settingsValue

                readonly property bool isHeader: settingMetadata.type === 'header'

                text: isHeader ? (value ? '\uf078' : '\uf054') : (capitalizeFirstLetter((settingMetadata.type != 'array' ? value : settingMetadata.values[value]).toString()))
                color: api.memory.get('settings.theme.textColor')
                font.family: isHeader ? fontawesome.name : subtitleFont.name
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
                incrementSetting(-1);
            }

            Keys.onRightPressed: {
                event.accepted = true;
                sfxToggle.play();
                incrementSetting(1);
            }

            Keys.onUpPressed: {
                event.accepted = true;
                sfxNav.play();

                do {
                    settingsListView.decrementCurrentIndex();
                } while (!settingsListView.currentItem.isEnabled || !settingsListView.currentItem.isExpanded)
            }

            Keys.onDownPressed: {
                event.accepted = true;
                sfxNav.play();

                do {
                    settingsListView.incrementCurrentIndex();
                } while (!settingsListView.currentItem.isEnabled || !settingsListView.currentItem.isExpanded)
            }

            Keys.onPressed: {
                if (event.isAutoRepeat) {
                    return;
                }

                if (api.keys.isAccept(event)) {
                    event.accepted = true;
                    sfxToggle.play();
                    incrementSetting(1);
                }

                if (api.keys.isCancel(event)) {
                    event.accepted = true;
                    sfxBack.play();
                    categoriesListView.focus = true;
                }
            }

            function incrementSetting(direction = 1) {
                var newValue = value;

                switch (settingMetadata.type) {
                    case 'bool':
                    case 'header':
                        newValue = !value;
                        break;
                    case 'int':
                        newValue = parseInt(value) + (settingMetadata.delta ? parseInt(settingMetadata.delta) : 1 ) * direction;
                        break;
                    case 'real':
                        newValue = parseFloat((parseFloat(value) + parseFloat(settingMetadata.delta) * direction).toFixed(getPrecision(settingMetadata.delta)));
                        break;
                    case 'array':
                        newValue = (parseInt(value) + settingMetadata.values.length + direction) % settingMetadata.values.length
                        break;
                }

                if (settingMetadata.min != null) {
                    newValue = Math.max(newValue, settingMetadata.min);
                }

                if (settingMetadata.max != null) {
                    newValue = Math.min(newValue, settingMetadata.max);
                }

                settingMetadata.onChanged ? settingMetadata.onChanged(newValue) : undefined
                api.memory.set(settingKey, newValue);
            }
        }
    }
}
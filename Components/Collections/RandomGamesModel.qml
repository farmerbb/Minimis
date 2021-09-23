import QtQuick 2.3
import SortFilterProxyModel 0.2

Item {
    readonly property alias games: topGames
    property int maxItems: 16

    SortFilterProxyModel {
        id: proxyModel

        sorters: ExpressionSorter { expression: modelLeft.title && modelRight.title && database.games.get(modelLeft).random < database.games.get(modelRight).random }
        sourceModel: api.allGames

        delayed: true
    }

    SortFilterProxyModel {
        id: topGames

        sourceModel: proxyModel

        filters: IndexFilter { maximumIndex: maxItems - 1 }

        delayed: true
    }
}
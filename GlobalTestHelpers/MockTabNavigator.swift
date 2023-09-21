import BitwardenShared
import UIKit

final class MockTabNavigator: TabNavigator {
    var navigators: [Navigator] = []
    var navigatorForTabValue: Int?
    var navigatorForTabReturns: Navigator?
    var rootViewController: UIViewController?
    var selectedIndex: Int = 0

    func setChildren(_ navigators: [Navigator]) {
        self.navigators = navigators
    }

    func navigator<Tab: TabRepresentable>(for tab: Tab) -> Navigator? {
        navigatorForTabValue = tab.index
        return navigatorForTabReturns
    }

    func setNavigators<Tab: Hashable & TabRepresentable>(_ tabs: [Tab: Navigator]) {
        navigators = tabs
            .sorted { $0.key.index < $1.key.index }
            .map(\.value)
    }
}

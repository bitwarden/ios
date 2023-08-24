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

    func navigator<Tab>(for tab: Tab) -> Navigator? where Tab: RawRepresentable, Tab.RawValue == Int {
        navigatorForTabValue = tab.rawValue
        return navigatorForTabReturns
    }
}

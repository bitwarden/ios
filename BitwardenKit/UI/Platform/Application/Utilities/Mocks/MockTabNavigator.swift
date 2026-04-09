import BitwardenKit
import UIKit

public final class MockTabNavigator: TabNavigator {
    public var navigators: [Navigator] = []
    public var navigatorForTabValue: Int?
    public var navigatorForTabReturns: Navigator?
    public var rootViewController: UIViewController?
    public var selectedIndex: Int = 0

    public init() {}

    public func setChildren(_ navigators: [Navigator]) {
        self.navigators = navigators
    }

    public func navigator<Tab: TabRepresentable>(for tab: Tab) -> Navigator? {
        navigatorForTabValue = tab.index
        return navigatorForTabReturns
    }

    public func present(
        _ viewController: UIViewController,
        animated: Bool,
        overFullscreen: Bool,
        onCompletion: (() -> Void)?,
    ) {}

    public func setNavigators<Tab: Hashable & TabRepresentable>(_ tabs: [Tab: Navigator]) {
        navigators = tabs
            .sorted { $0.key.index < $1.key.index }
            .map(\.value)
    }
}

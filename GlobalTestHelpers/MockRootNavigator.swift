import BitwardenShared
import UIKit

final class MockRootNavigator: RootNavigator {
    var theme: ThemeOption = .default
    var navigatorShown: Navigator?
    var rootViewController: UIViewController?

    func show(child: Navigator) {
        navigatorShown = child
    }

    func updateTheme(to themeOption: ThemeOption) {
        theme = themeOption
    }
}

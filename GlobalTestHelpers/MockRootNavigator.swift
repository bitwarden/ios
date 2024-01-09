import BitwardenShared
import UIKit

final class MockRootNavigator: RootNavigator {
    var appTheme: AppTheme = .default
    var navigatorShown: Navigator?
    var rootViewController: UIViewController?

    func show(child: Navigator) {
        navigatorShown = child
    }
}

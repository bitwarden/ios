import BitwardenShared
import UIKit

final class MockRootNavigator: RootNavigator {
    var navigatorShown: Navigator?
    var rootViewController: UIViewController?

    func show(child: Navigator?) {
        navigatorShown = child
    }
}

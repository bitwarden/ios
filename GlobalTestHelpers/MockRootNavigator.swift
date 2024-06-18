import BitwardenShared
import UIKit

final class MockRootNavigator: RootNavigator {
    var alerts: [Alert] = []
    var appTheme: AppTheme = .default
    var navigatorShown: Navigator?
    var rootViewController: UIViewController?

    func present(_ alert: Alert) {
        alerts.append(alert)
    }

    func present(_ alert: Alert, onDismissed: (() -> Void)?) {
        alerts.append(alert)
    }

    func show(child: Navigator) {
        navigatorShown = child
    }
}

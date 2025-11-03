import BitwardenKit
import UIKit

public final class MockRootNavigator: RootNavigator {
    public var alerts: [Alert] = []
    public var appTheme: AppTheme = .default
    public var navigatorShown: Navigator?
    public var rootViewController: UIViewController?

    public init() {}

    public func present(_ alert: Alert) {
        alerts.append(alert)
    }

    public func present(_ alert: Alert, onDismissed: (() -> Void)?) {
        alerts.append(alert)
    }

    public func present(
        _ viewController: UIViewController,
        animated: Bool,
        overFullscreen: Bool,
        onCompletion: (() -> Void)?,
    ) {}

    public func show(child: Navigator) {
        navigatorShown = child
    }
}

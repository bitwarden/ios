import BitwardenKit
import BitwardenShared
import SwiftUI

final class MockStackNavigator: StackNavigator {
    struct NavigationAction {
        var type: NavigationType
        var view: Any?
        var animated: Bool
        var embedInNavigationController: Bool?
        var hidesBottomBar: Bool?
        var isModalInPresentation: Bool?
        var overFullscreen: Bool?
    }

    enum NavigationType {
        case dismissed
        case dismissedWithCompletionHandler
        case pushed
        case popped
        case poppedToRoot
        case presented
        case presentedInSheet
        case replaced
    }

    var actions: [NavigationAction] = []
    var alertOnDismissed: (() -> Void)?
    var alerts: [BitwardenKit.Alert] = []
    var isEmpty = true
    var isNavigationBarHidden = false
    var isPresenting = false
    var rootViewController: UIViewController?

    var viewControllersToPop: [UIViewController] = []

    func dismiss(animated: Bool) {
        actions.append(NavigationAction(type: .dismissed, animated: animated))
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        completion?()
        actions.append(NavigationAction(type: .dismissedWithCompletionHandler, animated: animated))
    }

    func push<Content: View>(_ view: Content, animated: Bool, hidesBottomBar: Bool) {
        actions.append(NavigationAction(
            type: .pushed,
            view: view,
            animated: animated,
            hidesBottomBar: hidesBottomBar,
        ))
    }

    func push(_ viewController: UIViewController, animated: Bool) {
        actions.append(NavigationAction(
            type: .pushed,
            view: viewController,
            animated: animated,
        ))
    }

    @discardableResult
    func pop(animated: Bool) -> UIViewController? {
        actions.append(NavigationAction(type: .popped, animated: animated))
        return viewControllersToPop.last
    }

    @discardableResult
    func popToRoot(animated: Bool) -> [UIViewController] {
        actions.append(NavigationAction(type: .poppedToRoot, animated: animated))
        return viewControllersToPop
    }

    func present(_ alert: BitwardenKit.Alert) {
        alerts.append(alert)
    }

    func present(_ alert: BitwardenKit.Alert, onDismissed: (() -> Void)?) {
        alerts.append(alert)
        alertOnDismissed = onDismissed
    }

    func present<Content: View>( // swiftlint:disable:this function_parameter_count
        _ view: Content,
        animated: Bool,
        embedInNavigationController: Bool,
        isModalInPresentation: Bool,
        overFullscreen: Bool,
        onCompletion: (() -> Void)?,
    ) {
        onCompletion?()
        actions.append(
            NavigationAction(
                type: .presented,
                view: view,
                animated: animated,
                embedInNavigationController: embedInNavigationController,
                isModalInPresentation: isModalInPresentation,
                overFullscreen: overFullscreen,
            ),
        )
    }

    func present(
        _ viewController: UIViewController,
        animated: Bool,
        overFullscreen: Bool,
        onCompletion: (() -> Void)?,
    ) {
        onCompletion?()
        actions.append(
            NavigationAction(
                type: .presented,
                view: viewController,
                animated: animated,
                overFullscreen: overFullscreen,
            ),
        )
    }

    func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        isNavigationBarHidden = hidden
    }

    func replace<Content: View>(_ view: Content, animated: Bool) {
        actions.append(NavigationAction(type: .replaced, view: view, animated: animated))
    }
}

import BitwardenShared
import SwiftUI

final class MockStackNavigator: StackNavigator {
    struct NavigationAction {
        var type: NavigationType
        var view: Any?
        var animated: Bool
        var hidesBottomBar: Bool?
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
    var alerts: [BitwardenShared.Alert] = []
    var isPresenting: Bool { actions.last?.type == .presented }
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
            hidesBottomBar: hidesBottomBar
        ))
    }

    func push(_ viewController: UIViewController, animated: Bool) {
        actions.append(NavigationAction(
            type: .pushed,
            view: viewController,
            animated: animated
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

    func present(_ alert: BitwardenShared.Alert) {
        alerts.append(alert)
    }

    func present<Content: View>(_ view: Content, animated: Bool, overFullscreen: Bool) {
        actions.append(NavigationAction(type: .presented,
                                        view: view,
                                        animated: animated,
                                        overFullscreen: overFullscreen))
    }

    func present(_ viewController: UIViewController, animated: Bool) {
        actions.append(NavigationAction(type: .presented, view: viewController, animated: animated))
    }

    func replace<Content: View>(_ view: Content, animated: Bool) {
        actions.append(NavigationAction(type: .replaced, view: view, animated: animated))
    }
}

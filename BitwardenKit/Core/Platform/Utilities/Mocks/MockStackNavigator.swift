import BitwardenKit
import SwiftUI

public final class MockStackNavigator: StackNavigator {
    public struct NavigationAction {
        public var type: NavigationType
        public var view: Any?
        public var animated: Bool
        public var embedInNavigationController: Bool?
        public var hidesBottomBar: Bool?
        public var isModalInPresentation: Bool?
        public var overFullscreen: Bool?
    }

    public enum NavigationType {
        case dismissed
        case dismissedWithCompletionHandler
        case pushed
        case popped
        case poppedToRoot
        case presented
        case presentedInSheet
        case replaced
    }

    public var actions: [NavigationAction] = []
    public var alertOnDismissed: (() -> Void)?
    public var alerts: [BitwardenKit.Alert] = []
    public var isEmpty = true
    public var isNavigationBarHidden = false
    public var isPresenting = false
    public var rootViewController: UIViewController?

    public var viewControllersToPop: [UIViewController] = []

    public init() {}

    public func dismiss(animated: Bool) {
        actions.append(NavigationAction(type: .dismissed, animated: animated))
    }

    public func dismiss(animated: Bool, completion: (() -> Void)?) {
        completion?()
        actions.append(NavigationAction(type: .dismissedWithCompletionHandler, animated: animated))
    }

    public func push<Content: View>(_ view: Content, animated: Bool, hidesBottomBar: Bool) {
        actions.append(NavigationAction(
            type: .pushed,
            view: view,
            animated: animated,
            hidesBottomBar: hidesBottomBar,
        ))
    }

    public func push(_ viewController: UIViewController, animated: Bool) {
        actions.append(NavigationAction(
            type: .pushed,
            view: viewController,
            animated: animated,
        ))
    }

    @discardableResult
    public func pop(animated: Bool) -> UIViewController? {
        actions.append(NavigationAction(type: .popped, animated: animated))
        return viewControllersToPop.last
    }

    @discardableResult
    public func popToRoot(animated: Bool) -> [UIViewController] {
        actions.append(NavigationAction(type: .poppedToRoot, animated: animated))
        return viewControllersToPop
    }

    public func present(_ alert: BitwardenKit.Alert) {
        alerts.append(alert)
    }

    public func present(_ alert: BitwardenKit.Alert, onDismissed: (() -> Void)?) {
        alerts.append(alert)
        alertOnDismissed = onDismissed
    }

    public func present<Content: View>( // swiftlint:disable:this function_parameter_count
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

    public func present(
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

    public func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        isNavigationBarHidden = hidden
    }

    public func replace<Content: View>(_ view: Content, animated: Bool) {
        actions.append(NavigationAction(type: .replaced, view: view, animated: animated))
    }
}

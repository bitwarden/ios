import SwiftUI

// MARK: - StackNavigator

/// An object used to navigate between views in a stack interface.
///
@MainActor
public protocol StackNavigator: Navigator {
    /// Dismisses the view that was presented modally by the navigator.
    ///
    /// - Parameter animated: Whether the transition should be animated.
    ///
    func dismiss(animated: Bool)

    /// Pushes a view onto the navigator's stack.
    ///
    /// - Parameters:
    ///   - view: The view to push onto the stack.
    ///   - animated: Whether the transition should be animated.
    ///   - hidesBottomBar: Whether the bottom bar should be hidden when the view is pushed.
    ///
    func push<Content: View>(_ view: Content, animated: Bool, hidesBottomBar: Bool)

    /// Pushes a view controller onto the navigator's stack.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to push onto the stack.
    ///   - animated: Whether the transition should be animated.
    ///
    func push(_ viewController: UIViewController, animated: Bool)

    /// Pops a view off the navigator's stack.
    ///
    /// - Parameter animated: Whether the transition should be animated.
    /// - Returns: The `UIViewController` that was popped off the navigator's stack.
    ///
    @discardableResult
    func pop(animated: Bool) -> UIViewController?

    /// Pops all the view controllers on the stack except the root view controller.
    ///
    /// - Parameter animated: Whether the transition should be animated.
    /// - Returns: An array of `UIViewController`s that were popped of the navigator's stack.
    ///
    @discardableResult
    func popToRoot(animated: Bool) -> [UIViewController]

    /// Presents a view modally.
    ///
    /// - Parameters:
    ///   - view: The view to present.
    ///   - animated: Whether the transition should be animated.
    ///   - overFullscreen: Whether or not the presented modal should cover the full screen.
    ///
    func present<Content: View>(_ view: Content, animated: Bool, overFullscreen: Bool)

    /// Presents a view controller modally. Supports presenting on top of presented modals if necessary.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to present.
    ///   - animated: Whether the transition should be animated.
    ///
    func present(_ viewController: UIViewController, animated: Bool)

    /// Replaces the stack with the specified view.
    ///
    /// - Parameters:
    ///   - view: The view that will replace the stack.
    ///   - animated: Whether the transition should be animated.
    ///
    func replace<Content: View>(_ view: Content, animated: Bool)
}

extension StackNavigator {
    /// Dismisses the view that was presented modally by the navigator. Animation is controlled by `UI.animated`.
    ///
    func dismiss() {
        dismiss(animated: UI.animated)
    }

    /// Pushes a view onto the navigator's stack.
    ///
    /// - Parameters:
    ///   - view: The view to push onto the stack.
    ///   - animated: Whether the transition should be animated. Defaults to `UI.animated`.
    ///
    func push<Content: View>(_ view: Content, animated: Bool = UI.animated) {
        push(view, animated: animated, hidesBottomBar: false)
    }

    /// Pushes a view controller onto the navigator's stack.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to push onto the stack.
    ///   - animated: Whether the transition should be animated. Defaults to `UI.animated`.
    ///
    func push(_ viewController: UIViewController, animated: Bool = UI.animated) {
        push(viewController, animated: animated)
    }

    /// Pops a view off the navigator's stack. Animation is controlled by `UI.animated`.
    ///
    /// - Returns: The `UIViewController` that was popped off the navigator's stack.
    ///
    @discardableResult
    func pop() -> UIViewController? {
        pop(animated: UI.animated)
    }

    /// Pops all the view controllers on the stack except the root view controller. Animation is controlled by
    /// `UI.animated`.
    ///
    /// - Returns: An array of `UIViewController`s that were popped of the navigator's stack.
    ///
    @discardableResult
    func popToRoot() -> [UIViewController] {
        popToRoot(animated: UI.animated)
    }

    /// Presents a view modally.
    ///
    /// - Parameters:
    ///   - view: The view to present.
    ///   - animated: Whether the transition should be animated. Defaults to `UI.animated`.
    ///
    func present<Content: View>(_ view: Content, animated: Bool = UI.animated) {
        present(view, animated: animated, overFullscreen: false)
    }

    /// Presents a view controller modally. Supports presenting on top of presented modals if necessary. Animation is
    /// controlled by `UI.animated`.
    ///
    /// - Parameter viewController: The view controller to present.
    ///
    func present(_ viewController: UIViewController) {
        present(viewController, animated: UI.animated)
    }

    /// Replaces the stack with the specified view. Animation is controlled by `UI.animated`.
    ///
    /// - Parameter view: The view that will replace the stack.
    ///
    func replace<Content: View>(_ view: Content) {
        replace(view, animated: UI.animated)
    }
}

// MARK: - UINavigationController

extension UINavigationController: StackNavigator {
    public var rootViewController: UIViewController? {
        self
    }

    public func dismiss(animated: Bool) {
        dismiss(animated: animated, completion: nil)
    }

    @discardableResult
    public func pop(animated: Bool) -> UIViewController? {
        popViewController(animated: animated)
    }

    @discardableResult
    public func popToRoot(animated: Bool) -> [UIViewController] {
        popToRootViewController(animated: animated) ?? []
    }

    public func push<Content: View>(_ view: Content, animated: Bool, hidesBottomBar: Bool) {
        let viewController = UIHostingController(rootView: view)
        viewController.hidesBottomBarWhenPushed = hidesBottomBar
        push(viewController, animated: animated)
    }

    public func push(_ viewController: UIViewController, animated: Bool) {
        pushViewController(viewController, animated: animated)
    }

    public func present<Content: View>(_ view: Content, animated: Bool, overFullscreen: Bool) {
        let controller = UIHostingController(rootView: view)
        controller.isModalInPresentation = true
        if overFullscreen {
            controller.modalPresentationStyle = .overFullScreen
            controller.view.backgroundColor = .clear
        }
        present(controller, animated: animated)
    }

    public func present(_ viewController: UIViewController, animated: Bool) {
        var presentedChild = presentedViewController
        var availablePresenter: UIViewController? = self
        while presentedChild != nil {
            availablePresenter = presentedChild
            presentedChild = presentedChild?.presentedViewController
        }
        availablePresenter?.present(viewController, animated: animated, completion: nil)
    }

    public func replace<Content: View>(_ view: Content, animated: Bool) {
        setViewControllers([UIHostingController(rootView: view)], animated: animated)
    }
}

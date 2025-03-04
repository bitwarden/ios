import SwiftUI

// MARK: - StackNavigator

/// An object used to navigate between views in a stack interface.
///
@MainActor
public protocol StackNavigator: Navigator {
    /// Whether the stack of views in the navigator is empty.
    var isEmpty: Bool { get }

    /// Dismisses the view that was presented modally by the navigator.
    ///
    /// - Parameters animated: Whether the transition should be animated.
    ///
    func dismiss(animated: Bool)

    /// Dismisses the view that was presented modally by the navigator
    /// and executes a block of code when dismissing completes.
    ///
    /// - Parameters:
    ///  - animated: Whether the transition should be animated.
    ///  - completion: The block that is executed when dismissing completes.
    ///
    func dismiss(animated: Bool, completion: (() -> Void)?)

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
    ///   - onCompletion: A closure to call on completion.
    ///
    func present<Content: View>(
        _ view: Content,
        animated: Bool,
        overFullscreen: Bool,
        onCompletion: (() -> Void)?
    )

    /// Presents a view controller modally. Supports presenting on top of presented modals if necessary.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to present.
    ///   - animated: Whether the transition should be animated.
    ///   - overFullscreen: Whether or not the presented modal should cover the full screen.
    ///   - onCompletion: A closure to call on completion.
    ///
    func present(
        _ viewController: UIViewController,
        animated: Bool,
        overFullscreen: Bool,
        onCompletion: (() -> Void)?
    )

    /// Replaces the stack with the specified view.
    ///
    /// - Parameters:
    ///   - view: The view that will replace the stack.
    ///   - animated: Whether the transition should be animated.
    ///
    func replace<Content: View>(_ view: Content, animated: Bool)
}

extension StackNavigator {
    /// Dismisses the view that was presented modally by the navigator. Animation is controlled by
    /// `UI.animated`.
    ///
    func dismiss() {
        dismiss(animated: UI.animated)
    }

    /// Dismisses the view that was presented modally by the navigator. Animation is controlled by
    /// `UI.animated`. Executes a block of code when dismissing completes.
    ///
    func dismiss(completion: (() -> Void)?) {
        dismiss(animated: UI.animated, completion: completion)
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
    ///   - navigationTitle: The navigation title to pre-populate the navigation bar so that it doesn't flash.
    ///   - searchController: If non-nil, pre-populate the navigation bar with a search bar backed by the
    ///         supplied UISearchController.
    ///     Normal SwiftUI search contorls will not work if this value is supplied. Tracking the searchController
    ///     behavior must be done through a UISearchControllerDelegate or a UISearchResultsUpdating object.
    ///
    func push(
        _ viewController: UIViewController,
        animated: Bool = UI.animated,
        navigationTitle: String? = nil,
        searchController: UISearchController? = nil
    ) {
        if let navigationTitle {
            // Preset some navigation item values so that the navigation bar does not flash oddly once
            // the view's push animation has completed. This happens because `UIHostingController` does
            // not resolve its `navigationItem` properties until the view has been displayed on screen.
            // In this case, that doesn't happen until the push animation has completed, which results
            // in both the title and the search bar flashing into view after the push animation
            // completes. This occurs on all iOS versions (tested on iOS 17).
            //
            // The values set here are temporary, and are overwritten once the hosting controller has
            // resolved its root view's navigation bar modifiers.
            viewController.navigationItem.largeTitleDisplayMode = .never
            viewController.navigationItem.title = navigationTitle
            if let searchController {
                if #available(iOS 16.0, *) {
                    viewController.navigationItem.preferredSearchBarPlacement = .stacked
                }
                viewController.navigationItem.searchController = searchController
                viewController.navigationItem.hidesSearchBarWhenScrolling = false
            }
        }

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
    ///   - overFullscreen: Whether or not the presented modal should cover the full screen.
    ///   - onCompletion: The closure to call after presenting.
    ///
    func present<Content: View>(
        _ view: Content,
        animated: Bool = UI.animated,
        overFullscreen: Bool = false,
        onCompletion _: (() -> Void)? = nil
    ) {
        present(
            view,
            animated: animated,
            overFullscreen: overFullscreen,
            onCompletion: nil
        )
    }

    /// Presents a view controller modally. Supports presenting on top of presented modals if necessary. Animation is
    /// controlled by `UI.animated`.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to present.
    ///   - overFullscreen: Whether or not the presented modal should cover the full screen.
    ///   - onCompletion: The closure to call after presenting.
    ///
    func present(
        _ viewController: UIViewController,
        overFullscreen: Bool = false,
        onCompletion: (() -> Void)? = nil
    ) {
        present(
            viewController,
            animated: UI.animated,
            overFullscreen: overFullscreen,
            onCompletion: onCompletion
        )
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
    public var isEmpty: Bool {
        viewControllers.isEmpty
    }

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
        let animated = self.view.window != nil ? animated : false
        push(viewController, animated: animated)
    }

    public func push(_ viewController: UIViewController, animated: Bool) {
        let animated = view.window != nil ? animated : false
        pushViewController(viewController, animated: animated)
    }

    public func present<Content: View>(
        _ view: Content,
        animated: Bool,
        overFullscreen: Bool,
        onCompletion: (() -> Void)? = nil
    ) {
        let controller = UIHostingController(rootView: view)
        controller.isModalInPresentation = true
        if overFullscreen {
            controller.modalPresentationStyle = .overFullScreen
            controller.view.backgroundColor = .clear
        }
        let animated = self.view.window != nil ? animated : false
        present(controller, animated: animated, onCompletion: onCompletion)
    }

    public func present(
        _ viewController: UIViewController,
        animated: Bool,
        overFullscreen: Bool = false,
        onCompletion: (() -> Void)? = nil
    ) {
        var presentedChild = presentedViewController
        var availablePresenter: UIViewController? = self
        while presentedChild != nil {
            availablePresenter = presentedChild
            presentedChild = presentedChild?.presentedViewController
        }
        if overFullscreen {
            viewController.modalPresentationStyle = .overFullScreen
        }
        availablePresenter?.present(
            viewController,
            animated: animated,
            completion: onCompletion
        )
    }

    public func replace<Content: View>(_ view: Content, animated: Bool) {
        let animated = self.view.window != nil ? animated : false
        setViewControllers([UIHostingController(rootView: view)], animated: animated)
    }
}

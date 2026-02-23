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
    ///   - embedInNavigationController: Whether the presented view should be embedded in a
    ///     navigation controller.
    ///   - isModalInPresentation: Whether the presented view controller enforces a modal behavior.
    ///     This prevents interactive dismissal.
    ///   - overFullscreen: Whether or not the presented modal should cover the full screen.
    ///   - onCompletion: A closure to call on completion.
    ///
    func present<Content: View>( // swiftlint:disable:this function_parameter_count
        _ view: Content,
        animated: Bool,
        embedInNavigationController: Bool,
        isModalInPresentation: Bool,
        overFullscreen: Bool,
        onCompletion: (() -> Void)?,
    )

    /// Replaces the stack with the specified view.
    ///
    /// - Parameters:
    ///   - view: The view that will replace the stack.
    ///   - animated: Whether the transition should be animated.
    ///
    func replace<Content: View>(_ view: Content, animated: Bool)

    /// Sets whether the navigation bar should be hidden.
    ///
    /// - Parameters:
    ///   - hidden: Whether the navigation bar should be hidden.
    ///   - animated: Whether hiding or showing the navigation bar should be animated.
    ///
    func setNavigationBarHidden(_: Bool, animated: Bool)
}

public extension StackNavigator {
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
    ///     Normal SwiftUI search controls will not work if this value is supplied. Tracking the searchController
    ///     behavior must be done through a UISearchControllerDelegate or a UISearchResultsUpdating object.
    ///
    func push(
        _ viewController: UIViewController,
        animated: Bool = UI.animated,
        navigationTitle: String? = nil,
        searchController: UISearchController? = nil,
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
    ///   - embedInNavigationController: Whether the presented view should be embedded in a
    ///     navigation controller.
    ///   - isModalInPresentation: Whether the presented view controller enforces a modal behavior.
    ///     This prevents interactive dismissal.
    ///   - overFullscreen: Whether or not the presented modal should cover the full screen.
    ///   - onCompletion: The closure to call after presenting.
    ///
    func present<Content: View>(
        _ view: Content,
        animated: Bool = UI.animated,
        embedInNavigationController: Bool = true,
        isModalInPresentation: Bool = false,
        overFullscreen: Bool = false,
        onCompletion _: (() -> Void)? = nil,
    ) {
        present(
            view,
            animated: animated,
            embedInNavigationController: embedInNavigationController,
            isModalInPresentation: isModalInPresentation,
            overFullscreen: overFullscreen,
            onCompletion: nil,
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
    /// Returns whether the navigation controller's stack is empty.
    ///
    /// - Returns: `true` if there are no view controllers in the stack, `false` otherwise.
    public var isEmpty: Bool {
        viewControllers.isEmpty
    }

    /// Returns the root view controller of the navigation stack.
    ///
    /// For UINavigationController, this returns the navigation controller itself
    /// as it serves as the root container for the navigation stack.
    ///
    /// - Returns: The navigation controller instance.
    public var rootViewController: UIViewController? {
        self
    }

    /// Dismisses the modally presented view controller without a completion handler.
    ///
    /// This is a convenience method that calls the system's dismiss method
    /// with a nil completion handler.
    ///
    /// - Parameters:
    ///   - animated: Whether the dismissal should be animated.
    public func dismiss(animated: Bool) {
        dismiss(animated: animated, completion: nil)
    }

    /// Pops the top view controller from the navigation stack.
    ///
    /// Removes and returns the top view controller from the navigation stack.
    /// If the stack only contains the root view controller, this method does nothing
    /// and returns nil.
    ///
    /// - Parameters:
    ///   - animated: Whether the pop transition should be animated.
    /// - Returns: The view controller that was popped, or nil if no controller was popped.
    @discardableResult
    public func pop(animated: Bool) -> UIViewController? {
        popViewController(animated: animated)
    }

    /// Pops all view controllers except the root view controller.
    ///
    /// Removes all view controllers from the stack except the root view controller
    /// and returns an array of the popped controllers.
    ///
    /// - Parameters:
    ///   - animated: Whether the pop transition should be animated.
    /// - Returns: An array of view controllers that were popped from the stack.
    ///           Returns an empty array if no controllers were popped.
    @discardableResult
    public func popToRoot(animated: Bool) -> [UIViewController] {
        popToRootViewController(animated: animated) ?? []
    }

    /// Pushes a SwiftUI view onto the navigation stack.
    ///
    /// Wraps the provided SwiftUI view in a UIHostingController and pushes it
    /// onto the navigation stack. Automatically disables animation if the
    /// navigation controller is not currently in a window to prevent animation
    /// issues during initial setup.
    ///
    /// - Parameters:
    ///   - view: The SwiftUI view to push onto the stack.
    ///   - animated: Whether the push transition should be animated.
    ///   - hidesBottomBar: Whether the bottom bar (tab bar) should be hidden
    ///                     when this view controller is displayed.
    public func push<Content: View>(_ view: Content, animated: Bool, hidesBottomBar: Bool) {
        let viewController = UIHostingController(rootView: view)
        viewController.hidesBottomBarWhenPushed = hidesBottomBar
        let animated = self.view.window != nil ? animated : false
        push(viewController, animated: animated)
    }

    /// Pushes a view controller onto the navigation stack.
    ///
    /// Adds the specified view controller to the top of the navigation stack.
    /// Automatically disables animation if the navigation controller is not
    /// currently in a window to prevent animation issues during initial setup.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to push onto the stack.
    ///   - animated: Whether the push transition should be animated.
    public func push(_ viewController: UIViewController, animated: Bool) {
        let animated = view.window != nil ? animated : false
        pushViewController(viewController, animated: animated)
    }

    /// Presents a SwiftUI view modally.
    ///
    /// Wraps the provided SwiftUI view in a UIHostingController and presents it modally.
    /// Optionally embeds the view in a new navigation controller and configures
    /// various presentation options. Automatically disables animation if the
    /// navigation controller is not currently in a window to prevent animation issues
    /// during initial setup.
    ///
    /// - Parameters:
    ///   - view: The SwiftUI view to present modally.
    ///   - animated: Whether the presentation should be animated.
    ///   - embedInNavigationController: Whether to wrap the view in a new
    ///                                  navigation controller.
    ///   - isModalInPresentation: Whether the modal enforces modal behavior,
    ///                            preventing interactive dismissal.
    ///   - overFullscreen: Whether the modal should use full-screen presentation
    ///                     with a clear background.
    ///   - onCompletion: Optional closure called after presentation completes.
    public func present<Content: View>(
        _ view: Content,
        animated: Bool,
        embedInNavigationController: Bool,
        isModalInPresentation: Bool,
        overFullscreen: Bool,
        onCompletion: (() -> Void)? = nil,
    ) {
        let controller: UIViewController
        if embedInNavigationController {
            let navigationController = UINavigationController(rootViewController: UIHostingController(rootView: view))
            // Pass along the existing delegates to propagate view logging to new navigation controllers.
            navigationController.delegate = delegate
            navigationController.presentationController?.delegate = presentationController?.delegate
            controller = navigationController
        } else {
            controller = UIHostingController(rootView: view)
        }
        controller.isModalInPresentation = isModalInPresentation
        if overFullscreen {
            controller.modalPresentationStyle = .overFullScreen
            controller.view.backgroundColor = .clear
        }
        let animated = self.view.window != nil ? animated : false
        present(controller, animated: animated, onCompletion: onCompletion)
    }

    /// Replaces the entire navigation stack with a single SwiftUI view.
    ///
    /// Removes all existing view controllers from the navigation stack and
    /// replaces them with a single new view controller containing the specified
    /// SwiftUI view. Automatically disables animation if the navigation controller
    /// is not currently in a window to prevent animation issues during initial setup.
    ///
    /// - Parameters:
    ///   - view: The SwiftUI view that will become the new root of the stack.
    ///   - animated: Whether the replacement should be animated.
    public func replace<Content: View>(_ view: Content, animated: Bool) {
        let animated = self.view.window != nil ? animated : false
        setViewControllers([UIHostingController(rootView: view)], animated: animated)
    }
}

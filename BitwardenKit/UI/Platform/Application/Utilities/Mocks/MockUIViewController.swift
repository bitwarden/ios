import BitwardenKit
import UIKit
import XCTest

// MARK: - MockUIViewController

/// A mock UIViewController that can be used in tests that normally rely on the existence of a host app
/// because of details about how UIViewControllers present/dismiss other UIViewControllers.
public class MockUIViewController: UIViewController {
    // MARK: Static properties

    /// A size for the `mockWindow` and `mockView` objects to have.
    /// This happens to be the size of the iPhone 5, 5C, 5S, and SE.
    private static var mockWindowSize = CGRect(x: 0, y: 0, width: 320, height: 568)

    // MARK: Presentation Tracking

    /// Indicates whether the `present` method has been called.
    public var presentCalled = false

    /// The view controller that was presented, if any.
    public var presentedView: UIViewController?

    /// Indicates whether the presentation was animated.
    public var presentAnimated = false

    /// The completion handler passed to the `present` method.
    public var presentCompletion: (() -> Void)?

    /// Returns the currently presented view controller.
    override public var presentedViewController: UIViewController? {
        presentedView
    }

    // MARK: Dismissal Tracking

    /// Indicates whether the `dismiss` method has been called.
    public var dismissCalled = false

    /// Indicates whether the dismissal was animated.
    public var dismissAnimated = false

    /// The completion handler passed to the `dismiss` method.
    public var dismissCompletion: (() -> Void)?

    // MARK: Navigation Controller Support

    /// Internal storage for a navigation controller.
    private var _navigationController: UINavigationController?

    /// Returns the internally stored navigation controller, bypassing the superclass one.
    override public var navigationController: UINavigationController? {
        get { _navigationController }
        set { _navigationController = newValue }
    }

    // MARK: Mock Window and View Hierarchy

    /// The mock window used for testing view hierarchy.
    private var mockWindow: UIWindow?

    /// The mock view used as the main view.
    private var mockView: UIView?

    /// Returns the mock view or the default view if no mock view is set.
    override public var view: UIView! {
        get {
            mockView ?? super.view
        }
        set {
            mockView = newValue
            super.view = newValue
        }
    }

    /// Returns whether the mock view or default view is loaded.
    override public var isViewLoaded: Bool {
        mockView != nil || super.isViewLoaded
    }

    // MARK: Initialization

    /// Initializes the mock view controller with the specified nib name and bundle.
    ///
    /// - Parameters:
    ///   - nibNameOrNil: The name of the nib file to load, or nil if no nib should be loaded.
    ///   - nibBundleOrNil: The bundle containing the nib file, or nil for the main bundle.
    override init(
        nibName nibNameOrNil: String?,
        bundle nibBundleOrNil: Bundle?,
    ) {
        super.init(
            nibName: nibNameOrNil,
            bundle: nibBundleOrNil,
        )
        setUpMockHierarchy()
    }

    /// Initializes the mock navigation controller with a nil nib name and bundle.
    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    /// Initializes the mock view controller from a coder.
    ///
    /// - Parameters:
    ///   - coder: The coder to initialize from.
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpMockHierarchy()
    }

    // MARK: View Life Cycle Methods

    /// Called after the view controller's view is loaded into memory.
    /// Ensures that a mock view exists even if `loadView` wasn't called.
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Ensure we have a view even if loadView wasn't called
        if view == nil {
            view = UIView(frame: MockUIViewController.mockWindowSize)
        }
    }

    /// Creates the view controller's view programmatically.
    /// Sets up a mock view with the predefined mock window size.
    override public func loadView() {
        if mockView == nil {
            mockView = UIView(frame: MockUIViewController.mockWindowSize)
        }
        view = mockView
    }

    // MARK: UIViewController Overrides

    /// Presents a view controller modally and tracks the presentation details for testing.
    ///
    /// - Parameters:
    ///   - viewControllerToPresent: The view controller to present.
    ///   - animated: Whether to animate the presentation.
    ///   - completion: A completion handler to call after the presentation finishes.
    override public func present(
        _ viewControllerToPresent: UIViewController,
        animated: Bool,
        completion: (() -> Void)? = nil,
    ) {
        presentCalled = true
        presentedView = viewControllerToPresent
        presentAnimated = animated
        presentCompletion = completion

        // Set up the presented view controller's hierarchy
        viewControllerToPresent.beginAppearanceTransition(true, animated: animated)
        viewControllerToPresent.endAppearanceTransition()

        // Call completion if provided
        completion?()
    }

    /// Dismisses the currently presented view controller and tracks the dismissal details for testing.
    ///
    /// - Parameters:
    ///   - animated: Whether to animate the dismissal.
    ///   - completion: A completion handler to call after the dismissal finishes.
    override public func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        dismissCalled = true
        dismissAnimated = animated
        dismissCompletion = completion

        if let presentedView {
            presentedView.beginAppearanceTransition(false, animated: animated)
            presentedView.endAppearanceTransition()
        }

        // Clear the presented view controller
        presentedView = nil

        completion?()
    }

    // MARK: Helper Methods

    /// Resets and clears all local variables, to prepare the mock for reuse.
    public func reset() {
        presentCalled = false
        presentedView = nil
        presentAnimated = false
        presentCompletion = nil

        dismissCalled = false
        dismissAnimated = false
        dismissCompletion = nil

        _navigationController = nil
    }

    // MARK: Mock Hierarchy

    /// Sets up a `UIWindow` and `UIView` to use as mocks in the view hierarchy.
    private func setUpMockHierarchy() {
        // Create a mock window to avoid issues with view hierarchy
        mockWindow = UIWindow(frame: MockUIViewController.mockWindowSize)
        mockWindow?.rootViewController = self

        // Create a mock view
        mockView = UIView(frame: mockWindow?.frame ?? .zero)
        view = mockView
    }
}

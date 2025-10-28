import BitwardenKit
import UIKit
import XCTest

// MARK: - MockUIViewController

/// A mock UIViewController that can be used in tests that normally rely on the existence of a host app
/// because of details about how UIViewControllers present/dismiss other UIViewControllers.
public class MockUIViewController: UIViewController {
    // MARK: Presentation Tracking

    public var presentCalled = false
    public var presentedView: UIViewController?
    public var presentAnimated = false
    public var presentCompletion: (() -> Void)?

    // MARK: Dismissal Tracking

    public var dismissCalled = false
    public var dismissAnimated = false
    public var dismissCompletion: (() -> Void)?

    // MARK: Navigation Tracking

    public var pushViewControllerCalled = false
    public var pushedViewController: UIViewController?
    public var popViewControllerCalled = false

    // MARK: Mock Window and View Hierarchy

    private var mockWindow: UIWindow?
    private var mockView: UIView?

    /// A size for the `mockWindow` and `mockView` objects to have.
    /// This happens to be the size of the iPhone 5, 5C, 5S, and SE.
    private static var mockWindowSize = CGRect(x: 0, y: 0, width: 320, height: 568)

    // MARK: Initialization

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setUpMockHierarchy()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpMockHierarchy()
    }

    private func setUpMockHierarchy() {
        // Create a mock window to avoid issues with view hierarchy
        mockWindow = UIWindow(frame: MockUIViewController.mockWindowSize)
        mockWindow?.rootViewController = self

        // Create a mock view
        mockView = UIView(frame: mockWindow?.frame ?? .zero)
        view = mockView
    }

    // MARK: UIViewController Overrides

    public override func present(
        _ viewControllerToPresent: UIViewController,
        animated: Bool,
        completion: (() -> Void)? = nil
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

    // Override presentedViewController to return our tracked presented view
    public override var presentedViewController: UIViewController? {
        return presentedView
    }

    public override func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        dismissCalled = true
        dismissAnimated = animated
        dismissCompletion = completion

        if let presentedView = presentedView {
            presentedView.beginAppearanceTransition(false, animated: animated)
            presentedView.endAppearanceTransition()
        }

        // Clear the presented view controller
        presentedView = nil

        completion?()
    }

    public override var view: UIView! {
        get {
            return mockView ?? super.view
        }
        set {
            mockView = newValue
            super.view = newValue
        }
    }

    public override var isViewLoaded: Bool {
        return mockView != nil || super.isViewLoaded
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        // Ensure we have a view even if loadView wasn't called
        if view == nil {
            view = UIView(frame: MockUIViewController.mockWindowSize)
        }
    }

    public override func loadView() {
        if mockView == nil {
            mockView = UIView(frame: MockUIViewController.mockWindowSize)
        }
        view = mockView
    }

    // MARK: Navigation Controller Support

    private var _navigationController: UINavigationController?

    public override var navigationController: UINavigationController? {
        get { _navigationController }
        set { _navigationController = newValue }
    }

    // MARK: Helper Methods

    public func reset() {
        presentCalled = false
        presentedView = nil
        presentAnimated = false
        presentCompletion = nil

        dismissCalled = false
        dismissAnimated = false
        dismissCompletion = nil

        pushViewControllerCalled = false
        pushedViewController = nil
        popViewControllerCalled = false
    }

    // Simulate view appearance lifecycle
    public func simulateViewWillAppear(animated: Bool = false) {
        viewWillAppear(animated)
    }

    public func simulateViewDidAppear(animated: Bool = false) {
        viewDidAppear(animated)
    }

    public func simulateViewWillDisappear(animated: Bool = false) {
        viewWillDisappear(animated)
    }

    public func simulateViewDidDisappear(animated: Bool = false) {
        viewDidDisappear(animated)
    }
}

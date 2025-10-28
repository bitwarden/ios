import BitwardenKit
import UIKit
import XCTest

// MARK: - MockUIViewController

public class MockUIViewController: UIViewController {
    // MARK: - Presentation Tracking
    
    public var presentCalled = false
    public var presentedView: UIViewController?
    public var presentAnimated = false
    public var presentCompletion: (() -> Void)?
    
    // MARK: - Dismissal Tracking
    
    public var dismissCalled = false
    public var dismissAnimated = false
    public var dismissCompletion: (() -> Void)?
    
    // MARK: - Navigation Tracking
    
    public var pushViewControllerCalled = false
    public var pushedViewController: UIViewController?
    public var popViewControllerCalled = false
    
    // MARK: - Mock Window and View Hierarchy
    
    private var mockWindow: UIWindow?
    private var mockView: UIView?
    
    // MARK: - Initialization
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupMockHierarchy()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMockHierarchy()
    }
    
    private func setupMockHierarchy() {
        // Create a mock window to avoid issues with view hierarchy
        mockWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        mockWindow?.rootViewController = self
        
        // Create a mock view
        mockView = UIView(frame: mockWindow?.frame ?? .zero)
        view = mockView
    }
    
    // MARK: - UIViewController Overrides
    
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
    
    public override func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        dismissCalled = true
        dismissAnimated = animated
        dismissCompletion = completion
        
        if let presentedView = presentedView {
            presentedView.beginAppearanceTransition(false, animated: animated)
            presentedView.endAppearanceTransition()
        }
        
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
            view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        }
    }
    
    public override func loadView() {
        if mockView == nil {
            mockView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        }
        view = mockView
    }
    
    // MARK: - Navigation Controller Support
    
    private var _navigationController: UINavigationController?
    
    public override var navigationController: UINavigationController? {
        get { _navigationController }
        set { _navigationController = newValue }
    }
    
    // Helper method to set up navigation controller for testing
    public func setMockNavigationController(_ navigationController: MockNavigationController? = nil) {
        let navController = navigationController ?? MockNavigationController()
        _navigationController = navController
        
        // Only add as child if not already in hierarchy
        if !navController.viewControllers.contains(self) {
            navController.viewControllers = [self]
        }
    }
    
    // MARK: - Helper Methods
    
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
        
        // Reset navigation controller if it exists
        if let navController = _navigationController as? MockNavigationController {
            navController.reset()
        }
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

// MARK: - MockNavigationController

public class MockNavigationController: UINavigationController {
    var pushViewControllerCalled = false
    var pushedViewController: UIViewController?
    var pushAnimated = false
    
    var popViewControllerCalled = false
    var popAnimated = false
    var poppedViewController: UIViewController?
    
    // MARK: - Initialization
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public override init(rootViewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        // Set viewControllers array directly to avoid hierarchy issues
        viewControllers = [rootViewController]
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Overrides
    
    public override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        pushViewControllerCalled = true
        pushedViewController = viewController
        pushAnimated = animated
        
        // Add to view controllers array
        var controllers = viewControllers
        controllers.append(viewController)
        viewControllers = controllers
        
        // Simulate appearance transitions safely
        DispatchQueue.main.async {
            viewController.beginAppearanceTransition(true, animated: animated)
            viewController.endAppearanceTransition()
        }
    }
    
    @discardableResult
    public override func popViewController(animated: Bool) -> UIViewController? {
        popViewControllerCalled = true
        popAnimated = animated
        
        guard viewControllers.count > 1 else { return nil }
        
        var controllers = viewControllers
        let poppedVC = controllers.removeLast()
        poppedViewController = poppedVC
        viewControllers = controllers
        
        // Simulate appearance transitions safely
        DispatchQueue.main.async {
            poppedVC.beginAppearanceTransition(false, animated: animated)
            poppedVC.endAppearanceTransition()
        }
        
        return poppedVC
    }
    
    public func reset() {
        pushViewControllerCalled = false
        pushedViewController = nil
        pushAnimated = false
        
        popViewControllerCalled = false
        popAnimated = false
        poppedViewController = nil
    }
}

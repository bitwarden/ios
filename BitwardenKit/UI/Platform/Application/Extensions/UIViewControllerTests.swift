import BitwardenKitMocks
import XCTest

@testable import BitwardenKit

class UIViewControllerTests: BitwardenTestCase {
    // MARK: safePresent

    /// `safePresent` presents the view controller immediately when nothing is currently presented.
    func test_safePresent_presentsWhenNoPresentedViewController() {
        let subject = MockUIViewController()
        let viewController = UIViewController()
        var completionCalled = false

        subject.safePresent(viewController, animated: false, completion: { completionCalled = true })

        XCTAssertEqual(subject.presentedViewControllers.count, 1)
        XCTAssertTrue(subject.presentedViewControllers.first === viewController)
        XCTAssertTrue(completionCalled)
    }

    /// `safePresent` defers presentation while a dismiss is in progress and retries until it succeeds.
    func test_safePresent_retriesAndPresentsAfterDismissCompletes() {
        let subject = MockUIViewController()
        subject.presentedView = BeingDismissedViewController()
        let viewController = UIViewController()
        var completionCalled = false

        subject.safePresent(viewController, animated: false, completion: { completionCalled = true })

        // Not yet presented — retry is pending.
        XCTAssertTrue(subject.presentedViewControllers.isEmpty)

        // Simulate the dismiss completing so the next retry can succeed.
        subject.presentedView = nil

        waitFor { !subject.presentedViewControllers.isEmpty }

        XCTAssertEqual(subject.presentedViewControllers.count, 1)
        XCTAssertTrue(subject.presentedViewControllers.first === viewController)
        XCTAssertTrue(completionCalled)
    }

    /// `safePresent` does not present when the retry limit is exhausted while a dismiss is in progress.
    func test_safePresent_doesNotPresentWhenAttemptsExhausted() {
        let subject = MockUIViewController()
        subject.presentedView = BeingDismissedViewController()
        let viewController = UIViewController()
        var completionCalled = false

        subject.safePresent(viewController, animated: false, remainingAttempts: 0) { completionCalled = true }

        XCTAssertTrue(subject.presentedViewControllers.isEmpty)
        XCTAssertFalse(completionCalled)
    }

    // MARK: topmostViewController

    /// `topmostViewController` returns the top view controller for a view controller.
    func test_topmostViewController_isViewController() {
        let subject = UIViewController()
        XCTAssertEqual(subject.topmostViewController(), subject)
    }

    /// `topmostViewController` returns the top view controller for a navigation controller.
    func test_topmostViewController_isNavigationController() {
        let subject = UINavigationController()
        XCTAssertEqual(subject.topmostViewController(), subject)

        let viewControllerA = UIViewController()
        let viewControllerB = UIViewController()
        subject.viewControllers = [viewControllerA, viewControllerB]
        XCTAssertEqual(subject.topmostViewController(), viewControllerB)
        subject.popViewController(animated: false)
        XCTAssertEqual(subject.topmostViewController(), viewControllerA)
    }

    /// `topmostViewController` returns the top view controller for a tab bar controller.
    func test_topmostViewController_isTabBarController() {
        let subject = UITabBarController()
        XCTAssertEqual(subject.topmostViewController(), subject)

        let viewControllerA = UIViewController()
        let viewControllerB = UIViewController()
        subject.viewControllers = [viewControllerA, viewControllerB]
        XCTAssertEqual(subject.topmostViewController(), viewControllerA)
        subject.selectedIndex = 1
        XCTAssertEqual(subject.topmostViewController(), viewControllerB)
    }

    /// `topmostViewController` returns the top view controller when presenting a view controller.
    func test_topmostViewController_presentingViewController() {
        let subject = UIViewController()
        setKeyWindowRoot(viewController: subject)

        XCTAssertEqual(subject.topmostViewController(), subject)

        let viewController = UIViewController()
        subject.present(viewController, animated: false, completion: nil)
        waitFor { subject.presentedViewController != nil }
        XCTAssertEqual(subject.topmostViewController(), viewController)
    }

    /// `topmostViewController` returns the top view controller when presenting a navigation controller.
    func test_topmostViewController_presentingNavigationController() {
        let subject = UIViewController()
        let navigationController = UINavigationController()
        setKeyWindowRoot(viewController: subject)
        subject.present(navigationController, animated: false, completion: nil)

        XCTAssertEqual(subject.topmostViewController(), navigationController)

        let viewController = UIViewController()
        navigationController.setViewControllers([viewController], animated: false)
        XCTAssertEqual(subject.topmostViewController(), viewController)
    }

    /// `topmostViewController` returns the top view controller when presenting a tab bar controller.
    func test_topmostViewController_presentingTabBarController() {
        let subject = UIViewController()
        let tabBarController = UITabBarController()
        setKeyWindowRoot(viewController: subject)
        subject.present(tabBarController, animated: false, completion: nil)

        let viewControllerA = UIViewController()
        let navigationControllerA = UINavigationController(rootViewController: viewControllerA)
        let viewControllerB = UIViewController()
        let navigationControllerB = UINavigationController(rootViewController: viewControllerB)
        tabBarController.viewControllers = [navigationControllerA, navigationControllerB]

        XCTAssertEqual(subject.topmostViewController(), viewControllerA)

        tabBarController.selectedIndex = 1
        XCTAssertEqual(subject.topmostViewController(), viewControllerB)
    }
}

// MARK: - Test Helpers

/// A `UIViewController` subclass that reports itself as always being dismissed, used to simulate
/// a mid-dismissal state in `safePresent` tests.
private class BeingDismissedViewController: UIViewController {
    override var isBeingDismissed: Bool { true }
}

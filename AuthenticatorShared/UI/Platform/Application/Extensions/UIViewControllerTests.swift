import XCTest

@testable import AuthenticatorShared

class UIViewControllerTests: AuthenticatorTestCase {
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

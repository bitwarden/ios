import BitwardenKit
import BitwardenKitMocks
import SwiftUI
import TestHelpers
import XCTest

@testable import AuthenticatorShared

class AppModuleTests: BitwardenTestCase {
    // MARK: Properties

    var rootViewController: RootViewController!
    var subject: DefaultAppModule!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        rootViewController = RootViewController()
        subject = DefaultAppModule(services: .withMocks())
    }

    override func tearDown() {
        super.tearDown()

        rootViewController = nil
        subject = nil
    }

    // MARK: Tests

    /// `makeAppCoordinator` builds the app coordinator.
    @MainActor
    func test_makeAppCoordinator() {
        let coordinator = subject.makeAppCoordinator(appContext: .mainApp, navigator: rootViewController)
        coordinator.navigate(to: .tab(.settings(.settings)), context: nil)
        XCTAssertNotNil(rootViewController.childViewController)
    }

    /// `makeDebugMenuCoordinator()` builds the debug menu coordinator.
    @MainActor
    func test_makeDebugMenuCoordinator() {
        let navigationController = UINavigationController()
        let coordinator = subject.makeDebugMenuCoordinator(
            delegate: MockDebugMenuCoordinatorDelegate(),
            stackNavigator: navigationController,
        )
        coordinator.start()
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertTrue(navigationController.viewControllers[0] is UIHostingController<DebugMenuView>)
    }

    /// `makeNavigationController()` builds a navigation controller.
    @MainActor
    func test_makeNavigationController() {
        let navigationController = subject.makeNavigationController()
        XCTAssertTrue(navigationController is ViewLoggingNavigationController)
    }

    /// `makeSelectLanguageCoordinator()` builds the select language coordinator.
    @MainActor
    func test_makeSelectLanguageCoordinator() throws {
        let navigationController = MockStackNavigator()
        let coordinator = subject.makeSelectLanguageCoordinator(
            stackNavigator: navigationController,
        )
        coordinator.navigate(to: .open(currentLanguage: .default))
        let action = try XCTUnwrap(navigationController.actions.last)
        XCTAssertEqual(action.type, .presented)
        XCTAssertTrue(action.view is SelectLanguageView)
    }
}

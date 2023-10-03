import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - AuthCoordinatorTests

class AuthCoordinatorTests: BitwardenTestCase {
    // MARK: Properties

    var authDelegate: MockAuthDelegate!
    var rootNavigator: MockRootNavigator!
    var stackNavigator: MockStackNavigator!
    var subject: AuthCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        authDelegate = MockAuthDelegate()
        rootNavigator = MockRootNavigator()
        stackNavigator = MockStackNavigator()
        subject = AuthCoordinator(
            delegate: authDelegate,
            rootNavigator: rootNavigator,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator
        )
    }

    override func tearDown() {
        super.tearDown()
        authDelegate = nil
        rootNavigator = nil
        stackNavigator = nil
        subject = nil
    }

    // MARK: Tests

    /// `navigate(to:)` with `.complete` notifies the delegate that auth has completed.
    func test_navigate_complete() {
        subject.navigate(to: .complete)
        XCTAssertTrue(authDelegate.didCompleteAuthCalled)
    }

    /// `navigate(to:)` with `.createAccount` pushes the create account view onto the stack navigator.
    func test_navigate_createAccount() throws {
        subject.navigate(to: .createAccount)

        let navigationController = try XCTUnwrap(stackNavigator.actions.last?.view as? UINavigationController)
        XCTAssertTrue(stackNavigator.actions.last?.view is UINavigationController)
        XCTAssertTrue(navigationController.viewControllers.first is UIHostingController<CreateAccountView>)
    }

    /// `navigate(to:)` with `.dismiss` dismisses the presented view.
    func test_navigate_dismiss() throws {
        subject.navigate(to: .createAccount)
        subject.navigate(to: .dismiss)
        let lastAction = try XCTUnwrap(stackNavigator.actions.last)
        XCTAssertEqual(lastAction.type, .dismissed)
    }

    /// `navigate(to:)` with `.enterpriseSingleSignOn` pushes the enterprise single sign-on view onto the stack
    /// navigator.
    func test_navigate_enterpriseSingleSignOn() {
        subject.navigate(to: .enterpriseSingleSignOn)
        XCTAssertTrue(stackNavigator.actions.last?.view is Text)
    }

    /// `navigate(to:)` with `.landing` pushes the landing view onto the stack navigator.
    func test_navigate_landing() {
        subject.navigate(to: .landing)
        XCTAssertTrue(stackNavigator.actions.last?.view is LandingView)
    }

    /// `navigate(to:)` with `.landing` from `.login` pops back to the landing view.
    func test_navigate_landing_fromLogin() {
        stackNavigator.viewControllersToPop = [
            UIViewController(),
        ]
        subject.navigate(to: .landing)

        XCTAssertEqual(stackNavigator.actions.last?.type, .poppedToRoot)
    }

    /// `navigate(to:)` with `.login` pushes the login view onto the stack navigator.
    func test_navigate_login() throws {
        subject.navigate(to: .login(
            username: "username",
            region: "region",
            isLoginWithDeviceVisible: true
        ))

        XCTAssertEqual(stackNavigator.actions.last?.type, .pushed)
        let view = try XCTUnwrap(stackNavigator.actions.last?.view as? LoginView)
        let state = view.store.state
        XCTAssertEqual(state.username, "username")
        XCTAssertEqual(state.region, "region")
        XCTAssertTrue(state.isLoginWithDeviceVisible)
    }

    /// `navigate(to:)` with `.loginOptions` pushes the login options view onto the stack navigator.
    func test_navigate_loginOptions() {
        subject.navigate(to: .loginOptions)
        XCTAssertTrue(stackNavigator.actions.last?.view is Text)
    }

    /// `navigate(to:)` with `.loginWithDevice` pushes the login with device view onto the stack navigator.
    func test_navigate_loginWithDevice() {
        subject.navigate(to: .loginWithDevice)
        XCTAssertTrue(stackNavigator.actions.last?.view is Text)
    }

    /// `navigate(to:)` with `.masterPasswordHint` pushes the master password hint view onto the stack navigator.
    func test_navigate_masterPasswordHint() {
        subject.navigate(to: .masterPasswordHint)
        XCTAssertTrue(stackNavigator.actions.last?.view is Text)
    }

    /// `navigate(to:)` with `.regionSelection` pushes the region selection view onto the stack navigator.
    func test_navigate_regionSelection() {
        subject.navigate(to: .regionSelection)

        // Placeholder assertion until the region selection screen is added: BIT-268
        XCTAssertTrue(stackNavigator.actions.last?.view is Text)
    }

    /// `rootNavigator` uses a weak reference and does not retain a value once the root navigator has been erased.
    func test_rootNavigator_resetWeakReference() {
        var rootNavigator: MockRootNavigator? = MockRootNavigator()
        subject = AuthCoordinator(
            delegate: authDelegate,
            rootNavigator: rootNavigator!,
            services: ServiceContainer.withMocks(),
            stackNavigator: stackNavigator
        )
        XCTAssertNotNil(subject.rootNavigator)

        rootNavigator = nil
        XCTAssertNil(subject.rootNavigator)
    }

    /// `start()` presents the stack navigator within the root navigator.
    func test_start() {
        subject.start()
        XCTAssertIdentical(rootNavigator.navigatorShown, stackNavigator)
    }
}

// MARK: - MockAuthDelegate

class MockAuthDelegate: AuthCoordinatorDelegate {
    var didCompleteAuthCalled = false

    func didCompleteAuth() {
        didCompleteAuthCalled = true
    }
}

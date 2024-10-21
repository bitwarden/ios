// swiftlint:disable:this file_name

import XCTest

@testable import BitwardenShared

// MARK: - AppCoordinatorTests

@available(iOS 17.0, *)
class AppCoordinatorFido2Tests: BitwardenTestCase {
    // MARK: Properties

    var appExtensionDelegate: MockFido2AppExtensionDelegate!
    var module: MockAppModule!
    var rootNavigator: MockRootNavigator!
    var router: MockRouter<AuthEvent, AuthRoute>!
    var services: Services!
    var subject: AppCoordinator!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockFido2AppExtensionDelegate()
        router = MockRouter(routeForEvent: { _ in .landing })
        module = MockAppModule()
        module.authRouter = router
        rootNavigator = MockRootNavigator()
        services = ServiceContainer.withMocks()

        subject = AppCoordinator(
            appContext: .mainApp,
            appExtensionDelegate: appExtensionDelegate,
            module: module,
            rootNavigator: rootNavigator,
            services: services
        )
    }

    override func tearDown() {
        super.tearDown()
        appExtensionDelegate = nil
        module = nil
        rootNavigator = nil
        services = nil
        subject = nil
    }

    // MARK: Tests

    /// `handleEvent(_:)` with didStart, completeWithNeverUnlockKey and in fido2 autofill credential flow
    /// shows a transparent navigation controller and completes.
    @MainActor
    func test_handleEvent_didStartTransparentController() async throws {
        appExtensionDelegate.extensionMode = .autofillFido2Credential(
            MockPasskeyCredentialRequest(),
            userInteraction: true
        )
        appExtensionDelegate.authCompletionRoute = nil
        router.routeForEvent = { _ in .completeWithNeverUnlockKey }

        await subject.handleEvent(.didStart)

        XCTAssertNotNil(rootNavigator.navigatorShown)
        let navController = try XCTUnwrap(rootNavigator.navigatorShown as? UINavigationController)
        XCTAssertTrue(navController.isNavigationBarHidden)

        XCTAssertTrue(appExtensionDelegate.didCompleteAuthCalled)
    }

    /// `handleEvent(_:)` with didStart, completeWithNeverUnlockKey and not in fido2 autofill credential flow
    /// shows the corresponding auth route.
    @MainActor
    func test_handleEvent_didStartNeverUnlockKeyNormal() async throws {
        appExtensionDelegate.authCompletionRoute = nil
        router.routeForEvent = { _ in .completeWithNeverUnlockKey }

        await subject.handleEvent(.didStart)

        XCTAssertEqual(module.authCoordinator.routes, [.completeWithNeverUnlockKey])
    }
}

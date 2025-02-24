import XCTest

@testable import AuthenticatorShared

// MARK: - AnyRouterTests

@MainActor
class AnyRouterTests: AuthenticatorTestCase {
    // MARK: Properties

    var router: MockRouter<AuthEvent, AuthRoute>!
    var subject: AnyRouter<AuthEvent, AuthRoute>!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        router = MockRouter(routeForEvent: { _ in .vaultUnlock })
        subject = router.asAnyRouter()
    }

    override func tearDown() {
        super.tearDown()
        router = nil
        subject = nil
    }

    // MARK: Tests

    /// `handleAndRoute()` calls the `handleAndRoute()` method on the wrapped router.
    func test_handleAndRoute() async {
        var didStart = false
        router.routeForEvent = { event in
            guard case .didStart = event else { return .vaultUnlock }
            didStart = true
            return .complete
        }
        let route = await subject.handleAndRoute(.didStart)
        XCTAssertEqual(router.events, [.didStart])
        XCTAssertEqual(route, .complete)
        XCTAssertTrue(didStart)
    }
}

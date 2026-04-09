import BitwardenKit
import BitwardenKitMocks
import XCTest

// MARK: - AnyRouterTests

class AnyRouterTests: BitwardenTestCase {
    // MARK: Types

    enum TestEvent: Equatable {
        case didStart
    }

    enum TestRoute: Equatable {
        case complete
        case landing
    }

    // MARK: Properties

    var router: MockRouter<TestEvent, TestRoute>!
    var subject: AnyRouter<TestEvent, TestRoute>!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        router = MockRouter(routeForEvent: { _ in .landing })
        subject = router.asAnyRouter()
    }

    override func tearDown() {
        super.tearDown()
        router = nil
        subject = nil
    }

    // MARK: Tests

    /// `handleAndRoute()` calls the `handleAndRoute()` method on the wrapped router.
    @MainActor
    func test_handleAndRoute() async {
        var didStart = false
        router.routeForEvent = { event in
            guard case .didStart = event else { return .landing }
            didStart = true
            return .complete
        }
        let route = await subject.handleAndRoute(.didStart)
        XCTAssertEqual(router.events, [.didStart])
        XCTAssertEqual(route, .complete)
        XCTAssertTrue(didStart)
    }
}

import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

class TOTPExpirationManagerFactoryTests: BitwardenTestCase {
    // MARK: Properties

    var timeProvider: MockTimeProvider!
    var subject: DefaultTOTPExpirationManagerFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        timeProvider = MockTimeProvider(.currentTime)
        subject = DefaultTOTPExpirationManagerFactory(
            timeProvider: timeProvider,
        )
    }

    override func tearDown() {
        super.tearDown()

        timeProvider = nil
        subject = nil
    }

    // MARK: Tests

    /// `create(onExpiration:)` creates a `DefaultTOTPExpirationManager` with the
    /// given expiration closure.
    func test_create() {
        var called = false
        let expirationClosure: ([VaultListItem]) -> Void = { _ in
            called = true
        }
        let result = subject.create(onExpiration: expirationClosure)
        XCTAssertNotNil(result as? DefaultTOTPExpirationManager)
        if let onExpiration = result.onExpiration {
            onExpiration([])
        }
        XCTAssertTrue(called)
    }
}

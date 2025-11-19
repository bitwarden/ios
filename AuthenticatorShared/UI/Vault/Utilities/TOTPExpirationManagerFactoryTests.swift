@testable import AuthenticatorShared
import BitwardenKitMocks
import Combine
import XCTest

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
        let expirationClosure: ([ItemListItem]) -> Void = { _ in
            called = true
        }
        let itemPublisher = CurrentValueSubject<[ItemListSection]?, Never>([]).eraseToAnyPublisher()
        let result = subject.create(itemPublisher: itemPublisher, onExpiration: expirationClosure)
        XCTAssertNotNil(result as? DefaultTOTPExpirationManager)
        if let onExpiration = result.onExpiration {
            onExpiration([])
        }
        XCTAssertTrue(called)
    }
}

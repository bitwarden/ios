import XCTest

@testable import BitwardenShared

class DateProviderTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DefaultDateProvider!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()
        subject = DefaultDateProvider()
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `.now` is now.
    func test_nowIsNow() {
        XCTAssertEqual(subject.now.timeIntervalSinceNow, 0.0, accuracy: 0.1)
    }
}

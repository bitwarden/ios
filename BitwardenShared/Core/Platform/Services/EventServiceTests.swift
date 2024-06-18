import XCTest

@testable import BitwardenShared

class EventServiceTests: XCTestCase {
    // MARK: Properties

    var subject: EventService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DefaultEventService()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests
}

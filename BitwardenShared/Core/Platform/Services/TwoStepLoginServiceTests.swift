import XCTest

@testable import BitwardenShared

class TwoStepLoginServiceTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DefaultTwoStepLoginService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DefaultTwoStepLoginService(environmentService: MockEnvironmentService())
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// The two step URL returns the correct value.
    func test_twoStepLoginUrl() {
        XCTAssertEqual(subject.twoStepLoginUrl(), URL(string: "https://example.com/#/settings"))
    }
}

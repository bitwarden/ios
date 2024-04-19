import XCTest

@testable import BitwardenShared

class ClientBuilderTests: BitwardenTestCase {
    // MARK: Properties

    var errorReporter: MockErrorReporter!
    var mockPlatform: MockClientPlatform!
    var subject: DefaultClientBuilder!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        errorReporter = MockErrorReporter()
        mockPlatform = MockClientPlatform()
        subject = DefaultClientBuilder(errorReporter: errorReporter)
    }

    override func tearDown() {
        super.tearDown()

        errorReporter = nil
        mockPlatform = nil
        subject = nil
    }

    // MARK: Tests

    /// `buildClient()` creates a client and loads feature flags.
    func test_buildClient() async {
        let client = await subject.buildClient()

        XCTAssertNotNil(client)
        XCTAssertNotNil(mockPlatform.featureFlags)
    }
}

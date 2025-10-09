import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

class ClientBuilderTests: BitwardenTestCase {
    // MARK: Properties

    var clientManagedTokens: MockClientManagedTokens!
    var errorReporter: MockErrorReporter!
    var mockPlatform: MockPlatformClientService!
    var subject: DefaultClientBuilder!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        clientManagedTokens = MockClientManagedTokens()
        errorReporter = MockErrorReporter()
        mockPlatform = MockPlatformClientService()
        subject = DefaultClientBuilder(
            errorReporter: errorReporter,
            tokenProvider: clientManagedTokens,
        )
    }

    override func tearDown() {
        super.tearDown()

        clientManagedTokens = nil
        errorReporter = nil
        mockPlatform = nil
        subject = nil
    }

    // MARK: Tests

    /// `buildClient(for:)` creates a client and loads feature flags.
    func test_buildClient() {
        let builtClient = subject.buildClient()

        XCTAssertNotNil(builtClient)
        XCTAssertNotNil(mockPlatform.featureFlags)
    }
}

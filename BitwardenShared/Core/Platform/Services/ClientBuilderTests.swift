import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

class ClientBuilderTests: BitwardenTestCase {
    // MARK: Properties

    var client: MockClient!
    var errorReporter: MockErrorReporter!
    var mockPlatform: MockPlatformClientService!
    var sdkCipherRepository: MockSdkCipherRepository!
    var subject: DefaultClientBuilder!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        client = MockClient()
        errorReporter = MockErrorReporter()
        mockPlatform = MockPlatformClientService()
        sdkCipherRepository = MockSdkCipherRepository()
        subject = DefaultClientBuilder(
            clientMaker: { _ in self.client },
            errorReporter: errorReporter,
            sdkCipherRepository: sdkCipherRepository
        )
    }

    override func tearDown() {
        super.tearDown()

        client = nil
        errorReporter = nil
        mockPlatform = nil
        sdkCipherRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `buildClient(for:)` creates a client and loads feature flags without registering the
    /// repository when no user ID passed.
    func test_buildClient() {
        let builtClient = subject.buildClient(for: nil)

        XCTAssertNotNil(builtClient)
        XCTAssertNotNil(mockPlatform.featureFlags)
        XCTAssertNil(client.platformClient.stateMock.registerCipherRepositoryReceivedStore)
    }

    /// `buildClient(for:)` creates a client and loads feature flags registering the
    /// repository when a user ID is passed.
    func test_buildClient_withUserId() {
        let builtClient = subject.buildClient(for: "1")

        XCTAssertNotNil(builtClient)
        XCTAssertNotNil(mockPlatform.featureFlags)
        XCTAssertNotNil(client.platformClient.stateMock.registerCipherRepositoryReceivedStore)
    }
}

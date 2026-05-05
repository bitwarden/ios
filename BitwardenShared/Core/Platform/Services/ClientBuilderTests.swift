import BitwardenKit
import BitwardenKitMocks
import BitwardenSdkMocks
import XCTest

@testable import BitwardenShared

class ClientBuilderTests: BitwardenTestCase {
    // MARK: Properties

    var appIDService: AppIDService!
    var clientManagedTokens: MockClientManagedTokens!
    var environmentService: MockEnvironmentService!
    var mockPlatform: MockPlatformClientService!
    var subject: DefaultClientBuilder!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        appIDService = AppIDService(appIDSettingsStore: MockAppIDSettingsStore())
        clientManagedTokens = MockClientManagedTokens()
        environmentService = MockEnvironmentService()
        mockPlatform = MockPlatformClientService()
        subject = DefaultClientBuilder(
            appIDService: appIDService,
            environmentService: environmentService,
            tokenProvider: clientManagedTokens,
            userAgentBuilder: UserAgentBuilder(
                appName: "TestApp",
                appVersion: "1.0",
                systemDevice: MockSystemDevice(),
            ),
        )
    }

    override func tearDown() {
        super.tearDown()

        appIDService = nil
        clientManagedTokens = nil
        environmentService = nil
        mockPlatform = nil
        subject = nil
    }

    // MARK: Tests

    /// `buildClient(for:)` creates a client.
    func test_buildClient() async {
        let builtClient = await subject.buildClient()

        XCTAssertNotNil(builtClient)
        XCTAssertNotNil(mockPlatform.featureFlags)
    }
}

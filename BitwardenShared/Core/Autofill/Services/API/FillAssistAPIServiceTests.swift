import BitwardenKit
import BitwardenKitMocks
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - FillAssistAPIServiceTests

@MainActor
struct FillAssistAPIServiceTests {
    // MARK: Properties

    var activeAccountStateProvider: MockActiveAccountStateProvider!
    var client: MockHTTPClient!
    var stateService: MockStateService!
    var subject: FillAssistAPIService!

    // MARK: Initialization

    init() {
        activeAccountStateProvider = MockActiveAccountStateProvider()
        client = MockHTTPClient()
        stateService = MockStateService()
        let accountTokenProvider = MockAccountTokenProvider()
        accountTokenProvider.getTokenReturnValue = "ACCESS_TOKEN"
        subject = APIService(
            accountTokenProvider: accountTokenProvider,
            activeAccountStateProvider: activeAccountStateProvider,
            client: client,
            stateService: stateService,
        )
    }

    // MARK: Tests

    /// `getFormsMap()` performs the request with the correct method, URL, and no body.
    @Test
    func getFormsMap() async throws {
        client.result = .httpSuccess(testData: .formsMap)

        _ = try await subject.getFormsMap()

        let request = try #require(client.requests.last)
        #expect(request.method == .get)
        #expect(request.url.absoluteString == "https://example.com/fill-assist-rules/forms.v0.json")
        #expect(request.body == nil)
    }

    /// `getManifest()` performs the request with the correct method, URL, and no body.
    @Test
    func getManifest() async throws {
        client.result = .httpSuccess(testData: .fillAssistManifest)

        _ = try await subject.getManifest()

        let request = try #require(client.requests.last)
        #expect(request.method == .get)
        #expect(request.url.absoluteString == "https://example.com/fill-assist-rules/manifest.json")
        #expect(request.body == nil)
    }
}

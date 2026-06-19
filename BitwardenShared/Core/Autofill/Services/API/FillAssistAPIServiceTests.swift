import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared

// MARK: - FillAssistAPIServiceTests

@MainActor
struct FillAssistAPIServiceTests {
    // MARK: Properties

    var client: MockHTTPClient!
    var subject: FillAssistAPIService!

    // MARK: Initialization

    init() {
        client = MockHTTPClient()
        subject = APIService(client: client)
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
}

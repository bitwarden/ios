import BitwardenKit
import Foundation
import TestHelpers
import Testing

@testable import BitwardenShared

// MARK: - FillAssistAPIServiceTests

@MainActor
struct FillAssistAPIServiceTests {
    // MARK: Properties

    let client: MockHTTPClient
    let subject: FillAssistAPIService

    // MARK: Initialization

    init() {
        client = MockHTTPClient()
        subject = APIService(client: client)
    }

    // MARK: Tests

    /// `getFormsMap(filename:)` sends a request to the expected URL and decodes the response.
    @Test
    func getFormsMap() async throws {
        client.results = [.httpSuccess(testData: .formsMap)]

        _ = try await subject.getFormsMap(filename: "forms.v1.json")

        let request = try #require(client.requests.last)
        #expect(request.method == .get)
        #expect(request.url.absoluteString == "https://example.com/fill-assist-rules/forms.v1.json")
    }

    /// `getManifest()` sends a request to the manifest URL and decodes the response.
    @Test
    func getManifest() async throws {
        client.results = [.httpSuccess(testData: .fillAssistManifest)]

        _ = try await subject.getManifest()

        let request = try #require(client.requests.last)
        #expect(request.method == .get)
        #expect(
            request.url.absoluteString
                == "https://example.com/fill-assist-rules/\(Constants.FillAssist.manifestFilename)",
        )
    }
}

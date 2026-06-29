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

    /// `getFormsMap(filename:)` downloads the file at the expected URL and decodes the response.
    @Test
    func getFormsMap() async throws {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("forms.v1.json")
        try APITestData.formsMap.data.write(to: tempFile)
        client.downloadResults = [.success(tempFile)]

        _ = try await subject.getFormsMap(filename: "forms.v1.json")

        let request = try #require(client.downloadRequests.last)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString == "https://example.com/fill-assist-rules/forms.v1.json")
    }

    /// `getManifest()` downloads the manifest at the constant filename and decodes the response.
    @Test
    func getManifest() async throws {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent(Constants.FillAssist.manifestFilename)
        try APITestData.fillAssistManifest.data.write(to: tempFile)
        client.downloadResults = [.success(tempFile)]

        _ = try await subject.getManifest()

        let request = try #require(client.downloadRequests.last)
        #expect(request.httpMethod == "GET")
        #expect(
            request.url?.absoluteString
                == "https://example.com/fill-assist-rules/\(Constants.FillAssist.manifestFilename)",
        )
    }
}

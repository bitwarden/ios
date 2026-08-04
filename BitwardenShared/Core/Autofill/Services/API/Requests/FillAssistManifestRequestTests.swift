import Testing

@testable import BitwardenShared

// MARK: - FillAssistManifestRequestTests

struct FillAssistManifestRequestTests {
    // MARK: Tests

    /// `method` returns the correct HTTP method for the request.
    @Test
    func method() {
        #expect(FillAssistManifestRequest().method == .get)
    }

    /// `path` returns the path for the manifest JSON file.
    @Test
    func path() {
        #expect(FillAssistManifestRequest().path == "/manifest.json")
    }
}

import Testing

@testable import BitwardenShared

// MARK: - FormsMapRequestTests

struct FormsMapRequestTests {
    // MARK: Tests

    /// `path` returns the path for the forms map JSON file.
    @Test
    func path() {
        #expect(FormsMapRequest().path == "/forms.v0.json")
    }

    /// `method` returns the correct HTTP method for the request.
    @Test
    func method() {
        #expect(FormsMapRequest().method == .get)
    }
}

import Testing

@testable import BitwardenShared

// MARK: - FormsMapRequestTests

struct FormsMapRequestTests {
    // MARK: Tests

    /// `method` returns the correct HTTP method for the request.
    @Test
    func method() {
        #expect(FormsMapRequest(filename: "forms.v1.json").method == .get)
    }

    /// `path` returns a path built from the given filename.
    @Test
    func path() {
        #expect(FormsMapRequest(filename: "forms.v1.json").path == "/forms.v1.json")
    }
}

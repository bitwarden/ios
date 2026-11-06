import Testing

@testable import BitwardenShared

// MARK: - DevicesListRequestTests

struct DevicesListRequestTests {
    // MARK: Tests

    /// `body` is `nil`.
    @Test
    func body() {
        let subject = DevicesListRequest()
        #expect(subject.body == nil)
    }

    /// `method` is `.get`.
    @Test
    func method() {
        let subject = DevicesListRequest()
        #expect(subject.method == .get)
    }

    /// `path` is the correct value.
    @Test
    func path() {
        let subject = DevicesListRequest()
        #expect(subject.path == "/devices")
    }

    /// `query` is empty.
    @Test
    func query() {
        let subject = DevicesListRequest()
        #expect(subject.query.isEmpty)
    }
}

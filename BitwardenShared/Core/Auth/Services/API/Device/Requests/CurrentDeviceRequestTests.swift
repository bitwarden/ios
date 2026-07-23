import Testing

@testable import BitwardenShared

// MARK: - CurrentDeviceRequestTests

struct CurrentDeviceRequestTests {
    // MARK: Tests

    /// `body` is `nil`.
    @Test
    func body() {
        let subject = CurrentDeviceRequest(appId: "app-id")
        #expect(subject.body == nil)
    }

    /// `method` is `.get`.
    @Test
    func method() {
        let subject = CurrentDeviceRequest(appId: "app-id")
        #expect(subject.method == .get)
    }

    /// `path` interpolates the `appId` into the correct URL path.
    @Test
    func path() {
        let subject = CurrentDeviceRequest(appId: "app-id-123")
        #expect(subject.path == "/devices/identifier/app-id-123")
    }

    /// `query` is empty.
    @Test
    func query() {
        let subject = CurrentDeviceRequest(appId: "app-id")
        #expect(subject.query.isEmpty)
    }
}

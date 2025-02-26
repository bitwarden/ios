import XCTest

@testable import BitwardenShared

// MARK: - KnownDeviceRequestTests

class KnownDeviceRequestTests: BitwardenTestCase {
    // MARK: Static Values

    /// `body` is `nil`.
    func test_body() {
        let subject = KnownDeviceRequest(email: "", deviceIdentifier: "")
        XCTAssertNil(subject.body)
    }

    /// `method` is `.get`.
    func test_method() {
        let subject = KnownDeviceRequest(email: "", deviceIdentifier: "")
        XCTAssertEqual(subject.method, .get)
    }

    /// `path` is the correct value.
    func test_path() {
        let subject = KnownDeviceRequest(email: "", deviceIdentifier: "")
        XCTAssertEqual(subject.path, "/devices/knowndevice")
    }

    /// `query` is empty.
    func test_query() {
        let subject = KnownDeviceRequest(email: "", deviceIdentifier: "")
        XCTAssertTrue(subject.query.isEmpty)
    }

    // MARK: Init

    /// `init()` encodes the provided values in to the request headers correctly.
    func test_init() {
        let subject = KnownDeviceRequest(
            email: "email@example.com",
            deviceIdentifier: "1234"
        )

        XCTAssertEqual(subject.headers.count, 2)
        XCTAssertEqual(subject.headers["X-Request-Email"], "ZW1haWxAZXhhbXBsZS5jb20")
        XCTAssertEqual(subject.headers["X-Device-Identifier"], "1234")
    }
}

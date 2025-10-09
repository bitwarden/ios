import XCTest

@testable import BitwardenShared

class URLTests: BitwardenTestCase {
    // MARK: Tests

    /// `appWebURL` returns the app's web URL after the Bitwarden `iosapp://` URL scheme.
    func test_appWebURL() {
        XCTAssertEqual(URL(string: "iosapp://example.com")?.appWebURL, URL(string: "https://example.com"))

        XCTAssertNil(URL(string: "https://example.com")?.appWebURL)
    }

    /// `domain` returns the URL's domain constructed from the top-level and second-level domain.
    func test_domain() {
        XCTAssertEqual(URL(string: "https://localhost")?.domain, "localhost")
        XCTAssertEqual(URL(string: "https://localhost/test")?.domain, "localhost")
        XCTAssertEqual(URL(string: "https://1.1.1.1")?.domain, "1.1.1.1")
        XCTAssertEqual(URL(string: "https://1.1.1.1/test")?.domain, "1.1.1.1")

        XCTAssertEqual(URL(string: "https://example.com")?.domain, "example.com")
        XCTAssertEqual(URL(string: "https://example.co.uk")?.domain, "example.co.uk")

        XCTAssertEqual(URL(string: "https://example.com")?.domain, "example.com")
        XCTAssertEqual(URL(string: "https://sub.example.co.uk")?.domain, "example.co.uk")

        // Wildcard: *.compute.amazonaws.com
        XCTAssertEqual(
            URL(string: "https://sub.example.compute.amazonaws.com")?.domain,
            "sub.example.compute.amazonaws.com",
        )
        XCTAssertEqual(
            URL(string: "https://foo.sub.example.compute.amazonaws.com")?.domain,
            "sub.example.compute.amazonaws.com",
        )

        // Exception: !city.kobe.jp
        XCTAssertEqual(
            URL(string: "https://example.city.kobe.jp")?.domain,
            "example.city.kobe.jp",
        )
        XCTAssertEqual(
            URL(string: "https://sub.example.city.kobe.jp")?.domain,
            "example.city.kobe.jp",
        )
    }

    /// `hostWithPort` returns the URL's host with the port, if one exists.
    func test_hostWithPort() {
        XCTAssertEqual(URL(string: "https://example.com")?.hostWithPort, "example.com")
        XCTAssertEqual(URL(string: "https://example.com:8080")?.hostWithPort, "example.com:8080")
        XCTAssertEqual(URL(string: "https://test.example.com")?.hostWithPort, "test.example.com")
        XCTAssertEqual(URL(string: "https://test.example.com:8080")?.hostWithPort, "test.example.com:8080")
        XCTAssertNil(URL(string: "example.com")?.hostWithPort)
    }

    /// `isApp` returns whether the URL is an app URL using the Bitwarden `iosapp://` URL scheme.
    func test_isApp() throws {
        try XCTAssertTrue(XCTUnwrap(URL(string: "iosapp://example.com")).isApp)

        try XCTAssertFalse(XCTUnwrap(URL(string: "https://example.com")).isApp)
    }

    /// `setIsExcludedFromBackup(_:)` sets whether the file is excluded from backups.
    func test_setIsExcludedFromBackup() throws {
        let fileName = UUID().uuidString
        let url = try XCTUnwrap(URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent(fileName)
        try Data().write(to: url)

        try XCTAssertFalse(url.isExcludedFromBackups())

        try url.setIsExcludedFromBackup(true)
        try XCTAssertTrue(url.isExcludedFromBackups())

        try url.setIsExcludedFromBackup(false)
        try XCTAssertFalse(url.isExcludedFromBackups())

        try FileManager.default.removeItem(at: url)
    }
}

private extension URL {
    func isExcludedFromBackups() throws -> Bool {
        let values = try resourceValues(forKeys: [.isExcludedFromBackupKey])
        return values.isExcludedFromBackup ?? false
    }
}

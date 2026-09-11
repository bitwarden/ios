import XCTest

@testable import Networking

class OSLogHTTPLoggerTests: XCTestCase {
    // MARK: Properties

    var subject: OSLogHTTPLogger!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = OSLogHTTPLogger()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `formattedHeaders(_:)` returns a placeholder when there are no headers.
    func test_formattedHeaders_empty() {
        XCTAssertEqual(subject.formattedHeaders([:]), "(empty)")
    }

    /// `formattedHeaders(_:)` logs the values of headers that are known to be safe.
    func test_formattedHeaders_safeHeaders_logsValues() {
        let formatted = subject.formattedHeaders(["Content-Type": "application/json"])

        XCTAssertEqual(formatted, """
        [
          Content-Type: application/json
        ]
        """)
    }

    /// `formattedHeaders(_:)` redacts the values of headers that may carry credentials, such as
    /// authorization tokens, cookies, or user-configured custom headers.
    func test_formattedHeaders_sensitiveHeaders_redactsValues() {
        let sensitiveHeaders = [
            "Authorization": "Bearer secret-token",
            "CF-Access-Client-Secret": "secret-value",
            "Cookie": "session=secret-cookie",
        ]

        let formatted = subject.formattedHeaders(sensitiveHeaders)

        XCTAssertFalse(formatted.contains("secret-token"))
        XCTAssertFalse(formatted.contains("secret-value"))
        XCTAssertFalse(formatted.contains("secret-cookie"))
        XCTAssertTrue(formatted.contains("Authorization: [REDACTED]"))
        XCTAssertTrue(formatted.contains("CF-Access-Client-Secret: [REDACTED]"))
        XCTAssertTrue(formatted.contains("Cookie: [REDACTED]"))
    }
}

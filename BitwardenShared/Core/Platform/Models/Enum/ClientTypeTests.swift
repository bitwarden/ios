import XCTest

@testable import BitwardenShared

class ClientTypeTests: BitwardenTestCase {
    /// `stringValue` returns a string representation of the client type.
    func test_stringValue() {
        XCTAssertEqual(ClientType.browser.stringValue, "browser")
        XCTAssertEqual(ClientType.cli.stringValue, "cli")
        XCTAssertEqual(ClientType.desktop.stringValue, "desktop")
        XCTAssertEqual(ClientType.directoryConnector.stringValue, "connector")
        XCTAssertEqual(ClientType.mobile.stringValue, "mobile")
        XCTAssertEqual(ClientType.web.stringValue, "web")
    }
}

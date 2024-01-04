import BitwardenSdk
import XCTest

@testable import BitwardenShared

final class IconImageHelperTests: BitwardenTestCase {
    // MARK: Tests

    func test_getIconImage_emptyURIs() {
        let loginView = BitwardenSdk.LoginView.fixture(
            uris: []
        )
        let result = IconImageHelper.getIconImage(for: loginView, from: nil)
        XCTAssertNil(result)
    }

    func test_getIconImage_nilURIs() {
        let loginView = BitwardenSdk.LoginView.fixture()
        let result = IconImageHelper.getIconImage(for: loginView, from: nil)
        XCTAssertNil(result)
    }

    func test_getIconImage_nilURL() {
        let loginView = BitwardenSdk.LoginView.fixture(
            uris: [
                .init(uri: "bitwarden.com", match: nil),
            ]
        )
        let result = IconImageHelper.getIconImage(for: loginView, from: nil)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.absoluteString, "https://icons.bitwarden.net/bitwarden.com/icon.png")
    }

    func test_getIconImage_multiURI() {
        let loginView = BitwardenSdk.LoginView.fixture(
            uris: [
                .init(uri: nil, match: nil),
                .init(uri: "://peanuts", match: nil),
                .init(uri: "://peanuts.yum", match: nil),
                .init(uri: "bitwarden.com", match: nil),
            ]
        )
        let result = IconImageHelper.getIconImage(for: loginView, from: nil)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.absoluteString, "https://icons.bitwarden.net/bitwarden.com/icon.png")
    }
}

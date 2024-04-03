import BitwardenSdk
import XCTest

@testable import BitwardenShared

final class IconImageHelperTests: BitwardenTestCase {
    // MARK: Parameters

    let defaultURL = URL(string: "https://icons.bitwarden.net")!

    // MARK: Tests

    func test_getIconImage_emptyURIs() {
        let loginView = BitwardenSdk.LoginView.fixture(
            uris: []
        )
        let result = IconImageHelper.getIconImage(for: loginView, from: defaultURL)
        XCTAssertNil(result)
    }

    func test_getIconImage_nilURIs() {
        let loginView = BitwardenSdk.LoginView.fixture()
        let result = IconImageHelper.getIconImage(for: loginView, from: defaultURL)
        XCTAssertNil(result)
    }

    func test_getIconImage_nilURL() {
        let loginView = BitwardenSdk.LoginView.fixture(
            uris: [
                .fixture(uri: "bitwarden.com", match: nil),
            ]
        )
        let result = IconImageHelper.getIconImage(for: loginView, from: defaultURL)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.absoluteString, "https://icons.bitwarden.net/bitwarden.com/icon.png")
    }

    func test_getIconImage_multiURI() {
        let loginView = BitwardenSdk.LoginView.fixture(
            uris: [
                .fixture(uri: nil, match: nil),
                .fixture(uri: "://peanuts", match: nil),
                .fixture(uri: "://peanuts.yum", match: nil),
                .fixture(uri: "bitwarden.com", match: nil),
            ]
        )
        let result = IconImageHelper.getIconImage(for: loginView, from: defaultURL)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.absoluteString, "https://icons.bitwarden.net/bitwarden.com/icon.png")
    }
}

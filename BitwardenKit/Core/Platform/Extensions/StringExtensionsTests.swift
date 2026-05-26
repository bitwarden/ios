import BitwardenKit
import Combine
import XCTest

class StringExtensionsTests: BitwardenTestCase {
    // MARK: Tests

    /// `fixURLIfNeeded()` returns the same string when it can be directly converted to `URL`.
    func test_fixURLIfNeeded_sameStringWhenCanConvertToURL() {
        let string = "https://bitwarden.com"
        XCTAssertEqual(string.fixURLIfNeeded(), "https://bitwarden.com")
    }

    /// `fixURLIfNeeded()` returns the same string prefixed with "http://" when it can't be
    /// directly converted to `URL` and it's an IP address.
    func test_fixURLIfNeeded_httpWhenIPAddress() {
        let string = "192.168.0.1:8080"
        XCTAssertEqual(string.fixURLIfNeeded(), "http://192.168.0.1:8080")
    }

    /// `fixURLIfNeeded()` returns the same string prefixed with "https://" when it can't be
    /// directly converted to `URL` and it's not an IP address.
    func test_fixURLIfNeeded_httpsWhenNotIPAddress() {
        let string = "ht tp://broken.com"
        XCTAssertEqual(string.fixURLIfNeeded(), "https://ht tp://broken.com")
    }

    // MARK: Tests - removingMarkdownForVoiceOver

    /// `removingMarkdownForVoiceOver()` strips asterisk bold markers.
    func test_removingMarkdownForVoiceOver_bold() {
        XCTAssertEqual("Your charge is **$19.80**, due on **May 1**.".removingMarkdownForVoiceOver(),
                        "Your charge is $19.80, due on May 1.")
    }

    /// `removingMarkdownForVoiceOver()` strips underscore bold markers.
    func test_removingMarkdownForVoiceOver_underscoreBold() {
        XCTAssertEqual("__Bold text__".removingMarkdownForVoiceOver(), "Bold text")
    }

    /// `removingMarkdownForVoiceOver()` strips asterisk italic markers.
    func test_removingMarkdownForVoiceOver_italic() {
        XCTAssertEqual("This is *important*.".removingMarkdownForVoiceOver(), "This is important.")
    }

    /// `removingMarkdownForVoiceOver()` strips underscore italic markers.
    func test_removingMarkdownForVoiceOver_underscoreItalic() {
        XCTAssertEqual("This is _important_.".removingMarkdownForVoiceOver(), "This is important.")
    }

    /// `removingMarkdownForVoiceOver()` strips strikethrough markers.
    func test_removingMarkdownForVoiceOver_strikethrough() {
        XCTAssertEqual("~~Old price~~ New price.".removingMarkdownForVoiceOver(), "Old price New price.")
    }

    /// `removingMarkdownForVoiceOver()` strips inline links, keeping the link text.
    func test_removingMarkdownForVoiceOver_links() {
        XCTAssertEqual("Visit [Bitwarden](https://bitwarden.com) now.".removingMarkdownForVoiceOver(),
                        "Visit Bitwarden now.")
    }

    /// `removingMarkdownForVoiceOver()` does not partially strip bold markers as italic.
    func test_removingMarkdownForVoiceOver_boldNotStrippedAsItalic() {
        XCTAssertEqual("**Bold text**".removingMarkdownForVoiceOver(), "Bold text")
    }

    /// `removingMarkdownForVoiceOver()` returns the string unchanged when no markdown is present.
    func test_removingMarkdownForVoiceOver_noMarkdown() {
        let plain = "No markdown here."
        XCTAssertEqual(plain.removingMarkdownForVoiceOver(), plain)
    }
}

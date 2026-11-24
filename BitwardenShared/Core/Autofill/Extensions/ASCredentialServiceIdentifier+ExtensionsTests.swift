// swiftlint:disable:this file_name
import AuthenticationServices
import Testing

@testable import BitwardenShared

// MARK: - ASCredentialServiceIdentifierExtensionsTests

struct ASCredentialServiceIdentifierExtensionsTests {
    // MARK: Tests

    /// `matches(uri:)` matches a `.domain` identifier to a web URI with the same host, regardless of
    /// its scheme, port, path, or case.
    @Test(arguments: [
        ("https://www.example.com", true),
        ("http://WWW.EXAMPLE.COM:8080/login", true),
        ("www.example.com/login", true),
        ("https://example.com", false),
        ("https://login.www.example.com", false),
        ("iosapp://www.example.com", false),
    ])
    func matches_domain(uri: String, expected: Bool) {
        let subject = ASCredentialServiceIdentifier(identifier: "www.example.com", type: .domain)
        #expect(subject.matches(uri: uri) == expected)
    }

    /// `matches(uri:)` matches a `.URL` identifier to the same URI, ignoring surrounding whitespace
    /// and compared with a default `https://` scheme and without a trailing slash.
    @Test(arguments: [
        ("https://www.example.com/login", true),
        ("https://www.example.com/login/", true),
        ("www.example.com/login", true),
        (" https://www.example.com/login ", true),
        ("http://www.example.com/login", false),
        ("https://www.example.com", false),
    ])
    func matches_url(uri: String, expected: Bool) {
        let subject = ASCredentialServiceIdentifier(identifier: "https://www.example.com/login", type: .URL)
        #expect(subject.matches(uri: uri) == expected)
    }

    /// `normalizedURI` prepends "https://" for a domain identifier.
    @Test
    func normalizedURI_domain() {
        let subject = ASCredentialServiceIdentifier(identifier: "example.com", type: .domain)
        #expect(subject.normalizedURI == "https://example.com")
    }

    /// `normalizedURI` returns the identifier unchanged for an app identifier.
    @available(iOS 26.2, *)
    @Test
    func normalizedURI_app() {
        let subject = ASCredentialServiceIdentifier(identifier: "com.example.app", type: .app)
        #expect(subject.normalizedURI == "com.example.app")
    }

    /// `normalizedURI` returns the identifier unchanged for a URL identifier.
    @Test
    func normalizedURI_url() {
        let subject = ASCredentialServiceIdentifier(identifier: "https://example.com/login", type: .URL)
        #expect(subject.normalizedURI == "https://example.com/login")
    }
}

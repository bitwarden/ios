// swiftlint:disable:this file_name
import AuthenticationServices
import Testing

@testable import BitwardenShared

// MARK: - ASCredentialServiceIdentifierExtensionsTests

struct ASCredentialServiceIdentifierExtensionsTests {
    // MARK: Tests

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

import BitwardenSdk
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class CipherMatchingHelperTests: BitwardenTestCase {
    let ciphers: [CipherView] = [
        .fixture(
            login: .fixture(uris: [LoginUriView(uri: "https://vault.bitwarden.com", match: .exact)]),
            name: "Bitwarden (Exact)"
        ),
        .fixture(
            login: .fixture(uris: [LoginUriView(uri: "https://vault.bitwarden.com", match: .startsWith)]),
            name: "Bitwarden (Starts With)"
        ),
        .fixture(
            login: .fixture(uris: [LoginUriView(uri: "https://vault.bitwarden.com", match: .never)]),
            name: "Bitwarden (Never)"
        ),

        .fixture(
            login: .fixture(uris: [LoginUriView(uri: "https://example.com", match: .startsWith)]),
            name: "Example (Starts With)"
        ),

        .fixture(login: .fixture(), name: "No URIs"),
        .fixture(login: .fixture(uris: []), name: "Empty URIs"),
    ]

    // MARK: Tests

    /// `ciphersMatching(uri:ciphers)` returns the list of ciphers that match the URI for the exact
    /// match type.
    func test_ciphersMatching_exact() {
        let ciphers: [CipherView] = [
            .fixture(
                login: .fixture(uris: [LoginUriView(uri: "https://vault.bitwarden.com", match: .exact)]),
                name: "Bitwarden Vault"
            ),
            .fixture(
                login: .fixture(uris: [LoginUriView(uri: "https://bitwarden.com", match: .exact)]),
                name: "Bitwarden"
            ),
            .fixture(
                login: .fixture(uris: [LoginUriView(uri: "https://vault.bitwarden.com/login", match: .exact)]),
                name: "Bitwarden Login"
            ),
            .fixture(
                login: .fixture(uris: [
                    LoginUriView(uri: "https://bitwarden.com", match: .exact),
                    LoginUriView(uri: "https://vault.bitwarden.com", match: .exact),
                ]),
                name: "Bitwarden Multiple"
            ),
        ]

        assertInlineSnapshot(
            of: dumpMatching(uri: "https://vault.bitwarden.com", ciphers: ciphers),
            as: .lines
        ) {
            """
            Bitwarden Vault
            Bitwarden Multiple
            """
        }

        assertInlineSnapshot(
            of: dumpMatching(uri: "https://bitwarden.com", ciphers: ciphers),
            as: .lines
        ) {
            """
            Bitwarden
            Bitwarden Multiple
            """
        }

        XCTAssertTrue(CipherMatchingHelper.ciphersMatching(uri: "http://bitwarden.com", ciphers: ciphers).isEmpty)
    }

    /// `ciphersMatching(uri:ciphers)` returns the list of ciphers that match the URI for the never
    /// match type.
    func test_ciphersMatching_never() {
        let ciphers: [CipherView] = [
            .fixture(
                login: .fixture(uris: [LoginUriView(uri: "https://vault.bitwarden.com", match: .never)]),
                name: "Bitwarden Never"
            ),
            .fixture(
                login: .fixture(uris: [LoginUriView(uri: "https://vault.bitwarden.com", match: .exact)]),
                name: "Bitwarden Exact"
            ),
        ]

        assertInlineSnapshot(
            of: dumpMatching(uri: "https://vault.bitwarden.com", ciphers: ciphers),
            as: .lines
        ) {
            """
            Bitwarden Exact
            """
        }

        XCTAssertTrue(CipherMatchingHelper.ciphersMatching(uri: "http://bitwarden.com", ciphers: ciphers).isEmpty)
    }

    /// `ciphersMatching(uri:ciphers)` returns the list of ciphers that match the URI for the
    /// regular expression match type.
    func test_ciphersMatching_regularExpression() {
        let uris: [(String, String)] = [
            ("Wikipedia Special", "https://en.wikipedia.org/w/index.php?title=Special:UserLogin&returnto=Bitwarden"),
            ("Wikipedia Specjalna", "https://pl.wikipedia.org/w/index.php?title=Specjalna:Zaloguj&returnto=Bitwarden"),
            ("Wikipedia", "https://en.wikipedia.org/w/index.php"),
            ("Malicious", "https://malicious-site.com"),
            ("Bitwarden Wikipedia", "https://en.wikipedia.org/wiki/Bitwarden"),
        ]
        let ciphers = uris.map { name, uri in
            CipherView.fixture(
                login: .fixture(uris: [LoginUriView(uri: uri, match: .regularExpression)]),
                name: name
            )
        }

        assertInlineSnapshot(
            of: dumpMatching(uri: #"^https://[a-z]+\.wikipedia\.org/w/index\.php"#, ciphers: ciphers),
            as: .lines
        ) {
            """
            Wikipedia Special
            Wikipedia Specjalna
            Wikipedia
            """
        }
    }

    /// `ciphersMatching(uri:ciphers)` returns the list of ciphers that match the URI for the starts
    /// with match type.
    func test_ciphersMatching_startsWith() {
        assertInlineSnapshot(
            of: dumpMatching(uri: "https://vault.bitwarden.com", ciphers: ciphers),
            as: .lines
        ) {
            """
            Bitwarden (Exact)
            Bitwarden (Starts With)
            """
        }
    }

    // MARK: Private

    /// Returns a string containing a description of the matching ciphers.
    func dumpMatchingCiphers(_ ciphers: [CipherView]) -> String {
        ciphers.map(\.name).joined(separator: "\n")
    }

    /// Filters the ciphers that match the URI and returns a string containing the description of
    ///  the matching ciphers.
    func dumpMatching(uri: String, ciphers: [CipherView]) -> String {
        dumpMatchingCiphers(CipherMatchingHelper.ciphersMatching(uri: uri, ciphers: ciphers))
    }
}

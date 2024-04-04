import BitwardenSdk
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

class CipherMatchingHelperTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    let ciphers: [CipherView] = [
        .fixture(
            login: .fixture(uris: [LoginUriView.fixture(uri: "https://vault.bitwarden.com", match: .exact)]),
            name: "Bitwarden (Exact)"
        ),
        .fixture(
            login: .fixture(uris: [LoginUriView.fixture(uri: "https://vault.bitwarden.com", match: .startsWith)]),
            name: "Bitwarden (Starts With)"
        ),
        .fixture(
            login: .fixture(uris: [LoginUriView.fixture(uri: "https://vault.bitwarden.com", match: .never)]),
            name: "Bitwarden (Never)"
        ),

        .fixture(
            login: .fixture(uris: [LoginUriView.fixture(uri: "https://example.com", match: .startsWith)]),
            name: "Example (Starts With)"
        ),

        .fixture(login: .fixture(), name: "No URIs"),
        .fixture(login: .fixture(uris: []), name: "Empty URIs"),
    ]

    var settingsService: MockSettingsService!
    var stateService: MockStateService!
    var subject: CipherMatchingHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        settingsService = MockSettingsService()
        stateService = MockStateService()

        subject = CipherMatchingHelper(
            settingsService: settingsService,
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        settingsService = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `ciphersMatching(uri:ciphers)` returns the list of ciphers that match the URI for the base
    /// domain match type.
    func test_ciphersMatching_baseDomain() async {
        let uris: [(String, String)] = [
            ("Google", "http://google.com"),
            ("Google Accounts", "https://accounts.google.com"),
            ("Google Domain", "google.com"),
            ("Google Net", "https://google.net"),
            ("Yahoo", "http://yahoo.com"),
        ]
        let ciphers = uris.map { name, uri in
            CipherView.fixture(
                login: .fixture(uris: [LoginUriView.fixture(uri: uri, match: .domain)]),
                name: name
            )
        }

        let matchingCiphers = await subject.ciphersMatching(uri: "https://google.com", ciphers: ciphers)
        assertInlineSnapshot(
            of: dumpMatchingCiphers(matchingCiphers),
            as: .lines
        ) {
            """
            Google
            Google Accounts
            Google Domain
            """
        }
    }

    /// `ciphersMatching(uri:ciphers)` returns the list of ciphers that match the URI for the base
    /// domain match type using the Bitwarden iOS app scheme.
    func test_ciphersMatching_baseDomain_appScheme() async {
        settingsService.fetchEquivalentDomainsResult = .success([["google.com", "youtube.com"]])
        let ciphers = ciphersForUris(
            [
                ("Example", "https://example.com"),
                ("Example App Scheme", "iosapp://example.com"),
                ("Other", "https://other.com"),
            ],
            matchType: .domain
        )

        let matchingCiphers = await subject.ciphersMatching(uri: "iosapp://example.com", ciphers: ciphers)
        assertInlineSnapshot(
            of: dumpMatchingCiphers(matchingCiphers),
            as: .lines
        ) {
            """
            Example App Scheme
            Example
            """
        }
    }

    /// `ciphersMatching(uri:ciphers)` returns the list of ciphers that match the URI for the base
    /// domain match type using an equivalent domain.
    func test_ciphersMatching_baseDomain_equivalentDomains() async {
        settingsService.fetchEquivalentDomainsResult = .success([["google.com", "youtube.com"]])
        let ciphers = ciphersForUris(
            [
                ("Google", "https://google.com"),
                ("Google Account", "https://accounts.google.com"),
                ("Youtube", "https://youtube.com/login"),
                ("Yahoo", "https://yahoo.com"),
            ],
            matchType: .domain
        )

        let matchingCiphers = await subject.ciphersMatching(uri: "https://google.com", ciphers: ciphers)
        assertInlineSnapshot(
            of: dumpMatchingCiphers(matchingCiphers),
            as: .lines
        ) {
            """
            Google
            Google Account
            Youtube
            """
        }
    }

    /// `ciphersMatching(uri:ciphers)` returns the list of ciphers that match the URI using the
    /// default match type if the cipher doesn't specify a match type.
    func test_ciphersMatching_defaultMatchType() async {
        stateService.activeAccount = .fixture()

        let ciphers = ciphersForUris(
            [
                ("Google", "https://google.com"),
                ("Google Account", "https://accounts.google.com"),
                ("Youtube", "https://youtube.com/login"),
                ("Yahoo", "https://yahoo.com"),
            ],
            matchType: nil
        )

        stateService.defaultUriMatchTypeByUserId["1"] = .exact
        var matchingCiphers = await subject.ciphersMatching(uri: "https://yahoo.com", ciphers: ciphers)
        assertInlineSnapshot(
            of: dumpMatchingCiphers(matchingCiphers),
            as: .lines
        ) {
            """
            Yahoo
            """
        }

        stateService.defaultUriMatchTypeByUserId["1"] = .host
        matchingCiphers = await subject.ciphersMatching(uri: "https://google.com", ciphers: ciphers)
        assertInlineSnapshot(
            of: dumpMatchingCiphers(matchingCiphers),
            as: .lines
        ) {
            """
            Google
            """
        }
    }

    /// `ciphersMatching(uri:ciphers)` returns the list of ciphers that match the URI for the exact
    /// match type.
    func test_ciphersMatching_exact() async {
        let ciphers: [CipherView] = [
            .fixture(
                login: .fixture(uris: [LoginUriView.fixture(uri: "https://vault.bitwarden.com", match: .exact)]),
                name: "Bitwarden Vault"
            ),
            .fixture(
                login: .fixture(uris: [LoginUriView.fixture(uri: "https://bitwarden.com", match: .exact)]),
                name: "Bitwarden"
            ),
            .fixture(
                login: .fixture(uris: [LoginUriView.fixture(uri: "https://vault.bitwarden.com/login", match: .exact)]),
                name: "Bitwarden Login"
            ),
            .fixture(
                login: .fixture(uris: [
                    LoginUriView.fixture(uri: "https://bitwarden.com", match: .exact),
                    LoginUriView.fixture(uri: "https://vault.bitwarden.com", match: .exact),
                ]),
                name: "Bitwarden Multiple"
            ),
        ]

        var matchingCiphers = await subject.ciphersMatching(uri: "https://vault.bitwarden.com", ciphers: ciphers)
        assertInlineSnapshot(
            of: dumpMatchingCiphers(matchingCiphers),
            as: .lines
        ) {
            """
            Bitwarden Vault
            Bitwarden Multiple
            """
        }

        matchingCiphers = await subject.ciphersMatching(uri: "https://bitwarden.com", ciphers: ciphers)
        assertInlineSnapshot(
            of: dumpMatchingCiphers(matchingCiphers),
            as: .lines
        ) {
            """
            Bitwarden
            Bitwarden Multiple
            """
        }

        matchingCiphers = await subject.ciphersMatching(uri: "http://bitwarden.com", ciphers: ciphers)
        XCTAssertTrue(matchingCiphers.isEmpty)
    }

    /// `ciphersMatching(uri:ciphers)` returns the list of ciphers that match the URI for the host
    /// match type.
    func test_ciphersMatching_host() async {
        let uris: [(String, String)] = [
            ("Sub Domain 4000", "http://sub.domain.com:4000"),
            ("Sub Domain 4000 with Page", "https://sub.domain.com:4000/page.html"),
            ("Domain", "https://domain.com"),
            ("Sub Domain No Port", "https://sub.domain.com"),
            ("Sub Sub Domain", "https://sub2.sub.domain.com:4000"),
            ("Sub Domain 500", "https://sub.domain.com:5000"),
        ]
        let ciphers = uris.map { name, uri in
            CipherView.fixture(
                login: .fixture(uris: [LoginUriView.fixture(uri: uri, match: .host)]),
                name: name
            )
        }

        let matchingCiphers = await subject.ciphersMatching(uri: "https://sub.domain.com:4000", ciphers: ciphers)
        assertInlineSnapshot(
            of: dumpMatchingCiphers(matchingCiphers),
            as: .lines
        ) {
            """
            Sub Domain 4000
            Sub Domain 4000 with Page
            """
        }
    }

    /// `ciphersMatching(uri:ciphers)` returns the list of ciphers that match the URI for the never
    /// match type.
    func test_ciphersMatching_never() async {
        let ciphers: [CipherView] = [
            .fixture(
                login: .fixture(uris: [LoginUriView.fixture(uri: "https://vault.bitwarden.com", match: .never)]),
                name: "Bitwarden Never"
            ),
            .fixture(
                login: .fixture(uris: [LoginUriView.fixture(uri: "https://vault.bitwarden.com", match: .exact)]),
                name: "Bitwarden Exact"
            ),
        ]

        var matchingCiphers = await subject.ciphersMatching(uri: "https://vault.bitwarden.com", ciphers: ciphers)
        assertInlineSnapshot(
            of: dumpMatchingCiphers(matchingCiphers),
            as: .lines
        ) {
            """
            Bitwarden Exact
            """
        }

        matchingCiphers = await subject.ciphersMatching(uri: "http://bitwarden.com", ciphers: ciphers)
        XCTAssertTrue(matchingCiphers.isEmpty)
    }

    /// `ciphersMatching(uri:ciphers)` returns the list of ciphers that match the URI for the
    /// regular expression match type.
    func test_ciphersMatching_regularExpression() async {
        let cipher = CipherView.fixture(
            login: .fixture(
                uris: [
                    LoginUriView.fixture(
                        uri: #"^https://[a-z]+\.wikipedia\.org/w/index\.php"#,
                        match: .regularExpression
                    ),
                ]
            )
        )

        var matchingCiphers = await subject.ciphersMatching(
            uri: "https://en.wikipedia.org/w/index.php?title=Special:UserLogin&returnto=Bitwarden",
            ciphers: [cipher]
        )
        XCTAssertFalse(matchingCiphers.isEmpty)

        matchingCiphers = await subject.ciphersMatching(
            uri: "https://pl.wikipedia.org/w/index.php?title=Specjalna:Zaloguj&returnto=Bitwarden",
            ciphers: [cipher]
        )
        XCTAssertFalse(matchingCiphers.isEmpty)

        matchingCiphers = await subject.ciphersMatching(
            uri: "https://en.wikipedia.org/w/index.php",
            ciphers: [cipher]
        )
        XCTAssertFalse(matchingCiphers.isEmpty)

        matchingCiphers = await subject.ciphersMatching(
            uri: "https://malicious-site.com",
            ciphers: [cipher]
        )
        XCTAssertTrue(matchingCiphers.isEmpty)

        matchingCiphers = await subject.ciphersMatching(
            uri: "https://en.wikipedia.org/wiki/Bitwarden",
            ciphers: [cipher]
        )
        XCTAssertTrue(matchingCiphers.isEmpty)
    }

    /// `ciphersMatching(uri:ciphers)` returns the list of ciphers that match the URI for the starts
    /// with match type.
    func test_ciphersMatching_startsWith() async {
        let matchingCiphers = await subject.ciphersMatching(uri: "https://vault.bitwarden.com", ciphers: ciphers)
        assertInlineSnapshot(
            of: dumpMatchingCiphers(matchingCiphers),
            as: .lines
        ) {
            """
            Bitwarden (Exact)
            Bitwarden (Starts With)
            """
        }
    }

    // MARK: Private

    /// Returns a list of `CipherView`s created with the specified name, URI and match type.
    func ciphersForUris(_ nameUris: [(String, String)], matchType: BitwardenSdk.UriMatchType?) -> [CipherView] {
        nameUris.map { name, uri in
            CipherView.fixture(
                login: .fixture(uris: [LoginUriView.fixture(uri: uri, match: matchType)]),
                name: name
            )
        }
    }

    /// Returns a string containing a description of the matching ciphers.
    func dumpMatchingCiphers(_ ciphers: [CipherView]) -> String {
        ciphers.map(\.name).joined(separator: "\n")
    }
}

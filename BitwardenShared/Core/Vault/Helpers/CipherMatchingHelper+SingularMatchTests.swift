// swiftlint:disable:this file_name

import BitwardenSdk
import XCTest

@testable import BitwardenShared

class CipherMatchingHelperSingularMatchTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var settingsService: MockSettingsService!
    var stateService: MockStateService!
    var subject: DefaultCipherMatchingHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        settingsService = MockSettingsService()
        stateService = MockStateService()

        subject = DefaultCipherMatchingHelper(
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

    /// `doesCipherMatch(cipher:defaultMatchType:matchUri:matchingDomains:matchingFuzzyDomains:)`
    /// returns `.none` when cipher is not a login.
    func test_doesCipherMatch_noLogin() {
        let noLoginTypes: [CipherListViewType] = [.card(.fixture()), .identity, .secureNote, .sshKey]
        for type in noLoginTypes {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: type
                ),
                defaultMatchType: .domain,
                matchUri: "example.com",
                matchingDomains: ["example.com"],
                matchingFuzzyDomains: []
            )
            XCTAssertEqual(result, .none)
        }
    }

    /// `doesCipherMatch(cipher:defaultMatchType:matchUri:matchingDomains:matchingFuzzyDomains:)`
    /// returns `.none` when cipher is a login but doesn't have URIs.
    func test_doesCipherMatch_loginNoUris() {
        let result = subject.doesCipherMatch(
            cipher: .fixture(
                type: .login(.fixture())
            ),
            defaultMatchType: .domain,
            matchUri: "example.com",
            matchingDomains: ["example.com"],
            matchingFuzzyDomains: []
        )
        XCTAssertEqual(result, .none)
    }

    /// `doesCipherMatch(cipher:defaultMatchType:matchUri:matchingDomains:matchingFuzzyDomains:)`
    /// returns `.none` when cipher is a login, has URIs but is deleted.
    func test_doesCipherMatch_loginDeleted() {
        let result = subject.doesCipherMatch(
            cipher: .fixture(
                type: .login(.fixture(uris: [.fixture()])),
                deletedDate: .now
            ),
            defaultMatchType: .domain,
            matchUri: "example.com",
            matchingDomains: ["example.com"],
            matchingFuzzyDomains: []
        )
        XCTAssertEqual(result, .none)
    }

    /// `doesCipherMatch(cipher:defaultMatchType:matchUri:matchingDomains:matchingFuzzyDomains:)`
    /// returns `.exact` when when match type is `.domain` and the match URI base domain
    /// is the same as of the logins URI's base domains.
    func test_doesCipherMatch_domainExact() {
        let loginUrisToSucceed = [
            "http://google.com",
            "https://accounts.google.com",
            "google.com",
        ]

        for uri in loginUrisToSucceed {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [.fixture(uri: uri, match: .domain)]))
                ),
                defaultMatchType: .domain,
                matchUri: "https://google.com",
                matchingDomains: ["google.com"],
                matchingFuzzyDomains: []
            )
            XCTAssertEqual(result, .exact)
        }
    }

    /// `doesCipherMatch(cipher:defaultMatchType:matchUri:matchingDomains:matchingFuzzyDomains:)`
    /// returns `.none` when when match type is `.domain` and the match URI base domain
    /// is not the same as none of the logins URI's base domains.
    func test_doesCipherMatch_domainNone() {
        let loginUrisToFail = [
            "https://google.net",
            "http://yahoo.com",
            "iosapp://yahoo.com",
        ]

        for uri in loginUrisToFail {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [.fixture(uri: uri, match: .domain)]))
                ),
                defaultMatchType: .domain,
                matchUri: "https://google.com",
                matchingDomains: ["google.com"],
                matchingFuzzyDomains: []
            )
            XCTAssertEqual(result, .none)
        }
    }

    /// `doesCipherMatch(cipher:defaultMatchType:matchUri:matchingDomains:matchingFuzzyDomains:)`
    /// returns `.exact` when when match type is `.domain` and the match URI base domain
    /// is the same as of the logins URI's base domains in iosapp:// scheme.
    func test_doesCipherMatch_domainExactAppScheme() {
        let loginUrisToSucceed = [
            "https://example.com",
            "iosapp://example.com",
        ]

        for uri in loginUrisToSucceed {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [.fixture(uri: uri, match: .domain)]))
                ),
                defaultMatchType: .domain,
                matchUri: "iosapp://example.com",
                matchingDomains: ["example.com"],
                matchingFuzzyDomains: []
            )
            XCTAssertEqual(result, .exact, "On \(uri)")
        }
    }

    /// `doesCipherMatch(cipher:defaultMatchType:matchUri:matchingDomains:matchingFuzzyDomains:)`
    /// returns `.fuzzy` when when match type is `.domain` and the match URI base domain
    /// is the same as of the logins URI's base fuzzy domains in iosapp:// scheme.
    func test_doesCipherMatch_domainFuzzyAppScheme() {
        let loginUrisToSucceed = [
            "https://example.com",
            "iosapp://example.com",
        ]

        for uri in loginUrisToSucceed {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [.fixture(uri: uri, match: .domain)]))
                ),
                defaultMatchType: .domain,
                matchUri: "iosapp://example.com",
                matchingDomains: [],
                matchingFuzzyDomains: ["example.com"]
            )
            XCTAssertEqual(result, .fuzzy)
        }
    }

    /// `doesCipherMatch(cipher:defaultMatchType:matchUri:matchingDomains:matchingFuzzyDomains:)`
    /// returns `.exact` when when match type is `.host` and the match URI host is the same as the logins URI's host.
    func test_doesCipherMatch_hostExact() {
        let loginUrisToSucceed = [
            "http://sub.domain.com:4000",
            "https://sub.domain.com:4000/page.html",
        ]

        for uri in loginUrisToSucceed {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [.fixture(uri: uri, match: .host)]))
                ),
                defaultMatchType: .domain,
                matchUri: "https://sub.domain.com:4000",
                matchingDomains: ["example.com"],
                matchingFuzzyDomains: []
            )
            XCTAssertEqual(result, .exact)
        }
    }

    /// `doesCipherMatch(cipher:defaultMatchType:matchUri:matchingDomains:matchingFuzzyDomains:)`
    /// returns `.none` when when match type is `.host` and the match URI host is not the same
    /// as the logins URI's host.
    func test_doesCipherMatch_hostNone() {
        let loginUrisToFail = [
            "https://domain.com",
            "https://sub.domain.com",
            "sub2.sub.domain.com:4000",
            "https://sub.domain.com:5000",
            "iosapp://domain.com",
        ]

        for uri in loginUrisToFail {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [.fixture(uri: uri, match: .host)]))
                ),
                defaultMatchType: .domain,
                matchUri: "https://sub.domain.com:4000",
                matchingDomains: ["example.com"],
                matchingFuzzyDomains: []
            )
            XCTAssertEqual(result, .none)
        }
    }

    /// `doesCipherMatch(cipher:defaultMatchType:matchUri:matchingDomains:matchingFuzzyDomains:)`
    /// returns `.exact` when when match type is `.startsWith` and the match URI starts with one of the login's URIs.
    func test_doesCipherMatch_startsWithExact() {
        let loginUrisToSucceed = [
            "https://vault.bitwarden.com",
            "https://vault.bit",
        ]

        for uri in loginUrisToSucceed {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [
                        .fixture(uri: "noMatchExample.net", match: .startsWith),
                        .fixture(uri: uri, match: .startsWith),
                    ]))
                ),
                defaultMatchType: .domain,
                matchUri: "https://vault.bitwarden.com",
                matchingDomains: ["example.com"],
                matchingFuzzyDomains: []
            )
            XCTAssertEqual(result, .exact)
        }
    }

    /// `doesCipherMatch(cipher:defaultMatchType:matchUri:matchingDomains:matchingFuzzyDomains:)`
    /// returns `.none` when when match type is `.startsWith` and the match URI
    /// doesn't start with none of the login's URIs.
    func test_doesCipherMatch_startsWithNone() {
        let loginUrisToFail = [
            "https://vault.bitwarden.net",
            "https://vault.somethingelse.com",
            "iosapp://example.com",
        ]

        for uri in loginUrisToFail {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [
                        .fixture(uri: "noMatchExample.net", match: .startsWith),
                        .fixture(uri: uri, match: .startsWith),
                    ]))
                ),
                defaultMatchType: .domain,
                matchUri: "https://vault.bitwarden.com",
                matchingDomains: ["example.com"],
                matchingFuzzyDomains: []
            )
            XCTAssertEqual(result, .none)
        }
    }

    /// `doesCipherMatch(cipher:defaultMatchType:matchUri:matchingDomains:matchingFuzzyDomains:)`
    /// returns `.exact` when when match type is `.exact` and the match URI equals one of the login's URIs.
    func test_doesCipherMatch_exact() {
        let result = subject.doesCipherMatch(
            cipher: .fixture(
                type: .login(.fixture(uris: [
                    .fixture(uri: "noMatchExample.net", match: .exact),
                    .fixture(uri: "https://vault.bitwarden.com", match: .exact),
                ]))
            ),
            defaultMatchType: .domain,
            matchUri: "https://vault.bitwarden.com",
            matchingDomains: ["example.com"],
            matchingFuzzyDomains: []
        )
        XCTAssertEqual(result, .exact)
    }

    /// `doesCipherMatch(cipher:defaultMatchType:matchUri:matchingDomains:matchingFuzzyDomains:)`
    /// returns `.none` when when match type is `.startsWith` and the match URI
    /// is not equal to none of the login's URIs.
    func test_doesCipherMatch_exactNone() {
        let loginUrisToFail = [
            "https://vault.bitwarden.net",
            "https://vault.somethingelse.com",
            "iosapp://example.com",
        ]

        for uri in loginUrisToFail {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [
                        .fixture(uri: "noMatchExample.net", match: .exact),
                        .fixture(uri: uri, match: .exact),
                    ]))
                ),
                defaultMatchType: .domain,
                matchUri: "https://vault.bitwarden.com",
                matchingDomains: ["example.com"],
                matchingFuzzyDomains: []
            )
            XCTAssertEqual(result, .none)
        }
    }

    /// `doesCipherMatch(cipher:defaultMatchType:matchUri:matchingDomains:matchingFuzzyDomains:)`
    /// returns `.exact` when when match type is `.regularExpression` and the match URI matches
    /// the regular expression of one of the login's URIs.
    func test_doesCipherMatch_regularExpressionExact() {
        let matchingUrisToSucceed = [
            "https://en.wikipedia.org/w/index.php?title=Special:UserLogin&returnto=Bitwarden",
            "https://pl.wikipedia.org/w/index.php?title=Specjalna:Zaloguj&returnto=Bitwarden",
            "https://en.wikipedia.org/w/index.php",
        ]

        for uri in matchingUrisToSucceed {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [
                        .fixture(uri: #"^https://[a-z]+\.wikipedia\.org/w/index\.php"#, match: .regularExpression),
                    ]))
                ),
                defaultMatchType: .domain,
                matchUri: uri,
                matchingDomains: ["example.com"],
                matchingFuzzyDomains: []
            )
            XCTAssertEqual(result, .exact)
        }
    }

    /// `doesCipherMatch(cipher:defaultMatchType:matchUri:matchingDomains:matchingFuzzyDomains:)`
    /// returns `.none` when when match type is `.regularExpression` and the match URI doesn't
    /// match the regular expression of none of the login's URIs.
    func test_doesCipherMatch_regularExpressionNone() {
        let matchingUrisToFail = [
            "https://malicious-site.com",
            "https://en.wikipedia.org/wiki/Bitwarden",
        ]

        for uri in matchingUrisToFail {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [
                        .fixture(uri: #"^https://[a-z]+\.wikipedia\.org/w/index\.php"#, match: .regularExpression),
                    ]))
                ),
                defaultMatchType: .domain,
                matchUri: uri,
                matchingDomains: ["example.com"],
                matchingFuzzyDomains: []
            )
            XCTAssertEqual(result, .none)
        }
    }

    /// `doesCipherMatch(cipher:defaultMatchType:matchUri:matchingDomains:matchingFuzzyDomains:)`
    /// returns `.none` when when match type is `.never`.
    func test_doesCipherMatch_never() {
        let matchUrisToTest = [
            "https://vault.bitwarden.com",
            "https://vault.bitwarden",
            "https://vault.com",
        ]

        for uri in matchUrisToTest {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [
                        .fixture(uri: uri, match: .never),
                    ]))
                ),
                defaultMatchType: .domain,
                matchUri: "https://vault.bitwarden.com",
                matchingDomains: ["example.com"],
                matchingFuzzyDomains: []
            )
            XCTAssertEqual(result, .none)
        }
    }

    /// `getMatchingDomains(matchUri:)` returns empty when the URI is empty.
    func test_getMatchingDomains_emptyUri() async {
        let result = await subject.getMatchingDomains(matchUri: "")
        XCTAssertTrue(result.matching.isEmpty)
        XCTAssertTrue(result.fuzzyMatching.isEmpty)
    }

    /// `getMatchingDomains(matchUri:)` returns the passed URI domain when there are no
    /// equivalent domains.
    func test_getMatchingDomains_matchDomain() async {
        let result = await subject.getMatchingDomains(matchUri: "https://example.com")
        XCTAssertEqual(result.matching.count, 1)
        XCTAssertEqual(result.matching.first, "example.com")
        XCTAssertTrue(result.fuzzyMatching.isEmpty)
    }

    /// `getMatchingDomains(matchUri:)` returns the domains matching the equivalent domains.
    func test_getMatchingDomains_matchDomainEquivalentDomains() async {
        settingsService.fetchEquivalentDomainsResult = .success([
            [
                "google.com",
                "youtube.com",
            ],
        ])

        let result = await subject.getMatchingDomains(matchUri: "https://google.com")
        XCTAssertEqual(result.matching.map(\.self), [
            "youtube.com",
            "google.com",
        ])
    }

    /// `getMatchingDomains(matchUri:)` returns the domains matching the equivalent domains
    /// when URI to match has iosapp:// scheme.
    func test_getMatchingDomains_matchDomainEquivalentDomainsiOSAppScheme() async {
        settingsService.fetchEquivalentDomainsResult = .success([
            [
                "google.com",
                "youtube.com",
            ],
        ])

        let result = await subject.getMatchingDomains(matchUri: "iosapp://example.com")
        XCTAssertEqual(result.matching.map(\.self), [
            "iosapp://example.com",
        ])
        XCTAssertEqual(result.fuzzyMatching.map(\.self), [
            "example.com",
        ])
    }
} // swiftlint:disable:this file_length

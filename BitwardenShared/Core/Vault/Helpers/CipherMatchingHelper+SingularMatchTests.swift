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
        stateService.activeAccount = .fixture()
        stateService.defaultUriMatchTypeByUserId["1"] = .domain

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

    /// `doesCipherMatch(cipher:)` returns `.none` when there's no URI to match.
    func test_doesCipherMatch_noURIToMatch() async {
        subject.uriToMatch = nil
        let result = subject.doesCipherMatch(
            cipher: .fixture(
                type: .login(.fixture())
            )
        )
        XCTAssertEqual(result, .none)
    }

    /// `doesCipherMatch(cipher:)` returns `.none` when cipher is not a login.
    func test_doesCipherMatch_noLogin() async {
        subject.uriToMatch = "example.com"
        let noLoginTypes: [CipherListViewType] = [.card(.fixture()), .identity, .secureNote, .sshKey]
        for type in noLoginTypes {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: type
                )
            )
            XCTAssertEqual(result, .none)
        }
    }

    /// `doesCipherMatch(cipher:)` returns `.none` when cipher is a login but doesn't have URIs.
    func test_doesCipherMatch_loginNoUris() async {
        subject.uriToMatch = "example.com"
        let result = subject.doesCipherMatch(
            cipher: .fixture(
                type: .login(.fixture())
            )
        )
        XCTAssertEqual(result, .none)
    }

    /// `doesCipherMatch(cipher:)` returns `.none` when cipher is a login, has URIs but is deleted.
    func test_doesCipherMatch_loginDeleted() async {
        subject.uriToMatch = "example.com"
        let result = subject.doesCipherMatch(
            cipher: .fixture(
                type: .login(.fixture(uris: [.fixture()])),
                deletedDate: .now
            )
        )
        XCTAssertEqual(result, .none)
    }

    /// `doesCipherMatch(cipher:)` returns `.exact` when match type is `.domain` and the match URI base domain
    /// is the same as of the logins URI's base domains.
    func test_doesCipherMatch_domainExact() async {
        subject.uriToMatch = "https://google.com"
        subject.matchingDomains = ["google.com"]
        let loginUrisToSucceed = [
            "http://google.com",
            "https://accounts.google.com",
            "google.com",
        ]

        for uri in loginUrisToSucceed {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [.fixture(uri: uri, match: .domain)]))
                )
            )
            XCTAssertEqual(result, .exact)
        }
    }

    /// `doesCipherMatch(cipher:)` returns `.none` when match type is `.domain` and the match URI base domain
    /// is not the same as none of the logins URI's base domains.
    func test_doesCipherMatch_domainNone() async {
        subject.uriToMatch = "https://google.com"
        subject.matchingDomains = ["google.com"]
        let loginUrisToFail = [
            "https://google.net",
            "http://yahoo.com",
            "iosapp://yahoo.com",
        ]

        for uri in loginUrisToFail {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [.fixture(uri: uri, match: .domain)]))
                )
            )
            XCTAssertEqual(result, .none)
        }
    }

    /// `doesCipherMatch(cipher:)` returns `.exact` when match type is `.domain` and the match URI base domain
    /// is the same as of the logins URI's base domains in iosapp:// scheme.
    func test_doesCipherMatch_domainExactAppScheme() async {
        subject.uriToMatch = "iosapp://example.com"
        subject.matchingDomains = ["example.com"]
        let loginUrisToSucceed = [
            "https://example.com",
            "iosapp://example.com",
        ]

        for uri in loginUrisToSucceed {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [.fixture(uri: uri, match: .domain)]))
                )
            )
            XCTAssertEqual(result, .exact, "On \(uri)")
        }
    }

    /// `doesCipherMatch(cipher:)` returns `.fuzzy` when match type is `.domain` and the match URI base domain
    /// is the same as of the logins URI's base fuzzy domains in iosapp:// scheme.
    func test_doesCipherMatch_domainFuzzyAppScheme() async {
        subject.uriToMatch = "iosapp://example.com"
        subject.matchingDomains = []
        subject.matchingFuzzyDomains = ["example.com"]
        let loginUrisToSucceed = [
            "https://example.com",
            "iosapp://example.com",
        ]

        for uri in loginUrisToSucceed {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [.fixture(uri: uri, match: .domain)]))
                )
            )
            XCTAssertEqual(result, .fuzzy)
        }
    }

    /// `doesCipherMatch(cipher:)` returns `.exact` when match type is `.host`
    /// and the match URI host is the same as the logins URI's host.
    func test_doesCipherMatch_hostExact() async {
        subject.uriToMatch = "https://sub.domain.com:4000"
        subject.matchingDomains = ["example.com"]
        let loginUrisToSucceed = [
            "http://sub.domain.com:4000",
            "https://sub.domain.com:4000/page.html",
        ]

        for uri in loginUrisToSucceed {
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [.fixture(uri: uri, match: .host)]))
                )
            )
            XCTAssertEqual(result, .exact)
        }
    }

    /// `doesCipherMatch(cipher:)` returns `.none` when match type is `.host`
    /// and the match URI host is not the same as the logins URI's host.
    func test_doesCipherMatch_hostNone() async {
        subject.uriToMatch = "https://sub.domain.com:4000"
        subject.matchingDomains = ["example.com"]
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
                )
            )
            XCTAssertEqual(result, .none)
        }
    }

    /// `doesCipherMatch(cipher:)` returns `.exact` when match type is `.startsWith`
    /// and the match URI starts with one of the login's URIs.
    func test_doesCipherMatch_startsWithExact() async {
        subject.uriToMatch = "https://vault.bitwarden.com"
        subject.matchingDomains = ["example.com"]
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
                )
            )
            XCTAssertEqual(result, .exact)
        }
    }

    /// `doesCipherMatch(cipher:)` returns `.none` when match type is `.startsWith` and the match URI
    /// doesn't start with none of the login's URIs.
    func test_doesCipherMatch_startsWithNone() async {
        subject.uriToMatch = "https://vault.bitwarden.com"
        subject.matchingDomains = ["example.com"]
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
                )
            )
            XCTAssertEqual(result, .none)
        }
    }

    /// `doesCipherMatch(cipher:)` returns `.exact` when match type is `.exact`
    /// and the match URI equals one of the login's URIs.
    func test_doesCipherMatch_exact() async {
        subject.uriToMatch = "https://vault.bitwarden.com"
        subject.matchingDomains = ["example.com"]
        let result = subject.doesCipherMatch(
            cipher: .fixture(
                type: .login(.fixture(uris: [
                    .fixture(uri: "noMatchExample.net", match: .exact),
                    .fixture(uri: "https://vault.bitwarden.com", match: .exact),
                ]))
            )
        )
        XCTAssertEqual(result, .exact)
    }

    /// `doesCipherMatch(cipher:)` returns `.none` when match type is `.startsWith` and the match URI
    /// is not equal to none of the login's URIs.
    func test_doesCipherMatch_exactNone() async {
        subject.uriToMatch = "https://vault.bitwarden.com"
        subject.matchingDomains = ["example.com"]
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
                )
            )
            XCTAssertEqual(result, .none)
        }
    }

    /// `doesCipherMatch(cipher:)` returns `.exact` when match type is `.regularExpression`
    /// and the match URI matches the regular expression of one of the login's URIs.
    func test_doesCipherMatch_regularExpressionExact() async {
        let matchingUrisToSucceed = [
            "https://en.wikipedia.org/w/index.php?title=Special:UserLogin&returnto=Bitwarden",
            "https://pl.wikipedia.org/w/index.php?title=Specjalna:Zaloguj&returnto=Bitwarden",
            "https://en.wikipedia.org/w/index.php",
        ]

        for uri in matchingUrisToSucceed {
            await subject.prepare(uri: uri)
            subject.matchingDomains = ["example.com"]
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [
                        .fixture(uri: #"^https://[a-z]+\.wikipedia\.org/w/index\.php"#, match: .regularExpression),
                    ]))
                )
            )
            XCTAssertEqual(result, .exact)
        }
    }

    /// `doesCipherMatch(cipher:)` returns `.none` when match type is `.regularExpression`
    /// and the match URI doesn't match the regular expression of none of the login's URIs.
    func test_doesCipherMatch_regularExpressionNone() async {
        let matchingUrisToFail = [
            "https://malicious-site.com",
            "https://en.wikipedia.org/wiki/Bitwarden",
        ]

        for uri in matchingUrisToFail {
            await subject.prepare(uri: uri)
            subject.matchingDomains = ["example.com"]
            let result = subject.doesCipherMatch(
                cipher: .fixture(
                    type: .login(.fixture(uris: [
                        .fixture(uri: #"^https://[a-z]+\.wikipedia\.org/w/index\.php"#, match: .regularExpression),
                    ]))
                )
            )
            XCTAssertEqual(result, .none)
        }
    }

    /// `doesCipherMatch(cipher:)` returns `.none` when match type is `.never`.
    func test_doesCipherMatch_never() async {
        await subject.prepare(uri: "https://vault.bitwarden.com")
        subject.matchingDomains = ["example.com"]
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
                )
            )
            XCTAssertEqual(result, .none)
        }
    }

    /// `prepare(uri:)` sets the default match type in its state.
    func test_prepare_setsDefaultMatchType() async {
        stateService.defaultUriMatchTypeByUserId["1"] = .startsWith
        await subject.prepare(uri: "https://example.com")
        XCTAssertEqual(subject.defaultMatchType, .startsWith)
    }

    /// `prepare(uri:)` set matching/fuzzy domains as empty when the URI is empty.
    func test_prepare_emptyUri() async {
        await subject.prepare(uri: "")
        XCTAssertTrue(subject.matchingDomains.isEmpty)
        XCTAssertTrue(subject.matchingFuzzyDomains.isEmpty)
    }

    /// `prepare(uri:)` sets the passed URI domain as matching domains when there are no
    /// equivalent domains.
    func test_prepare_matchDomain() async {
        await subject.prepare(uri: "https://example.com")
        XCTAssertEqual(subject.matchingDomains.count, 1)
        XCTAssertEqual(subject.matchingDomains.first, "example.com")
        XCTAssertTrue(subject.matchingFuzzyDomains.isEmpty)
    }

    /// `prepare(uri:)` sets the domains matching the equivalent domains.
    func test_prepare_matchDomainEquivalentDomains() async {
        settingsService.fetchEquivalentDomainsResult = .success([
            [
                "google.com",
                "youtube.com",
            ],
        ])

        await subject.prepare(uri: "https://google.com")
        XCTAssertEqual(subject.matchingDomains.sorted(), [
            "google.com",
            "youtube.com",
        ])
    }

    /// `prepare(uri:)` sets the domains matching the equivalent domains
    /// when URI to match has iosapp:// scheme.
    func test_prepare_matchDomainEquivalentDomainsiOSAppScheme() async {
        settingsService.fetchEquivalentDomainsResult = .success([
            [
                "google.com",
                "youtube.com",
            ],
        ])

        await subject.prepare(uri: "iosapp://example.com")
        XCTAssertEqual(Array(subject.matchingDomains), [
            "iosapp://example.com",
        ])
        XCTAssertEqual(Array(subject.matchingFuzzyDomains), [
            "example.com",
        ])
    }
} // swiftlint:disable:this file_length

import AuthenticationServices
import BitwardenSdk
import XCTest

@testable import BitwardenShared

class CredentialIdentityFactoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var subject: DefaultCredentialIdentityFactory!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DefaultCredentialIdentityFactory()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `createCredentialIdentities(from:)` creates the credential identities (one time code and password)
    /// from the given cipher view.
    func test_createCredentialIdentities_allIdentities() async throws {
        guard #available(iOS 18.0, *) else {
            throw XCTSkip("iOS 18.0 is required to run this test.")
        }

        let expectedName = "CipherName"
        let expectedUri = "https://example.com"
        let expectedUsername = "test"
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: expectedUri, match: .domain),
                ],
                username: expectedUsername,
                totp: "1234",
            ),
            name: expectedName,
        )
        let identities = await subject.createCredentialIdentities(from: cipher, accountHasPremium: true)
        XCTAssertEqual(identities.count, 2)
        let oneTimeCodeIdentity = try XCTUnwrap(identities[0] as? ASOneTimeCodeCredentialIdentity)
        let passwordIdentity = try XCTUnwrap(identities[1] as? ASPasswordCredentialIdentity)

        XCTAssertEqual(oneTimeCodeIdentity.label, expectedName)
        XCTAssertEqual(oneTimeCodeIdentity.serviceIdentifier.identifier, "example.com")
        XCTAssertEqual(
            oneTimeCodeIdentity.serviceIdentifier.type,
            ASCredentialServiceIdentifier.IdentifierType.domain,
        )
        XCTAssertEqual(oneTimeCodeIdentity.recordIdentifier, cipher.id)

        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, "example.com")
        XCTAssertEqual(
            passwordIdentity.serviceIdentifier.type,
            ASCredentialServiceIdentifier.IdentifierType.domain,
        )
        XCTAssertEqual(passwordIdentity.user, expectedUsername)
        XCTAssertEqual(passwordIdentity.recordIdentifier, cipher.id)
    }

    /// `createCredentialIdentities(from:)` creates the credential identities (one time code and password)
    /// from the given cipher view when some of the uris are nil, empty or have match `.never`.
    func test_createCredentialIdentities_allIdentitiesWithSomeUnmatchingUris() async throws {
        guard #available(iOS 18.0, *) else {
            throw XCTSkip("iOS 18.0 is required to run this test.")
        }

        let expectedName = "CipherName"
        let expectedUri = "https://example.com"
        let expectedUsername = "test"
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: nil, match: .domain),
                    .fixture(uri: "", match: .domain),
                    .fixture(uri: expectedUri, match: .domain),
                    .fixture(uri: nil, match: .never),
                    .fixture(uri: "https://example2.com", match: .never),
                ],
                username: expectedUsername,
                totp: "1234",
            ),
            name: expectedName,
        )
        let identities = await subject.createCredentialIdentities(from: cipher, accountHasPremium: true)
        XCTAssertEqual(identities.count, 2)
        let oneTimeCodeIdentity = try XCTUnwrap(identities[0] as? ASOneTimeCodeCredentialIdentity)
        let passwordIdentity = try XCTUnwrap(identities[1] as? ASPasswordCredentialIdentity)

        XCTAssertEqual(oneTimeCodeIdentity.label, expectedName)
        XCTAssertEqual(oneTimeCodeIdentity.serviceIdentifier.identifier, "example.com")
        XCTAssertEqual(
            oneTimeCodeIdentity.serviceIdentifier.type,
            ASCredentialServiceIdentifier.IdentifierType.domain,
        )
        XCTAssertEqual(oneTimeCodeIdentity.recordIdentifier, cipher.id)

        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, "example.com")
        XCTAssertEqual(
            passwordIdentity.serviceIdentifier.type,
            ASCredentialServiceIdentifier.IdentifierType.domain,
        )
        XCTAssertEqual(passwordIdentity.user, expectedUsername)
        XCTAssertEqual(passwordIdentity.recordIdentifier, cipher.id)
    }

    /// `createCredentialIdentities(from:accountHasPremium:)` creates one time code and password
    /// identities for each of the login's AutoFill URIs, including each unique service identifier
    /// only once.
    func test_createCredentialIdentities_multipleUris() async throws {
        guard #available(iOS 18.0, *) else {
            throw XCTSkip("iOS 18.0 is required to run this test.")
        }

        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "https://example.com", match: .domain),
                    .fixture(uri: "https://example.org/login", match: nil),
                    .fixture(uri: "https://never.com", match: .never),
                    .fixture(uri: "iosapp://com.example.app", match: nil),
                    .fixture(uri: "https://example.com/login", match: .domain),
                ],
                username: "test",
                totp: "1234",
            ),
        )
        let identities = await subject.createCredentialIdentities(from: cipher, accountHasPremium: true)
        XCTAssertEqual(identities.count, 6)

        let oneTimeCodeIdentities = try identities[0 ..< 3].map { identity in
            try XCTUnwrap(identity as? ASOneTimeCodeCredentialIdentity)
        }
        let passwordIdentities = try identities[3 ..< 6].map { identity in
            try XCTUnwrap(identity as? ASPasswordCredentialIdentity)
        }

        let expectedIdentifiers = ["example.com", "example.org", "iosapp://com.example.app"]
        let expectedTypes: [ASCredentialServiceIdentifier.IdentifierType] = [.domain, .domain, .URL]
        XCTAssertEqual(oneTimeCodeIdentities.map(\.serviceIdentifier.identifier), expectedIdentifiers)
        XCTAssertEqual(oneTimeCodeIdentities.map(\.serviceIdentifier.type), expectedTypes)
        XCTAssertEqual(oneTimeCodeIdentities.map(\.recordIdentifier), Array(repeating: cipher.id, count: 3))
        XCTAssertEqual(passwordIdentities.map(\.serviceIdentifier.identifier), expectedIdentifiers)
        XCTAssertEqual(passwordIdentities.map(\.serviceIdentifier.type), expectedTypes)
        XCTAssertEqual(passwordIdentities.map(\.recordIdentifier), Array(repeating: cipher.id, count: 3))
        XCTAssertEqual(passwordIdentities.map(\.user), Array(repeating: "test", count: 3))
    }

    /// `createCredentialIdentities(from:)` returns no credentials if the cipher view uris
    /// has match `.never`.
    func test_createCredentialIdentities_noCredentialsOnMatchNever() async throws {
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("iOS 17.0 is required to run this test.")
        }

        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "https://example.com", match: .never),
                ],
                username: "test",
                totp: "1234",
            ),
        )
        let identities = await subject.createCredentialIdentities(from: cipher, accountHasPremium: true)
        XCTAssertTrue(identities.isEmpty)
    }

    /// `createCredentialIdentities(from:)` returns no credentials if the cipher view has no uris
    func test_createCredentialIdentities_noUris() async throws {
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("iOS 17.0 is required to run this test.")
        }

        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                username: "test",
                totp: "1234",
            ),
        )
        let identities = await subject.createCredentialIdentities(from: cipher, accountHasPremium: true)
        XCTAssertTrue(identities.isEmpty)
    }

    /// `createCredentialIdentities(from:)` returns no credentials if the cipher view is not login.
    func test_createCredentialIdentities_notLogin() async throws {
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("iOS 17.0 is required to run this test.")
        }

        let cipher = CipherView.fixture(
            card: .fixture(),
        )
        let identities = await subject.createCredentialIdentities(from: cipher, accountHasPremium: true)
        XCTAssertTrue(identities.isEmpty)
    }

    /// `createCredentialIdentities(from:)` creates only OTC credential identity
    /// from the given cipher view when the cipher doesn't have username nor password..
    func test_createCredentialIdentities_otcIdentityWhenNoUsernameNorPassword() async throws {
        guard #available(iOS 18.0, *) else {
            throw XCTSkip("iOS 18.0 is required to run this test.")
        }

        let expectedName = "CipherName"
        let expectedUri = "https://example.com"
        let cipher = CipherView.fixture(
            login: .fixture(
                uris: [
                    .fixture(uri: expectedUri, match: .domain),
                ],
                totp: "1234",
            ),
            name: expectedName,
        )
        let identities = await subject.createCredentialIdentities(from: cipher, accountHasPremium: true)
        XCTAssertEqual(identities.count, 1)
        let oneTimeCodeIdentity = try XCTUnwrap(identities[0] as? ASOneTimeCodeCredentialIdentity)

        XCTAssertEqual(oneTimeCodeIdentity.label, expectedName)
        XCTAssertEqual(oneTimeCodeIdentity.serviceIdentifier.identifier, "example.com")
        XCTAssertEqual(
            oneTimeCodeIdentity.serviceIdentifier.type,
            ASCredentialServiceIdentifier.IdentifierType.domain,
        )
        XCTAssertEqual(oneTimeCodeIdentity.recordIdentifier, cipher.id)
    }

    /// `createCredentialIdentities(from:)` creates only password credential identity
    /// from the given cipher view when there is no totp.
    func test_createCredentialIdentities_passwordOnly() async throws {
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("iOS 17.0 is required to run this test.")
        }

        let expectedUri = "https://example.com"
        let expectedUsername = "test"
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: expectedUri, match: .domain),
                ],
                username: expectedUsername,
            ),
        )
        let identities = await subject.createCredentialIdentities(from: cipher, accountHasPremium: true)
        XCTAssertEqual(identities.count, 1)
        let passwordIdentity = try XCTUnwrap(identities[0] as? ASPasswordCredentialIdentity)

        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, "example.com")
        XCTAssertEqual(
            passwordIdentity.serviceIdentifier.type,
            ASCredentialServiceIdentifier.IdentifierType.domain,
        )
        XCTAssertEqual(passwordIdentity.user, expectedUsername)
        XCTAssertEqual(passwordIdentity.recordIdentifier, cipher.id)
    }

    /// `createCredentialIdentities(from:accountHasPremium:)` includes OTC identity when
    /// the account is not Premium but the organization uses TOTP.
    func test_createCredentialIdentities_totpAuthorizedViaOrg() async throws {
        guard #available(iOS 18.0, *) else {
            throw XCTSkip("iOS 18.0 is required to run this test.")
        }

        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "https://example.com", match: .domain),
                ],
                username: "test",
                totp: "1234",
            ),
            organizationUseTotp: true,
        )
        let identities = await subject.createCredentialIdentities(from: cipher, accountHasPremium: false)
        XCTAssertEqual(identities.count, 2)
        XCTAssertTrue(identities[0] is ASOneTimeCodeCredentialIdentity)
        XCTAssertTrue(identities[1] is ASPasswordCredentialIdentity)
    }

    /// `createCredentialIdentities(from:accountHasPremium:)` includes OTC identity when
    /// the account has Premium even if the organization does not use TOTP.
    func test_createCredentialIdentities_totpAuthorizedViaPremium() async throws {
        guard #available(iOS 18.0, *) else {
            throw XCTSkip("iOS 18.0 is required to run this test.")
        }

        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "https://example.com", match: .domain),
                ],
                username: "test",
                totp: "1234",
            ),
            organizationUseTotp: false,
        )
        let identities = await subject.createCredentialIdentities(from: cipher, accountHasPremium: true)
        XCTAssertEqual(identities.count, 2)
        XCTAssertTrue(identities[0] is ASOneTimeCodeCredentialIdentity)
        XCTAssertTrue(identities[1] is ASPasswordCredentialIdentity)
    }

    /// `createCredentialIdentities(from:accountHasPremium:)` returns only password identity when
    /// the account is not Premium and the organization does not use TOTP.
    func test_createCredentialIdentities_totpNotAuthorized() async throws {
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("iOS 17.0 is required to run this test.")
        }

        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "https://example.com", match: .domain),
                ],
                username: "test",
                totp: "1234",
            ),
            organizationUseTotp: false,
        )
        let identities = await subject.createCredentialIdentities(from: cipher, accountHasPremium: false)
        XCTAssertEqual(identities.count, 1)
        XCTAssertTrue(identities[0] is ASPasswordCredentialIdentity)
    }

    /// `createCredentialIdentities(from:)` returns no credentials if the cipher view uris
    /// are empty.
    func test_createCredentialIdentities_uriEmpty() async throws {
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("iOS 17.0 is required to run this test.")
        }

        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "", match: .domain),
                ],
                username: "test",
                totp: "1234",
            ),
        )
        let identities = await subject.createCredentialIdentities(from: cipher, accountHasPremium: true)
        XCTAssertTrue(identities.isEmpty)
    }

    /// `createCredentialIdentities(from:)` returns no credentials if the cipher view uris
    /// are `nil`.
    func test_createCredentialIdentities_uriNil() async throws {
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("iOS 17.0 is required to run this test.")
        }

        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: nil, match: .domain),
                ],
                username: "test",
                totp: "1234",
            ),
        )
        let identities = await subject.createCredentialIdentities(from: cipher, accountHasPremium: true)
        XCTAssertTrue(identities.isEmpty)
    }

    /// `createCredentialIdentities(from:accountHasPremium:)` uses the host as a `.domain`
    /// service identifier for both identities when the login URI doesn't have a scheme and uses
    /// the default match type.
    func test_createCredentialIdentities_uriWithoutScheme() async throws {
        guard #available(iOS 18.0, *) else {
            throw XCTSkip("iOS 18.0 is required to run this test.")
        }

        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "www.example.com", match: nil),
                ],
                username: "test",
                totp: "1234",
            ),
        )
        let identities = await subject.createCredentialIdentities(from: cipher, accountHasPremium: true)
        XCTAssertEqual(identities.count, 2)
        let oneTimeCodeIdentity = try XCTUnwrap(identities[0] as? ASOneTimeCodeCredentialIdentity)
        let passwordIdentity = try XCTUnwrap(identities[1] as? ASPasswordCredentialIdentity)

        XCTAssertEqual(oneTimeCodeIdentity.serviceIdentifier.identifier, "www.example.com")
        XCTAssertEqual(
            oneTimeCodeIdentity.serviceIdentifier.type,
            ASCredentialServiceIdentifier.IdentifierType.domain,
        )
        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, "www.example.com")
        XCTAssertEqual(
            passwordIdentity.serviceIdentifier.type,
            ASCredentialServiceIdentifier.IdentifierType.domain,
        )
    }

    /// `createPasswordCredentialIdentities(from:)` uses an iOS app URI unchanged as a `.URL`
    /// service identifier.
    func test_createPasswordCredentialIdentities_appUri() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "iosapp://com.example.app", match: .domain),
                ],
                username: "test",
            ),
        )
        let passwordIdentity = try XCTUnwrap(subject.createPasswordCredentialIdentities(from: cipher).first)
        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, "iosapp://com.example.app")
        XCTAssertEqual(passwordIdentity.serviceIdentifier.type, ASCredentialServiceIdentifier.IdentifierType.URL)
    }

    /// `createPasswordCredentialIdentities(from:)` uses the login URI unchanged as a `.URL`
    /// service identifier when the login URI has match `exact`.
    func test_createPasswordCredentialIdentities_exactMatch() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "https://www.example.com/login", match: .exact),
                ],
                username: "test",
            ),
        )
        let passwordIdentity = try XCTUnwrap(subject.createPasswordCredentialIdentities(from: cipher).first)
        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, "https://www.example.com/login")
        XCTAssertEqual(passwordIdentity.serviceIdentifier.type, ASCredentialServiceIdentifier.IdentifierType.URL)
    }

    /// `createPasswordCredentialIdentities(from:)` adds an `https://` scheme to the `.URL` service
    /// identifier when the login URI has match `exact` and doesn't have a scheme.
    func test_createPasswordCredentialIdentities_exactMatchWithoutScheme() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "www.example.com", match: .exact),
                ],
                username: "test",
            ),
        )
        let passwordIdentity = try XCTUnwrap(subject.createPasswordCredentialIdentities(from: cipher).first)
        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, "https://www.example.com")
        XCTAssertEqual(passwordIdentity.serviceIdentifier.type, ASCredentialServiceIdentifier.IdentifierType.URL)
    }

    /// `createPasswordCredentialIdentities(from:)` uses the host without its port as a `.domain`
    /// service identifier when the login URI has match `host`.
    func test_createPasswordCredentialIdentities_hostMatch() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "https://sub.example.com:8443/login", match: .host),
                ],
                username: "test",
            ),
        )
        let passwordIdentity = try XCTUnwrap(subject.createPasswordCredentialIdentities(from: cipher).first)
        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, "sub.example.com")
        XCTAssertEqual(passwordIdentity.serviceIdentifier.type, ASCredentialServiceIdentifier.IdentifierType.domain)
    }

    /// `createPasswordCredentialIdentities(from:)` uses the host as a `.domain` service
    /// identifier when the login URI has an `http://` scheme and a path.
    func test_createPasswordCredentialIdentities_httpScheme() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "http://example.com/login", match: .domain),
                ],
                username: "test",
            ),
        )
        let passwordIdentity = try XCTUnwrap(subject.createPasswordCredentialIdentities(from: cipher).first)
        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, "example.com")
        XCTAssertEqual(passwordIdentity.serviceIdentifier.type, ASCredentialServiceIdentifier.IdentifierType.domain)
    }

    /// `createPasswordCredentialIdentities(from:)` uses the IP address as a `.domain` service
    /// identifier when the login URI is an IP address and port without a scheme.
    func test_createPasswordCredentialIdentities_ipAddress() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "192.168.1.10:8000", match: .domain),
                ],
                username: "test",
            ),
        )
        let passwordIdentity = try XCTUnwrap(subject.createPasswordCredentialIdentities(from: cipher).first)
        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, "192.168.1.10")
        XCTAssertEqual(passwordIdentity.serviceIdentifier.type, ASCredentialServiceIdentifier.IdentifierType.domain)
    }

    /// `createPasswordCredentialIdentities(from:)` returns no identities when the login Uri is empty.
    func test_createPasswordCredentialIdentities_loginUriEmpty() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "", match: .domain),
                ],
                username: "expectedUsername",
            ),
        )
        let passwordIdentities = subject.createPasswordCredentialIdentities(from: cipher)
        XCTAssertTrue(passwordIdentities.isEmpty)
    }

    /// `createPasswordCredentialIdentities(from:)` returns no identities when the login Uri has match `never`.
    func test_createPasswordCredentialIdentities_loginUriNever() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "https://example.com", match: .never),
                ],
                username: "expectedUsername",
            ),
        )
        let passwordIdentities = subject.createPasswordCredentialIdentities(from: cipher)
        XCTAssertTrue(passwordIdentities.isEmpty)
    }

    /// `createPasswordCredentialIdentities(from:)` returns no identities when there are 0 login uris.
    func test_createPasswordCredentialIdentities_loginUrisEmpty() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [],
                username: "expectedUsername",
            ),
        )
        let passwordIdentities = subject.createPasswordCredentialIdentities(from: cipher)
        XCTAssertTrue(passwordIdentities.isEmpty)
    }

    /// `createPasswordCredentialIdentities(from:)` creates a password identity for each of the
    /// login's AutoFill URIs, using each URI's match type, and includes each unique service
    /// identifier only once.
    func test_createPasswordCredentialIdentities_multipleUris() {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "www.example.net", match: .exact),
                    .fixture(uri: "https://example.com/path", match: .startsWith),
                    .fixture(uri: "https://EXAMPLE.org:8080", match: .host),
                    .fixture(uri: "https://www.example.net/", match: .exact),
                    .fixture(uri: "https://example.org/login", match: .domain),
                ],
                username: "test",
            ),
        )
        let passwordIdentities = subject.createPasswordCredentialIdentities(from: cipher)

        XCTAssertEqual(
            passwordIdentities.map(\.serviceIdentifier.identifier),
            ["https://www.example.net", "https://example.com/path", "example.org"],
        )
        XCTAssertEqual(
            passwordIdentities.map(\.serviceIdentifier.type),
            [.URL, .URL, .domain],
        )
    }

    /// `createPasswordCredentialIdentities(from:)` returns no identities when cipher doesn't have login.
    func test_createPasswordCredentialIdentities_noLogin() throws {
        let cipher = CipherView.fixture(
            login: nil,
        )
        let passwordIdentities = subject.createPasswordCredentialIdentities(from: cipher)
        XCTAssertTrue(passwordIdentities.isEmpty)
    }

    /// `createPasswordCredentialIdentities(from:)` uses the login URI unchanged as a `.URL`
    /// service identifier when the login URI has match `regularExpression`.
    func test_createPasswordCredentialIdentities_regularExpressionMatch() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "^https://.*\\.example\\.com$", match: .regularExpression),
                ],
                username: "test",
            ),
        )
        let passwordIdentity = try XCTUnwrap(subject.createPasswordCredentialIdentities(from: cipher).first)
        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, "^https://.*\\.example\\.com$")
        XCTAssertEqual(passwordIdentity.serviceIdentifier.type, ASCredentialServiceIdentifier.IdentifierType.URL)
    }

    /// `createPasswordCredentialIdentities(from:)` keeps a `.domain` and a `.URL` service identifier
    /// for the same site, since they're different service identifiers.
    func test_createPasswordCredentialIdentities_sameSiteDifferentTypes() {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "https://example.com", match: .domain),
                    .fixture(uri: "https://example.com", match: .exact),
                ],
                username: "test",
            ),
        )
        let passwordIdentities = subject.createPasswordCredentialIdentities(from: cipher)

        XCTAssertEqual(
            passwordIdentities.map(\.serviceIdentifier.identifier),
            ["example.com", "https://example.com"],
        )
        XCTAssertEqual(
            passwordIdentities.map(\.serviceIdentifier.type),
            [.domain, .URL],
        )
    }

    /// `createPasswordCredentialIdentities(from:)` uses the login URI unchanged as a `.URL`
    /// service identifier when the login URI has match `startsWith`.
    func test_createPasswordCredentialIdentities_startsWithMatch() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "https://www.example.com/account", match: .startsWith),
                ],
                username: "test",
            ),
        )
        let passwordIdentity = try XCTUnwrap(subject.createPasswordCredentialIdentities(from: cipher).first)
        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, "https://www.example.com/account")
        XCTAssertEqual(passwordIdentity.serviceIdentifier.type, ASCredentialServiceIdentifier.IdentifierType.URL)
    }

    /// `createPasswordCredentialIdentities(from:)` returns the password credential from the cipher.
    func test_createPasswordCredentialIdentities_success() throws {
        let expectedUri = "https://example.com"
        let expectedUsername = "test"
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: expectedUri, match: .domain),
                ],
                username: expectedUsername,
            ),
        )
        let passwordIdentities = subject.createPasswordCredentialIdentities(from: cipher)
        XCTAssertEqual(passwordIdentities.count, 1)
        let passwordIdentity = try XCTUnwrap(passwordIdentities.first)
        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, "example.com")
        XCTAssertEqual(passwordIdentity.serviceIdentifier.type, ASCredentialServiceIdentifier.IdentifierType.domain)
        XCTAssertEqual(passwordIdentity.user, expectedUsername)
        XCTAssertEqual(passwordIdentity.recordIdentifier, cipher.id)
    }

    /// `createPasswordCredentialIdentities(from:)` uses the lowercased host as a `.domain`
    /// service identifier when the login URI contains uppercase characters.
    func test_createPasswordCredentialIdentities_uppercaseUri() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "HTTPS://WWW.EXAMPLE.COM/Login", match: .domain),
                ],
                username: "test",
            ),
        )
        let passwordIdentity = try XCTUnwrap(subject.createPasswordCredentialIdentities(from: cipher).first)
        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, "www.example.com")
        XCTAssertEqual(passwordIdentity.serviceIdentifier.type, ASCredentialServiceIdentifier.IdentifierType.domain)
    }

    /// `createPasswordCredentialIdentities(from:)` ignores leading and trailing whitespace and
    /// newlines in the login URI.
    func test_createPasswordCredentialIdentities_uriWithWhitespace() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "  www.example.com\n", match: .domain),
                ],
                username: "test",
            ),
        )
        let passwordIdentity = try XCTUnwrap(subject.createPasswordCredentialIdentities(from: cipher).first)
        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, "www.example.com")
        XCTAssertEqual(passwordIdentity.serviceIdentifier.type, ASCredentialServiceIdentifier.IdentifierType.domain)
    }

    /// `createPasswordCredentialIdentities(from:)` uses the host as a `.domain` service
    /// identifier when the login URI doesn't have a scheme.
    func test_createPasswordCredentialIdentities_uriWithoutScheme() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "www.example.com", match: .domain),
                ],
                username: "test",
            ),
        )
        let passwordIdentity = try XCTUnwrap(subject.createPasswordCredentialIdentities(from: cipher).first)
        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, "www.example.com")
        XCTAssertEqual(passwordIdentity.serviceIdentifier.type, ASCredentialServiceIdentifier.IdentifierType.domain)
    }

    /// `createPasswordCredentialIdentities(from:)` uses the host without its port as a `.domain`
    /// service identifier when the login URI is a host and port without a scheme.
    func test_createPasswordCredentialIdentities_uriWithoutSchemeWithPort() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "localhost:8080", match: .domain),
                ],
                username: "test",
            ),
        )
        let passwordIdentity = try XCTUnwrap(subject.createPasswordCredentialIdentities(from: cipher).first)
        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, "localhost")
        XCTAssertEqual(passwordIdentity.serviceIdentifier.type, ASCredentialServiceIdentifier.IdentifierType.domain)
    }

    /// `createPasswordCredentialIdentities(from:)` returns no identities when login username is empty.
    func test_createPasswordCredentialIdentities_usernameEmpty() throws {
        let expectedUri = "https://example.com"
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: expectedUri, match: .domain),
                ],
                username: "",
            ),
        )
        let passwordIdentities = subject.createPasswordCredentialIdentities(from: cipher)
        XCTAssertTrue(passwordIdentities.isEmpty)
    }

    /// `createPasswordCredentialIdentities(from:)` returns no identities when login username is `nil`.
    func test_createPasswordCredentialIdentities_usernameNil() throws {
        let expectedUri = "https://example.com"
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: expectedUri, match: .domain),
                ],
                username: nil,
            ),
        )
        let passwordIdentities = subject.createPasswordCredentialIdentities(from: cipher)
        XCTAssertTrue(passwordIdentities.isEmpty)
    }
} // swiftlint:disable:this file_length

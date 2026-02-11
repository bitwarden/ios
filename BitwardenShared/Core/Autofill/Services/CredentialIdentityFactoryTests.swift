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
        let identities = await subject.createCredentialIdentities(from: cipher)
        XCTAssertEqual(identities.count, 2)
        let oneTimeCodeIdentity = try XCTUnwrap(identities[0] as? ASOneTimeCodeCredentialIdentity)
        let passwordIdentity = try XCTUnwrap(identities[1] as? ASPasswordCredentialIdentity)

        XCTAssertEqual(oneTimeCodeIdentity.label, expectedName)
        XCTAssertEqual(oneTimeCodeIdentity.serviceIdentifier.identifier, expectedUri)
        XCTAssertEqual(
            oneTimeCodeIdentity.serviceIdentifier.type,
            ASCredentialServiceIdentifier.IdentifierType.URL,
        )
        XCTAssertEqual(oneTimeCodeIdentity.recordIdentifier, cipher.id)

        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, expectedUri)
        XCTAssertEqual(
            passwordIdentity.serviceIdentifier.type,
            ASCredentialServiceIdentifier.IdentifierType.URL,
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
        let identities = await subject.createCredentialIdentities(from: cipher)
        XCTAssertEqual(identities.count, 2)
        let oneTimeCodeIdentity = try XCTUnwrap(identities[0] as? ASOneTimeCodeCredentialIdentity)
        let passwordIdentity = try XCTUnwrap(identities[1] as? ASPasswordCredentialIdentity)

        XCTAssertEqual(oneTimeCodeIdentity.label, expectedName)
        XCTAssertEqual(oneTimeCodeIdentity.serviceIdentifier.identifier, expectedUri)
        XCTAssertEqual(
            oneTimeCodeIdentity.serviceIdentifier.type,
            ASCredentialServiceIdentifier.IdentifierType.URL,
        )
        XCTAssertEqual(oneTimeCodeIdentity.recordIdentifier, cipher.id)

        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, expectedUri)
        XCTAssertEqual(
            passwordIdentity.serviceIdentifier.type,
            ASCredentialServiceIdentifier.IdentifierType.URL,
        )
        XCTAssertEqual(passwordIdentity.user, expectedUsername)
        XCTAssertEqual(passwordIdentity.recordIdentifier, cipher.id)
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
        let identities = await subject.createCredentialIdentities(from: cipher)
        XCTAssertEqual(identities.count, 1)
        let oneTimeCodeIdentity = try XCTUnwrap(identities[0] as? ASOneTimeCodeCredentialIdentity)

        XCTAssertEqual(oneTimeCodeIdentity.label, expectedName)
        XCTAssertEqual(oneTimeCodeIdentity.serviceIdentifier.identifier, expectedUri)
        XCTAssertEqual(
            oneTimeCodeIdentity.serviceIdentifier.type,
            ASCredentialServiceIdentifier.IdentifierType.URL,
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
        let identities = await subject.createCredentialIdentities(from: cipher)
        XCTAssertEqual(identities.count, 1)
        let passwordIdentity = try XCTUnwrap(identities[0] as? ASPasswordCredentialIdentity)

        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, expectedUri)
        XCTAssertEqual(
            passwordIdentity.serviceIdentifier.type,
            ASCredentialServiceIdentifier.IdentifierType.URL,
        )
        XCTAssertEqual(passwordIdentity.user, expectedUsername)
        XCTAssertEqual(passwordIdentity.recordIdentifier, cipher.id)
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
        let identities = await subject.createCredentialIdentities(from: cipher)
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
        let identities = await subject.createCredentialIdentities(from: cipher)
        XCTAssertTrue(identities.isEmpty)
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
        let identities = await subject.createCredentialIdentities(from: cipher)
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
        let identities = await subject.createCredentialIdentities(from: cipher)
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
        let identities = await subject.createCredentialIdentities(from: cipher)
        XCTAssertTrue(identities.isEmpty)
    }

    /// `tryCreatePasswordCredentialIdentity(from:)` returns the password credential from the cipher.
    func test_tryCreatePasswordCredentialIdentity_success() throws {
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
        let passwordIdentity = try XCTUnwrap(
            subject.tryCreatePasswordCredentialIdentity(from: cipher),
        )
        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, expectedUri)
        XCTAssertEqual(passwordIdentity.serviceIdentifier.type, ASCredentialServiceIdentifier.IdentifierType.URL)
        XCTAssertEqual(passwordIdentity.user, expectedUsername)
        XCTAssertEqual(passwordIdentity.recordIdentifier, cipher.id)
    }

    /// `tryCreatePasswordCredentialIdentity(from:)` returns `nil` when cipher doesn't have login.
    func test_tryCreatePasswordCredentialIdentity_noLogin() throws {
        let cipher = CipherView.fixture(
            login: nil,
        )
        let passwordIdentity = subject.tryCreatePasswordCredentialIdentity(from: cipher)
        XCTAssertNil(passwordIdentity)
    }

    /// `tryCreatePasswordCredentialIdentity(from:)` returns `nil` when the login Uri has match `never`.
    func test_tryCreatePasswordCredentialIdentity_loginUriNever() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "https://example.com", match: .never),
                ],
                username: "expectedUsername",
            ),
        )
        let passwordIdentity = subject.tryCreatePasswordCredentialIdentity(from: cipher)
        XCTAssertNil(passwordIdentity)
    }

    /// `tryCreatePasswordCredentialIdentity(from:)` returns `nil` when the login Uri is empty.
    func test_tryCreatePasswordCredentialIdentity_loginUriEmpty() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: "", match: .domain),
                ],
                username: "expectedUsername",
            ),
        )
        let passwordIdentity = subject.tryCreatePasswordCredentialIdentity(from: cipher)
        XCTAssertNil(passwordIdentity)
    }

    /// `tryCreatePasswordCredentialIdentity(from:)` returns `nil` when there are 0 login uris.
    func test_tryCreatePasswordCredentialIdentity_loginUrisEmpty() throws {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [],
                username: "expectedUsername",
            ),
        )
        let passwordIdentity = subject.tryCreatePasswordCredentialIdentity(from: cipher)
        XCTAssertNil(passwordIdentity)
    }

    /// `tryCreatePasswordCredentialIdentity(from:)` returns `nil` when login username is `nil`.
    func test_tryCreatePasswordCredentialIdentity_usernameNil() throws {
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
        let passwordIdentity = subject.tryCreatePasswordCredentialIdentity(from: cipher)
        XCTAssertNil(passwordIdentity)
    }

    /// `tryCreatePasswordCredentialIdentity(from:)` returns `nil` when login username is empty.
    func test_tryCreatePasswordCredentialIdentity_usernameEmpty() throws {
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
        let passwordIdentity = subject.tryCreatePasswordCredentialIdentity(from: cipher)
        XCTAssertNil(passwordIdentity)
    }
}

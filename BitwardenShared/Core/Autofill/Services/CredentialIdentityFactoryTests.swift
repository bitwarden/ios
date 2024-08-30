import AuthenticationServices
import BitwardenSdk
import XCTest

@testable import BitwardenShared

class CredentialIdentityFactoryTests: BitwardenTestCase {
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
                username: expectedUsername
            )
        )
        let passwordIdentity = try XCTUnwrap(
            subject.tryCreatePasswordCredentialIdentity(from: cipher)
        )
        XCTAssertEqual(passwordIdentity.serviceIdentifier.identifier, expectedUri)
        XCTAssertEqual(passwordIdentity.serviceIdentifier.type, ASCredentialServiceIdentifier.IdentifierType.URL)
        XCTAssertEqual(passwordIdentity.user, expectedUsername)
        XCTAssertEqual(passwordIdentity.recordIdentifier, cipher.id)
    }

    /// `tryCreatePasswordCredentialIdentity(from:)` returns `nil` when cipher doesn't have login.
    func test_tryCreatePasswordCredentialIdentity_noLogin() throws {
        let cipher = CipherView.fixture(
            login: nil
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
                username: "expectedUsername"
            )
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
                username: "expectedUsername"
            )
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
                username: "expectedUsername"
            )
        )
        let passwordIdentity = subject.tryCreatePasswordCredentialIdentity(from: cipher)
        XCTAssertNil(passwordIdentity)
    }

    /// `tryCreatePasswordCredentialIdentity(from:)` returns `nil` when login username is `nil`.
    func test_tryCreatePasswordCredentialIdentity_usernameNil() throws {
        let expectedUri = "https://example.com"
        let expectedUsername = "test"
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: expectedUri, match: .domain),
                ],
                username: nil
            )
        )
        let passwordIdentity = subject.tryCreatePasswordCredentialIdentity(from: cipher)
        XCTAssertNil(passwordIdentity)
    }

    /// `tryCreatePasswordCredentialIdentity(from:)` returns `nil` when login username is empty.
    func test_tryCreatePasswordCredentialIdentity_usernameEmpty() throws {
        let expectedUri = "https://example.com"
        let expectedUsername = "test"
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "1234",
                uris: [
                    .fixture(uri: expectedUri, match: .domain),
                ],
                username: ""
            )
        )
        let passwordIdentity = subject.tryCreatePasswordCredentialIdentity(from: cipher)
        XCTAssertNil(passwordIdentity)
    }
}

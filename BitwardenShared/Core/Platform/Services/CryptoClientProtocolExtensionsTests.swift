import BitwardenSdk
import BitwardenSdkMocks
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class CryptoClientProtocolExtensionsTests: BitwardenTestCase {
    // MARK: Properties

    var subject: MockCryptoClientProtocol!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = MockCryptoClientProtocol()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    // `initializeUserCrypto(account:encryptionKeys:method:)` initializes the user crypto using a
    // user's master password.
    func test_initializeUserCrypto_masterPassword() async throws {
        try await subject.initializeUserCrypto(
            account: .fixture(),
            encryptionKeys: AccountEncryptionKeys(
                cryptographicState: .fixtureV2(),
                encryptedUserKey: "encryptedUserKey",
            ),
            method: .masterPasswordUnlock(
                password: "password123",
                masterPasswordUnlock: MasterPasswordUnlockData(
                    kdf: .pbkdf2(iterations: 600_000),
                    masterKeyWrappedUserKey: "MASTER_KEY_WRAPPED_USER_KEY",
                    salt: "SALT",
                ),
            ),
        )

        let request = try XCTUnwrap(subject.initializeUserCryptoReceivedReq)
        XCTAssertEqual(request.userId, "1")
        XCTAssertEqual(request.kdfParams, .pbkdf2(iterations: 600_000))
        XCTAssertEqual(request.email, "user@bitwarden.com")

        guard case let .v2(privateKey, signedPublicKey, signingKey, securityState) = request.accountCryptographicState
        else {
            XCTFail("Expected V2 accountCryptographicState")
            return
        }

        XCTAssertEqual(
            request.method,
            .masterPasswordUnlock(
                password: "password123",
                masterPasswordUnlock: MasterPasswordUnlockData(
                    kdf: .pbkdf2(iterations: 600_000),
                    masterKeyWrappedUserKey: "MASTER_KEY_WRAPPED_USER_KEY",
                    salt: "SALT",
                ),
            ),
        )
        XCTAssertEqual(privateKey, "WRAPPED_PRIVATE_KEY")
        XCTAssertEqual(signedPublicKey, "SIGNED_PUBLIC_KEY")
        XCTAssertEqual(signingKey, "WRAPPED_SIGNING_KEY")
        XCTAssertEqual(securityState, "SECURITY_STATE")
    }

    // `initializeUserCrypto(account:encryptionKeys:method:)` initializes the user crypto using a
    // user's PIN.
    func test_initializeUserCrypto_pin() async throws {
        try await subject.initializeUserCrypto(
            account: .fixture(),
            encryptionKeys: AccountEncryptionKeys(
                cryptographicState: .fixtureV2(),
                encryptedUserKey: "encryptedUserKey",
            ),
            method: .pin(pin: "1234", pinProtectedUserKey: "pinProtectedUserKey"),
        )

        let request = try XCTUnwrap(subject.initializeUserCryptoReceivedReq)
        XCTAssertEqual(request.userId, "1")
        XCTAssertEqual(request.kdfParams, .pbkdf2(iterations: 600_000))
        XCTAssertEqual(request.email, "user@bitwarden.com")
        XCTAssertEqual(request.method, .pin(pin: "1234", pinProtectedUserKey: "pinProtectedUserKey"))

        guard case let .v2(privateKey, signedPublicKey, signingKey, securityState) = request.accountCryptographicState
        else {
            XCTFail("Expected V2 accountCryptographicState")
            return
        }
        XCTAssertEqual(privateKey, "WRAPPED_PRIVATE_KEY")
        XCTAssertEqual(signedPublicKey, "SIGNED_PUBLIC_KEY")
        XCTAssertEqual(signingKey, "WRAPPED_SIGNING_KEY")
        XCTAssertEqual(securityState, "SECURITY_STATE")
    }
}

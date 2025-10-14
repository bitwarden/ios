import XCTest

@testable import BitwardenShared

class CryptoClientProtocolExtensionsTests: BitwardenTestCase {
    // MARK: Properties

    var subject: MockCryptoClient!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = MockCryptoClient()
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
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "encryptedUserKey",
            ),
            method: .password(password: "password123", userKey: "userKey"),
        )

        let request = try XCTUnwrap(subject.initializeUserCryptoRequest)
        XCTAssertEqual(request.userId, "1")
        XCTAssertEqual(request.kdfParams, .pbkdf2(iterations: 600_000))
        XCTAssertEqual(request.email, "user@bitwarden.com")
        XCTAssertEqual(request.method, .password(password: "password123", userKey: "userKey"))
        XCTAssertEqual(request.privateKey, "PRIVATE_KEY")
        XCTAssertEqual(request.securityState, "SECURITY_STATE")
        XCTAssertEqual(request.signingKey, "WRAPPED_SIGNING_KEY")
    }

    // `initializeUserCrypto(account:encryptionKeys:method:)` initializes the user crypto using a
    // user's master password and their master password unlock data.
    func test_initializeUserCrypto_masterPassword_masterPasswordUnlockData() async throws {
        try await subject.initializeUserCrypto(
            account: .fixture(profile: .fixture(
                userDecryptionOptions: UserDecryptionOptions(
                    hasMasterPassword: true,
                    masterPasswordUnlock: MasterPasswordUnlockResponseModel(
                        kdf: KdfConfig(kdfType: .pbkdf2sha256, iterations: 850_000),
                        masterKeyEncryptedUserKey: nil,
                        salt: nil,
                    ),
                    keyConnectorOption: nil,
                    trustedDeviceOption: nil,
                ),
            )),
            encryptionKeys: AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "encryptedUserKey",
            ),
            method: .password(password: "password123", userKey: "userKey"),
        )

        let request = try XCTUnwrap(subject.initializeUserCryptoRequest)
        XCTAssertEqual(request.userId, "1")
        XCTAssertEqual(request.kdfParams, .pbkdf2(iterations: 850_000))
        XCTAssertEqual(request.email, "user@bitwarden.com")
        XCTAssertEqual(request.method, .password(password: "password123", userKey: "userKey"))
        XCTAssertEqual(request.privateKey, "PRIVATE_KEY")
        XCTAssertEqual(request.securityState, "SECURITY_STATE")
        XCTAssertEqual(request.signingKey, "WRAPPED_SIGNING_KEY")
    }

    // `initializeUserCrypto(account:encryptionKeys:method:)` initializes the user crypto using a
    // user's PIN.
    func test_initializeUserCrypto_pin() async throws {
        try await subject.initializeUserCrypto(
            account: .fixture(),
            encryptionKeys: AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "encryptedUserKey",
            ),
            method: .pin(pin: "1234", pinProtectedUserKey: "pinProtectedUserKey"),
        )

        let request = try XCTUnwrap(subject.initializeUserCryptoRequest)
        XCTAssertEqual(request.userId, "1")
        XCTAssertEqual(request.kdfParams, .pbkdf2(iterations: 600_000))
        XCTAssertEqual(request.email, "user@bitwarden.com")
        XCTAssertEqual(request.method, .pin(pin: "1234", pinProtectedUserKey: "pinProtectedUserKey"))
        XCTAssertEqual(request.privateKey, "PRIVATE_KEY")
        XCTAssertEqual(request.securityState, "SECURITY_STATE")
        XCTAssertEqual(request.signingKey, "WRAPPED_SIGNING_KEY")
    }
}

import BitwardenSdk
import XCTest

@testable import BitwardenShared

class AuthRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var clientCrypto: MockClientCrypto!
    var subject: DefaultAuthRepository!
    var stateService: MockStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientCrypto = MockClientCrypto()
        stateService = MockStateService()

        subject = DefaultAuthRepository(
            clientCrypto: clientCrypto,
            stateService: stateService
        )
    }

    override func tearDown() {
        super.tearDown()

        clientCrypto = nil
        subject = nil
        stateService = nil
    }

    // MARK: Tests

    /// `unlockVault(password:)` unlocks the vault with the user's password.
    func test_unlockVault() async throws {
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(encryptedPrivateKey: "PRIVATE_KEY", encryptedUserKey: "USER_KEY"),
        ]

        await assertAsyncDoesNotThrow {
            try await subject.unlockVault(password: "password")
        }

        XCTAssertEqual(
            clientCrypto.initializeCryptoRequest,
            InitCryptoRequest(
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                password: "password",
                userKey: "USER_KEY",
                privateKey: "PRIVATE_KEY",
                organizationKeys: [:]
            )
        )
    }

    /// `unlockVault(password:)` throws an error if the vault is unable to be unlocked.
    func test_unlockVault_error() async {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.unlockVault(password: "")
        }
    }
}

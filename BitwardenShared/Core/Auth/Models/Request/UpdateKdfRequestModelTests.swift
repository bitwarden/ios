import BitwardenSdk
import XCTest

@testable import BitwardenShared

class UpdateKdfRequestModelTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(response:)` initializes `UpdateKdfRequestModel` from a `UpdateKdfResponse`.
    func test_init_response() {
        let subject = UpdateKdfRequestModel(
            response: UpdateKdfResponse(
                masterPasswordAuthenticationData: MasterPasswordAuthenticationData(
                    kdf: .pbkdf2(iterations: 600_000),
                    salt: "AUTHENTICATION_SALT",
                    masterPasswordAuthenticationHash: "MASTER_PASSWORD_AUTHENTICATION_HASH",
                ),
                masterPasswordUnlockData: MasterPasswordUnlockData(
                    kdf: .argon2id(iterations: 3, memory: 64, parallelism: 4),
                    masterKeyWrappedUserKey: "MASTER_KEY_WRAPPED_USER_KEY",
                    salt: "UNLOCK_SALT",
                ),
                oldMasterPasswordAuthenticationData: MasterPasswordAuthenticationData(
                    kdf: .pbkdf2(iterations: 100_000),
                    salt: "OLD_SALT",
                    masterPasswordAuthenticationHash: "OLD_MASTER_PASSWORD_AUTHENTICATION_HASH",
                ),
            ),
        )
        XCTAssertEqual(
            subject,
            UpdateKdfRequestModel(
                authenticationData: MasterPasswordAuthenticationDataRequestModel(
                    kdf: KdfConfig(kdfType: .pbkdf2sha256, iterations: 600_000),
                    masterPasswordAuthenticationHash: "MASTER_PASSWORD_AUTHENTICATION_HASH",
                    salt: "AUTHENTICATION_SALT",
                ),
                key: "MASTER_KEY_WRAPPED_USER_KEY",
                masterPasswordHash: "OLD_MASTER_PASSWORD_AUTHENTICATION_HASH",
                newMasterPasswordHash: "MASTER_PASSWORD_AUTHENTICATION_HASH",
                unlockData: MasterPasswordUnlockDataRequestModel(
                    kdf: KdfConfig(kdfType: .argon2id, iterations: 3, memory: 64, parallelism: 4),
                    masterKeyWrappedUserKey: "MASTER_KEY_WRAPPED_USER_KEY",
                    salt: "UNLOCK_SALT",
                ),
            ),
        )
    }
}

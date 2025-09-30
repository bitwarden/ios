import XCTest

@testable import BitwardenShared

class AccountTests: BitwardenTestCase {
    // MARK: Tests

    /// `kdfConfig` returns the default KDF config if the KDF values are `nil`.
    func test_kdfConfig_defaults() throws {
        let subject = Account.fixture(
            profile: .fixture(kdfIterations: nil, kdfMemory: nil, kdfParallelism: nil, kdfType: nil)
        )
        XCTAssertEqual(subject.kdf, KdfConfig(kdfType: .pbkdf2sha256, iterations: 600_000))
    }

    /// `kdfConfig` returns the KDF config for the account using the accounts KDF values.
    func test_kdfConfig_values() throws {
        let subject = Account.fixture(
            profile: .fixture(kdfIterations: 1_000_000, kdfMemory: 64, kdfParallelism: 4, kdfType: .argon2id)
        )
        XCTAssertEqual(
            subject.kdf,
            KdfConfig(kdfType: .argon2id, iterations: 1_000_000, memory: 64, parallelism: 4)
        )
    }

    /// `init(identityTokenResponseModel:)` initializes an account from an identity token response.
    func test_init_identityTokenResponseModel() throws {
        // swiftlint:disable:next line_length
        let accessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2OTY5MDg4NzksInN1YiI6IjEzNTEyNDY3LTljZmUtNDNiMC05NjlmLTA3NTM0MDg0NzY0YiIsIm5hbWUiOiJCaXR3YXJkZW4gVXNlciIsImVtYWlsIjoidXNlckBiaXR3YXJkZW4uY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImlhdCI6MTUxNjIzOTAyMiwicHJlbWl1bSI6ZmFsc2UsImFtciI6WyJBcHBsaWNhdGlvbiJdfQ.KDqC8kUaOAgBiUY8eeLa0a4xYWN8GmheXTFXmataFwM"
        let subject = try Account(
            identityTokenResponseModel: .fixture(accessToken: accessToken),
            environmentURLs: nil
        )

        XCTAssertEqual(
            subject,
            Account(
                profile: Account.AccountProfile(
                    avatarColor: nil,
                    email: "user@bitwarden.com",
                    emailVerified: nil,
                    forcePasswordResetReason: nil,
                    hasPremiumPersonally: false,
                    kdfIterations: 600_000,
                    kdfMemory: nil,
                    kdfParallelism: nil,
                    kdfType: .pbkdf2sha256,
                    name: "Bitwarden User",
                    orgIdentifier: nil,
                    stamp: nil,
                    userDecryptionOptions: UserDecryptionOptions(
                        hasMasterPassword: true,
                        keyConnectorOption: nil,
                        trustedDeviceOption: nil
                    ),
                    userId: "13512467-9cfe-43b0-969f-07534084764b"
                ),
                settings: Account.AccountSettings(environmentUrls: nil),
                _tokens: nil
            )
        )
    }

    func test_initials_oneName_short() throws {
        let subject = Account.fixture(
            profile: .fixture(
                email: "user@bitwarden.com",
                name: "AJ"
            )
        )
        let initials = subject.initials()

        XCTAssertEqual("AJ", initials)
    }

    func test_initials_oneName_long() throws {
        let subject = Account.fixture(
            profile: .fixture(
                email: "user@bitwarden.com",
                name: "User"
            )
        )
        let initials = subject.initials()

        XCTAssertEqual("US", initials)
    }

    func test_initials_twoNames() throws {
        let subject = Account.fixture(
            profile: .fixture(
                email: "user@bitwarden.com",
                name: "Bitwarden User"
            )
        )
        let initials = subject.initials()

        XCTAssertEqual("BU", initials)
    }

    func test_initials_threeNames() throws {
        let subject = Account.fixture(
            profile: .fixture(
                email: "user@bitwarden.com",
                name: "An Interesting User"
            )
        )
        let initials = subject.initials()

        XCTAssertEqual("AI", initials)
    }

    func test_initials_email_oneName() throws {
        let subject = Account.fixture(
            profile: .fixture(
                email: "user@bitwarden.com",
                name: nil
            )
        )
        let initials = subject.initials()

        XCTAssertEqual("US", initials)
    }

    func test_initials_email_oneName_short() throws {
        let subject = Account.fixture(
            profile: .fixture(
                email: "a@bitwarden.com",
                name: nil
            )
        )
        let initials = subject.initials()

        XCTAssertEqual("A", initials)
    }

    func test_initials_email_oneNamePlus() throws {
        let subject = Account.fixture(
            profile: .fixture(
                email: "user+1@bitwarden.com",
                name: nil
            )
        )
        let initials = subject.initials()

        XCTAssertEqual("U1", initials)
    }

    func test_initials_email_twoNamesDot() throws {
        let subject = Account.fixture(
            profile: .fixture(
                email: "test.user@bitwarden.com",
                name: nil
            )
        )
        let initials = subject.initials()

        XCTAssertEqual("TU", initials)
    }

    func test_initials_empty() throws {
        let subject = Account.fixture(
            profile: .fixture(
                email: "",
                name: nil
            )
        )
        let initials = subject.initials()

        XCTAssertNil(initials)
    }
}

import XCTest

@testable import BitwardenShared

class AccountTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(identityTokenResponseModel:)` initializes an account from an identity token response.
    func test_init_identityTokenResponseModel() throws {
        // swiftlint:disable:next line_length
        let accessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMzUxMjQ2Ny05Y2ZlLTQzYjAtOTY5Zi0wNzUzNDA4NDc2NGIiLCJuYW1lIjoiQml0d2FyZGVuIFVzZXIiLCJlbWFpbCI6InVzZXJAYml0d2FyZGVuLmNvbSIsImlhdCI6MTUxNjIzOTAyMiwicHJlbWl1bSI6ZmFsc2V9.Pbd74CpalStTjFTvUBaxmHkl4Z0gwVLHATVFIzvYpjE"
        let subject = try Account(identityTokenResponseModel: .fixture(accessToken: accessToken))

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
                tokens: Account.AccountTokens(
                    accessToken: accessToken,
                    refreshToken: "REFRESH_TOKEN"
                )
            )
        )
    }
}

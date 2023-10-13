import XCTest

@testable import BitwardenShared

class AccountTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(identityTokenResponseModel:)` initializes an account from an identity token response.
    func test_init_identityTokenResponseModel() throws {
        // swiftlint:disable:next line_length
        let accessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2OTY5MDg4NzksInN1YiI6IjEzNTEyNDY3LTljZmUtNDNiMC05NjlmLTA3NTM0MDg0NzY0YiIsIm5hbWUiOiJCaXR3YXJkZW4gVXNlciIsImVtYWlsIjoidXNlckBiaXR3YXJkZW4uY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImlhdCI6MTUxNjIzOTAyMiwicHJlbWl1bSI6ZmFsc2UsImFtciI6WyJBcHBsaWNhdGlvbiJdfQ.KDqC8kUaOAgBiUY8eeLa0a4xYWN8GmheXTFXmataFwM"
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

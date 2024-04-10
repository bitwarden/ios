import Foundation

@testable import BitwardenShared

extension Account {
    static func fixture(
        profile: AccountProfile = .fixture(),
        settings: AccountSettings = .fixture(),
        tokens: AccountTokens? = nil
    ) -> Account {
        Account(
            profile: profile,
            settings: settings,
            _tokens: tokens
        )
    }

    static func fixtureAccountLogin() -> Account {
        Account.fixture(
            profile: Account.AccountProfile.fixture(
                emailVerified: nil,
                hasPremiumPersonally: false,
                name: "Bitwarden User",
                stamp: nil,
                userDecryptionOptions: UserDecryptionOptions(
                    hasMasterPassword: true,
                    keyConnectorOption: nil,
                    trustedDeviceOption: TrustedDeviceUserDecryptionOption(
                        encryptedPrivateKey: "PRIVATE_KEY",
                        encryptedUserKey: "USER_KEY",
                        hasAdminApproval: true,
                        hasLoginApprovingDevice: true,
                        hasManageResetPasswordPermission: false
                    )
                ),
                userId: "13512467-9cfe-43b0-969f-07534084764b"
            ),
            settings: Account.AccountSettings(
                environmentUrls: EnvironmentUrlData(base: URL(string: "https://vault.bitwarden.com")!)
            ),
            tokens: nil
        )
    }
}

extension Account.AccountProfile {
    static func fixture(
        avatarColor: String? = nil,
        email: String = "user@bitwarden.com",
        emailVerified: Bool? = true,
        forcePasswordResetReason: ForcePasswordResetReason? = nil,
        hasPremiumPersonally: Bool? = true,
        kdfIterations: Int? = 600_000,
        kdfMemory: Int? = nil,
        kdfParallelism: Int? = nil,
        kdfType: KdfType? = .pbkdf2sha256,
        name: String? = nil,
        orgIdentifier: String? = nil,
        stamp: String? = "stamp",
        userDecryptionOptions: UserDecryptionOptions? = UserDecryptionOptions(
            hasMasterPassword: true,
            keyConnectorOption: nil,
            trustedDeviceOption: TrustedDeviceUserDecryptionOption(
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY",
                hasAdminApproval: true,
                hasLoginApprovingDevice: true,
                hasManageResetPasswordPermission: false
            )
        ),
        userId: String = "1"
    ) -> Account.AccountProfile {
        Account.AccountProfile(
            avatarColor: avatarColor,
            email: email,
            emailVerified: emailVerified,
            forcePasswordResetReason: forcePasswordResetReason,
            hasPremiumPersonally: hasPremiumPersonally,
            kdfIterations: kdfIterations,
            kdfMemory: kdfMemory,
            kdfParallelism: kdfParallelism,
            kdfType: kdfType,
            name: name,
            orgIdentifier: orgIdentifier,
            stamp: stamp,
            userDecryptionOptions: userDecryptionOptions,
            userId: userId
        )
    }
}

extension Account.AccountSettings {
    static func fixture(
        environmentUrls: EnvironmentUrlData? = .fixture()
    ) -> Account.AccountSettings {
        Account.AccountSettings(
            environmentUrls: environmentUrls
        )
    }
}

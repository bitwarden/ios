@testable import BitwardenShared

extension Account {
    static func fixture(
        profile: AccountProfile = .fixture(),
        settings: AccountSettings = .fixture(),
        tokens: AccountTokens = .fixture()
    ) -> Account {
        Account(
            profile: profile,
            settings: settings,
            tokens: tokens
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
        kdfIterations: Int = 600_000,
        kdfMemory: Int? = nil,
        kdfParallelism: Int? = nil,
        kdfType: KdfType = .pbkdf2sha256,
        name: String? = nil,
        orgIdentifier: String? = nil,
        stamp: String = "STAMP",
        userDecryptionOptions: UserDecryptionOptions? = nil,
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
        environmentUrls: EnvironmentUrlData = .fixture()
    ) -> Account.AccountSettings {
        Account.AccountSettings(
            environmentUrls: environmentUrls
        )
    }
}

extension Account.AccountTokens {
    static func fixture(
        accessToken: String = "ACCESS_TOKEN",
        refreshToken: String = "REFRESH_TOKEN"
    ) -> Account.AccountTokens {
        Account.AccountTokens(
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }
}

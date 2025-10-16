import Foundation

@testable import BitwardenShared

extension ProfileResponseModel {
    static func fixture(
        accountKeys: PrivateKeysResponseModel? = nil,
        avatarColor: String? = nil,
        creationDate: Date? = nil,
        culture: String? = nil,
        email: String? = nil,
        emailVerified: Bool = false,
        forcePasswordReset: Bool = false,
        id: String = UUID().uuidString,
        key: String? = nil,
        masterPasswordHint: String? = nil,
        name: String? = nil,
        organizations: [ProfileOrganizationResponseModel]? = nil,
        premium: Bool = false,
        premiumFromOrganization: Bool = false,
        privateKey: String? = nil,
        securityStamp: String? = nil,
        twoFactorEnabled: Bool = false,
        usesKeyConnector: Bool = false,
    ) -> ProfileResponseModel {
        self.init(
            accountKeys: accountKeys,
            avatarColor: avatarColor,
            creationDate: creationDate,
            culture: culture,
            email: email,
            emailVerified: emailVerified,
            forcePasswordReset: forcePasswordReset,
            id: id,
            key: key,
            masterPasswordHint: masterPasswordHint,
            name: name,
            organizations: organizations,
            premium: premium,
            premiumFromOrganization: premiumFromOrganization,
            privateKey: privateKey,
            securityStamp: securityStamp,
            twoFactorEnabled: twoFactorEnabled,
            usesKeyConnector: usesKeyConnector,
        )
    }
}

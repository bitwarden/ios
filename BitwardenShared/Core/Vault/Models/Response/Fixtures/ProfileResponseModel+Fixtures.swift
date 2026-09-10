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
        masterPasswordHint: String? = nil,
        name: String? = nil,
        organizations: [ProfileOrganizationResponseModel]? = nil,
        organizationsNew: [ProfileOrganizationResponseModel]? = nil,
        premium: Bool = false,
        premiumFromOrganization: Bool = false,
        privateKey: String? = nil,
        providerOrganizations: [ProfileProviderOrganizationResponseModel]? = nil,
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
            masterPasswordHint: masterPasswordHint,
            name: name,
            organizations: organizations,
            organizationsNew: organizationsNew,
            premium: premium,
            premiumFromOrganization: premiumFromOrganization,
            privateKey: privateKey,
            providerOrganizations: providerOrganizations,
            securityStamp: securityStamp,
            twoFactorEnabled: twoFactorEnabled,
            usesKeyConnector: usesKeyConnector,
        )
    }
}
